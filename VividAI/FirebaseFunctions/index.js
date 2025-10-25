const functions = require('firebase-functions');
const admin = require('firebase-admin');
const crypto = require('crypto');

// Initialize Firebase Admin
admin.initializeApp();

const db = admin.firestore();

// MARK: - Trial Validation Function
exports.validateTrial = functions.https.onCall(async (data, context) => {
    // Verify App Check token
    if (!context.app) {
        throw new functions.https.HttpsError('failed-precondition', 'App Check token required');
    }
    
    // Verify Firebase Auth token
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    }
    
    const { deviceId, trialId, startDate, isActive, deviceFingerprint, userId } = data;
    
    try {
        // Check for abuse patterns
        const abuseResult = await detectTrialAbuse(deviceId, deviceFingerprint, userId);
        if (abuseResult.isAbuse) {
            return {
                isValid: false,
                isActive: false,
                daysRemaining: 0,
                serverValidated: true,
                abuseDetected: true,
                reason: abuseResult.reason
            };
        }
        
        // Get trial data from Firestore
        const trialRef = db.collection('trials').doc(trialId);
        const trialDoc = await trialRef.get();
        
        if (!trialDoc.exists) {
            return {
                isValid: false,
                isActive: false,
                daysRemaining: 0,
                serverValidated: true,
                abuseDetected: false,
                reason: 'Trial not found'
            };
        }
        
        const trialData = trialDoc.data();
        const trialStartDate = trialData.startDate.toDate();
        const trialEndDate = new Date(trialStartDate.getTime() + (3 * 24 * 60 * 60 * 1000)); // 3 days
        const now = new Date();
        
        const isExpired = now > trialEndDate;
        const daysRemaining = Math.max(0, Math.ceil((trialEndDate - now) / (24 * 60 * 60 * 1000)));
        
        // Update trial status if expired
        if (isExpired && trialData.isActive) {
            await trialRef.update({
                isActive: false,
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
        }
        
        return {
            isValid: !isExpired,
            isActive: !isExpired && trialData.isActive,
            daysRemaining: daysRemaining,
            serverValidated: true,
            abuseDetected: false,
            reason: isExpired ? 'Trial expired' : null
        };
        
    } catch (error) {
        console.error('Error validating trial:', error);
        throw new functions.https.HttpsError('internal', 'Failed to validate trial');
    }
});

// MARK: - Start Trial Function
exports.startTrial = functions.https.onCall(async (data, context) => {
    // Verify App Check token
    if (!context.app) {
        throw new functions.https.HttpsError('failed-precondition', 'App Check token required');
    }
    
    // Verify Firebase Auth token
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    }
    
    const { trialType, deviceFingerprint, userId, deviceInfo } = data;
    
    try {
        // Check for existing trials
        const existingTrialsQuery = await db.collection('trials')
            .where('userId', '==', userId)
            .where('isActive', '==', true)
            .get();
        
        if (!existingTrialsQuery.empty) {
            return {
                isValid: false,
                isActive: false,
                daysRemaining: 0,
                serverValidated: true,
                abuseDetected: true,
                reason: 'User already has an active trial'
            };
        }
        
        // Check for abuse patterns
        const abuseResult = await detectTrialAbuse(null, deviceFingerprint, userId);
        if (abuseResult.isAbuse) {
            return {
                isValid: false,
                isActive: false,
                daysRemaining: 0,
                serverValidated: true,
                abuseDetected: true,
                reason: abuseResult.reason
            };
        }
        
        // Create new trial
        const trialId = crypto.randomUUID();
        const now = new Date();
        
        const trialData = {
            userId: userId,
            deviceId: deviceInfo.vendorId,
            trialId: trialId,
            trialType: trialType,
            startDate: admin.firestore.Timestamp.fromDate(now),
            isActive: true,
            deviceFingerprint: deviceFingerprint,
            deviceInfo: deviceInfo,
            serverValidated: true,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        };
        
        await db.collection('trials').doc(trialId).set(trialData);
        
        // Log trial start event
        await db.collection('analytics').add({
            event: 'trial_started',
            userId: userId,
            trialId: trialId,
            trialType: trialType,
            deviceFingerprint: deviceFingerprint,
            timestamp: admin.firestore.FieldValue.serverTimestamp()
        });
        
        return {
            isValid: true,
            isActive: true,
            daysRemaining: 3,
            serverValidated: true,
            abuseDetected: false,
            reason: null
        };
        
    } catch (error) {
        console.error('Error starting trial:', error);
        throw new functions.https.HttpsError('internal', 'Failed to start trial');
    }
});

// MARK: - Abuse Detection Function
exports.detectAbuse = functions.https.onCall(async (data, context) => {
    // Verify App Check token
    if (!context.app) {
        throw new functions.https.HttpsError('failed-precondition', 'App Check token required');
    }
    
    // Verify Firebase Auth token
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    }
    
    const { userId, deviceFingerprint, deviceInfo } = data;
    
    try {
        const abuseResult = await detectTrialAbuse(null, deviceFingerprint, userId);
        
        return {
            isAbuse: abuseResult.isAbuse,
            reason: abuseResult.reason,
            confidence: abuseResult.confidence,
            detectedPatterns: abuseResult.detectedPatterns
        };
        
    } catch (error) {
        console.error('Error detecting abuse:', error);
        throw new functions.https.HttpsError('internal', 'Failed to detect abuse');
    }
});

// MARK: - Helper Functions

async function detectTrialAbuse(deviceId, deviceFingerprint, userId) {
    const detectedPatterns = [];
    let confidence = 0.0;
    let reason = null;
    
    try {
        // Check for multiple trials from same device fingerprint
        const fingerprintTrialsQuery = await db.collection('trials')
            .where('deviceFingerprint', '==', deviceFingerprint)
            .get();
        
        if (fingerprintTrialsQuery.size > 1) {
            detectedPatterns.push('multiple_trials_same_fingerprint');
            confidence += 0.4;
        }
        
        // Check for multiple trials from same user
        const userTrialsQuery = await db.collection('trials')
            .where('userId', '==', userId)
            .get();
        
        if (userTrialsQuery.size > 1) {
            detectedPatterns.push('multiple_trials_same_user');
            confidence += 0.3;
        }
        
        // Check for suspicious device patterns
        if (deviceInfo && deviceInfo.isSimulator) {
            detectedPatterns.push('simulator_usage');
            confidence += 0.2;
        }
        
        // Check for rapid trial attempts
        const recentTrialsQuery = await db.collection('trials')
            .where('userId', '==', userId)
            .where('createdAt', '>', admin.firestore.Timestamp.fromDate(new Date(Date.now() - 24 * 60 * 60 * 1000)))
            .get();
        
        if (recentTrialsQuery.size > 0) {
            detectedPatterns.push('rapid_trial_attempts');
            confidence += 0.3;
        }
        
        // Check for suspicious timing patterns
        const currentHour = new Date().getHours();
        if (currentHour < 6 || currentHour > 22) {
            detectedPatterns.push('suspicious_timing');
            confidence += 0.1;
        }
        
        // Check for device fingerprint manipulation
        if (deviceFingerprint.length < 32 || deviceFingerprint === 'test' || deviceFingerprint === 'fake') {
            detectedPatterns.push('manipulated_fingerprint');
            confidence += 0.5;
        }
        
        const isAbuse = confidence > 0.5;
        
        if (isAbuse) {
            reason = `Abuse detected: ${detectedPatterns.join(', ')}`;
        }
        
        return {
            isAbuse: isAbuse,
            reason: reason,
            confidence: confidence,
            detectedPatterns: detectedPatterns
        };
        
    } catch (error) {
        console.error('Error in abuse detection:', error);
        return {
            isAbuse: false,
            reason: null,
            confidence: 0.0,
            detectedPatterns: []
        };
    }
}

// MARK: - Scheduled Functions

// Clean up expired trials daily
exports.cleanupExpiredTrials = functions.pubsub.schedule('0 2 * * *').onRun(async (context) => {
    console.log('Running cleanup of expired trials');
    
    const now = new Date();
    const threeDaysAgo = new Date(now.getTime() - (3 * 24 * 60 * 60 * 1000));
    
    const expiredTrialsQuery = await db.collection('trials')
        .where('startDate', '<', admin.firestore.Timestamp.fromDate(threeDaysAgo))
        .where('isActive', '==', true)
        .get();
    
    const batch = db.batch();
    expiredTrialsQuery.docs.forEach(doc => {
        batch.update(doc.ref, {
            isActive: false,
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
    });
    
    await batch.commit();
    
    console.log(`Cleaned up ${expiredTrialsQuery.size} expired trials`);
    return null;
});

// Generate abuse reports weekly
exports.generateAbuseReport = functions.pubsub.schedule('0 3 * * 1').onRun(async (context) => {
    console.log('Generating weekly abuse report');
    
    const weekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    
    const abuseEventsQuery = await db.collection('analytics')
        .where('event', '==', 'abuse_detected')
        .where('timestamp', '>', admin.firestore.Timestamp.fromDate(weekAgo))
        .get();
    
    const report = {
        totalAbuseEvents: abuseEventsQuery.size,
        generatedAt: admin.firestore.FieldValue.serverTimestamp(),
        period: 'weekly'
    };
    
    await db.collection('reports').add(report);
    
    console.log(`Generated abuse report: ${abuseEventsQuery.size} events`);
    return null;
});

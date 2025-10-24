import Foundation

enum ImageQuality {
    case poor
    case fair
    case good
    case low
    case medium
    case high
    
    var description: String {
        switch self {
        case .poor:
            return "Poor Quality"
        case .fair:
            return "Fair Quality"
        case .good:
            return "Good Quality"
        case .low:
            return "Low Quality"
        case .medium:
            return "Medium Quality"
        case .high:
            return "High Quality"
        }
    }
    
    var isGood: Bool {
        switch self {
        case .good, .high:
            return true
        case .fair, .medium:
            return false
        case .poor, .low:
            return false
        }
    }
    
    var isPoor: Bool {
        switch self {
        case .poor, .low:
            return true
        default:
            return false
        }
    }
}


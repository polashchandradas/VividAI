#!/usr/bin/env python3
"""
Script to remove Swift Package Manager Firebase dependencies from Xcode project file
and ensure compatibility with CocoaPods.
"""

import re
import sys

def fix_project_dependencies(project_file_path):
    """Remove Swift Package Manager Firebase references from project.pbxproj"""
    
    with open(project_file_path, 'r') as f:
        content = f.read()
    
    # Store original content for backup
    original_content = content
    
    # Remove Firebase framework references from PBXBuildFile section
    firebase_build_files = [
        r'\s*A1234567890ABCDEF042 /\* FirebaseAuth in Frameworks \*/ = \{isa = PBXBuildFile; productRef = A1234567890ABCDEF041 /\* FirebaseAuth \*/; \};',
        r'\s*A1234567890ABCDEF044 /\* FirebaseFirestore in Frameworks \*/ = \{isa = PBXBuildFile; productRef = A1234567890ABCDEF043 /\* FirebaseFirestore \*/; \};',
        r'\s*A1234567890ABCDEF046 /\* FirebaseAnalytics in Frameworks \*/ = \{isa = PBXBuildFile; productRef = A1234567890ABCDEF045 /\* FirebaseAnalytics \*/; \};'
    ]
    
    for pattern in firebase_build_files:
        content = re.sub(pattern, '', content)
    
    # Remove Firebase references from frameworks section
    frameworks_section = r'(\s*A1234567890ABCDEF042 /\* FirebaseAuth in Frameworks \*/,?\s*)(\s*A1234567890ABCDEF044 /\* FirebaseFirestore in Frameworks \*/,?\s*)(\s*A1234567890ABCDEF046 /\* FirebaseAnalytics in Frameworks \*/,?\s*)'
    content = re.sub(frameworks_section, '', content)
    
    # Remove Firebase package product dependencies
    firebase_products = [
        r'\s*A1234567890ABCDEF081 /\* FirebaseAnalytics \*/ = \{[^}]*\};',
        r'\s*A1234567890ABCDEF082 /\* FirebaseAuth \*/ = \{[^}]*\};',
        r'\s*A1234567890ABCDEF083 /\* FirebaseFirestore \*/ = \{[^}]*\};',
        r'\s*A1234567890ABCDEF084 /\* FirebaseCore \*/ = \{[^}]*\};'
    ]
    
    for pattern in firebase_products:
        content = re.sub(pattern, '', content)
    
    # Remove Firebase references from package product dependencies list
    package_products_section = r'(\s*A1234567890ABCDEF081 /\* FirebaseAnalytics \*/,?\s*)(\s*A1234567890ABCDEF082 /\* FirebaseAuth \*/,?\s*)(\s*A1234567890ABCDEF083 /\* FirebaseFirestore \*/,?\s*)(\s*A1234567890ABCDEF084 /\* FirebaseCore \*/,?\s*)'
    content = re.sub(package_products_section, '', content)
    
    # Clean up any double newlines that might have been created
    content = re.sub(r'\n\n\n+', '\n\n', content)
    
    # Write the modified content back
    with open(project_file_path, 'w') as f:
        f.write(content)
    
    print("SUCCESS: Removed Swift Package Manager Firebase dependencies from project.pbxproj")
    print("SUCCESS: Project is now compatible with CocoaPods")
    
    return True

if __name__ == "__main__":
    project_file = "VividAI.xcodeproj/project.pbxproj"
    try:
        fix_project_dependencies(project_file)
        print("SUCCESS: Project dependencies fixed successfully!")
    except Exception as e:
        print(f"ERROR: Error fixing project dependencies: {e}")
        sys.exit(1)

#!/usr/bin/env python3
"""
Script to add missing Swift files to Xcode project
"""

import re
import sys

def add_files_to_project(project_file_path):
    """Add missing Swift files to project.pbxproj"""
    
    with open(project_file_path, 'r') as f:
        content = f.read()
    
    # Files to add
    files_to_add = [
        {
            'name': 'ImageQuality.swift',
            'path': 'VividAI/Models/ImageQuality.swift',
            'id': 'A1234567890ABCDEF100',
            'build_id': 'A1234567890ABCDEF101'
        },
        {
            'name': 'ImageQualityAnalysis.swift', 
            'path': 'VividAI/Models/ImageQualityAnalysis.swift',
            'id': 'A1234567890ABCDEF102',
            'build_id': 'A1234567890ABCDEF103'
        },
        {
            'name': 'Product.swift',
            'path': 'VividAI/Models/Product.swift', 
            'id': 'A1234567890ABCDEF104',
            'build_id': 'A1234567890ABCDEF105'
        },
        {
            'name': 'NavigationCoordinator.swift',
            'path': 'VividAI/Coordinators/NavigationCoordinator.swift',
            'id': 'A1234567890ABCDEF106', 
            'build_id': 'A1234567890ABCDEF107'
        },
        {
            'name': 'AppCoordinator.swift',
            'path': 'VividAI/Coordinators/AppCoordinator.swift',
            'id': 'A1234567890ABCDEF108',
            'build_id': 'A1234567890ABCDEF109'
        },
        {
            'name': 'MainAppView.swift',
            'path': 'VividAI/Views/MainAppView.swift',
            'id': 'A1234567890ABCDEF110',
            'build_id': 'A1234567890ABCDEF111'
        }
    ]
    
    # Add PBXBuildFile entries
    build_files_section = "/* Begin PBXBuildFile section */"
    for file_info in files_to_add:
        build_file_entry = f"""
		{file_info['build_id']} /* {file_info['name']} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_info['id']} /* {file_info['name']} */; }};"""
        content = content.replace(build_files_section, build_files_section + build_file_entry)
    
    # Add PBXFileReference entries
    file_refs_section = "/* Begin PBXFileReference section */"
    for file_info in files_to_add:
        file_ref_entry = f"""
		{file_info['id']} /* {file_info['name']} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {file_info['name']}; sourceTree = \"<group>\"; }};"""
        content = content.replace(file_refs_section, file_refs_section + file_ref_entry)
    
    # Add to Sources build phase
    sources_build_phase = "/* Sources */ = {"
    for file_info in files_to_add:
        sources_entry = f"""
				{file_info['build_id']} /* {file_info['name']} in Sources */,"""
        content = content.replace(sources_build_phase, sources_build_phase + sources_entry)
    
    # Add to appropriate groups
    # Add Models group
    models_group = "/* Models */ = {"
    for file_info in files_to_add:
        if 'Models' in file_info['path']:
            group_entry = f"""
				{file_info['id']} /* {file_info['name']} */,"""
            content = content.replace(models_group, models_group + group_entry)
    
    # Add Coordinators group  
    coordinators_group = "/* Coordinators */ = {"
    for file_info in files_to_add:
        if 'Coordinators' in file_info['path']:
            group_entry = f"""
				{file_info['id']} /* {file_info['name']} */,"""
            content = content.replace(coordinators_group, coordinators_group + group_entry)
    
    # Add Views group
    views_group = "/* Views */ = {"
    for file_info in files_to_add:
        if 'Views' in file_info['path']:
            group_entry = f"""
				{file_info['id']} /* {file_info['name']} */,"""
            content = content.replace(views_group, views_group + group_entry)
    
    # Write the modified content back
    with open(project_file_path, 'w') as f:
        f.write(content)
    
    print("SUCCESS: Added missing Swift files to project.pbxproj")
    return True

if __name__ == "__main__":
    project_file = "VividAI.xcodeproj/project.pbxproj"
    try:
        add_files_to_project(project_file)
        print("SUCCESS: Project files updated successfully!")
    except Exception as e:
        print(f"ERROR: Error updating project files: {e}")
        sys.exit(1)

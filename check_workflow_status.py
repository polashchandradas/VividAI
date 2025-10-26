#!/usr/bin/env python3
"""
VividAI Workflow Status Checker

This script checks the status of GitHub Actions workflows for the VividAI project.
"""

import os
import subprocess
import json
from datetime import datetime

def get_latest_commit():
    """Get the latest commit hash and message."""
    try:
        result = subprocess.run(
            ["git", "log", "-1", "--pretty=format:%h %s"],
            capture_output=True,
            text=True,
            cwd=os.getcwd()
        )
        return result.stdout.strip()
    except Exception as e:
        return f"Error: {e}"

def get_workflow_files():
    """Get list of workflow files."""
    workflow_dir = ".github/workflows"
    if not os.path.exists(workflow_dir):
        return []
    
    workflows = []
    for file in os.listdir(workflow_dir):
        if file.endswith(".yml") or file.endswith(".yaml"):
            workflows.append(file)
    return sorted(workflows)

def parse_workflow_name(file_path):
    """Extract workflow name from YAML file."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            for line in f:
                if line.startswith("name:"):
                    return line.replace("name:", "").strip().strip('"').strip("'")
    except Exception as e:
        return f"Error: {e}"
    return "Unknown"

def get_workflow_details():
    """Get details about all workflow files."""
    workflows = []
    workflow_dir = ".github/workflows"
    
    if not os.path.exists(workflow_dir):
        return []
    
    for file in sorted(os.listdir(workflow_dir)):
        if file.endswith((".yml", ".yaml")):
            file_path = os.path.join(workflow_dir, file)
            name = parse_workflow_name(file_path)
            workflows.append({
                "file": file,
                "name": name,
                "path": file_path
            })
    
    return workflows

def print_status():
    """Print workflow status report."""
    print("\n" + "="*80)
    print("VividAI Workflow Status Report")
    print("="*80)
    
    # Get latest commit
    latest_commit = get_latest_commit()
    print(f"\nLatest Commit: {latest_commit}")
    
    # Get workflows
    workflows = get_workflow_details()
    
    if not workflows:
        print("\n[ERROR] No workflow files found in .github/workflows")
        return
    
    print(f"\nFound {len(workflows)} workflow(s):\n")
    
    for i, workflow in enumerate(workflows, 1):
        print(f"{i}. {workflow['name']}")
        print(f"   File: {workflow['file']}")
        print(f"   Path: {workflow['path']}")
        print()
    
    print("\n" + "="*80)
    print("NEXT STEPS:")
    print("="*80)
    print("\n1. Go to https://github.com/polashchandradas/VividAI/actions")
    print("2. Check the status of each workflow:")
    for i, workflow in enumerate(workflows, 1):
        print(f"   - {workflow['name']}")
    print("\n3. Look for green checkmarks on all workflows")
    print("4. If any workflow fails, check the logs for errors")
    print("5. Download IPA artifacts from successful builds")
    print("\n" + "="*80)
    print("Common Issues to Watch For:")
    print("="*80)
    print("\n[ERROR] 'Multiple commands produce Info.plist'")
    print("   -> Should be fixed in commit 91603aa")
    print("\n[ERROR] 'App bundle not found'")
    print("   -> Check if build completed successfully")
    print("\n[ERROR] 'App executable missing'")
    print("   -> Check if app bundle is valid")
    print("\n[ERROR] 'BUILD FAILED'")
    print("   -> Check build logs for specific errors")
    print("\n" + "="*80)

if __name__ == "__main__":
    print_status()


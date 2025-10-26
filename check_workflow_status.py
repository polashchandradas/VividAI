#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
GitHub Actions Workflow Status Checker
Checks the status of recent workflows for the VividAI repository
"""

import requests
import json
import time
from datetime import datetime

def check_workflow_status():
    """Check the status of recent GitHub Actions workflows"""
    
    # GitHub API endpoint for workflow runs
    url = "https://api.github.com/repos/polashchandradas/VividAI/actions/runs"
    
    headers = {
        "Accept": "application/vnd.github.v3+json",
        "User-Agent": "VividAI-Workflow-Checker"
    }
    
    try:
        print("Checking GitHub Actions workflow status...")
        print("=" * 60)
        
        response = requests.get(url, headers=headers)
        
        if response.status_code == 200:
            data = response.json()
            workflows = data.get('workflow_runs', [])
            
            if not workflows:
                print("No workflow runs found")
                return
            
            print(f"Found {len(workflows)} recent workflow runs")
            print()
            
            # Show last 5 workflows
            for i, workflow in enumerate(workflows[:5]):
                workflow_name = workflow.get('name', 'Unknown')
                status = workflow.get('status', 'Unknown')
                conclusion = workflow.get('conclusion', 'Unknown')
                created_at = workflow.get('created_at', 'Unknown')
                html_url = workflow.get('html_url', '')
                
                # Parse timestamp
                try:
                    dt = datetime.fromisoformat(created_at.replace('Z', '+00:00'))
                    time_str = dt.strftime('%Y-%m-%d %H:%M:%S UTC')
                except:
                    time_str = created_at
                
                # Status emoji
                if conclusion == 'success':
                    status_emoji = "[SUCCESS]"
                elif conclusion == 'failure':
                    status_emoji = "[FAILED]"
                elif conclusion == 'cancelled':
                    status_emoji = "[CANCELLED]"
                elif status == 'in_progress':
                    status_emoji = "[RUNNING]"
                else:
                    status_emoji = "[UNKNOWN]"
                
                print(f"{status_emoji} Workflow #{i+1}: {workflow_name}")
                print(f"   Status: {status}")
                print(f"   Conclusion: {conclusion}")
                print(f"   Created: {time_str}")
                print(f"   URL: {html_url}")
                print()
                
                # Check if this is the most recent workflow
                if i == 0:
                    if conclusion == 'success':
                        print("Latest workflow completed successfully!")
                    elif conclusion == 'failure':
                        print("Latest workflow failed - check the logs for details")
                    elif status == 'in_progress':
                        print("Latest workflow is still running...")
                    else:
                        print(f"Latest workflow status: {status} ({conclusion})")
                    print()
            
        else:
            print(f"Failed to fetch workflow data: {response.status_code}")
            print(f"Response: {response.text}")
            
    except Exception as e:
        print(f"Error checking workflow status: {e}")

if __name__ == "__main__":
    check_workflow_status()
#!/bin/bash

# Cleanup script for Terraform Logic App deployment
set -e

echo "🧹 Logic App Terraform Cleanup Script"
echo "======================================"

# Check if Terraform state exists
if [ ! -f ".terraform/terraform.tfstate" ] && [ ! -f "terraform.tfstate" ]; then
    echo "ℹ️  No Terraform state found. Nothing to clean up."
    exit 0
fi

# Show current state
echo "📋 Current deployed resources:"
terraform show

echo ""
read -p "🤔 Are you sure you want to destroy all resources? This cannot be undone! (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cleanup cancelled"
    exit 1
fi

# Destroy resources
echo "🧹 Destroying resources..."
terraform destroy -auto-approve

echo "✅ All resources have been destroyed!"
echo "ℹ️  Note: terraform.tfstate backup files remain for recovery if needed."
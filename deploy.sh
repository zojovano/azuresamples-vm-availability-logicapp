#!/bin/bash

# Deploy script for Terraform Logic App deployment
set -e

echo "🚀 Logic App Terraform Deployment Script"
echo "========================================="

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo "📝 terraform.tfvars not found. Creating from example..."
    cp terraform.tfvars.example terraform.tfvars
    echo "⚠️  Please edit terraform.tfvars with your actual values:"
    echo "   - subscription_id: Your Azure subscription ID"
    echo "   - email_recipient: Your email address for notifications"
    echo ""
    echo "Then run this script again."
    exit 1
fi

# Validate setup
echo "🔍 Running validation checks..."
./validate.sh

# Initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init

# Show plan
echo "📋 Showing deployment plan..."
terraform plan

# Ask for confirmation
read -p "🤔 Do you want to proceed with the deployment? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deployment cancelled"
    exit 1
fi

# Apply changes
echo "🚀 Deploying Logic App..."
terraform apply -auto-approve

echo "✅ Deployment completed!"
echo ""
echo "📋 Important next steps:"
echo "1. Go to the Azure portal and find your Logic App"
echo "2. Authorize the Office 365 connection"
echo "3. Copy the HTTP trigger URL from the Logic App"
echo "4. Configure your Azure Monitor alert to use this URL as an action"
echo ""
echo "🎉 Your VM Availability monitoring Logic App is ready!"
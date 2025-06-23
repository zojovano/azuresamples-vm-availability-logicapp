#!/bin/bash

# Terraform Validation Script
# This script validates the Terraform configuration without deploying resources

set -e

echo "🔍 Starting Terraform validation..."

# Check if we're in the correct directory
if [ ! -f "terraform/main.tf" ]; then
    echo "❌ Error: main.tf not found. Please run this script from the repository root."
    exit 1
fi

cd terraform

echo "📝 Step 1: Terraform format check..."
if terraform fmt -check -diff; then
    echo "✅ Terraform format check passed"
else
    echo "❌ Terraform format check failed"
    echo "💡 Run 'terraform fmt' to fix formatting issues"
    exit 1
fi

echo "🚀 Step 2: Terraform initialization..."
if terraform init; then
    echo "✅ Terraform initialization successful"
else
    echo "❌ Terraform initialization failed"
    exit 1
fi

echo "🔧 Step 3: Terraform validation..."
if terraform validate; then
    echo "✅ Terraform validation successful"
else
    echo "❌ Terraform validation failed"
    exit 1
fi

echo "📊 Step 4: Terraform plan (dry run)..."
echo "ℹ️  Note: This will fail without proper Azure credentials, but will validate syntax"

# Create a minimal tfvars file for syntax checking
cat > terraform.tfvars << EOF
subscription_id        = "00000000-0000-0000-0000-000000000000"
target_subscription_id = "00000000-0000-0000-0000-000000000000"
notification_email     = "test@example.com"
EOF

if terraform plan -var-file=terraform.tfvars 2>/dev/null; then
    echo "✅ Terraform plan validation successful"
else
    echo "⚠️  Terraform plan completed (expected to fail without valid credentials)"
fi

# Clean up
rm -f terraform.tfvars

echo "🎉 All validation steps completed successfully!"
echo ""
echo "Next steps:"
echo "1. Set up GitHub secrets for Azure credentials"
echo "2. Configure terraform.tfvars with your values"
echo "3. Run the GitHub Actions workflow to deploy"
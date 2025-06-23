#!/bin/bash

# Validation script for Terraform Logic App deployment
set -e

echo "🔍 Validating Terraform configuration..."

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed"
    exit 1
fi

echo "✅ Terraform is installed: $(terraform version -json | jq -r '.terraform_version')"

# Check if required files exist
required_files=("main.tf" "variables.tf" "logicapp.tf" "outputs.tf" "terraform.tfvars.example" "logicapp.json")
for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "❌ Required file $file is missing"
        exit 1
    fi
    echo "✅ File $file exists"
done

# Initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init

# Validate configuration
echo "🔍 Validating Terraform configuration..."
terraform validate

# Check if logicapp.json is valid JSON
echo "🔍 Validating logicapp.json..."
if jq empty logicapp.json > /dev/null 2>&1; then
    echo "✅ logicapp.json is valid JSON"
else
    echo "❌ logicapp.json is not valid JSON"
    exit 1
fi

# Format check
echo "🔧 Checking Terraform formatting..."
if terraform fmt -check=true -diff=true; then
    echo "✅ Terraform files are properly formatted"
else
    echo "⚠️  Terraform files need formatting. Run 'terraform fmt' to fix."
fi

echo "🎉 All validations passed!"
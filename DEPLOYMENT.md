# GitHub Actions Deployment Guide

This guide explains how to set up and use the GitHub Actions workflow to deploy the VM Availability Logic App to your Azure subscription.

## Overview

The GitHub Actions workflow automates the deployment of:
- Azure Logic App with VM availability monitoring workflow
- User-assigned managed identity for secure API access
- Office 365 connection for email notifications
- Role assignments for Resource Graph access

## Prerequisites

### 1. Azure App Registration and Federated Identity Setup

Create an App Registration with federated identity for secure GitHub Actions authentication:

```bash
# Create app registration
az ad app create \
  --display-name "logic-app-deployment-oidc" \
  --sign-in-audience AzureADMyOrg

# Get the application ID
APP_ID=$(az ad app list --display-name "logic-app-deployment-oidc" --query "[0].appId" -o tsv)

# Create service principal
az ad sp create --id $APP_ID

# Get the service principal object ID
SP_OBJECT_ID=$(az ad sp list --display-name "logic-app-deployment-oidc" --query "[0].id" -o tsv)

# Assign roles to the service principal
az role assignment create \
  --assignee $SP_OBJECT_ID \
  --role "Contributor" \
  --scope "/subscriptions/YOUR_SUBSCRIPTION_ID"

# Additional role assignment for managed identity operations
az role assignment create \
  --assignee $SP_OBJECT_ID \
  --role "User Access Administrator" \
  --scope "/subscriptions/YOUR_SUBSCRIPTION_ID"

# Configure federated identity for GitHub Actions
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-actions-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:YOUR_GITHUB_USERNAME/azuresamples-vm-availability-logicapp:ref:refs/heads/main",
    "description": "GitHub Actions Main Branch",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# Optional: Add federated credential for pull requests
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-actions-pr",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:YOUR_GITHUB_USERNAME/azuresamples-vm-availability-logicapp:pull_request",
    "description": "GitHub Actions Pull Requests",
    "audiences": ["api://AzureADTokenExchange"]
  }'

echo "App ID (use as AZURE_CLIENT_ID): $APP_ID"
```

**Important**: Replace `YOUR_GITHUB_USERNAME` with your actual GitHub username and `YOUR_SUBSCRIPTION_ID` with your Azure subscription ID.

### 2. Required GitHub Secrets

Configure these secrets in your GitHub repository (Settings → Secrets and variables → Actions):

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `AZURE_CLIENT_ID` | App Registration application ID | `12345678-1234-1234-1234-123456789012` |
| `AZURE_SUBSCRIPTION_ID` | Target Azure subscription ID | `87654321-4321-4321-4321-210987654321` |
| `AZURE_TENANT_ID` | Azure tenant ID | `539d8bb1-bbd5-4f9d-836d-223c3e6d1e43` |
| `AZURE_TARGET_SUBSCRIPTION_ID` | Subscription to monitor for VM alerts | Same as AZURE_SUBSCRIPTION_ID or different |
| `NOTIFICATION_EMAIL` | Email for alert notifications | `admin@yourcompany.com` |
| `STATE_STORAGE_ACCOUNT` | Azure Storage account name for Terraform state | `mystorageaccount` |
| `STATE_CONTAINER` | Azure Storage container name for Terraform state | `tfstate` |
| `STATE_RESOURCE_GROUP` | Azure Resource Group containing the storage account | `rg-terraform-state` |
| `STORAGE-ACCESS-KEY` | Storage account access key for Terraform state | `ZmFrZWFjY2Vzc2tleQ==` |

**Note**: With federated identity, you no longer need to store the `AZURE_CLIENT_SECRET` as a GitHub secret, enhancing security by eliminating long-lived credentials.

### 3. Office 365 Connection Authorization

After deployment, you'll need to authorize the Office 365 connection:

1. Go to Azure Portal → Resource Groups → Your Logic App Resource Group
2. Open the Office 365 API Connection
3. Click "Edit API connection"
4. Click "Authorize" and sign in with your Office 365 account
5. Save the connection

## Deployment Workflows

### Automatic Deployment

**Trigger**: Push to `main` branch with changes in `terraform/` directory

```bash
git add terraform/
git commit -m "Update Logic App configuration"
git push origin main
```

**Process**:
1. Terraform format check
2. Terraform initialization
3. Terraform validation
4. Terraform apply (auto-approved)
5. Output deployment details

### Pull Request Validation

**Trigger**: Pull request targeting `main` branch with changes in `terraform/` directory

**Process**:
1. Terraform format check
2. Terraform initialization
3. Terraform validation
4. Terraform plan (no changes applied)
5. Plan results posted as PR comment

### Manual Deployment

**Trigger**: Manual workflow dispatch

1. Go to GitHub repository → Actions tab
2. Select "Deploy Logic App Infrastructure"
3. Click "Run workflow"
4. Select branch (usually `main`)
5. Choose action:
   - **plan**: Preview changes without applying
   - **apply**: Deploy infrastructure
   - **destroy**: Remove all infrastructure

## Configuration Customization

### Terraform Variables

You can customize the deployment by modifying variables in `terraform/variables.tf` or by setting them in the GitHub workflow.

Key variables:
- `resource_group_name`: Name of the resource group (default: "rg-vm-availability-logicapp")
- `location`: Azure region (default: "East US")
- `logic_app_name`: Name of the Logic App (default: "la-vm-availability-monitor")
- `notification_email`: Email for notifications (set via GitHub secret)

### Workflow Environment

The workflow uses a `production` environment for additional security. You can:
- Require manual approval for deployments
- Set environment-specific secrets
- Add protection rules

## Monitoring and Troubleshooting

### Workflow Logs

View detailed logs in GitHub Actions:
1. Go to Actions tab
2. Click on the workflow run
3. Expand job steps to see detailed output

### Common Issues

**Issue**: `Error: Insufficient privileges to complete the operation`
**Solution**: Ensure the App Registration service principal has both "Contributor" and "User Access Administrator" roles

**Issue**: `Error: AADSTS70021: No matching federated identity record found`
**Solution**: Verify that the federated identity credentials are configured correctly for your GitHub repository and branch

**Issue**: `Error: Office 365 connection not authorized`
**Solution**: Manually authorize the Office 365 connection in Azure Portal (see step 3 in Prerequisites)

**Issue**: `Error: Logic App deployment failed`
**Solution**: Check that all required secrets are set correctly and the target subscription exists

### Terraform State

The workflow uses Azure Storage as a remote backend for Terraform state. This requires the following secrets to be configured:
- `STATE_STORAGE_ACCOUNT`: Azure Storage account name for Terraform state
- `STATE_CONTAINER`: Azure Storage container name for Terraform state  
- `STATE_RESOURCE_GROUP`: Azure Resource Group containing the storage account
- `STORAGE-ACCESS-KEY`: Storage account access key for authenticating to the storage backend

**Benefits of remote state:**
- State file is stored securely in Azure Storage
- Enables collaboration between team members
- Provides state locking to prevent concurrent modifications
- Automatic backup and versioning capabilities

## Security Considerations

1. **Federated Identity**: Uses OpenID Connect (OIDC) for secure authentication without long-lived secrets
2. **Secrets Management**: Minimal sensitive values stored as GitHub secrets (no client secrets required)
3. **Least Privilege**: App Registration service principal has minimal required permissions
4. **Managed Identity**: Logic App uses managed identity for Azure API access
5. **Environment Protection**: Production environment can require approvals

## Next Steps

After successful deployment:

1. **Configure VM Alerts**: Set up Azure Monitor alerts to trigger the Logic App
2. **Test the Workflow**: Send a test HTTP request to the Logic App trigger URL
3. **Monitor Performance**: Use Azure Monitor to track Logic App execution
4. **Customize Logic**: Modify the workflow logic for your specific requirements

## Support

For issues with:
- **GitHub Actions**: Check workflow logs and GitHub documentation
- **Terraform**: Review Terraform logs and Azure provider documentation
- **Logic App**: Use Azure Portal diagnostics and logs
- **Azure Resources**: Check Azure Portal for resource status and configuration
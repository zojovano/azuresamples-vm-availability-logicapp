# Azure Sample - Combine VM Availability Alert and Resource Graph based VM Health Status with Logic App Action

## Summary

Use LogicApp as an Alert action and decide whether to send a notification (e.g. e-mail) or not based on additional information (Azure Resource Health information in this case) when VM Availability metrics threshold is reached.

## Deployment Options

### Option 1: Terraform Deployment (Recommended)

#### Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) installed
- Azure CLI installed and logged in (`az login`)
- Appropriate Azure permissions to create Logic Apps, API Connections, and Role Assignments

#### Steps

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd azuresamples-vm-availability-logicapp
   ```

2. Copy the example variables file and customize it:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. Edit `terraform.tfvars` with your values:
   ```hcl
   subscription_id = "your-subscription-id"
   email_recipient = "your-email@example.com"
   location        = "East US"
   ```

4. Initialize and deploy with Terraform:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

   Or use the automated deployment script:
   ```bash
   ./deploy.sh
   ```

5. (Optional) Run the validation script to test your setup:
   ```bash
   ./validate.sh
   ```

6. After deployment:
   - Note the Logic App callback URL from the output
   - Configure your Azure Monitor alert to use the Logic App as an action
   - You'll need to authorize the Office 365 connection in the Azure portal

#### Terraform Configuration

The Terraform deployment creates:
- Resource Group
- Logic App (Consumption tier) with the workflow from `logicapp.json`
- Office 365 API Connection
- Managed Identity with Reader permissions for Azure Resource Graph
- All necessary role assignments

#### Cleanup

To remove all deployed resources:
```bash
terraform destroy
```

Or use the automated cleanup script:
```bash
./cleanup.sh
```

### Option 2: Manual Deployment

For manual deployment, follow the original steps below and use the workflow definition in [logicapp.json](logicapp.json).

## Steps


![alt text](image.png)

1) Azure VM Availability (preview) Metric used to define Azure Alert

![alt text](image-4.png)

1.1) Alert Definition - Conditions

![alt text](image-5.png)

1.2) Azure Alerts showing VM Availability alert triggered


![alt text](image-1.png)


2) Azure Resource Graph query used to retrieve Azure VM resource health information

![alt text](image-6.png)

3) Logic App with the workflow to:
   
- Receive alert
- Query Azure Resource Graph API to retrieve Resource Health information
- Decide based on the status whether to send e-mail notification or ignore the alert

> [!NOTE]
> Logic App Workflow code is available in the [logicapp.json](logicapp.json)

![alt text](image-2.png)

1) Logic App with the workflow - Condition 

IF "VirtualMachineDeallocationInitiated" (means a user has requested VM to be stopped) then ignore the Alert

![alt text](image-3.png)

![alt text](image-7.png)

## References

- https://learn.microsoft.com/en-us/azure/azure-monitor/alerts/alerts-logic-apps?tabs=send-email
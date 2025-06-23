output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.main.name
}

output "logic_app_name" {
  description = "Name of the created Logic App"
  value       = var.logic_app_name
}

output "logic_app_id" {
  description = "ID of the created Logic App"
  value       = jsondecode(azurerm_resource_group_template_deployment.logic_app.output_content).logicAppId.value
}

output "managed_identity_principal_id" {
  description = "Principal ID of the managed identity"
  value       = azurerm_user_assigned_identity.logic_app.principal_id
}

output "logic_app_workflow_callback_url" {
  description = "HTTP trigger callback URL for the Logic App workflow"
  value       = jsondecode(azurerm_resource_group_template_deployment.logic_app.output_content).callbackUrl.value
  sensitive   = true
}

output "storage_account_name" {
  description = "Storage account not needed for consumption Logic App"
  value       = "N/A - Consumption Logic App"
}
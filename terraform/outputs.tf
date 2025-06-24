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
  value       = azurerm_logic_app_standard.main.id
}

output "managed_identity_principal_id" {
  description = "Principal ID of the managed identity"
  value       = azurerm_user_assigned_identity.logic_app.principal_id
}

output "logic_app_workflow_callback_url" {
  description = "Default hostname for the Logic App Standard (workflow URLs need to be configured within the Logic App)"
  value       = "https://${azurerm_logic_app_standard.main.default_hostname}"
  sensitive   = false
}

output "workflow_trigger_url" {
  description = "Base URL for the vm-monitor workflow (full callback URL needs to be retrieved from Azure portal or CLI)"
  value       = "https://${azurerm_logic_app_standard.main.default_hostname}/runtime/webhooks/workflow/api/management/workflows/vm-monitor/triggers/When_a_HTTP_request_is_received/listCallbackUrl?api-version=2020-05-01-preview"
  sensitive   = false
}

output "storage_account_name" {
  description = "Storage account name for Logic App Standard"
  value       = azurerm_storage_account.logic_app.name
}

output "app_service_plan_name" {
  description = "WorkflowStandard Plan name for Logic App Standard"
  value       = azurerm_service_plan.logic_app.name
}

output "storage_availability_alert_name" {
  description = "Name of the storage availability metric alert"
  value       = azurerm_monitor_metric_alert.storage_availability.name
}

output "office365_connection_name" {
  description = "Name of the Office 365 API connection"
  value       = azurerm_api_connection.office365.name
}
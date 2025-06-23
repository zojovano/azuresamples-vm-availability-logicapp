output "logic_app_name" {
  description = "Name of the deployed Logic App"
  value       = azurerm_logic_app_workflow.main.name
}

output "logic_app_id" {
  description = "ID of the deployed Logic App"
  value       = azurerm_logic_app_workflow.main.id
}

output "logic_app_access_endpoint" {
  description = "Access endpoint for the Logic App"
  value       = azurerm_logic_app_workflow.main.access_endpoint
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "logic_app_principal_id" {
  description = "Principal ID of the Logic App's managed identity"
  value       = azurerm_logic_app_workflow.main.identity[0].principal_id
}

output "office365_connection_id" {
  description = "ID of the Office 365 API connection"
  value       = azurerm_api_connection.office365.id
}
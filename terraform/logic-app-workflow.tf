# Logic App Standard workflow files deployment

# Local values for workflow configuration
locals {
  # Read and prepare the workflow definition from logicapp.json
  workflow_definition = jsondecode(file("${path.root}/../logicapp.json"))

  # Extract just the definition part for Logic App Standard format
  standard_workflow = {
    definition = local.workflow_definition.definition
    kind       = local.workflow_definition.kind
  }
}

# Create host.json for Logic App Standard
resource "azapi_resource_action" "upload_host_json" {
  type                   = "Microsoft.Web/sites@2022-03-01"
  resource_id            = azurerm_logic_app_standard.main.id
  action                 = "hostruntime/admin/vfs/site/wwwroot/host.json"
  method                 = "PUT"
  response_export_values = ["*"]

  body = jsonencode({
    version         = "2.0"
    functionTimeout = "00:05:00"
    healthMonitor = {
      enabled              = true
      healthCheckInterval  = "00:00:30"
      healthCheckWindow    = "00:02:00"
      healthCheckThreshold = 6
      counterThreshold     = 0.80
    }
    logging = {
      fileLoggingMode = "debugOnly"
      logLevel = {
        default = "Information"
      }
    }
    extensionBundle = {
      id      = "Microsoft.Azure.Functions.ExtensionBundle.Workflows"
      version = "[1.*, 2.0.0)"
    }
  })

  depends_on = [azurerm_logic_app_standard.main]
}

# Create connections.json for Office 365 connection
resource "azapi_resource_action" "upload_connections_json" {
  type                   = "Microsoft.Web/sites@2022-03-01"
  resource_id            = azurerm_logic_app_standard.main.id
  action                 = "hostruntime/admin/vfs/site/wwwroot/connections.json"
  method                 = "PUT"
  response_export_values = ["*"]

  body = jsonencode({
    managedApiConnections = {
      office365 = {
        api = {
          id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Web/locations/${azurerm_resource_group.main.location}/managedApis/office365"
        }
        connection = {
          id = azurerm_api_connection.office365.id
        }
        connectionRuntimeUrl = "https://${azurerm_logic_app_standard.main.default_hostname}"
        authentication = {
          type = "ManagedServiceIdentity"
        }
      }
    }
  })

  depends_on = [
    azurerm_logic_app_standard.main,
    azurerm_api_connection.office365
  ]
}

# Create the workflow folder and upload workflow.json
resource "azapi_resource_action" "upload_workflow_json" {
  type                   = "Microsoft.Web/sites@2022-03-01"
  resource_id            = azurerm_logic_app_standard.main.id
  action                 = "hostruntime/admin/vfs/site/wwwroot/vm-monitor/workflow.json"
  method                 = "PUT"
  response_export_values = ["*"]

  body = jsonencode(local.standard_workflow)

  depends_on = [
    azapi_resource_action.upload_host_json,
    azapi_resource_action.upload_connections_json
  ]
}
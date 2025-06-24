# Logic App Standard workflow files deployment

# Note: The workflow definition deployment is now handled via Azure CLI in GitHub Actions
# The logicapp.json file contains the workflow definition that gets deployed via CLI

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

# Note: Logic App workflow deployment is now handled via Azure CLI in GitHub Actions
# See .github/workflows/deploy.yml for the workflow deployment step
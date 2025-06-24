# Logic App Standard workflow files deployment via zip package

# Create a data source for the zip file with dynamic content
locals {
  # Read and prepare the workflow definition from workflow file
  workflow_definition = jsondecode(file("${path.module}/workflows/logicappalert/logicapp.json"))

  # Prepare connections.json content with dynamic values
  connections_content = {
    managedApiConnections = {
      office365 = {
        api = {
          id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Web/locations/${azurerm_resource_group.main.location}/managedApis/office365"
        }
        connection = {
          id = azurerm_api_connection.office365.id
        }
        connectionRuntimeUrl = "https://${var.logic_app_name}.azurewebsites.net"
        authentication = {
          type = "ManagedServiceIdentity"
        }
      }
    }
  }

  # Host.json configuration
  host_content = {
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
  }
}

# Create individual files for the Logic App
resource "local_file" "host_json" {
  content  = jsonencode(local.host_content)
  filename = "${path.module}/temp_workflows/host.json"
}

resource "local_file" "connections_json" {
  content  = jsonencode(local.connections_content)
  filename = "${path.module}/temp_workflows/connections.json"
}

resource "local_file" "workflow_json" {
  content  = jsonencode(local.workflow_definition)
  filename = "${path.module}/temp_workflows/vm-monitor/workflow.json"
}

# Create the zip file with all workflow files
data "archive_file" "workflows" {
  type        = "zip"
  output_path = "${path.module}/workflows.zip"

  source_dir = "${path.module}/temp_workflows"

  depends_on = [
    local_file.host_json,
    local_file.connections_json,
    local_file.workflow_json
  ]
}

# Deploy the workflow zip file to Logic App Standard
resource "azapi_resource_action" "deploy_workflows_zip" {
  type        = "Microsoft.Web/sites@2022-03-01"
  resource_id = azurerm_logic_app_standard.main.id
  action      = "extensions/zipdeploy"
  method      = "POST"

  body = filebase64(data.archive_file.workflows.output_path)

  depends_on = [
    azurerm_logic_app_standard.main,
    data.archive_file.workflows
  ]
}
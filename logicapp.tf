# Get current Azure client configuration
data "azurerm_client_config" "current" {}

# Create Office 365 API Connection
resource "azurerm_api_connection" "office365" {
  name                = var.office365_connection_name
  resource_group_name = azurerm_resource_group.main.name
  managed_api_id      = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/providers/Microsoft.Web/locations/${var.location}/managedApis/office365"
  display_name        = "Office 365 Connection"

  tags = var.tags
}

# Load and modify the workflow definition from the existing logicapp.json
locals {
  # Read the existing workflow definition
  original_workflow = jsondecode(file("${path.module}/logicapp.json"))
  
  # Create modified workflow with parameterized values
  workflow_definition = {
    "$schema"      = local.original_workflow.definition["$schema"]
    contentVersion = local.original_workflow.definition.contentVersion
    
    triggers = local.original_workflow.definition.triggers
    
    actions = merge(
      local.original_workflow.definition.actions,
      {
        # Update the Resource Graph action to use the parameterized subscription ID
        Call_Azure_Resource_Graph_Explorer = merge(
          local.original_workflow.definition.actions.Call_Azure_Resource_Graph_Explorer,
          {
            inputs = merge(
              local.original_workflow.definition.actions.Call_Azure_Resource_Graph_Explorer.inputs,
              {
                body = merge(
                  local.original_workflow.definition.actions.Call_Azure_Resource_Graph_Explorer.inputs.body,
                  {
                    subscriptions = [var.subscription_id]
                  }
                )
              }
            )
          }
        )
        
        # Update the email action to use parameterized values
        Condition = merge(
          local.original_workflow.definition.actions.Condition,
          {
            else = {
              actions = {
                "Send_an_email_(V2)" = merge(
                  local.original_workflow.definition.actions.Condition.else.actions["Send_an_email_(V2)"],
                  {
                    inputs = merge(
                      local.original_workflow.definition.actions.Condition.else.actions["Send_an_email_(V2)"].inputs,
                      {
                        host = {
                          connection = {
                            name = azurerm_api_connection.office365.id
                          }
                        }
                        body = merge(
                          local.original_workflow.definition.actions.Condition.else.actions["Send_an_email_(V2)"].inputs.body,
                          {
                            To = var.email_recipient
                          }
                        )
                      }
                    )
                  }
                )
              }
            }
          }
        )
      }
    )
    
    outputs = local.original_workflow.definition.outputs
    staticResults = local.original_workflow.definition.staticResults
  }
}

# Create Logic App (Consumption)
resource "azurerm_logic_app_workflow" "main" {
  name                = var.logic_app_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  identity {
    type = "SystemAssigned"
  }

  workflow_schema   = "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#"
  workflow_version  = "1.0.0.0"

  tags = var.tags
}

# Apply the workflow definition using ARM template deployment
resource "azurerm_resource_group_template_deployment" "logic_app_workflow" {
  name                = "${var.logic_app_name}-workflow-deployment"
  resource_group_name = azurerm_resource_group.main.name
  deployment_mode     = "Incremental"

  template_content = jsonencode({
    "$schema"      = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
    contentVersion = "1.0.0.0"
    
    resources = [
      {
        type       = "Microsoft.Logic/workflows"
        apiVersion = "2019-05-01"
        name       = azurerm_logic_app_workflow.main.name
        location   = azurerm_logic_app_workflow.main.location
        
        identity = {
          type = "SystemAssigned"
        }
        
        properties = {
          definition = local.workflow_definition
        }
      }
    ]
  })

  depends_on = [
    azurerm_logic_app_workflow.main,
    azurerm_api_connection.office365
  ]
}

# Assign Reader role to Logic App's managed identity for Resource Graph access
resource "azurerm_role_assignment" "logic_app_reader" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Reader"
  principal_id         = azurerm_logic_app_workflow.main.identity[0].principal_id
}
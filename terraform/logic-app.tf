# User-assigned managed identity for Logic App
resource "azurerm_user_assigned_identity" "logic_app" {
  name                = var.managed_identity_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = var.tags
}

# Role assignment for managed identity to read resource health data
resource "azurerm_role_assignment" "resource_graph_reader" {
  scope                = "/subscriptions/${var.target_subscription_id}"
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.logic_app.principal_id
}

# Office 365 API Connection
resource "azurerm_api_connection" "office365" {
  name                = var.office365_connection_name
  resource_group_name = azurerm_resource_group.main.name
  managed_api_id      = "/subscriptions/${var.subscription_id}/providers/Microsoft.Web/locations/${azurerm_resource_group.main.location}/managedApis/office365"

  tags = var.tags
}

# Logic App Workflow (Consumption-based) with ARM template
resource "azurerm_resource_group_template_deployment" "logic_app" {
  name                = "${var.logic_app_name}-deployment"
  resource_group_name = azurerm_resource_group.main.name
  deployment_mode     = "Incremental"

  parameters_content = jsonencode({
    logicAppName = {
      value = var.logic_app_name
    }
    location = {
      value = azurerm_resource_group.main.location
    }
    managedIdentityId = {
      value = azurerm_user_assigned_identity.logic_app.id
    }
    targetSubscriptionId = {
      value = var.target_subscription_id
    }
    notificationEmail = {
      value = var.notification_email
    }
    office365ConnectionId = {
      value = azurerm_api_connection.office365.id
    }
    office365ConnectionName = {
      value = azurerm_api_connection.office365.name
    }
    office365ManagedApiId = {
      value = azurerm_api_connection.office365.managed_api_id
    }
  })

  template_content = jsonencode({
    "$schema"      = "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#"
    contentVersion = "1.0.0.0"
    parameters = {
      logicAppName = {
        type = "string"
      }
      location = {
        type = "string"
      }
      managedIdentityId = {
        type = "string"
      }
      targetSubscriptionId = {
        type = "string"
      }
      notificationEmail = {
        type = "string"
      }
      office365ConnectionId = {
        type = "string"
      }
      office365ConnectionName = {
        type = "string"
      }
      office365ManagedApiId = {
        type = "string"
      }
    }
    resources = [
      {
        type       = "Microsoft.Logic/workflows"
        apiVersion = "2019-05-01"
        name       = "[parameters('logicAppName')]"
        location   = "[parameters('location')]"
        identity = {
          type = "UserAssigned"
          userAssignedIdentities = {
            "[parameters('managedIdentityId')]" = {}
          }
        }
        properties = {
          state = "Enabled"
          parameters = {
            "$connections" = {
              value = {
                office365 = {
                  connectionId   = "[parameters('office365ConnectionId')]"
                  connectionName = "[parameters('office365ConnectionName')]"
                  id             = "[parameters('office365ManagedApiId')]"
                }
              }
            }
          }
          definition = {
            "$schema"      = "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#"
            contentVersion = "1.0.0.0"
            parameters = {
              "$connections" = {
                defaultValue = {}
                type         = "Object"
              }
            }
            triggers = {
              manual = {
                type = "Request"
                kind = "Http"
                inputs = {
                  schema = {
                    type = "object"
                    properties = {
                      schemaId = {
                        type = "string"
                      }
                      data = {
                        type = "object"
                        properties = {
                          essentials = {
                            type = "object"
                            properties = {
                              alertId = {
                                type = "string"
                              }
                              alertRule = {
                                type = "string"
                              }
                              severity = {
                                type = "string"
                              }
                              signalType = {
                                type = "string"
                              }
                              monitorCondition = {
                                type = "string"
                              }
                              monitoringService = {
                                type = "string"
                              }
                              alertTargetIDs = {
                                type = "array"
                                items = {
                                  type = "string"
                                }
                              }
                              originAlertId = {
                                type = "string"
                              }
                              firedDateTime = {
                                type = "string"
                              }
                              resolvedDateTime = {
                                type = "string"
                              }
                              description = {
                                type = "string"
                              }
                              essentialsVersion = {
                                type = "string"
                              }
                              alertContextVersion = {
                                type = "string"
                              }
                            }
                          }
                          alertContext = {
                            type       = "object"
                            properties = {}
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
            actions = {
              Call_Azure_Resource_Graph_Explorer = {
                runAfter = {}
                type     = "Http"
                inputs = {
                  uri    = "https://management.azure.com/providers/Microsoft.ResourceGraph/resources?api-version=2021-03-01"
                  method = "POST"
                  headers = {
                    "Content-Type" = "application/json"
                  }
                  body = {
                    query         = "healthresources | where type == 'microsoft.resourcehealth/resourceannotations' | where properties.targetResourceType == 'Microsoft.Compute/virtualMachines' | project name, resourceGroup, properties.targetResourceId, properties.reasonType, properties.reason, properties.annotationName, properties.impactType, properties.context, properties.occurredTime"
                    subscriptions = ["[parameters('targetSubscriptionId')]"]
                    options = {
                      resultFormat = "table"
                      top          = 100
                    }
                  }
                  authentication = {
                    type = "ManagedServiceIdentity"
                  }
                }
              }
              Parse_Resource_Graph_JSON_Response = {
                runAfter = {
                  Call_Azure_Resource_Graph_Explorer = ["Succeeded"]
                }
                type = "ParseJson"
                inputs = {
                  content = "@body('Call_Azure_Resource_Graph_Explorer')"
                  schema = {
                    type = "object"
                    properties = {
                      totalRecords = {
                        type = "integer"
                      }
                      count = {
                        type = "integer"
                      }
                      data = {
                        type = "object"
                        properties = {
                          columns = {
                            type = "array"
                            items = {
                              type = "object"
                              properties = {
                                name = {
                                  type = "string"
                                }
                                type = {
                                  type = "string"
                                }
                              }
                              required = ["name", "type"]
                            }
                          }
                          rows = {
                            type = "array"
                            items = {
                              type = "array"
                            }
                          }
                        }
                      }
                      facets = {
                        type = "array"
                      }
                      resultTruncated = {
                        type = "string"
                      }
                    }
                  }
                }
              }
              Compose_Rows = {
                runAfter = {
                  Parse_Resource_Graph_JSON_Response = ["Succeeded"]
                }
                type   = "Compose"
                inputs = "@body('Parse_Resource_Graph_JSON_Response')?['data']?['rows']"
              }
              Initialize_Array = {
                runAfter = {
                  Compose_Rows = ["Succeeded"]
                }
                type = "InitializeVariable"
                inputs = {
                  variables = [
                    {
                      name  = "TransformedRows"
                      type  = "array"
                      value = []
                    }
                  ]
                }
              }
              For_each = {
                runAfter = {
                  Initialize_Array = ["Succeeded"]
                }
                type    = "Foreach"
                foreach = "@outputs('Compose_Rows')"
                actions = {
                  Compose_Rows_and_Columns = {
                    type = "Compose"
                    inputs = {
                      name                        = "@{items('For_each')?[0]}"
                      resourceGroup               = "@{items('For_each')?[1]}"
                      properties_targetResourceId = "@{items('For_each')?[2]}"
                      properties_reasonType       = "@{items('For_each')?[3]}"
                      properties_reason           = "@{items('For_each')?[4]}"
                      properties_annotationName   = "@{items('For_each')?[5]}"
                      properties_impactType       = "@{items('For_each')?[6]}"
                      properties_context          = "@{items('For_each')?[7]}"
                      properties_occurredTime     = "@{items('For_each')?[8]}"
                    }
                  }
                  Append_to_array_variable = {
                    runAfter = {
                      Compose_Rows_and_Columns = ["Succeeded"]
                    }
                    type = "AppendToArrayVariable"
                    inputs = {
                      name  = "TransformedRows"
                      value = "@outputs('Compose_Rows_and_Columns')"
                    }
                  }
                }
              }
              Condition = {
                runAfter = {
                  For_each = ["Succeeded"]
                }
                type = "If"
                expression = {
                  and = [
                    {
                      greater = [
                        "@length(variables('TransformedRows'))",
                        0
                      ]
                    },
                    {
                      not = {
                        or = [
                          {
                            equals = [
                              "@variables('TransformedRows')[0]['properties_annotationName']",
                              "VirtualMachineDeallocationInitiated"
                            ]
                          },
                          {
                            equals = [
                              "@variables('TransformedRows')[0]['properties_annotationName']",
                              "VirtualMachineStartInitiatedByControlPlane"
                            ]
                          }
                        ]
                      }
                    }
                  ]
                }
                actions = {
                  "Send_an_email_(V2)" = {
                    type = "ApiConnection"
                    inputs = {
                      host = {
                        connection = {
                          name = "@parameters('$connections')['office365']['connectionId']"
                        }
                      }
                      method = "post"
                      path   = "/v2/Mail"
                      body = {
                        To         = "[parameters('notificationEmail')]"
                        Subject    = "VM Availability Alert"
                        Body       = "<p><strong>VM Availability Alert</strong></p><p>A virtual machine availability issue has been detected that requires attention.</p><p>Details: @{variables('TransformedRows')[0]}</p>"
                        Importance = "Normal"
                      }
                    }
                  }
                }
                else = {
                  actions = {}
                }
              }
            }
          }
        }
      }
    ]
    outputs = {
      logicAppId = {
        type  = "string"
        value = "[resourceId('Microsoft.Logic/workflows', parameters('logicAppName'))]"
      }
      callbackUrl = {
        type  = "string"
        value = "[listCallbackURL(concat(resourceId('Microsoft.Logic/workflows', parameters('logicAppName')), '/triggers/manual'), '2019-05-01').value]"
      }
    }
  })

  tags = var.tags

  depends_on = [
    azurerm_user_assigned_identity.logic_app,
    azurerm_api_connection.office365
  ]
}
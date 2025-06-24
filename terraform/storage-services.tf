# Storage Services Configuration

# Blob Service
resource "azurerm_storage_management_policy" "logic_app_blob" {
  storage_account_id = azurerm_storage_account.logic_app.id

  rule {
    name    = "default"
    enabled = true

    filters {
      blob_types = ["blockBlob"]
    }

    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = 30
      }
    }
  }

  depends_on = [azurerm_storage_account.logic_app]
}

# Storage containers needed for Logic App runtime
resource "azurerm_storage_container" "azure_webjobs_hosts" {
  name                  = "azure-webjobs-hosts"
  storage_account_name  = azurerm_storage_account.logic_app.name
  container_access_type = "private"

  depends_on = [azurerm_storage_account.logic_app]
}

resource "azurerm_storage_container" "azure_webjobs_secrets" {
  name                  = "azure-webjobs-secrets"
  storage_account_name  = azurerm_storage_account.logic_app.name
  container_access_type = "private"

  depends_on = [azurerm_storage_account.logic_app]
}

# File share for Logic App content
resource "azurerm_storage_share" "logic_app_content" {
  name                 = "${var.logic_app_name}-content"
  storage_account_name = azurerm_storage_account.logic_app.name
  quota                = 100
  access_tier          = "TransactionOptimized"

  depends_on = [azurerm_storage_account.logic_app]
}

# Storage queue for Logic App triggers
resource "azurerm_storage_queue" "flow_job_triggers" {
  name                 = "flow2f9590d042a6383jobtriggers00"
  storage_account_name = azurerm_storage_account.logic_app.name

  depends_on = [azurerm_storage_account.logic_app]
}

# Storage tables for Logic App runtime
resource "azurerm_storage_table" "flows" {
  name                 = "flow2f9590d042a6383flows"
  storage_account_name = azurerm_storage_account.logic_app.name

  depends_on = [azurerm_storage_account.logic_app]
}

resource "azurerm_storage_table" "flow_access_keys" {
  name                 = "flow2f9590d042a6383flowaccesskeys"
  storage_account_name = azurerm_storage_account.logic_app.name

  depends_on = [azurerm_storage_account.logic_app]
}

resource "azurerm_storage_table" "flow_runtime_context" {
  name                 = "flow2f9590d042a6383flowruntimecontext"
  storage_account_name = azurerm_storage_account.logic_app.name

  depends_on = [azurerm_storage_account.logic_app]
}

resource "azurerm_storage_table" "flow_subscriptions" {
  name                 = "flow2f9590d042a6383flowsubscriptions"
  storage_account_name = azurerm_storage_account.logic_app.name

  depends_on = [azurerm_storage_account.logic_app]
}

resource "azurerm_storage_table" "flow_subscription_summary" {
  name                 = "flow2f9590d042a6383flowsubscriptionsummary"
  storage_account_name = azurerm_storage_account.logic_app.name

  depends_on = [azurerm_storage_account.logic_app]
}

resource "azurerm_storage_table" "job_definitions" {
  name                 = "flow2f9590d042a6383jobdefinitions"
  storage_account_name = azurerm_storage_account.logic_app.name

  depends_on = [azurerm_storage_account.logic_app]
}

resource "azurerm_storage_table" "flow_instance_flows" {
  name                 = "flow2f9590d042a6383948c519a17253a0flows"
  storage_account_name = azurerm_storage_account.logic_app.name

  depends_on = [azurerm_storage_account.logic_app]
}

resource "azurerm_storage_table" "flow_instance_flows2" {
  name                 = "flow2f9590d042a6383a36dc2df3ad11b8flows"
  storage_account_name = azurerm_storage_account.logic_app.name

  depends_on = [azurerm_storage_account.logic_app]
}
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

# WorkflowStandard Plan for Logic App Standard
resource "azurerm_service_plan" "logic_app" {
  name                = var.app_service_plan_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Windows"
  sku_name            = "WS1"

  # Additional settings to match ARM template
  per_site_scaling_enabled     = false
  zone_balancing_enabled       = false
  worker_count                 = 1
  maximum_elastic_worker_count = 1

  tags = var.tags
}

# Storage Account for Logic App Standard
resource "azurerm_storage_account" "logic_app" {
  name                     = "${var.storage_account_name}${random_string.storage_suffix.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  access_tier              = "Hot"

  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = true
  shared_access_key_enabled       = true
  https_traffic_only_enabled      = true

  network_rules {
    default_action = "Allow"
    bypass         = ["AzureServices"]
  }

  tags = var.tags
}

# Random string for storage account name uniqueness
resource "random_string" "storage_suffix" {
  length  = 6
  special = false
  upper   = false
}

# Logic App Standard
resource "azurerm_logic_app_standard" "main" {
  name                       = var.logic_app_name
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  app_service_plan_id        = azurerm_service_plan.logic_app.id
  storage_account_name       = azurerm_storage_account.logic_app.name
  storage_account_access_key = azurerm_storage_account.logic_app.primary_access_key
  version                    = "~4"
  https_only                 = false
  client_affinity_enabled    = false

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.logic_app.id]
  }

  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"      = "node"
    "WEBSITE_NODE_DEFAULT_VERSION"  = "~18"
    "AzureWebJobsFeatureFlags"      = "EnableWorkerIndexing"
    "WORKFLOWS_SUBSCRIPTION_ID"     = var.target_subscription_id
    "WORKFLOWS_LOCATION_NAME"       = azurerm_resource_group.main.location
    "WORKFLOWS_RESOURCE_GROUP_NAME" = azurerm_resource_group.main.name
    "NOTIFICATION_EMAIL"            = var.notification_email
    "OFFICE365_CONNECTION_ID"       = azurerm_api_connection.office365.id
    "OFFICE365_CONNECTION_NAME"     = azurerm_api_connection.office365.name
    "OFFICE365_MANAGED_API_ID"      = azurerm_api_connection.office365.managed_api_id
  }


  depends_on = [
    azurerm_user_assigned_identity.logic_app,
    azurerm_api_connection.office365
  ]
}

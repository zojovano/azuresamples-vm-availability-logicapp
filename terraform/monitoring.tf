# Storage Account Availability Metric Alert
resource "azurerm_monitor_metric_alert" "storage_availability" {
  name                = "${azurerm_storage_account.logic_app.name}-AvailabilityAlert"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_storage_account.logic_app.id]
  description         = "Metric Alert for Storage Account Availability"
  severity            = 1
  enabled             = true
  frequency           = "PT5M"
  window_size         = "PT5M"
  auto_mitigate       = true

  criteria {
    metric_namespace = "Microsoft.Storage/storageAccounts"
    metric_name      = "Availability"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 90
  }

  tags = merge(var.tags, {
    _deployed_by_amba = "True"
  })

  depends_on = [azurerm_storage_account.logic_app]
}
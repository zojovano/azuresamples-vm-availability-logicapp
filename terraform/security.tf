# Security Configuration for Logic App

# Basic publishing credentials policies using azapi since azurerm doesn't have direct support
resource "azapi_resource" "ftp_publishing_policy" {
  type      = "Microsoft.Web/sites/basicPublishingCredentialsPolicies@2024-04-01"
  name      = "ftp"
  parent_id = azurerm_logic_app_standard.main.id

  body = jsonencode({
    properties = {
      allow = false
    }
  })

  depends_on = [azurerm_logic_app_standard.main]
}

resource "azapi_resource" "scm_publishing_policy" {
  type      = "Microsoft.Web/sites/basicPublishingCredentialsPolicies@2024-04-01"
  name      = "scm"
  parent_id = azurerm_logic_app_standard.main.id

  body = jsonencode({
    properties = {
      allow = false
    }
  })

  depends_on = [azurerm_logic_app_standard.main]
}
# security.tf

resource "azurerm_role_assignment" "acr_pull" {
  principal_id         = azurerm_container_app.springboot_app.identity.principal_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.acr.id
}

# Ensure SSL for MySQL connections
resource "azurerm_mysql_flexible_server" "mysql" {
  ...
  ssl_enforcement = "Enabled"
}

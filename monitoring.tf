# Create a Log Analytics workspace
resource "azurerm_log_analytics_workspace" "example" {
  name                = "springboot-logs"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Diagnostic settings for Azure Container App
resource "azurerm_monitor_diagnostic_setting" "app_diagnostics" {
  name               = "container-app-diagnostics"
  target_resource_id = azurerm_container_app.spring-boot.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id

  log {
    category = "AppServiceConsoleLogs"
    enabled  = true
    retention_policy {
      enabled = true
      days    = 30
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = true
    retention_policy {
      enabled = true
      days    = 30
    }
  }
}

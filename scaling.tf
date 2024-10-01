# scaling.tf

resource "azurerm_monitor_autoscale_setting" "autoscale" {
  name                = "autoscale-setting"
  resource_group_name = var.resource_group_name
  target_resource_id  = azurerm_container_app.springboot_app.id

  profile {
    name = "defaultProfile"

    capacity {
      minimum = var.min_replicas
      maximum = var.max_replicas
      default = var.min_replicas
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_container_app.springboot_app.id
        operator           = "GreaterThan"
        statistic          = "Average"
        threshold          = 75
        time_grain         = "PT1M"
        time_window        = "PT5M"
        time_aggregation   = "Average"
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_container_app.springboot_app.id
        operator           = "LessThan"
        statistic          = "Average"
        threshold          = 30
        time_grain         = "PT1M"
        time_window        = "PT5M"
        time_aggregation   = "Average"
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }
}

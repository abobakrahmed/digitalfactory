# compute.tf

resource "azurerm_app_service_plan" "appserviceplan" {
  name                = "springboot-container-plan"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku {
    tier = "PremiumV2"
    size = "P1v2"
  }
  kind     = "Linux"
  reserved = true
}

resource "azurerm_container_registry" "acr" {
  name                = "springbootacr"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_container_app_environment" "app_env" {
  name                       = "container-app-env"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id
}

resource "azurerm_container_app" "springboot_app" {
  name                         = "springboot-container-app"
  container_app_environment_id = azurerm_container_app_environment.app_env.id
  resource_group_name          = var.resource_group_name
  revision_mode                = "Single"

  identity {
    type = "SystemAssigned"
  }

  template {
    container {
      name   = "springboot-app"
      image  = var.container_image
      cpu    = 0.5
      memory = "1Gi"
    }

    scale {
      min_replicas = var.min_replicas
      max_replicas = var.max_replicas

      rule {
        name = "http-scaling"
        custom {
          type = "http"
          metadata = {
            concurrentRequests = "50"
          }
        }
      }
    }
  }
}

resource "azurerm_role_assignment" "acr_pull" {
  principal_id         = azurerm_container_app.springboot_app.identity.principal_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.acr.id
}

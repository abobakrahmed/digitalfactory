# Configure the Azure provider
provider "azurerm" {
  features {}
}

# Create a Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "digitalfactory-rg"
  location = "East US"
}

# Create a MySQL Flexible Server
resource "azurerm_mysql_flexible_server" "mysql" {
  name                = "my-springboot-db"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  administrator_login          = "mysqladmin"
  administrator_password       = "StrongP@ssw0rd123"  # Replace with a secure password
  version                      = "8.0"
  sku_name                     = "GP_Gen5_2"
  storage_mb                   = 5120
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  storage_auto_grow = "Enabled"
  high_availability_mode = "ZoneRedundant"

  delegated_subnet_id = azurerm_subnet.subnet.id
}


# Create a Virtual Network and Subnet for MySQL
resource "azurerm_virtual_network" "vnet" {
  name                = "app-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "mysql-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create App Service Plan for Container-based App Service
resource "azurerm_app_service_plan" "appserviceplan" {
  name                = "springboot-container-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku {
    tier = "PremiumV2"
    size = "P1v2"
  }
  kind = "Linux"
  reserved = true  # Required for Linux containers
}

resource "azurerm_log_analytics_workspace" "example" {
  name                = "testing-logs"
  location            = resource.azurerm_resource_group.rg.location
  resource_group_name = resource.azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "example" {
  name                       = "testing"
  location                   = resource.azurerm_resource_group.rg.location
  resource_group_name        = resource.azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id

}


resource "azurerm_container_app" "spring-boot" {
  name                         = "spring-boot-app"
  container_app_environment_id = azurerm_container_app_environment.example.id
  resource_group_name          = resource.azurerm_resource_group.rg.name
  revision_mode                = "Single"

  identity {
    type = "SystemAssigned"
  }

  template {
    container {
      name   = "spring-boot-app"
      image  = "${data.azurerm_container_registry.existing_acr.login_server}/spring_app:latest"
      cpu    = 0.5
      memory = "1Gi"
    }
  }
}

# Optionally: Create a Container Registry to store Docker images
resource "azurerm_container_registry" "acr" {
  name                = "springbootacr"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

# Grant the Container App access to pull from Azure Container Registry
resource "azurerm_role_assignment" "acr_pull" {
  principal_id         = azurerm_container_app.spring-boot.identity.principal_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.acr.id
}


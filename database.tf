# database.tf

resource "azurerm_mysql_flexible_server" "mysql" {
  name                = "my-springboot-db"
  location            = var.location
  resource_group_name = var.resource_group_name

  administrator_login    = var.mysql_admin_username
  administrator_password = var.mysql_admin_password
  version                = "8.0"
  sku_name               = "GP_Gen5_2"
  storage_mb             = 5120
  backup_retention_days  = 7
  geo_redundant_backup_enabled = false

  storage_auto_grow      = "Enabled"
  high_availability_mode = "ZoneRedundant"
  delegated_subnet_id    = azurerm_subnet.subnet.id
}

resource "azurerm_mysql_flexible_server_firewall_rule" "allow_azure" {
  name                = "AllowAzure"
  server_name         = azurerm_mysql_flexible_server.mysql.name
  resource_group_name = var.resource_group_name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}


# Output the App Service URL
output "app_service_url" {
  value = azurerm_app_service.appservice.default_site_hostname
}

# Output the MySQL Connection String
output "mysql_connection_string" {
  value = "jdbc:mysql://${azurerm_mysql_flexible_server.mysql.fqdn}:3306/mydatabase"
}



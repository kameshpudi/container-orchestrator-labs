# Azure SQL DB

resource "azurerm_sql_server" "sqlsrv" {
  name                         = "${var.prefix}sqlsrv${var.env}"
  resource_group_name          = var.resource_group_name
  location                     = var.location
  version                      = "12.0"
  administrator_login          = var.sqldbusername
  administrator_login_password = var.sqldbpassword

  tags = {
    environment = var.env
    source      = "AzureDevCollege"
  }
}

resource "azurerm_sql_database" "sqldb" {
  name                             = var.sqldbname#"${var.prefix}sqldb${var.env}"
  resource_group_name              = var.resource_group_name
  location                         = var.location
  server_name                      = azurerm_sql_server.sqlsrv.name
  requested_service_objective_name = "S0"
  edition                          = "Standard"
  tags = {
    environment = var.env
    source      = "AzureDevCollege"
  }
}

resource "azurerm_sql_firewall_rule" "sqldb" {
  name                = "FirewallRule1"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_sql_server.sqlsrv.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

output "sqldb_connectionstring" {
  value       = "Server=tcp:${azurerm_sql_server.sqlsrv.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_sql_database.sqldb.name};Persist Security Info=False;User ID=${azurerm_sql_server.sqlsrv.administrator_login};Password=${azurerm_sql_server.sqlsrv.administrator_login_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  description = "SQL DB Connection String"
}
output "sqldb_username" {
  value       = azurerm_sql_server.sqlsrv.administrator_login
}
output "sqldb_pwd" {
  value       = azurerm_sql_server.sqlsrv.administrator_login_password
}
output "sqldb_server" {
  value       = azurerm_sql_server.sqlsrv.fully_qualified_domain_name
}
output "sqldb_name" {
  value       = azurerm_sql_database.sqldb.name
}
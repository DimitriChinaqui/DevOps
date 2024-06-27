output "web_vm_public_ip" {
  value = azurerm_public_ip.lb_public_ip.ip_address
}

output "sql_server_fqdn" {
  value = azurerm_mssql_server.sql_server.fully_qualified_domain_name
}


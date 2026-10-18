output "resource_group_name" {
  description = "Name of the resource group holding all resources."
  value       = azurerm_resource_group.main.name
}

output "web_app_url" {
  description = "Public URL of the Linux web app."
  value       = "https://${azurerm_linux_web_app.main.default_hostname}"
}

output "sql_server_fqdn" {
  description = "Fully qualified domain name of the Azure SQL server."
  value       = azurerm_mssql_server.main.fully_qualified_domain_name
}

output "key_vault_uri" {
  description = "URI of the Key Vault."
  value       = azurerm_key_vault.main.vault_uri
}

output "servicebus_namespace" {
  description = "Name of the Service Bus namespace."
  value       = azurerm_servicebus_namespace.main.name
}

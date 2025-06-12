output "storage_account_name" {
  value = azurerm_storage_account.storage.name
}

output "storage_account_key" {
  value     = azurerm_storage_account.storage.primary_access_key
  sensitive = true
}

output "storage_connection_string" {
  value     = azurerm_storage_account.storage.primary_connection_string
  sensitive = true
}

output "function_app_name" {
  value = azurerm_linux_function_app.function.name
}

output "function_app_url" {
  value = "https://${azurerm_linux_function_app.function.default_hostname}"
}
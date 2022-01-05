
output "ai_instrumentation_key" {
  value       = azurerm_application_insights.appinsights.instrumentation_key
  description = "Application Insights Instrumentation Key"
}

output "keyvaultid" {
  value       = azurerm_key_vault.keyvault.id
  description = "KeyVault ID"
}
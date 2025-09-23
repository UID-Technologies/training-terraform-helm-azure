# output "resource_groups" {
#   value = azurerm_resource_group.rg[*].name
# }

# output "storage_accounts" {
#   value = { for k, sa in azurerm_storage_account.sa : k => sa.name }
# }
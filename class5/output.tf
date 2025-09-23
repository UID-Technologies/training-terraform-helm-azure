output "acr_login_server" {
  value       = azurerm_container_registry.acr.login_server
  description = "The login server URL of the Azure Container Registry."

}

output "image_full_name" {
  value       = "${azurerm_container_registry.acr.login_server}/${var.image_name}:${var.image_tag}"
  description = "The full name of the Docker image including tag."
}

output "aci_fqdn" {
  # only present when deploy_ccontainer is true
  value       = var.deploy_container ? azurerm_container_group.app[0].fqdn : "ACI not deployed. Set deploy_container to true and apply again."
  description = "ACI Fully Qualified Domain Name (FQDN)."
}
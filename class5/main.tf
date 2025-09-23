locals {
  image_refs = "${azurerm_container_registry.acr.login_server}/${var.image_name}:${var.image_tag}"
}

resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Basic"
  admin_enabled       = true
  tags                = var.tags
}

# ACI will be created only when this variable is set to true
resource "azurerm_container_group" "app" {
  count               = var.deploy_container ? 1 : 0
  name                = "aci-hello"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  ip_address_type     = "Public"
  dns_name_label      = var.dns_label
  restart_policy      = "Always"
  tags                = var.tags

  image_registry_credential {
    server   = azurerm_container_registry.acr.login_server
    username = azurerm_container_registry.acr.admin_username
    password = azurerm_container_registry.acr.admin_password
  }
  container {
    name   = "web"
    image  = local.image_refs
    cpu    = var.cpu_cores
    memory = var.memory_gb

    ports {
      port     = 80
      protocol = "TCP"
    }

    environment_variables = {
      PORT = "80"
    }
  }

  # Open port 80 publicly
  exposed_port {
    port     = 80
    protocol = "TCP"
  }
}
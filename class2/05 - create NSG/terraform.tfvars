resource_group_name = "rg-tf-vnet"
location            = "Central India"
vnet_name           = "vnet-tf-lab"
address_space       = ["10.0.0.0/16"]
subnet_name         = "subnet1"
subnet_prefixes     = ["10.0.1.0/24"]

admin_username = "azureuser"
ssh_public_key = "./id_rsa.pub"
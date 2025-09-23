# Lab : Understanding Provisioners in Terraform

### Objective:
- Understanding what Provisioners are and when to use them
- Create a VM in Azure and run provisioners on it
- Learn how to upload script from your machine to the azure machine
- Execute it usaing `remote-exec`


### Step 1: Create Project Structure
```bash
mkdir terraform-provisioners-lab
cd terraform-provisioners-lab
```

Create files
```bash
- main.tf
- variables.tf
- outputs.tf
```

### Step 2: Define Providers and Resource Group (`main.tf`)
```yaml
terraform {
  required_version = ">= 1.0.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }

    random = {
      source  = "hashicorp/random"
      version = ">= 3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "7f12001e-fded-41fd-b58b-f041b465dbed"
  tenant_id       = "de52d802-5286-4ced-88f2-a6fee88d2b34"
  # uses azure CLI auth by default (az login)

}

resource "azurerm_resource_group" "rg" {
  name     = "rg-provisioner-lab"
  location = "Central India"
}
```


### Step 3: Create a Virtual Network and Subnet
```yaml
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-provisioner-lab"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "snet-provisioner-lab"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  
}
```

### Step 4: Create Public IP and NIC
```yaml
resource "azurerm_public_ip" "pip" {
  name                = "pip-provisioner-lab"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "nic" {
  name                = "nic-provisioner-lab"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id         = azurerm_public_ip.pip.id
  }
}
```

*If you don't have ssh key generate 
```
ssh-keygen -t rsa -b 4096     
```


### Step 5: Create a Network Security Group
```yaml
resource "azurerm_network_security_group" "nsg" {
  name = "nsg-provisioner-lab"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "nic_nsg" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
  
}
```


### Step 6: Create a Script Locally
Inside your terraform project folder, create a new file `setup.sh`:
```yaml

#!/bin/bash
# Simple setup script for demo
sudo apt-get update -y
sudo apt-get install -y apache2
echo "<h1>Apache installed via File Provisioner</h1>" | sudo tee /var/www/html/index.html
sudo systemctl enable apache2
sudo systemctl restart apache2

```




### Step 7: Create Linux VM with Provisioners
```yaml
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm-provisioner-lab"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_B1s"
  admin_username      = "azureuser"
  
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("${path.module}/id_rsa.pub")
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_disk {    
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }


# File Provisioner
provisioner "file" {
  source      = "${path.module}/setup.sh"
  destination = "/home/azureuser/setup.sh"

  connection {
      type        = "ssh"
      user        = "azureuser"
      private_key = file("${path.module}/id_rsa")
      host        = self.public_ip_address
      timeout     = "5m"
    }
  
}
  # ---Remote Exec Provider ---
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/azureuser/setup.sh",
      "bash /home/azureuser/setup.sh"
    ]
    connection {
      type        = "ssh"
      user        = "azureuser"
      private_key = file("${path.module}/id_rsa")
      host        = self.public_ip_address
      timeout     = "5m"
    }
  }
}

```

### Step 8: Outputs
```yaml
output "public_ip" {
  value = azurerm_public_ip.pip.ip_address
}

```

### Step 9: Run the Lab
1. Initialize Terraform
```bash
terraform init
```

2. Validate Configuration
```bash
terraform validate
```

3. Plan and Format
```bash
terraform fmt
terraform plan
```

4. Apply Configuration
```bash
terraform apply --auto-approve
```


5. After VM creation:
- Check `creation-log.txt` in your local directory - provide **local-exec** ran.
- Visit the VM puiblic IP in a browser - you should see:
**Deployed via Terraform Provisioners** - proves **remote-exec** ran


### Step 9: Clean Up
```bash
terraform destroy --auto-approve
```
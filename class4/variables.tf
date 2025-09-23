variable "location" {
  description = "The Azure region to deploy resources"
  type        = string
  default     = "Central India"
}

variable "rg_name" {
  description = "The name of the Resource Group"
  type        = string
  default     = "rg-multiple-vms-lab"
}

variable "name_prefix" {
  description = "Prefix for naming resources"
  type        = string
  default     = "lab"
}

variable "vm_count" {
  description = "Number of VMs to create"
  type        = number
  default     = 3
}

variable "admin_username" {
  description = "Admin username for the VMs"
  type        = string
  default     = "azureuser"
}

variable "vm_size" {
  description = "Size of the VMs"
  type        = string
  default     = "Standard_B1s"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    environment = "lab"
    project     = "multiple-vms"
  }
}

variable "ssh_key_path" {
  description = "Path to the SSH public key"
  type        = string
  default     = "./id_rsa.pub"
}

variable "zones" {
  description = "Availability zones for the VMs"
  type        = list(string)
  default     = ["1", "2", "3"] # AZs in Central India or your chosen region
}

variable "data_disk_size_gb" {
  description = "Size of the data disk in GB"
  type        = number
  default     = 20
}
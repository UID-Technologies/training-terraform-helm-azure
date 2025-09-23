variable "region_instance_type" {
  type = map(list(string))
  default = {
    "East US" = ["Standard_DS1_v2", "Standard_DS2_v2"]
    "West US" = ["Standard_DS1_v2", "Standard_DS2_v2"]
    "Central US" = ["Standard_DS1_v2", "Standard_DS2_v2"]
  }
}
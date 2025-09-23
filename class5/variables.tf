variable "location" {
  type        = string
  default     = "Central India"
  description = "This is azure region"
}

variable "rg_name" {
  type        = string
  default     = "rg-docker-aci-lab"
  description = "This is resource group name"
}

variable "acr_name" {
  type        = string
  default     = "varunacrdockerlab2807" # must be globally unique, lowercase, 5-50 characters
  description = "This is azure container registry name"
}

variable "image_name" {
  type        = string
  default     = "aci-hello"
  description = "This is azure container instance name"
}

variable "image_tag" {
  type        = string
  default     = "v1"
  description = "This is docker image tag"
}

variable "dns_label" {
  type        = string
  default     = "varunacilab2807" # must be globally unique within the region
  description = "This is azure container instance dns label"
}

variable "deploy_container" {
  type        = bool
  default     = true
  description = "Set true After pushing image to ACR, then apply again to create ACI"
}

variable "cpu_cores" {
  type        = number
  default     = 1
  description = "This is azure container instance cpu cores"

}

variable "memory_gb" {
  type        = number
  default     = 1.5
  description = "This is azure container instance memory in gb"

}

variable "tags" {
  type = map(string)
  default = {
    environment = "dev"
    team        = "devops"
  }
  description = "This is a map of tags to assign to the resources"
}
variable "team_members" {
  description = "list of team members"
  type        = list(string)
  default     = ["Alice", "Bob", "Charlie"]
}

variable "enable_docs" {
  description = "toggle optional resource with count"
  type        = bool
  default     = true
}

variable "services" {
  description = "service name for for_each over a set"
  type        = set(string)
  default     = ["auth", "payment", "orders"]
}

variable "users" {
  description = "map of users for for_each over object"
  type = map(object({
    role : string
    quota : number
  }))
  default = {
    "paul" = {
      role  = "admin"
      quota = 100
    },
    "jane" = {
      role  = "user"
      quota = 50
    }
    "doe" = {
      role  = "user"
      quota = 30
    }
  }
}
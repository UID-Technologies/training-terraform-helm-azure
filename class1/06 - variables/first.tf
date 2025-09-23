variable "username" {
  
}

output "printblock" {
  value = "Hello, ${ var.username }"
}
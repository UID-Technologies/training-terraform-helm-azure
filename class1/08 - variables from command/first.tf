# variable "username" {
  
# }

# variable "age" {
  
# }

output "printblock" {
  value = "Hello, ${ var.username }. You are ${ var.age } years old."
  
}


# terraform plan -var "username=John" -var "age=30"
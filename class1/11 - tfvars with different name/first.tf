output "printblock" {
  value = "Hello, ${ var.name }, you are ${ var.age } years old."
}


# terraform plan -var-file="development.tfvars"
# terraform plan -var-file="production.tfvars"
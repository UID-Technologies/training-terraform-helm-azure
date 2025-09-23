variable "username" {
  type = string
}

output "printblock" {
  value = "Hello, ${ var.username }!"
}

# Windows (bash)
# export TF_VAR_username="John2"
# echo $TF_VAR_username
# terraform plan

# Windows (powershell)
# $env:TF_VAR_username="John"
# echo $env:TF_VAR_username
# terraform plan

# Windows (CMD)
# set TF_VAR_username=John
# echo %TF_VAR_username%
# terraform plan

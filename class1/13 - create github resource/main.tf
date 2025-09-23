resource "github_repository" "terraform-repo" {
  name = "first-repo-with-terraform"
  description = "My first repo with terraform - v2"
  visibility = "public"
  auto_init = true
}


# terraform init
# terraform plan
# terraform apply
# terraform destroy
# Lab: Docker container on Azure (ACR + ACI) with Terraform

- Resource Group : 1
- Azure Container Registry with admin enabled : 1
- Sample Nodejs HTTP app container image pushed to ACR: 1
- Azure Container Instance pulling the image from ACR: 1
- Public endpoint vie DNS Label


### Step 1: Create ACR with Terraform
```
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply --auto-approve
```

### Step 2: Build and Push image to ACR
```
az acr login --name <acr_name>

cd app
docker build -t <acr_login_server>/<image_name>:<image_tag>
docker push <acr_login_server>/<image_name>:<image_tag>

az acr repository list --name <acr_name> --output table
az acr repository show-tags --name <acr_name> --repository <image_name> --output table

```

```
az acr login --name varunacrdockerlab2807xxx00
cd app
docker build -t varunacrdockerlab2807xxx00.azurecr.io/aci-hello:v1 .
docker push varunacrdockerlab2807xxx00.azurecr.io/aci-hello:v1
az acr repository list --name varunacrdockerlab2807xxx00 --output table
az acr repository show-tags --name varunacrdockerlab2807xxx00 --repository aci-hello --output table

```


### Step 3: Deploy ACI with terrarform
```
deploy_container  = true
```
```
terraform apply --auto-approve
```
```
open the browser

http://<aci_fqdn>
```
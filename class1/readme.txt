# Terraform


# What is IaC - Infrastructure as Code
- it is a method of managing and provisioning IT infrastructure using code rather then manual configuration
- it allows the team to automate the setup and management of their infrastructure, making it more efficient and consistent



# Working of Infrastructure as code?
- it is method of defining and managing your system infrastructure using code
- with IaC, resource can be managed in a consistent and organize way
- it treat the configuration file like a source code, making it possible to use version control, track the errors and easily update


# Role of IaC in DevOps?
- DevOps focuses on ensuring that development and operations team deliver software more quickly and higher quality
- IaC plays a string role in this, automating and managing of infrastructure along with continous intergration and continous delivery pipeline


# Features of IaC
- automation
- repeatability
- version control
- transparency
- improved security


# Application of IaC
- cloud computing
- DevOps
- Ci/CD
- Networking
- Web app deployment
- database deployment



# What is terraform?
- it is an open source infrastructure as code tool developed by hashicorp
- it is used to define and provision the complete infrastructure using an easy to learn declarative language

it is an infrastruture provisioning tool where you can store cloud infrastructure sets as a code

it is very similar tool such as cloudformation, ARM which you would use to automate your aws/azure infrastructure but you can use only that on specific cloud with terraform you can use it on other cloud as well


AWS / Azure / GCP

- IaaS
- PaaS
- SaaS



# Terraform Core Concept
- infrastructure as Code
- declarative configuration
- state management
- execute plan 
- resource graph
- providers and modules




# Terraform Life Cycle
1. write - define infrastructure using HCL
2. init - initialize terraform in the working directory
3. plan - preview changes before applying them
4. apply - execute changes to reach the desired state
5. destroy - removes resouces when they are no longer needed



# Main features of terraform

1. declarative configuration
- users define the desired state of the infrastructure in confgiration file and terraform ensures that state is achieved
- use HasiCorp Configuration Language (HCL) or JSON

2. Multi-Cloud Support
- works with major cloud providers like AWS, Azure and GCP and others
- support on-premises solution eg openStack, VMWhere
- can manage third party services like database, kubernetes and networking

3. state management
- keeps track of infrastrcure using a state file (terraform.tfstate)
- ensures changes are incremental and controlled
- can be stored locally or remotely

4. modular and reusable
- support modules, which are resusable infrastructure components
- enable DRY principle (dont repeat your self)

5. execution plan (terraform plan)
- show a preview of the changes before applying them
- helps avoid unintended modification

6. Automation and Ci/CD integration
- works with GitHub Actions, Jenkins, GitLab other DevOps tools
- enable automated infrastructure deployment

7. Provising and Orchestration
- automate the creation, updating and deleting of resource
- can interact with configuration management tools like ansible, chef, puppet etc

8. Resource Graphing
- uses a dependency graph to determine the optimal order of resource creation
- ensure efficient provisioning


9. immutable infrastrcuture
- promotes rebuilding infrastructure rather then modifying it in place
- reduce configuration drift and improved consistency


10. extensive vie providers
- terrafdorm uses providers to manage different infrastructure componets
- many providers are available for cloud, database, networking and security



# Terrform Architecture
terraform consist of serveral key components
- terraform core - manage state, plan changes and applies update
- providers - plugins that allow terraform to amange infrastructure resources
- modules - reusable infrastructure components
- state file - store metadata and resources information



# Installation of terraform
Step 1: downalod the terraform zip folder
https://developer.hashicorp.com/terraform/install


Step 2: unzip the folder

Step 3: copy the path and set in the environemnt variable

Step 4: open the terminal and check the version
> terrafom version


Terraform v1.12.2
on windows_386


Step 5: install vscode
https://code.visualstudio.com/download


Step 6: install terraform extension in vscode
HashiCorp Terraform


Step 7: create azure free tier account





# Terraform Variables

1. interactive terminal
2. command line 
3. tfvars
4. envirnment variable



# Precedence of variable assignment
from lowest to highest priority

1. default value
variable "name"{
  type = ""
  default = ""
}


2. envirnment variable (TF_VAR_name)


3. terraform.tfvars


4. terraform.tfvars.json


5. any *.auto.tfvars


6. direct cli

-var="name=value"








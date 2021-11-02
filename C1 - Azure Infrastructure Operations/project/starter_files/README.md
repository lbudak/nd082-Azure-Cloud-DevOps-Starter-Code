# Azure Infrastructure Operations Project: Deploying a scalable IaaS web server in Azure

### Introduction
For this project, you will write a Packer template and a Terraform template to deploy a customizable, scalable web server in Azure.

### Getting Started
1. Clone this repository

2. Create your infrastructure as code

3. Update this README to reflect how someone would use your code.

### Dependencies
1. Create an [Azure Account](https://portal.azure.com) 
2. Install the [Azure command line interface](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
3. Install [Packer](https://www.packer.io/downloads)
4. Install [Terraform](https://www.terraform.io/downloads.html)

### Instructions
1.  Clone this repository locally
2.  Log in to Azure using Azure CLI
```bash
az login
```
3.  Create and apply custom policy for tagging
```bash
az policy definition create \
    --name "tagging-policy" \
    --description "Ensures all indexed resources in your subscription have tags and deny deployment if they do not." \
    --display-name "Deny deployment without tags" \
    --mode "All" \
    --rules ./policy_rules.json

az policy assignment create --policy "tagging-policy"
```
4.  Create a Server image using Packer
```bash
packer build ./packer/server.json
``` 
> Make sure that the **resource group** specified in **Packer** for image is the same image specified in **Terraform**.
5.  Change current directory to terraform folder and initialize terraform
```bash
cd ./terraform

terraform init
```
6.  Generate a execution plan for the infrastructure, showing what actions Terraform would take to apply the current configuration. This command will not actually perform the planned actions
```bash
terraform plan -out solution.plan
```
This will also output a plan file which will be used as input to the "apply" command.

>To customize input variables and then generate the plan, change the default values of variables in file terraform/vars.tf:
```
variable "num_of_instances" {
    type = number
    default = 5

    validation {
    condition     = var.num_of_instances > 0 && var.num_of_instances < 6
    error_message = "The number of instances must not be more than 5."
  }
}
```
>Or with following command:
```bash
terraform plan -out "solution.plan" \
    -var 'num_of_instances = 5'
```
7.  Deploy the infrastructure using Terraform
```bash
terraform apply "solution.plan"
```
To see the deployed infrastructure run:
```bash
terraform show
```
### Output
You should have the following
[output](https://github.com/lbudak/nd082-Azure-Cloud-DevOps-Starter-Code/tree/master/C1%20-%20Azure%20Infrastructure%20Operations/project/starter_files/terraform/apply_output.txt)


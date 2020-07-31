# Terraform 101 :taco:

This repo and class we will explore terraform, a tool from Hashicorp. Terreform comes from the later of 'Terra' and 'forma' which means form / change. And means to create earth.

The naming convention is because the tool is used to orchestrate our infrastructure and is part of IAC (Infrastructure as Code).

IAC:
- Configuration Management tools
- Orchestration tools

### Configuration Management tools
Tools include Chef, puppet and Ansible
-> Helps us create imutable infrastructure
If we SSH into our testing server and install `sudo apt-get install type-script`
Now we need to do this all all our other machines.

If we have something, like a play or some type of configuration management tool, then we can make this change more imutable and it will be easier to replicate everywhere.

The idea is you should be able to terminate a machine, run a scrip and endup exactly at the same location / state as the previous machine.

A tool that help you do this is a configuration management tools.

--> end game should be a AMI of some sort.

### Orchestration tools
Terraform, AWScloudformation and other.

This will create the infrastructure, not only the specific machine, but the networking, security, monitoring and all the the setup around the machine that creates a production environment.


Example usage:
1) Terraform creates VPC
2) creates two subnets
3) Adds rules and security
4) Deploys AMIs and runs scripts



Example usage:
1) Automation server gets triggered
2) Test are run in machine created from AMI (configuration)
3) Passing test trigger next step on automation server
4) New AMI is created with previous AMI + new code
5) Success full creation triggers next step in automation server
6) Calls terraform script to create infrastructure and deploy new AMI (with new code)








The conjuntion of the two, allows us to define our infrastructure as code.

Along with Version control - such as git; and cloud providers, it all allows us to maintain and manipulate infrastructure in ways that where not possible beffore.

### Terraform terminology & commands

Terraform will work with a cloud provider.
You will need programatic access and api keys.

Set these in your enviroment variables using the correct naming conventions.

#### Terminology

- providers
- resources
  - ec2
- variables

#### Commands

- `terraform init`
- `terraform plan`
- `terraform apply`
- `terraform destroy`


### Modules / Separation of Concerns

In example repo - **Terraform Code-along** - the original `main.tf` file was split into sections:
	- Central
	- App (Public)
	- DB (Private)

Overall structure was as follows:

- terraform_codealong
	- modules
		- app_tier
			- main.tf
			- outputs.tf
			- variables.tf
		- db_tier
			- main.tf
			- outputs.tf
			- variables.tf
	- scripts
		- app
			- init.sh.tpl
	- main.tf
	- variables.tf


Each tier requires its own set of `main.tf` `outputs.tf` and `variables.tf`

- Relevent VPC components will be created within `main.tf`
- Individual `variables.tf` files will reference the variables used within `main.tf`
	- Point out to either external `variables.tf`, `secret_vars.tf` or `outputs.tf` of other module(s)
- Any variables that will be needed FROM a tier (in another tier) will be generated in the `outputs.tf` file
- Finally, in the primary `main.tf` file, modules will need to be referenced, as well as variables that will be used within, see example below.


### Examples
###### For full example, see https://github.com/paddyjclancy/terraform_codealong

Reference to secondary module within main `main.tf`:
```
module "app_tier" {
  source = "./modules/app_tier" 							# locator of app main file
  vpc_id = aws_vpc.mainvpc.id 								# reference to id of resource made in same file
  name = var.name 									# variable created in primary variable file
  my_ip = var.my_ip 							 		# variable created in primary variable file
  internet_gateway_id = aws_internet_gateway.gw.id 				 	# reference to id of resource made in same file
  db_private_ip = module.db_tier.db_private_ip  					# variable created in output of db_tier
  ami_app = var.ami_app 								# variable created in primary variable file
}
```

Example of primary `variable.tf` file:
```	
variable "vpc_id" {
  type = string
  default= "vpc-08039043ffb902e94"
}

variable "name" {
  type = string
  default= "Eng57.PC."
}
```

Example of secondary `variable.tf` file (app tier):
```	
variable "vpc_id" {
  description = "The VPC we want the instance to launch within"  
}

variable "name" {
  description = "Root base on naming for convention"
}

variable "my_ip" {
  description = "Local IP to create secure port 22 connection with resources"
}
.....
```

Example of `outputs.tf` file (app tier):
```
output "app_sg_id" {
  description = "ID of app SG"
  value = aws_security_group.sgapp.id
}

output "subpublic_cidr_block" {
  description = "cidr_block of public subnet"
  value = aws_subnet.subpublic.cidr_block
}
```


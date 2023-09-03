# Session 01 - CMB-TF

## Lab 1 - Installing Terraform

### Manual Install (any supported OS)

Download from HashiCorp website:

1. [https://developer.hashicorp.com/terraform/downloads](https://developer.hashicorp.com/terraform/downloads)
2. Select appropriate operating system and architecture
3. Unzip and copy terraform executable to a directory in your path
4. Or, add location to your PATH variable

### Package Install for macOS

This requires [Homebrew](https://brew.sh).  From a terminal:

```shell
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```

### Package Install for Windows

This requires [Chocolatey](https://chocolatey.org).  From a command-prompt:

```shell
choco install terraform
```

### Package Install for Debian-based Linux

We must add the HashiCorp Apt repository:

```shell
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

### Package Install fro Red Hat-based Linux

We must the HashiCorp RPM repository:

```shell
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo yum -y install terraform
```

## Lab 2 - Understanding the Terraform CLI

First we need to create a lab directory structure:

```shell
mkdir -p terraform-labs/session-01/lab-02
cd terraform-labs
code .
```

In a terminal, run the following code:

```shell
cd session-01/lab-02
terraform version
terraform -help
terraform init
```

Next, make a new file named `session-01/lab-02/main.tf` in Visual Studio Code and paste the following code:

```terraform
resource "random_string" "random" {
  length = 10
}
```

Add Terraform auto-complete:

```shell
terraform -install-autocomplete
```

Run the following commands, analyzing each:

```shell
terraform plan
terraform apply
terraform plan -destroy
terraform destroy
terraform plan -out=tfplan
terraform show tfplan
terraform apply tfplan
terraform show
```

Update the `session-01/lab-02/main.tf` file with the following:

```terraform
resource "random_string" "random" {
  length = 16
     special  = true
  override_special = "/@$"
min_numeric = 6
   min_special      = 2
  min_upper =3
}
```

Run:

```shell
terraform fmt
terraform apply -auto-approve
```

Review and understand the plan output:

```shell
terraform apply
```

Review your AWS console and find the EC2 instance that we deployed:

```shell
terraform destroy
```

## Lab 3 - Terraform Language Basics

Open the `terraform-labs` directory in Visual Studio Code and create a new directory:

```shell
mkdir -p session-01/lab-03
cd session-01/lab-03
```

Create a new file named `session-01/lab-03/network.tf` in Visual Studio Code and paste the following code:

```terraform
resource "aws_vpc" "vpc" {
  cidr_block = "10.1.0.0/16"

  tags = {
    Name    = "vpc-tf-basics"
    Session = "01"
    Lab     = "03"
  }
}
```

In the terminal, run (using your access credentials):

```shell
export AWS_ACCESS_KEY_ID="<AWS_ACCESS_KEY_ID>"
export AWS_SECRET_ACCESS_KEY="<AWS_SECRET_ACCESS_KEY>"
export AWS_SESSION_TOKEN=""
export AWS_REGION="us-east-1"
terraform init
terraform plan -out tfplan
terraform apply tfplan
```

Create a new file named `session-01/lab-03/variables.tf` in Visual Studio Code and paste the following code:

```terraform
variable "vpc_name" {
  type        = string
  default     = "vpc-tf-basics"
  description = "VPC Name tag."
}

variable "vpc_cidr_block" {
  type        = string
  default     = "10.1.0.0/16"
  description = "VPC address space."
}

variable "subnet_name" {
  type        = string
  default     = "public_subnet-1a"
  description = "Subnet Name tag."
}

variable "subnet_cidr_block" {
  type        = string
  default     = "10.1.42.0/24"
  description = "Subnet address space."
}

variable "availability_zone" {
  type        = string
  default     = "us-east-1a"
  description = "Deployment availability zone."
}
```

Update the file named `session-01/lab-03/network.tf` in Visual Studio Code to resemble the following:

```terraform
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name    = var.vpc_name
    Session = "01"
    Lab     = "03"
  }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.subnet_cidr_block
  availability_zone = var.availability_zone

  tags = {
    Name = var.subnet_name
  }
}
```

Run:

```shell
terraform plan -out tfplan
terraform apply tfplan
```

Add the following to the `session-01/lab-03/variables.tf` file:

```terraform
variable "instance_name" {
  type        = string
  description = "EC2 instance name."
}

variable "instance_size" {
  type        = string
  default     = "t2.micro"
  description = "EC2 instance size."
}
```

Create a new file named `session-01/lab-03/compute.tf` in Visual Studio Code and paste the following code:

```terraform
resource "aws_network_interface" "nic" {
  subnet_id   = aws_subnet.public.id

  tags = {
    Name = "${var.instance_name}-nic"
  }
}

data "aws_ami" "amzn-linux-2023-ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

resource "aws_instance" "ec2" {
  ami           = data.aws_ami.amzn-linux-2023-ami.id
  instance_type = var.instance_size

  network_interface {
    network_interface_id = aws_network_interface.nic.id
    device_index         = 0
  }

  associate_public_ip_address = true

  tags = {
    Name    = var.instance_name
    Session = "01"
    Lab     = "03"
  }
}
```

Run:

```shell
terraform plan -out tfplan # Enter "ec2-tf-basics" for var.instance_name when prompted
terraform apply tfplan
```

Create a new file named `session-01/lab-03/outputs.tf` in Visual Studio Code and paste the following code:

```terraform
output "ssh_connection_string" {
  value = "ssh -i ec2_rsa ec2-user@${aws_instance.ec2.public_dns}"
}
```

Run:

```shell
export TF_VAR_instance_name="ec2-tf-basics"
terraform plan -out tfplan
terraform apply tfplan
```

Apply an existing SSH keypair:

1. Run: `ssh-keygen -b 2048 -t rsa` and name the file `ec2_rsa` when prompted
1. Copy the contents to your clipboard: `cat ec2_rsa.pub`
1. Connect to the AWS EC2 instance via "EC2 Instance Connect"
1. Run: `sudo nano ~/.ssh/authorized_keys`
1. Paste the contents of the `ec2_rsa.pub` (saved to your clipboard) to a new line at the end of the file and save the file
1. Run: `` `terraform output -raw ssh_connection_string` `` (ensure you place this within backticks)

Clean up the deployment:

```shell
terraform destroy -auto-approve
```
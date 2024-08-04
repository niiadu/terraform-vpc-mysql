# Terraform Microsoft Sql Server Deployment and Access Using AWS VPN Endpoint
## Setting Up a Secure Infrastructure with Terraform, AWS, and Easy-RSA
I'll walk you through the steps of creating a secure infrastructure using Terraform, AWS, and Easy-RSA. We'll generate SSL certificates, set up an RDS database, Microsoft Active Directory and configure a VPN endpoint for secure access.

## Prerequisites
Before we begin, make sure you have the following tools installed:

`Terraform`: Infrastructure as Code (IaC) tool to manage and provision your infrastructure.

`AWS CLI`: Command-line interface to interact with AWS services.

`Easy-RSA`: Utility for creating and managing a Public Key Infrastructure (PKI).

## Step 1: Generate SSL Certificates with Easy-RSA
First, we need to generate SSL certificates for securing communication. We'll use Easy-RSA to create a Certificate Authority (CA) and generate certificates for our server and client.

```
# Clone the Easy-RSA repository
git clone https://github.com/OpenVPN/easy-rsa.git

# Navigate to the Easy-RSA directory
cd easy-rsa/easyrsa3

# Initialize the PKI (Public Key Infrastructure)
./easyrsa init-pki

# Build the Certificate Authority (CA)
./easyrsa build-ca nopass

# Generate a server certificate
./easyrsa --san=DNS:server build-server-full server nopass

# Generate a client certificate
./easyrsa build-client-full client1.domain.tld nopass

# Create a custom directory to store the certificates
mkdir ~/custom_folder/
cp pki/ca.crt ~/custom_folder/
cp pki/issued/server.crt ~/custom_folder/
cp pki/private/server.key ~/custom_folder/
cp pki/issued/client1.domain.tld.crt ~/custom_folder
cp pki/private/client1.domain.tld.key ~/custom_folder/

# Navigate to the custom directory
cd ~/custom_folder/

# Import the server certificate to AWS ACM
aws acm import-certificate --certificate fileb://server.crt --private-key fileb://server.key --certificate-chain fileb://ca.crt

# Import the client certificate to AWS ACM
aws acm import-certificate --certificate fileb://client1.domain.tld.crt --private-key fileb://client1.domain.tld.key --certificate-chain fileb://ca.crt
```

<img width="1190" alt="Screenshot 2024-08-02 at 9 46 39 PM" src="https://github.com/user-attachments/assets/52f46e7f-f9e3-4c9a-ac39-1246c84e9257">

## Step 2: Define Terraform Configuration
We'll use Terraform to define our AWS infrastructure, including EC2 instances, RDS database, IAM roles, and VPN endpoints.

### AWS Secret Manager
```
# AWS Secrets Manager configuration
resource "aws_secretsmanager_secret" "db_credentials" {
  name = "${var.account_name}_db_credentials"
}

# Store database credentials in Secrets Manager
resource "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id     = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db-username
    password = random_password.db-password.result
  })
}

# Local variables for database credentials
locals {
  db_credentials = jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)

  depends_on = [aws_secretsmanager_secret_version.db_secret_version]
}
```
<img width="1429" alt="Screenshot 2024-08-03 at 5 09 25 PM" src="https://github.com/user-attachments/assets/233c3e53-cde7-4597-9cd9-104f444dfd8d">

### SSM Parameter Store to store sensitive data
```
# Store VPC and subnet IDs in SSM Parameter Store
resource "aws_ssm_parameter" "vpc-id" {
  name       = "${var.account_name}-vpcID"
  value      = aws_vpc.this[0].id
  type       = "String"
  depends_on = [aws_vpc.this[0]]
}

resource "aws_ssm_parameter" "pub-sn-1" {
  type       = "String"
  name       = "${var.account_name}-Public-Subnet-1"
  value      = aws_subnet.public[0].id
  depends_on = [aws_subnet.public[0]]
}

resource "aws_ssm_parameter" "pub-sn-2" {
  type       = "String"
  name       = "${var.account_name}-Public-Subnet-2"
  value      = aws_subnet.public[1].id
  depends_on = [aws_subnet.public[1]]
}

resource "aws_ssm_parameter" "pri-sn-1" {
  type       = "String"
  name       = "${var.account_name}-Private-Subnet-1"
  value      = aws_subnet.private[0].id
  depends_on = [aws_subnet.private[0]]
}

resource "aws_ssm_parameter" "pri-sn-2" {
  type       = "String"
  name       = "${var.account_name}-Private-Subnet-2"
  value      = aws_subnet.private[1].id
  depends_on = [aws_subnet.private[1]]
}
```
<img width="1424" alt="Screenshot 2024-08-03 at 5 13 35 PM" src="https://github.com/user-attachments/assets/6ab28f0e-9c6f-4c88-9773-b1ae2acb5c19">

### Private EC2 Instance with bash script to change port number to 2031
```
# Create an EC2 instance
resource "aws_instance" "Private-Server" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = var.instance_type
  subnet_id       = aws_ssm_parameter.pri-sn-1.value
  security_groups = [aws_security_group.my_security_group.id]
  key_name        = var.key-pair
  user_data       = filebase64("${path.module}/ssh-port.sh")

  tags = {
    Name = "${var.account_name}-web-Private-1"
  }
}
```
<img width="1237" alt="Screenshot 2024-08-03 at 5 00 55 PM" src="https://github.com/user-attachments/assets/eba72b03-1c64-4f01-976a-51a3a45f3661">

### MySql Server Database

```
# Create an RDS instance
resource "aws_db_instance" "database-instance" {
  allocated_storage       = 20
  identifier              = "mysqlserver"
  engine                  = "sqlserver-ex"
  engine_version          = "15.00.4043.16.v1"
  instance_class          = "db.t3.micro"
  username                = local.db_credentials.username
  password                = local.db_credentials.password
  skip_final_snapshot     = true
  availability_zone       = var.azs[0]
  db_subnet_group_name    = aws_db_subnet_group.database-subnet.name
  license_model           = "license-included"
  vpc_security_group_ids  = [aws_security_group.my_security_group.id]
  domain                  = aws_directory_service_directory.my-directory.id
  domain_iam_role_name    = aws_iam_role.role.name
}
```

<img width="1189" alt="Screenshot 2024-08-03 at 5 09 05 PM" src="https://github.com/user-attachments/assets/29212e4d-a06d-490f-a2ad-c9f4252de7e7">

<img width="1188" alt="Screenshot 2024-08-03 at 5 08 49 PM" src="https://github.com/user-attachments/assets/f7d3274e-f761-43de-9ab4-ed567ec1be65">

### Microsoft Active Directory

```
# Create a Microsoft Active Directory
resource "aws_directory_service_directory" "my-directory" {
  name     = "corp.mydirectory.com"
  password = "niiadu1234@#?"
  edition  = "Standard"
  type     = "MicrosoftAD"

  vpc_settings {
    vpc_id     = aws_vpc.this[0].id
    subnet_ids = [aws_subnet.private[0].id, aws_subnet.private[1].id]
  }

  tags = {
    Project = "MySql Project"
  }
}
```
<img width="1192" alt="Screenshot 2024-08-03 at 8 19 43 PM" src="https://github.com/user-attachments/assets/7f548b4d-db01-488b-b287-5ddd56f40eaf">

### Creating a VPN endpoint and authorizing it to be accessed by users

```
# Create a VPN endpoint
resource "aws_ec2_client_vpn_endpoint" "my-vpn-endpoint" {
  description            = "terraform-clientvpn-example"
  server_certificate_arn = "arn:aws:acm:eu-north-1:736024348173:certificate/5c166788-55ca-4b08-a812-a086cfcf273f"
  client_cidr_block      = "192.168.128.0/22"
  vpc_id                 = aws_vpc.this[0].id
  security_group_ids     = [aws_security_group.my_security_group.id]

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = "arn:aws:acm:eu-north-1:736024348173:certificate/ba6f95b2-ac2d-4564-b606-73be59667499"
  }

  connection_log_options {
    enabled = false
  }
}

# Authorize VPN access
resource "aws_ec2_client_vpn_authorization_rule" "example" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.my-vpn-endpoint.id
  target_network_cidr    = var.cidr
  authorize_all_groups   = true
}
```
<img width="1230" alt="Screenshot 2024-08-03 at 8 06 49 PM" src="https://github.com/user-attachments/assets/80487dc5-46b5-4e54-ac6b-b3f4b40f3722">

### VPN endpoint network association with private subnets

```
# Associate VPN with subnets
resource "aws_ec2_client_vpn_network_association" "vpn-association-1" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.my-vpn-endpoint.id
  subnet_id              = aws_subnet.private[0].id
}

resource "aws_ec2_client_vpn_network_association" "vpn-association-2" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.my-vpn-endpoint.id
  subnet_id              = aws_subnet.private[1].id
}
```
 <img width="1230" alt="Screenshot 2024-08-03 at 8 07 02 PM" src="https://github.com/user-attachments/assets/3e3b5a64-e333-47d3-adc5-a6794bdc1d06">

### This shows the AWS VPN Client being connected from my local machine.

<img width="322" alt="Screenshot 2024-08-03 at 4 41 36 PM" src="https://github.com/user-attachments/assets/be77f1d5-ab25-42a4-b981-8b7610b3ed2a">

<img width="473" alt="Screenshot 2024-08-03 at 4 48 14 PM" src="https://github.com/user-attachments/assets/0bb6ca84-413b-42a4-8799-44c7ca45cca5">

### Successfully Changing Port number to 2031
This image proves that the following bash shell script successful changed the port number of the host server to port 2031.

```
#!/bin/bash
sudo apt update && sudo apt upgrade -y

sudo -i
mkdir -p /etc/systemd/system/ssh.socket.d

cat > /etc/systemd/system/ssh.socket.d/override.conf <<EOF
[Socket]
ListenStream=
ListenStream=2031
EOF

sudo systemctl daemon-reload
sudo systemctl restart ssh.socket
```
<img width="868" alt="Screenshot 2024-08-03 at 5 02 39 PM" src="https://github.com/user-attachments/assets/4543a709-5804-430e-b757-0bc02dc87a08">

## Conclusion
In this blog post, we successfully set up a secure infrastructure using Terraform, AWS, and Easy-RSA. We generated SSL certificates, created an RDS database,Microsoft Active Directory configured an EC2 instance and changed the default port to 2031, and set up a VPN endpoint for secure access. This setup ensures that our infrastructure is both secure and easily manageable.

## Usage
- Execute the command `terraform init` to setup the project workspace.
- Excute the command `terrraform plan` to get a preview of the resources, terraform is going to implement incase you go ahead with it. This will give you detailed informations on resources to be provisioned
- Execute the command `terraform apply` to provision the infrastructure. This will create a VPC with Private and Public Subnets,a Load Balancer, Auto Scaling group, a NAT Gateway and EC2 instances.
- Execute the command `terraform destroy` to destroy the infrastructure.


## Note
The resources created in this example may incur cost. So please make sure to destroy the infrastructure if you don't need it.

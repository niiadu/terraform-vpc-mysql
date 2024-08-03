# This is dynamically calling the db secrets we based to the secrets manager, and use in creating the DB
data "aws_secretsmanager_secret_version" "current" {
  secret_id = aws_secretsmanager_secret.db_credentials.id

  depends_on = [ aws_secretsmanager_secret_version.db_secret_version ]
}

# Databse Subnet, in the private subnet we created for the private subent
resource "random_password" "db-password" {
  length = 16
  special = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_db_subnet_group" "database-subnet" {
  name       = "database-subnets"
  subnet_ids = [ aws_subnet.private[0].id, aws_subnet.private[1].id ]

  tags = {
    Name = "My DB subnet group"
  }
}

# AWS secrets manager configuration
resource "aws_secretsmanager_secret" "db_credentials" {
  name = "${var.account_name}_db_credentials"
}

# Aws secret manager credential, passed to the secret manager directory
resource "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id     = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = var.db-username
    password = random_password.db-password.result
  })
}

# This saves the data in a JSON formet, for easy access by the DB
locals {
  db_credentials = jsondecode(data.aws_secretsmanager_secret_version.current.secret_string)

  depends_on = [aws_secretsmanager_secret_version.db_secret_version]
}

#Database configuration instance
resource "aws_db_instance" "database-instance" {
  allocated_storage      = 20
#   db_name                = ""
  identifier = "mysqlserver"
  engine                 = "sqlserver-ex"
  engine_version         = "15.00.4043.16.v1"
  instance_class         = "db.t3.micro"
  username               = local.db_credentials.username
  password               = local.db_credentials.password
#   parameter_group_name   = "default.mysql8.0"
  skip_final_snapshot    = true
  availability_zone      = var.azs[0]
  db_subnet_group_name   = aws_db_subnet_group.database-subnet.name
  license_model = "license-included"
  # multi_az               = true
  vpc_security_group_ids = [aws_security_group.my_security_group.id]
  domain = aws_directory_service_directory.my-directory.id
  domain_iam_role_name = aws_iam_role.role.name
}

# resource "aws_db_instance_role_association" "the-role" {
#   db_instance_identifier = aws_db_instance.database-instance.identifier
#   feature_name           = "IAMAuthentication"
#   role_arn               = aws_iam_role.role.arn
# }


# Security Group for the database in the private DB subnet, to allow access from the EC2 instances in the private subnet
resource "aws_security_group" "my_security_group" {
  name        = "Server Security Group"
  description = "My security group"
  vpc_id      = aws_vpc.this[0].id

  ingress {
    description = "All access within the security group"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self = true
  }

    ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

     ingress {
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Database and Server Security Group"
  }
}
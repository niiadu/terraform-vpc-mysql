# Mircrosoft active directory with an IAM role associated to access the DB
resource "aws_directory_service_directory" "my-directory" {
  name = "corp.mydirectory.com"
  #   password = "SuperSecretPassw0rd"
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

# i am role for the MS AD
resource "aws_iam_role" "role" {
  name = "rds-directory-service-access-role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "rds.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Project = "MySql Project"
  }
}

# IAM policy for the role
resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSDirectoryServiceAccess"
}
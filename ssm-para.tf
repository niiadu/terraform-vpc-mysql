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
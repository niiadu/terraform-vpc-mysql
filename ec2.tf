resource "aws_instance" "Private-Server" {
  ami             = data.aws_ami.ubuntu.id // Ubuntu  AMI
  instance_type   = var.instance_type
  subnet_id       = aws_ssm_parameter.pri-sn-1.value
  security_groups = [aws_security_group.my_security_group.id]
  key_name        = var.key-pair
  user_data       = filebase64("${path.module}/ssh-port.sh")

  tags = {
    Name = "${var.account_name}-web-Private-1"
  }
}
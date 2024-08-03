resource "aws_ec2_client_vpn_endpoint" "my-vpn-endpoint" {
  description            = "terraform-clientvpn-example"
  server_certificate_arn = "arn:aws:acm:eu-north-1:736024348173:certificate/5c166788-55ca-4b08-a812-a086cfcf273f"
  client_cidr_block      = "154.161.148.0/22"
  vpc_id = aws_vpc.this[0].id
  security_group_ids = [aws_security_group.my_security_group.id]

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = "arn:aws:acm:eu-north-1:736024348173:certificate/ba6f95b2-ac2d-4564-b606-73be59667499"
  }

  connection_log_options {
    enabled               = false
  }
}

resource "aws_ec2_client_vpn_authorization_rule" "example" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.my-vpn-endpoint.id
  target_network_cidr    = var.cidr
  authorize_all_groups   = true
}

resource "aws_ec2_client_vpn_network_association" "vpn-association-1" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.my-vpn-endpoint.id
  subnet_id              = aws_subnet.private[0].id
}

resource "aws_ec2_client_vpn_network_association" "vpn-association-2" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.my-vpn-endpoint.id
  subnet_id              = aws_subnet.private[1].id
}
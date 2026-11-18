mock_provider "aws" {}

run "network_nat_gateway_plan" {
  command = plan

  variables {
    environment       = "dev"
    availability_zone = "us-east-1a"
    egress_mode       = "nat-gateway"
  }

  assert {
    condition     = aws_subnet.hosts.map_public_ip_on_launch == false
    error_message = "Session host subnet must never assign public IPs."
  }

  assert {
    condition     = length(aws_nat_gateway.avd) == 1
    error_message = "nat-gateway egress_mode should provision one NAT Gateway."
  }

  assert {
    condition     = length(aws_security_group.session_host.ingress) == 0
    error_message = "Session host security group must not expose inbound internet rules."
  }

  assert {
    condition     = length(aws_security_group.session_host.egress) == 2
    error_message = "Session host security group should allow TCP 443 and UDP 3478 egress by default."
  }
}

run "network_vpc_endpoints_no_nat_plan" {
  command = plan

  variables {
    environment                   = "dev"
    availability_zone             = "us-east-1a"
    egress_mode                   = "vpc-endpoints"
    enable_rdp_shortpath_udp_3478 = false
  }

  assert {
    condition     = length(aws_nat_gateway.avd) == 0
    error_message = "vpc-endpoints egress_mode should not provision a NAT Gateway."
  }

  assert {
    condition     = length(aws_security_group.session_host.egress) == 1
    error_message = "Disabling RDP Shortpath should leave only TCP 443 egress."
  }
}

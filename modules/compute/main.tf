terraform {
  required_version = ">= 1.7.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.60"
    }
  }
}

resource "aws_iam_role" "session_host" {
  name = "role-avd-hosts-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "role-avd-hosts-${var.environment}"
    Environment = var.environment
    avd-ops     = "hybrid-aws"
  }
}

resource "aws_iam_role_policy" "arc_sp_secret" {
  count = var.arc_sp_secret_arn != "" ? 1 : 0
  name  = "policy-avd-arc-secret-${var.environment}"
  role  = aws_iam_role.session_host.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = [var.arc_sp_secret_arn]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "session_host" {
  name = "ip-avd-hosts-${var.environment}"
  role = aws_iam_role.session_host.name

  tags = {
    Name        = "ip-avd-hosts-${var.environment}"
    Environment = var.environment
    avd-ops     = "hybrid-aws"
  }
}

resource "aws_launch_template" "session_host" {
  name_prefix            = "lt-avd-hybrid-${var.environment}-"
  image_id               = var.source_ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [var.security_group_id]
  user_data              = var.user_data_ps1 != "" ? base64encode(var.user_data_ps1) : null

  iam_instance_profile {
    arn = aws_iam_instance_profile.session_host.arn
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = var.boot_disk_size_gb
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name                   = "avdh-${var.environment}"
      Environment            = var.environment
      avd-ops                = "hybrid-aws"
      avd-arc-resource-group = var.arc_resource_group
      avd-host-pool-name     = var.host_pool_name
      avd-identity-mode      = "entra-joined"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "session_hosts" {
  name                = "asg-avd-hosts-${var.environment}"
  vpc_zone_identifier = [var.private_subnet_id]
  desired_capacity    = var.session_host_count
  min_size            = 0
  max_size            = max(var.session_host_count, 1)
  health_check_type   = "EC2"

  launch_template {
    id      = aws_launch_template.session_host.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "avdh-${var.environment}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "avd-ops"
    value               = "hybrid-aws"
    propagate_at_launch = true
  }

  tag {
    key                 = "avd-arc-resource-group"
    value               = var.arc_resource_group
    propagate_at_launch = true
  }

  tag {
    key                 = "avd-host-pool-name"
    value               = var.host_pool_name
    propagate_at_launch = true
  }
}

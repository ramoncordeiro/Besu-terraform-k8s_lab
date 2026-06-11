# Data source

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical


  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}


# step 2:generate key locally
resource "tls_private_key" "besu_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key_pem" {
  content         = tls_private_key.besu_key.private_key_pem
  filename        = "${path.module}/../../besu-lab-key.pem"
  file_permission = "0600" #only owner can read
}

#step 3: register public key in AWS

resource "aws_key_pair" "besu_key" {
  key_name   = var.key_name
  public_key = tls_private_key.besu_key.public_key_openssh

  tags = {
    Project     = var.project_tag
    Environment = var.environment_tag
  }
}


# step 4: Security Group in firewall

resource "aws_security_group" "besu_sg" {
  name        = "${var.project_tag}-sg"
  description = "Security group for Besu Lab EC2 instance"

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "Grafana"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # rule for besu p2p tcp
  ingress {
    description = "Besu P2P TCP"
    from_port   = 30303
    to_port     = 30303
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # rule for besu p2p udp (node discovery)
  ingress {
    description = "Besu P2P UDP"
    from_port   = 30303
    to_port     = 30303
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # rule for json-rpc
  ingress {
    description = "Besu JSON-RPC"
    from_port   = 8545
    to_port     = 8545
    protocol    = "tcp"
    self        = true
  }

  #rule for metrics
  ingress {
    description = "Besu Metrics"
    from_port   = 9545
    to_port     = 9545
    protocol    = "tcp"
    self        = true
  }

  ingress {
    description = "Kubernetes API (k3s)"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project     = var.project_tag
    Environment = var.environment_tag
  }
}

resource "aws_instance" "besu_node" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.besu_key.key_name
  vpc_security_group_ids      = [aws_security_group.besu_sg.id]
  associate_public_ip_address = true

  # script tht runs on boot
  user_data = file("${path.module}/../../bootstrap-cluster.sh")


  # root disk bigger than default 
  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3" #ssd modern and cheaper than gp2
    delete_on_termination = true
  }

  tags = {
    Name        = "${var.project_tag}-ec2"
    Project     = var.project_tag
    Environment = var.environment_tag
  }
}

output "ec2_public_ip" {
  description = "Public IP address of the EC2 ssh"
  value       = aws_instance.besu_node.public_ip
}

output "ec2_public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_instance.besu_node.public_dns
}

output "ssh_command" {
  description = "SSH command to connect to the EC2 instance"
  value       = "ssh -i ${local_file.private_key_pem.filename} ubuntu@${aws_instance.besu_node.public_ip}"
}

output "private_key_pem" {
  description = "Private key PEM content"
  value       = tls_private_key.besu_key.private_key_pem
  sensitive   = true
}
variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "us-east-1"
}

# Kind of EC2 instance (size).
#t2.micro

variable "instance_type" {
  description = "The type of EC2 instance to create."
  type        = string
  default     = "t2.micro"
}


# SSH Keypair

variable "key_name" {
  description = "SSH key pair name "
  type        = string
  default     = "besu-lab-key"
}

# Allowed CIRD for SSH access to the EC2 instance.
variable "allowed_ssh_cidr" {
  description = "Range of allowed IPs to connect ssh"
  type        = string
  default     = "0.0.0.0/0"
}

variable "project_tag" {
  description = "Tag to identify the project in AWS"
  type        = string
  default     = "besu-lab"
}

variable "environment_tag" {
  description = "tag 'Environment for all resources (e.g: dev, prod"
  type        = string
  default     = "portfolio"
}

variable "root_volume_size" {
  description = "Size of the EC2 in GB"
  type        = number
  default     = 20
}


variable "kubeconfig_path" {
  description = "Path to save the kubeconfig file on the local machine"
  type        = string
  default     = "~/.kube/config-besu"
}
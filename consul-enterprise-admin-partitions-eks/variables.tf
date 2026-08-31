# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

variable "eks_cluster_name_primary" {
  description = "Name of the primary EKS Cluster that runs the Consul Enterprise server cluster"
  type        = string
  default     = "primary"
}
variable "eks_cluster_name_secondary" {
  type        = string
  description = "Name of the secondary EKS Cluster that runs the Consul Enterprise client cluster"
  default     = "secondary"
}
variable "license_name" {
  type        = string
  description = "The name of the Consul Enterprise license file. Place this file in the `./consul_enterprise/` directory"
  default     = "consul.hclic"

  validation {
    condition     = fileexists(pathexpand("./consul_enterprise/${var.license_name}"))
    error_message = "Consul Enterprise license file not found at ${var.license_name}. Please place the license file in the `./consul_enterprise/` directory."
  }
}

# Default tags to pass to AWS. You can set them here, or in a tfvars file.
variable "default_tags" {
  type = map(string)
  default = {
    github = "hashicorp/learn-consul-kubernetes"
  }
}

variable "eks_cluster_primary_ips_consul_server" {
  description = "The CIDR groups for the Primary Cluster's IP addresses"
  default = {
    vpc      = "10.100.0.0/16"
    private  = "10.100.1.0/24"
    public   = "10.100.2.0/24"
    internet = "0.0.0.0/0"
  }
}

variable "eks_cluster_secondary_ips_consul_client" {
  description = "The CIDR groups for the Secondary Cluster's IP addresses"
  default = {
    vpc      = "172.30.0.0/16"
    private  = "172.30.1.0/24"
    public   = "172.30.2.0/24"
    internet = "0.0.0.0/0"
  }
}

# The name of the Consul Enterprise installation types. If this comment is here
# please don't change these values. The configs are currently reliant on these namse
# which will be addressed at a later time.
variable "deploy_type" {
  default = {
    server = "server"
    client = "client"
  }
}

variable "aws_region" {
  default = "us-east-1"
  type    = string
}

variable "availability_zones" {
  description = "The AZs in which the Clusters will deploy"
  default = {
    zone_one = "us-east-1a"
    zone_two = "us-east-1f"
  }
}

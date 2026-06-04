# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

locals {
  license_content  = file("${path.root}/${path.module}/${var.license_name}")
}

# This module only runs when `terraform destroy` is invoked.
module "cleanup" {
  source = "./cleanup"
  vpc_id = var.vpc_id
  eks_cluster_primary = var.eks_cluster_primary
  deploy_type = var.deploy_type
  eks_cluster_name = var.eks_cluster_name
  region  = var.region
}

resource "null_resource" "install_consul_enterprise" {
  provisioner "local-exec" {
    # The aws command line will update your kubeconfig with your cluster info, so you can use `kubectl` locally.
    command = "aws eks update-kubeconfig --region ${data.aws_region.current.name} --name ${var.eks_cluster_name} --alias ${var.eks_cluster_name}"
  }
  # Install EKS Service Accounts
  provisioner "local-exec" {
    working_dir = path.module
    command = "kubectl --context ${var.eks_cluster_name} apply -f kubernetes-admin-service-account.yaml"
  }
  # Install the k8s dashboard
  provisioner "local-exec" {
    working_dir = path.module
    command = "kubectl --context ${var.eks_cluster_name} apply -f kubernetes-dashboard.yaml"
  }
  # Install the K8s storage class
  provisioner "local-exec" {
    working_dir = path.module
    command = "kubectl --context ${var.eks_cluster_name} apply -f kubernetes-storage.yaml"
  }
  # Create a Consul namespace
  provisioner "local-exec" {
    working_dir = path.module
    command     = "kubectl --context ${var.eks_cluster_name} create namespace consul"
  }
  # Store consul enterprise license in Kubernetes, any cluster as part of this terraform code will need to upload the license.
  provisioner "local-exec" {
    working_dir = path.module
    command     = "kubectl --context ${var.eks_cluster_name} create --namespace=consul secret generic consul-ent-license --from-literal=\"key=${local.license_content}\""
  }
}


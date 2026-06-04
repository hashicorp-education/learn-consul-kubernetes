# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

terraform {
  required_providers {
    tls = {
      source  = "hashicorp/tls"
    }
  }
}

data "tls_certificate" "oidc" {
  url = aws_eks_cluster.primary.identity[0].oidc[0].issuer
}

# EKS addon
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = aws_eks_cluster.primary.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = "v1.60.1-eksbuild.1" #"v1.29.1-eksbuild.1"
  service_account_role_arn = aws_iam_role.ebs_csi_driver.arn
}

# AWS Identity and Access Management (IAM) OpenID Connect (OIDC) provider
resource "aws_iam_openid_connect_provider" "eks" {
  url             = aws_eks_cluster.primary.identity.0.oidc.0.issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]
}

# IAM
resource "aws_iam_role" "ebs_csi_driver" {
  name               = "ebs-csi-driver-${var.eks_cluster_name}"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_driver_assume_role.json
}

data "aws_iam_policy_document" "ebs_csi_driver_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    actions = [
      "sts:AssumeRoleWithWebIdentity",
    ]

    condition {
      test     = "StringEquals"
      variable = "${aws_iam_openid_connect_provider.eks.url}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${aws_iam_openid_connect_provider.eks.url}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

  }
}

resource "aws_iam_role_policy_attachment" "AmazonEBSCSIDriverPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_driver.name
}

module "iam" {
  source = "./iam"
}
module "networking" {
  source = "./networking"
  lib_cluster_name = var.eks_cluster_name
  eks_cidr_blocks = var.eks_vpc_cidr_block
  availability_zones = var.availability_zones
}

resource "aws_eks_cluster" "primary" {
  name     = var.eks_cluster_name
  role_arn = module.iam.eks_admin_partition_arn
  vpc_config {
    subnet_ids = [module.networking.subnet_ids.private,
                  module.networking.subnet_ids.public]
    endpoint_public_access = true
    endpoint_private_access = true
  }
}

module "update_eks_cluster_sgs" {
  source = "./create-new-sg"
  vpc_id = module.networking.vpc_id
  existing_sg_id = aws_eks_cluster.primary.vpc_config.0.cluster_security_group_id
  cidr_blocks = [var.eks_vpc_cidr_block_primary.public, var.eks_vpc_cidr_block_primary.private, var.eks_vpc_cidr_block_secondary.private, var.eks_vpc_cidr_block_secondary.public]
  depends_on = [aws_eks_cluster.primary]
}

resource "aws_eks_node_group" "public" {
  node_group_name_prefix = "ngPublic"
  cluster_name  = aws_eks_cluster.primary.name
  node_role_arn = module.iam.eks_admin_partition_arn
  subnet_ids    = [module.networking.subnet_ids.public]

  scaling_config {
    desired_size = var.number_of_nodes.public.desired
    max_size     = var.number_of_nodes.public.max_nodes
    min_size     = var.number_of_nodes.public.min_nodes
  }
  labels = {
    "type" = "public"
  }
  tags = {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "owned"
    "Name" = "eks_node_group_public_instances"
  }

  instance_types = ["m5.large"]
  disk_size = 100
}

resource "aws_eks_node_group" "private" {
  node_group_name_prefix = "ngPriv"
  cluster_name  = aws_eks_cluster.primary.name
  node_role_arn = module.iam.eks_admin_partition_arn
  subnet_ids    = [module.networking.subnet_ids.private]

  scaling_config {
    desired_size = var.number_of_nodes.private.desired
    max_size     = var.number_of_nodes.private.max_nodes
    min_size     = var.number_of_nodes.private.min_nodes
  }
  tags = {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "owned"
    "Name" = "eks_node_group_private_instances"
  }
  labels = {
    "type" = "private"
  }
  instance_types = ["m5.large"]
  disk_size = 100
}




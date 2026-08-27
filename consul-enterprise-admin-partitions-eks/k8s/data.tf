# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

data "aws_region" "current" {}
data "aws_security_group" "eks_cluster" {
  id = aws_eks_cluster.eks-cluster.vpc_config.0.cluster_security_group_id
}

data "tls_certificate" "oidc" {
  url = aws_eks_cluster.eks-cluster.identity[0].oidc[0].issuer
}
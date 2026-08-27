# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

output "vpc_id" {
  value = module.networking.vpc_id
}
output "route_table_id" {
  value = module.networking.route_table_id
}
output "main_route_table_id" {
  value = module.networking.main_route_table_id
}
output "security_group_id" {
  value = aws_eks_cluster.eks-cluster.vpc_config.0.cluster_security_group_id
}

output "public-subnet-id" {
  value = module.networking.public-subnet-id
}

output "private-subnet-id" {
  value = module.networking.private-subnet-id
}

output "eks_security_group" {
  value = data.aws_security_group.eks_cluster.id
}
module "dc2" {
  source = "../../environments/terraform/eks"

  datacenter_name = "dc2"
  output_dir      = "~/.kube"
  region          = "us-west-1"
}

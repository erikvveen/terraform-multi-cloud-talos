locals {
  
  clusters = [
    {
      name                = "dev-cluster"
      cloud_platform      = "linode"
      region              = "nl-ams"
      tags                = ["dev", "kubernetes"]
      pod_cidr            = "10.244.0.0/16"
      service_cidr        = "10.96.0.0/12"
      linode_token        = var.linode_token
      talos_version       = "v1.8.3"
      kubernetes_version  = "1.31.0"
      config_patch_files  = ["cilium.yaml"]
    },
    {
      name                = "prod-cluster"
      cloud_platform      = "linode"
      region              = "eu-central"
      tags                = ["prod", "kubernetes"]
      pod_cidr            = "10.245.0.0/16"
      service_cidr        = "10.97.0.0/12"
      linode_token        = var.linode_token
      talos_version       = "v1.8.3"
      kubernetes_version  = "1.31.0"
      config_patch_files  = ["cilium.yaml"]

    }
  ]

linode_clusters = [ for cluster in local.clusters : cluster if cluster.cloud_platform == "linode"]
aws_clusters = [for cluster in local.clusters : cluster if cluster.cloud_platform == "aws"]

tags = [ "kubernetes.io/cluster/talos-cute = owned"]

vpc = {
  name                          = "talos-vpc"
  region                        = "eu-central-1"
  cidr                          = "10.1.0.0/18"
  additional_public_subnet_tags = {"kubernetes.io/cluster/talos-cute" = "owned"}
}

}




module "vpc" {
  source = "git::https://github.com/isovalent/terraform-aws-vpc"
  count = length(local.aws_clusters)

  name                          = local.vpc.name
  region                        = local.aws_clusters[count.index].region
  cidr                          = local.vpc.cidr
  tags                          = local.aws_clusters[count.index].tags
  additional_public_subnet_tags = local.vpc.additional_public_subnet_tags
}

module "talos_linode_clusters" {
  source = "git::https://github.com/erikvveen/terraform-linode-talos-ext.git"
  count = length(local.linode_clusters)
  
  providers = {
    talos = talos
    random = random
    linode = linode
  }

  cluster_name       = local.linode_clusters[count.index].name
  region             = local.linode_clusters[count.index].region
  tags               = local.linode_clusters[count.index].tags
  pod_cidr           = local.linode_clusters[count.index].pod_cidr
  service_cidr       = local.linode_clusters[count.index].service_cidr
  linode_token       = local.linode_clusters[count.index].linode_token
  talos_version      = local.linode_clusters[count.index].talos_version
  kubernetes_version = local.linode_clusters[count.index].kubernetes_version
  config_patch_files = local.linode_clusters[count.index].config_patch_files
}

module "talos_aws_clusters" {
  source = "git::https://github.com/erikvveen/terraform-aws-talos.git"
  count = length(local.aws_clusters)

  providers = {
    aws = aws
    talos = talos
    random = random
  }

  talos_version      = local.aws_clusters[count.index].talos_version
  kubernetes_version = local.aws_clusters[count.index].kubernetes_version
  cluster_name       = local.aws_clusters[count.index].name
  region             = local.aws_clusters[count.index].region
  tags               = local.aws_clusters[count.index].tags
  pod_cidr           = local.aws_clusters[count.index].pod_cidr
  service_cidr       = local.aws_clusters[count.index].service_cidr
  vpc_id             = local.aws_clusters[count.index].vpc_id
  config_patch_files = local.linode_clusters[count.index].config_patch_files

}


#FW NOT IN TALOS MODULES, IS AKAMAI INTERNAL ONLY 
module "Akamai-FW-Linode-cluster" {
  source = "git::https://github.com/erikvveen/Akamai-FW.git"
  count = length(local.linode_clusters)

  depends_on = [ module.talos_linode_clusters]

  kubeconfig_file                     = module.talos_linode_clusters[count.index].path_to_kubeconfig_file
  control_plane_ips                   = module.talos_linode_clusters[count.index].control_plane_nodes_ip_addresses
  worker_ips                          = module.talos_linode_clusters[count.index].worker_nodes_ip_addresses
  control_plane_private_ip_addresses  = module.talos_linode_clusters[count.index].control_plane_private_ip_addresses
  worker_nodes_private_ip_addresses   = module.talos_linode_clusters[count.index].worker_nodes_private_ip_addresses
  nodebalancer_ip                     = module.talos_linode_clusters[count.index].nb_ip_address

  control_plane_ids = module.talos_linode_clusters[count.index].control_plane_nodes_id 
  worker_nodes_ids  = module.talos_linode_clusters[count.index].worker_nodes_id
  nodebalancer_id   = module.talos_linode_clusters[count.index].nb-k8s-nb_id
}



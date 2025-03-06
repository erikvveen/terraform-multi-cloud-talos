terraform {
  required_providers {
   
    talos = {
      source  = "siderolabs/talos"
      version = ">= 0.7.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    linode = {
      source = "linode/linode"
      version = "2.31.1"
    }
    aws = {
      source = "hashicorp/aws"
      version = ">= 5.46.0"
    }
  }
}
provider "talos" {
  version = "0.7.1"
}

provider "random" {
  version = "~> 3.5"
}

provider "linode" {
  token    = var.linode_token
}

provider "aws" {
  region = "eu-central-1"
}

provider "helm" {
}



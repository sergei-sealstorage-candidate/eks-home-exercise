
#S3 Bucket Terrafrom State

module "tf_s3_bucket" {
  source = "./module/s3"
  tf_s3_bucket_name = "sealstorage-tf-state"   
}

#VPC and Subnets for EKS Cluster

module "eks_vpc" {
  source     = "./module/vpc"
  cidr_block = "10.0.0.0/16"
  public_ip_on_launch = true
}

# EKS Module from Terrafrom AWS Modules

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "my-cluster" # forgot to change claster name from terraform module usage example =/
  cluster_version = "1.30"

  cluster_endpoint_public_access  = true

  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  vpc_id                   = module.eks_vpc.aws_vpc_id
  subnet_ids               = module.eks_vpc.aws_subnet_ids

  eks_managed_node_group_defaults = {
    instance_types = ["t3.small"]
  }

  eks_managed_node_groups = {
    sealstorage = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.small"]

      min_size     = 3
      max_size     = 3
      desired_size = 3
    }
  }

  enable_cluster_creator_admin_permissions = true

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

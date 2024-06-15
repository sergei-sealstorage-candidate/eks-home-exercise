# eks-home-exercise
Take Home Exercise

This is the Step by Step documentation of what has been done during this Take Home Assigment

## Step 1

### Cloud Envirment Prep

For this Home Exercise we need to create AWS EKS Cluster with 3 nodes and 3 pods whic is running in each Node. To make this test more closer to production release, we should image that we just starting the project and we don't have any envirment set-up yet. So for this we will create a new AWS Account, whic can be done using AWS Organizations. This will give us the whole isolation resoucres, bill visability and doesn't conflict to any of personal pproject.

In Order to create new AWS Account account we can use aws-cli

```
$ aws organizations create-account --email SerKhazov+sealstorage@gmail.com --account-name SealStorage-PlayGround
```

The next step we need to Switch Role using AWS Console using New Account ID or we can do it using aws-cli command `aws sts assume-role` passing new account role arn. After switching role we get logged in into newly create account *SealStorage-PlayGround* so we can create a new users and permissions. For this test we will create one user only with cli access and one ReadOnly User with AWS Console access. AWS Console ReadOnly user will be shared with SealStorage engineers.

## Step 2

### Local Environment Set Up

After Creating nesessary users we need to create additional AWS Profile config on local envirment in order to comminicate with the cloud. We can create New Profile Config using aws-cli and 

```
aws configure --profile SealStorage
```

Enter AWS Access Keys and AWS Secret Keys

```
AWS Access Key ID [None]: <YourAccessKeyID> # Hidden from sec purpuse
AWS Secret Access Key [None]: <YourSecretAccessKey> # Hidden from sec purpuse
Default region name [None]: 'us-east-1'
Default output format [None]: json
```

In order to check if we heve access to the SealStorage-PlayGround cloud we can get for example list of users using provided credentials profile

```
$ aws iam list-users --profile=SealStorage
```

## Step 3

### Terraform Set Up

For this test we need to try to make as much as possible automated approach. So terrafrom is the greate tool in order to create automation for envirment and keep the whole infrastructure as a code and keep versioning.

For terrafrom set up we need to specify aws provider and backend as s3 bucket. We create a new module for s3 bucket

```
resource "aws_s3_bucket" "terraform-bkt" {
  bucket  = var.tf_s3_bucket_name
  tags    = {
	Name          = "SealStorage"
	Environment    = "Development"
  }
}
```

And we need to include this module into main.tf file

```
module "tf_s3_bucket" {
    source = "./module/s3"
    tf_s3_bucket_name = "sealstorage-tf-state"   
}
```

After this we can run terrafrom init and apply if the plan looks good.

```
$ terraform init && terraform apply
```

After succesfull bucket creation we should see new s3 bucket in SealStorage-PlayGround cloud.

Now we can specify new bucket as terrafrom state backend as

```
terraform {
    backend "s3" {
      bucket = "sealstorage-tf-state"
      key = "state/terraform.tfstate"
      region = "us-east-1"
      profile = "SealStorage"
    }
}
```
After that we should run terraform init one more time and we should be able to sync local state with remote state

```
$ terraform init

Initializing the backend...
Do you want to copy existing state to the new backend?
  Pre-existing state was found while migrating the previous "local" backend to the
  newly configured "s3" backend. No existing state was found in the newly
  configured "s3" backend. Do you want to copy this state to the new "s3"
  backend? Enter "yes" to copy and "no" to start with an empty state.

  Enter a value: yes

````

## Step 4

### Networking and VPC

In order to create EKS Cluster first we need to create Networking for future EKS Cluster. Inorder to set up network for EKS we gonna use VPC and related to VPC module. VPC module that you can see below creates 3 subnets across different Availability Zones.

VPC Module

After we should include new VPC module into `main.tf`

```
module "tf_s3_bucket" {
  source = "./module/s3"
  tf_s3_bucket_name = "sealstorage-tf-state"   
}

module "eks_vpc" {
  source     = "./module/vpc"
  cidr_block = "10.0.0.0/16"
  public_ip_on_launch = true
}
```

Run `$ terraform apply`

### EKS Cluster creation

In order to create EKS cluster we are going to use defind terraform module `terraform-aws-modules/eks/aws` from terraform repository and will provide desire node count size 3 and instance type `t3.small` 

```
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
```

After adding this module into `main.tf` we need to apply these changes.

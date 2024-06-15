# eks-home-exercise

This is the Step by Step documentation of what have been done during SealStorage Take Home Assigment

## Table

* [Step #1](https://github.com/sergei-sealstorage-candidate/eks-home-exercise?tab=readme-ov-file#step-1)
  - [Cloud Environment Prep](https://github.com/sergei-sealstorage-candidate/eks-home-exercise?tab=readme-ov-file#cloud-environment-prep)
* [Step #2](https://github.com/sergei-sealstorage-candidate/eks-home-exercise?tab=readme-ov-file#step-2)
  - [Local Environment Set Up](https://github.com/sergei-sealstorage-candidate/eks-home-exercise?tab=readme-ov-file#local-environment-set-up)  
* [Step #3](https://github.com/sergei-sealstorage-candidate/eks-home-exercise?tab=readme-ov-file#step-3)
  - [Terraform Set Up](https://github.com/sergei-sealstorage-candidate/eks-home-exercise?tab=readme-ov-file#terraform-set-up)
* [Step #4](https://github.com/sergei-sealstorage-candidate/eks-home-exercise?tab=readme-ov-file#step-4)
  - [Networking and VPC](https://github.com/sergei-sealstorage-candidate/eks-home-exercise?tab=readme-ov-file#networking-and-vpc)
  - [EKS Cluster creation](https://github.com/sergei-sealstorage-candidate/eks-home-exercise?tab=readme-ov-file#eks-cluster-creation)
* [Step #5](https://github.com/sergei-sealstorage-candidate/eks-home-exercise?tab=readme-ov-file#step-5)
  - [EKS Auth config](https://github.com/sergei-sealstorage-candidate/eks-home-exercise?tab=readme-ov-file#eks-auth-config)
  - [Deploy Kubernetes resources](https://github.com/sergei-sealstorage-candidate/eks-home-exercise?tab=readme-ov-file#deploy-kubernetes-resources)
* [Step #6](https://github.com/sergei-sealstorage-candidate/eks-home-exercise?tab=readme-ov-file#step-6)
  - [EKS Auth config](https://github.com/sergei-sealstorage-candidate/eks-home-exercise?tab=readme-ov-file#eks-auth-config)
  - [Deploy Kubernetes resources](https://github.com/sergei-sealstorage-candidate/eks-home-exercise?tab=readme-ov-file#deploy-kubernetes-resources)
* [Step #7](https://github.com/sergei-sealstorage-candidate/eks-home-exercise?tab=readme-ov-file#step-7)
  - [Future otimizations](https://github.com/sergei-sealstorage-candidate/eks-home-exercise?tab=readme-ov-file#future-otimizations)
  - [Issues During Exercise](https://github.com/sergei-sealstorage-candidate/eks-home-exercise?tab=readme-ov-file#issues-during-exercise)
 

## Final Result URL

```
curl http://a37d4a4eaf4bc49f4a46989e34bb456a-d36adbd74180ed5b.elb.us-east-1.amazonaws.com/
```

[View GitHub Action Builds](https://github.com/sergei-sealstorage-candidate/eks-home-exercise/actions)

[View AWS EKS Cluster](https://us-east-1.console.aws.amazon.com/eks/home?region=us-east-1#/clusters/my-cluster)

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

In order to create EKS Cluster first we need to create Networking for future EKS Cluster. Inorder to set up network for EKS we going to use VPC and related to VPC module. VPC module that you can see below creates 3 subnets across different Availability Zones.

[VPC Module](https://github.com/sergei-sealstorage-candidate/eks-home-exercise/tree/main/infrastructure/module)

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

## Step 5

### EKS Auth config

After EKS Cluster created successefully we need to update local kubeconfig in order to set up communication with the EKS cluster. We can do it using aws cli command:

```
$ aws eks update-kubeconfig --name my-cluster --profile=SealStorage
```

after that we can check if everything works as expected. we can get list of naspaces for example, it should give us defult list of naspace

```
$ kubectl get namespace -o wide
NAME              STATUS   AGE
default           Active   29m
kube-node-lease   Active   29m
kube-public       Active   29m
kube-system       Active   29m
```

So now we can add user access for EKS cluster by creating ConfigMap with mapping AWS user to the Clusetr groups

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapUsers: |
    - userarn: arn:aws:iam::339712846046:user/admin
      username: admin
      groups:
        - system:masters
```
after that we should run command to apply this config

```
$ kubectl apply -f aws-auth.yml
```

### Deploy Kubernetes resources

We need to create 3 pods where each pods running in separate Node. After accessing this pods we need to get information about pods. In order to do so we going to use **nginx** web server. To display node and pod information we can use **ConfigMap** for creating template. As following:

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: html-config
data:
  startup-script.sh: |
    #!/bin/sh
    cat <<EOF > /usr/share/nginx/html/index.html
    <!DOCTYPE html>
    <html>
    <head>
      <title>NGINX Pod Information</title>
    </head>
    <body>
      <h1>NGINX Pod Information</h1>
      <p><b>Pod Name:</b> ${POD_NAME}</p>
      <p><b>Node Name:</b> ${NODE_NAME}</p>
      <p><b>Namespace:</b> ${POD_NAMESPACE}</p>
      <p><b>Pod IP:</b> ${POD_IP}</p>
    </body>
    </html>
    EOF
```

Next step we need to declare yaml for Nginx Deployment. Which looks as following:

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      initContainers:
      - name: init-script
        image: busybox
        command:
          - /bin/sh
          - -c
          - |
            cp /config/startup-script.sh /scripts/startup-script.sh
            chmod +x /scripts/startup-script.sh
        volumeMounts:
        - name: config-volume
          mountPath: /config
        - name: scripts
          mountPath: /scripts
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: POD_IP
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
        - name: NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        volumeMounts:
        - name: html
          mountPath: /usr/share/nginx/html
        - name: scripts
          mountPath: /scripts
        command: ["/bin/sh"]
        args:
          - -c
          - |
            /scripts/startup-script.sh
      volumes:
      - name: html
        emptyDir: {}
      - name: config-volume
        configMap:
          name: html-config
      - name: scripts
        emptyDir: {}
```

And in order to make public access for Nginx server with LoadBalancer we need to define service that will expose Nginx pods into the LoadBalance.  

```
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-backend-protocol: tcp
    service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
    service.beta.kubernetes.io/aws-load-balancer-type: nlb
spec:
  type: LoadBalancer
  externalTrafficPolicy: Local
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  selector:
    app: nginx
```

At the end we need to apply all this changes. in order to make it more automated way. it make sence to create crit for this service deployment. Which looks as following:

```
#!/bin/bash

# Deploy Kubernetes resources
kubectl apply -f nginx-config.yaml
kubectl apply -f k8s-deployment.yaml
kubectl apply -f k8s-service.yaml

# Get the LoadBalancer URL
echo "Waiting for the LoadBalancer to get an external IP..."
sleep 120
kubectl get services
```

Now we can deploy all k8s resource using above script

```
$ chmod +x deploy.sh
$ ./deploy.sh
```

After finishing of all resource deployment we should be able to access load balancer URL

```
curl http://a37d4a4eaf4bc49f4a46989e34bb456a-d36adbd74180ed5b.elb.us-east-1.amazonaws.com/
```

## Step 6

### Automation

For the infrastractrue automation and cintinues delevery we can use GitHub Action together with terraform. Any new Pull request can show us the terraform plan of the new infrastructure and give infrastructure verification before code review. This automation can be extend as well for k8s resources deployment. You can find the Github action terraform plan script bellow:

```
name: Terraform Plan

on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  terraform:
    name: 'Terraform Plan'
    runs-on: ubuntu-latest

    steps:
    - name: 'Checkout GitHub Action'
      uses: actions/checkout@v2

    - name: 'Set up Terraform'
      uses: hashicorp/setup-terraform@v1
      with:
        terraform_version: 1.5.7 # Match with Local Terraform version

    - name: 'Terraform Init and Plan'
      working-directory: ./infrastructure
      run: terraform init && terraform plan
      env:
        AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
        AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        AWS_DEFAULT_REGION: 'us-east-1'
```

In order to run this GitHub action we need to add **AWS_ACCESS_KEY_ID** and **AWS_SECRET_ACCESS_KEY** into repository as secrets.

If pull request look good for code reviewr and it's ready to be merge we can create the following GitHub Action script:

```
name: Terraform Apply

on:
  push:
    branches:
      - main

jobs:
  terraform:
    name: 'Terraform Apply'
    runs-on: ubuntu-latest

    steps:
    - name: 'Checkout GitHub Action'
      uses: actions/checkout@v2

    - name: 'Set up Terraform'
      uses: hashicorp/setup-terraform@v1
      with:
        terraform_version: 1.5.7 # Match with Local Terraform version

    - name: 'Terraform Apply'
      working-directory: ./infrastructure
      run: terraform init && terraform apply -auto-approve
      env:
        AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
        AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        AWS_DEFAULT_REGION: 'us-east-1'
```

This github action script will be executed any time when Pull request is merged with **main** branch.

### [View GitHub Action Build](https://github.com/sergei-sealstorage-candidate/eks-home-exercise/actions)

## Step 7

### Future Automation Otimizations

* For future automation optimization we can improve piple by adding source condition when inftrastructure changes happened in this case terrafrom plan and apply will be executed.

* We can create helm charts and add ArgoCD in order to manage Kubernates Resources and provisening any service changes

* As well we can add [**terragrun**](https://terragrunt.gruntwork.io/) in order to manage different envirment such as production, development, staging for existing **terrform** modules.

* For better CloudSecurity support we can strt using [**HashiCorp Vault**](https://www.vaultproject.io/) for better secrtes managing and idenety-based access automation

### Issues During Exercise

One of the issues I have faced during this exercise implemntation is that LoadBalancer returned result with the big latency 9s or even more sometime. The reason why it happned because the service routed external traffic to any pod within the cluster, regardless of which node received the traffic. It resulted to long latency delays. Which means that traffic was forwarded between nodes to reach a pod that matches the service’s selector. Which seems like resulted in lond node lookup. In order to fix it I have changed the service declaration with 

```
externalTrafficPolicy: Cluster -> externalTrafficPolicy: Local
```
It reduced the latency which only route external traffic to the pods on the node where the traffic was received. This means that the traffic is not forwarded between nodes, which provide some benefits. Since traffic is not forwarded between nodes, it can reduce latency by eliminating an extra network hop.

In order to find this issue I was looking into log of the pod in order to find out if the server itself is fast enogh also I was checking CloudWatch log for Created Load Balancers there where findout about big latance. 

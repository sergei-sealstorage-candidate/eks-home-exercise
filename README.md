# eks-home-exercise
Take Home Exercise

This is the Step by Step documentation of what has been done during this Take Home Assigment

## Step 1

Cloud Envirment Prep

For this Home Exercise we need to create AWS EKS Cluster with 3 nodes and 3 pods whic is running in each Node. To make this test more closer to production release, we should image that we just starting the project and we don't have any envirment set-up yet. So for this we will create a new AWS Account, whic can be done using AWS Organizations. This will give us the whole isolation resoucres, bill visability and doesn't conflict to any of personal pproject.

In Order to create new AWS Account account we can use aws-cli

```
$ aws organizations create-account --email SerKhazov+sealstorage@gmail.com --account-name SealStorage-PlayGround
```

The next step we need to Switch Role using AWS Console using New Account ID or we can do it using aws-cli command `aws sts assume-role` passing new account role arn. After switching role we get logged in into newly create account *SealStorage-PlayGround* so we can create a new users and permissions. For this test we will create one user only with cli access and one ReadOnly User with AWS Console access. AWS Console ReadOnly user will be shared with SealStorage engineers.

## Step 2
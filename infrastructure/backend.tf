terraform {
    backend "s3" {
      bucket = "sealstorage-tf-state"
      key = "state/terraform.tfstate"
      region = "us-east-1"
      profile = "SealStorage"
    }
}

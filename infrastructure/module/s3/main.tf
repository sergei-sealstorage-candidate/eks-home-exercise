resource "aws_s3_bucket" "terraform-bkt" {
  bucket  = var.tf_s3_bucket_name
  tags    = {
	Name          = "SealStorage"
	Environment    = "Development"
  }
}
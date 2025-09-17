# ---------------------------
# AWS Providers
# ---------------------------
provider "aws" {
  region = var.region
}

# CloudFront requires certificates to be in us-east-1
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
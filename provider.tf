terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">=5.31.0"
    }
  }
}

provider "aws" {
  # Configuration options
    region = var.region
}

terraform {
  backend "s3" {
    bucket = "niiadu12"
    key    = "terraform.tfstate"
    region = "eu-north-1"
  }
}

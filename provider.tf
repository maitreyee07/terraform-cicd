terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" # Keeps you on the latest 6.x lifecycle
    }
  }
}
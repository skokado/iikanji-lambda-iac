terraform {
  required_providers {
    aws = {
      version = "~> 6.30"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

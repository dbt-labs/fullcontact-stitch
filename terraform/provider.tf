provider "aws" {
  region = "us-east-1"
  allowed_account_ids = ["${var.AWS_ACCOUNT_ID}"]
  profile = "${var.AWS_PROFILE}"
}

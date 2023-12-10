#!/bin/bash
# Setup AWS Cloudshell to use terraform from tf folder.
# This file is intended to help get going with terraform in your AWS account using cloudshell.

aws_account_id="$(aws sts get-caller-identity --query Account)"
aws_region="$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]')"
aws_tf_module="$(curl -Ls https://github.com/hashicorp/terraform-provider-aws/releases/latest | grep "<title>Release" | awk '{ print $2}' | awk '{gsub(/v/,"")}; 1')"
latest="$(curl -s https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r -M '.current_version')"

# Install tfenv to manage terraform installs
git clone https://github.com/tfutils/tfenv.git ~/.tfenv
mkdir ~/bin
ln -s ~/.tfenv/bin/* ~/bin/
tfenv install
tfenv use $latest
terraform --version

# Set alias for terraform to tf
echo "alias tf='terraform'" >> ~/.bashrc 
source ~/.bashrc
# Build a tf folder to house terraform files and load the basic files required
mkdir ~/tf && cd ~/tf
pwd

cat <<EOT >> providers.tf
provider "aws" {
  region              = var.aws_region
  allowed_account_ids = [var.aws_account_id]
}
EOT

cat <<EOT >> terraform.tf
terraform {

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= ${aws_tf_module}"
    }
  }

  required_version = ">= ${latest}"

}
EOT

cat <<EOT >> terraform.tfvars
aws_account_id       = ${aws_account_id} 
aws_region           = "${aws_region}"
EOT

cat <<EOT >> variables.tf
variable "aws_account_id" {
  type        = string
  description = "Allowed AWS account ID where resources can be created"
}

variable "aws_region" {
  type        = string
  description = "AWS Region where resources will be created"
}
EOT

echo "Initial terraform files needed are created below:"
echo ""
echo "providers.tf"
cat providers.tf
echo ""
echo "terraform.tf"
cat terraform.tf
echo ""
echo "terraform.tfvars"
cat terraform.tfvars
echo ""
echo "variables.tf"
cat variables.tf
echo ""
# Start the terraform initialisation, local state file setup etc
cd ~/tf
terraform init
echo ""
echo "Terraform setup and ready"
echo "Create your resource files in  ~/tf/<filename>.tf then run 'tf plan' and 'tf apply'"

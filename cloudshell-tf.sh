#!/bin/bash
# setup_terraform.sh

# 1. Reliable context discovery
# AWS_REGION is standard, but if it's jumbled, we query the CloudShell metadata service
echo "Discovering environment..."
account_id=$(aws sts get-caller-identity --query Account --output text)

# This is the most robust way to get the region in CloudShell:
if [ -n "$AWS_REGION" ]; then
    region=$AWS_REGION
elif [ -n "$AWS_CONTAINER_CREDENTIALS_FULL_URI" ]; then
    # Parse region from the metadata URI if the env var is missing
    region=$(echo "$AWS_CONTAINER_CREDENTIALS_FULL_URI" | sed -E 's/.*\.([a-z0-9-]+)\.amazonaws\.com.*/\1/')
else
    # Last ditch effort: aws configure
    region=$(aws configure get region)
fi

# Final safety check: if region is still blank, default to where you are likely to be
region=${region:-ap-southeast-2} 

echo "Account: $account_id"
echo "Region:  $region"

# 2. Setup tfenv (Persistence Check)
if [ ! -d "$HOME/.tfenv" ]; then
    echo "Installing tfenv..."
    git clone --depth=1 https://github.com/tfutils/tfenv.git ~/.tfenv
    mkdir -p ~/bin
    ln -s ~/.tfenv/bin/* ~/bin/
    export PATH="$HOME/bin:$PATH"
    echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
fi

# 3. Get Terraform
echo "Setting up terraform..."
tfenv install latest
tfenv use latest
tf_ver=$(terraform --version | head -n1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')

# 4. Create Files
mkdir -p ~/tf && cd ~/tf

cat <<EOF > providers.tf
provider "aws" {
  region              = var.aws_region
  allowed_account_ids = [var.aws_account_id]
}
EOF

cat <<EOF > terraform.tf
terraform {
  required_version = ">= ${tf_ver}"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
EOF

cat <<EOF > variables.tf
variable "aws_account_id" { type = string }
variable "aws_region"     { type = string }
EOF

cat <<EOF > terraform.tfvars
aws_account_id = "$account_id"
aws_region     = "$region"
EOF

# 5. Bash Alias
if ! grep -q "alias tf=" ~/.bashrc; then
    echo "alias tf='terraform'" >> ~/.bashrc
fi

echo "Done. Run 'tf init' in ~/tf"

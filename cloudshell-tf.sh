#!/bin/bash
# setup_terraform.sh - Configures CloudShell with tfenv and base providers

# Get session context
echo "Checking environment..."
account_id=$(aws sts get-caller-identity --query Account --output text)

# Use CloudShell's native region env var
region=${AWS_REGION:-$(aws configure get region)}
region=${region:-us-east-1}

echo "Context: $account_id in $region"

# Setup tfenv if not already present
if [ ! -d "$HOME/.tfenv" ]; then
    echo "Installing tfenv..."
    git clone --depth=1 https://github.com/tfutils/tfenv.git ~/.tfenv
    mkdir -p ~/bin
    ln -s ~/.tfenv/bin/* ~/bin/
    
    # Update PATH for immediate use and future sessions
    export PATH="$HOME/bin:$PATH"
    echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
else
    echo "tfenv is already in ~/.tfenv"
fi

# Manage terraform versions
echo "Fetching latest terraform..."
tfenv install latest
tfenv use latest
tf_version=$(terraform --version | head -n1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')

# Initialize working directory
mkdir -p ~/tf && cd ~/tf

# Generate boilerplate hcl
cat <<EOF > providers.tf
provider "aws" {
  region              = var.aws_region
  allowed_account_ids = [var.aws_account_id]
}
EOF

cat <<EOF > terraform.tf
terraform {
  required_version = ">= ${tf_version}"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
EOF

cat <<EOF > variables.tf
variable "aws_account_id" {
  type        = string
  description = "Target AWS Account ID"
}

variable "aws_region" {
  type        = string
  description = "Target AWS Region"
}
EOF

cat <<EOF > terraform.tfvars
aws_account_id = "$account_id"
aws_region     = "$region"
EOF

# Add shorthand alias
if ! grep -q "alias tf=" ~/.bashrc; then
    echo "alias tf='terraform'" >> ~/.bashrc
fi

echo "------------------------------------------------"
echo "Setup finished. Directory: ~/tf"
echo "Terraform version: $tf_version"
echo "Run 'tf init' to begin."

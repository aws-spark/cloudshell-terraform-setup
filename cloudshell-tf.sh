#!/bin/bash
# setup_terraform.sh

echo "Discovering environment..."
account_id=$(aws sts get-caller-identity --query Account --output text)

# Metadata trick to get region without an API call
if [ -n "$AWS_REGION" ]; then
    region=$AWS_REGION
elif [ -n "$AWS_CONTAINER_CREDENTIALS_FULL_URI" ]; then
    region=$(echo "$AWS_CONTAINER_CREDENTIALS_FULL_URI" | sed -E 's/.*\.([a-z0-9-]+)\.amazonaws\.com.*/\1/')
else
    region=$(aws configure get region)
fi

# Hardcoded fallback if discovery fails (change this to your preferred region)
region=${region:-ap-southeast-6} 

echo "Account: $account_id"
echo "Region:  $region"

# Setup tfenv
if [ ! -d "$HOME/.tfenv" ]; then
    echo "Installing tfenv..."
    git clone --depth=1 https://github.com/tfutils/tfenv.git ~/.tfenv
    mkdir -p ~/bin
    ln -s ~/.tfenv/bin/* ~/bin/
    
    # Apply to CURRENT session immediately
    export PATH="$HOME/bin:$PATH"
    # Persist for FUTURE sessions
    echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
else
    echo "tfenv already installed."
    export PATH="$HOME/bin:$PATH"
fi

# Install Terraform
echo "Setting up terraform..."
tfenv install latest
tfenv use latest
tf_ver=$(terraform --version | head -n1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')

# Create Workspace
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

# Setup 'tf' alias for CURRENT session
alias tf='terraform'

# Persist 'tf' alias for FUTURE sessions
if ! grep -q "alias tf=" ~/.bashrc; then
    echo "alias tf='terraform'" >> ~/.bashrc
fi

echo "------------------------------------------------"
echo "Setup finished."
echo "Terraform version: $tf_ver"
echo "Region set to: $region"
echo ""
echo "NOTE: The 'tf' alias is ready. Run: tf init"

#!/bin/bash
# setup_terraform.sh

# 1. Environment Discovery
echo "Checking environment..."
account_id=$(aws sts get-caller-identity --query Account --output text)

# Metadata URI check for region
if [ -n "$AWS_REGION" ]; then
    region=$AWS_REGION
elif [ -n "$AWS_CONTAINER_CREDENTIALS_FULL_URI" ]; then
    region=$(echo "$AWS_CONTAINER_CREDENTIALS_FULL_URI" | sed -E 's/.*\.([a-z0-9-]+)\.amazonaws\.com.*/\1/')
else
    region=$(aws configure get region)
fi

region=${region:-ap-southeast-2}
echo "Context: $account_id in $region"

# 2. Latest Versions Discovery
echo "Fetching latest version metadata..."
# Get latest Terraform Core version
tf_latest=$(curl -s https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r '.current_version')

# Get latest AWS Provider version from official HashiCorp API
aws_p_latest=$(curl -s https://api.releases.hashicorp.com/v1/releases/terraform-provider-aws | jq -r '.[0].version')

echo "Latest Terraform: $tf_latest"
echo "Latest AWS Provider: $aws_p_latest"

# 3. Setup tfenv
if [ ! -d "$HOME/.tfenv" ]; then
    echo "Installing tfenv..."
    git clone --depth=1 https://github.com/tfutils/tfenv.git ~/.tfenv
    mkdir -p ~/bin
    ln -s ~/.tfenv/bin/* ~/bin/
    export PATH="$HOME/bin:$PATH"
    echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
else
    export PATH="$HOME/bin:$PATH"
fi

# 4. Install Terraform
tfenv install "$tf_latest"
tfenv use "$tf_latest"

# 5. Build Workspace Files
mkdir -p ~/tf && cd ~/tf

cat <<EOF > providers.tf
provider "aws" {
  region              = var.aws_region
  allowed_account_ids = [var.aws_account_id]
}
EOF

cat <<EOF > terraform.tf
terraform {
  required_version = ">= ${tf_latest}"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "${aws_p_latest}"
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

# 6. Session Persistence
alias tf='terraform'
if ! grep -q "alias tf=" ~/.bashrc; then
    echo "alias tf='terraform'" >> ~/.bashrc
fi

# 7. Initialization
echo "------------------------------------------------"
echo "Initializing Terraform in $(pwd)..."
terraform init

echo ""
echo "Setup Complete."
echo "You are now in ~/tf and ready to build."

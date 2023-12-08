This shell script is intended to quickly and easily setup terraform with your AWS cloudshell to start building resources in the same account.
The terraform statefile is stored locally in cloudshell so this option is intended for dev/test and sandpit/sandbox use primarily, or for anyone wanting to give terraform a go with AWS, this is 
 a quick and easy method.

Requirements:

An AWS account with access to use cloudshell:
https://aws.amazon.com/cloudshell/

Connect to your AWS account and start cloudshell

Run this from the cloudshell terminal to setup and initialise terraform:

```curl -sSL https://raw.githubusercontent.com/aws-spark/cloudshell-terraform-setup/main/cloudshell-tf.sh -o $HOME/cloudshell-tf.sh; chmod +x $HOME/cloudshell-tf.sh; bash $HOME/cloudshell-tf.sh```

Start building your .tf files in ~/tf folder. There's a ton of resources out there to guide you on what you want built, eg: https://registry.terraform.io/providers/hashicorp/aws/latest/docs - review the services on the left for documentation on how to get started. For example: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket - to build a s3 bucket.
Once you have your new .tf files ready to test:
Try "tf plan" and then "tf apply" - you are building with Infrastructure as Code now.

To undo what this script does - or to run it again to update, from within cloudshell these commands will delete things, so use with caution:
```
rm -rf ~/.tfenv
rm -rf ~/bin
rm ~/cloudshell-tf.sh
rm -rf ~/tf
sed -i '$d' ~/.bashrc
```

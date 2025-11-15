#!/bin/bash
cd $1
# delete_folder=("rds" "aws_secret" "alb" "asg" "null_resource" "asg" "cloudfront" "route53")
delete_folder=$(ls)
for files in ${delete_folder[@]}; do 
  rm -f $files/terrag*
  cp ../permissions/iam_role/terragrunt.hcl $files/
done
resource "aws_s3_bucket" "panda-bucket" {
  bucket = var.bucket_name
  force_destroy = true  # optional, deletes objects when destroying


  tags = {
    Name        = "${var.bucket_name}-files"
    Environment = "Dev"
  }
}


# Define folder path relative to the module
locals {
  # upload_folder = "${path.root}/application-code/application-code"
  upload_folder = var.upload_folder_with_terragrunt

  # Collect all files under application-code/
  all_files = fileset(local.upload_folder, "**/*")
  # files_to_exclude = ["DbConfig.js"]
#   files_to_exclude = ["DbConfig.js", "nginx.conf"]

  # Exclude dbconfig.js or any file you don't want
  files_to_upload = [
    # for file in local.all_files : file
    # if file != "DbConfig.js" 
    # files_to_upload = [
    for file in local.all_files : file
    # if !contains(local.files_to_exclude, file)
  ]

  
}

# Upload all filtered files recursively
resource "aws_s3_object" "app_code_upload" {
  for_each = { for file in local.files_to_upload : file => file }

  bucket = aws_s3_bucket.panda-bucket.id
  # key = "application-code/${dirname(each.key)}/${basename(each.key)}"

  # source = "${local.upload_folder}/${each.key}"
  # etag   = filemd5("${local.upload_folder}/${each.key}")
  key    = "application-code/${each.value}"    # keep same folder structure
  # source = "${path.root}/application-code/application-code/${each.value}"
  source = "${local.upload_folder}/${each.value}"
  etag   = filemd5("${local.upload_folder}/${each.value}")

  acl = "private"
}


# # Define folder path relative to the module
# locals {
#   upload_folder = "${path.root}/application-code/web-tier"

#   # Collect all files under application-code/
#   all_files = fileset(local.upload_folder, "**")

#   # Exclude dbconfig.js or any file you don't want
#   files_to_upload = [
#     for file in local.all_files : file 
#   ]
# }

# # Upload all filtered files recursively
# resource "aws_s3_object" "web_code_upload" {
#   for_each = { for file in local.files_to_upload : file => file }

#   bucket = aws_s3_bucket.panda-bucket.id
#   key = "application-code/web-tier/${basename(each.key)}"
#   source = "${local.upload_folder}/${each.key}"
#   etag   = filemd5("${local.upload_folder}/${each.key}")
# }
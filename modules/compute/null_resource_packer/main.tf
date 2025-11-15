resource "null_resource" "build_ami" {

  provisioner "local-exec" {
    environment = {
      VPC_ID    = var.vpc_id
      SUBNET_ID = var.pub_sub_1a_id
      # Get RDS details from Terraform state
      DB_HOST                         = var.endpoint_address
      DB_PORT                         = var.db_port
      DB_USER                         = var.db_username
      DB_PASSWORD                     = var.db_password
      DB_NAME                         = var.db_name
      DB_PORT                         = var.db_port
      RDS_SG_ID                       = var.db_sg_id
      s3_ssm_cw_instance_profile_name = var.s3_ssm_cw_instance_profile_name
      db_secret_name                  = var.db_secret_name
      internal_alb_dns_name           = var.internal_alb_dns_name
      bucket_name                     = var.panda_bucket_name
      aws_region                      = var.region
      ssh_interface                      = var.ssh_interface
      ssh_username                      = var.ssh_username
      backend_ami_type    = var.backend_ami_type
      backend_instance_type                      = var.backend_instance_type
      backend_volume_type                      = var.backend_volume_type
      backend_volume_size                      = var.backend_volume_size
      backend_ami_name                      = var.backend_ami_name
      frontend_ami_type    = var.frontend_ami_type
      frontend_instance_type                      = var.frontend_instance_type
      frontend_volume_type                      = var.frontend_volume_type
      frontend_volume_size                      = var.frontend_volume_size
      frontend_ami_name                      = var.frontend_ami_name
      environment                      = var.environment
      packer_folder = var.packer_folder

    }
    # command = "bash ../packer/packer-script.sh"
    command = "bash ${var.packer_folder}/packer-script.sh"
    # command = var.packer_folder
  }
}

data "local_file" "packer_manifest_backend" {
  # filename   = "../packer/backend/manifest.json"
  filename   = "${var.packer_folder}/backend/manifest.json"
  depends_on = [null_resource.build_ami]
}

data "local_file" "packer_manifest_frontend" {
  # filename   = "../packer/frontend/manifest.json"
  filename   = "${var.packer_folder}/frontend/manifest.json"
  depends_on = [null_resource.build_ami]
}

locals {
  packer_manifest_backend = jsondecode(data.local_file.packer_manifest_backend.content)
  packer_manifest_frontend = jsondecode(data.local_file.packer_manifest_frontend.content)

  backend_ami_id  = split(":", local.packer_manifest_backend.builds[0].artifact_id)[1]
  frontend_ami_id = split(":", local.packer_manifest_frontend.builds[0].artifact_id)[1]
}




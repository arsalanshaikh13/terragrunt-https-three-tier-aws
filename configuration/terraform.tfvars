region                  = "us-east-1"
project_name            = "panda-three-tier-app"
#choose environment
environment = "dev"
# vpc variables 
vpc_cidr                = "10.0.0.0/16"
pub_sub_1a_cidr         = "10.0.1.0/24"
pub_sub_2b_cidr         = "10.0.2.0/24"
pri_sub_3a_cidr         = "10.0.3.0/24"
pri_sub_4b_cidr         = "10.0.4.0/24"
pri_sub_5a_cidr         = "10.0.5.0/24"
pri_sub_6b_cidr         = "10.0.6.0/24"
pri_sub_7a_cidr         = "10.0.7.0/24"
pri_sub_8b_cidr         = "10.0.8.0/24"

# nat instance related variables
# nat_instance_count = 1
nat_instance_type = "t4g.small" # 750 hrs free / month till dec 31 2025
nat_volume_type = "standard"
nat_volume_size = 8

# backend tfstate bootstrapping variables
bucket_name             = "panda-app-bucket-terragrunt"
backend_bucket_name = "panda-backend"
dynamodb_table      = "panda-lock-table"

# Database values which is to pass on to the rds and apps
db_username             = "admin_3_tier"
db_password             = "Asd1-CaPQ22"
db_name                 = "lirw_react_node_app"
db_port                 = "3306"

# only specific to rds
db_engine = "mysql"
db_identifier = "panda-dev-db"
db_instance_type = "db.t4g.micro"
db_version = "8.0.42"
db_storage_volume = 20
db_storage_type = "standard"
db_sub_name = "panda-db-subnet-a-b"
retention_period = 0

# asg variables
max_size = 1
min_size = 1
desired_cap = 1
asg_health_check_type = "ELB" #"ELB" or default EC2

# asg and null resource variables combined
backend_ami_type = "al2023-ami-2023.*-arm64"
frontend_ami_type = "al2023-ami-2023.*-arm64"
backend_instance_type =  "t4g.small" # free tier till 31st dec/2025
frontend_instance_type =  "t4g.small" # free tier till 31st dec/2025
frontend_volume_type = "standard"
frontend_volume_size = 8
backend_volume_type = "standard"
backend_volume_size = 8
ssh_username = "ec2-user"
ssh_interface = "session_manager" # or "public_ip"
backend_ami_name = "three-tier-backend"
frontend_ami_name = "three-tier-frontend"
# domain records
certificate_domain_name = "devsandbox.space"
additional_domain_name  = "www.devsandbox.space"
# alb_api_domain_name     = "api.devsandbox.space"
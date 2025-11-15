variable "region" {
  # default = "us-east-1"
  type    = string
}

variable "backend_bucket_name" {
  type = string
}
variable "dynamodb_table" {
  type = string  
}
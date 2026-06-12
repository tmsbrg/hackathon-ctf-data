# Nordwind AWS migration — local tfvars (DO NOT COMMIT)
aws_region = "eu-west-1"
environment = "staging"
vpc_cidr = "10.42.0.0/16"

db_instance_class = "db.t3.medium"
db_username = "nw_staging_admin"
db_password = "TfNwDb_Staging_7xK!"

s3_backup_bucket = "nw-tf-state-staging"
tags = {
  company = "Nordwind Logistics BV"
  managed_by = "terraform"
}

variable "resource_group_name" { type = string }
variable "location"            { type = string }
variable "env"                 { type = string }
variable "env_suffix"          { type = string }
variable "subnet_id"           { type = string }

variable "storage_account_name" { type = string }
variable "sql_server_fqdn"      { type = string }
variable "sql_db_name"          { type = string }

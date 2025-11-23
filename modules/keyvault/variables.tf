variable "resource_group_name"     { type = string }
variable "location"                { type = string }
variable "env"                     { type = string }
variable "env_suffix"              { type = string }
variable "sql_connection_string" {
  type      = string
  sensitive = true
}
variable "storage_account_name"    { type = string }

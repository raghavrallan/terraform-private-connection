variable "resource_group_name"    { type = string }
variable "location"              { type = string }
variable "env"                   { type = string }
variable "env_suffix"            { type = string }

variable "vnet_id"               { type = string }
variable "subnet_id_privatelink" { type = string }

variable "storage_account_id"    { type = string }
variable "sql_server_id"         { type = string }
variable "acr_id"                { type = string }
variable "key_vault_id"          { type = string }

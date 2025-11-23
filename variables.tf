variable "env" {
  description = "Environment name (dev/stage/prod)"
  type        = string
}

variable "env_suffix" {
  description = "Environment suffix to append to resource names for uniqueness"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

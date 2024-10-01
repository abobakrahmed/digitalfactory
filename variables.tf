# variables.tf

# Resource Group
variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
  default     = "digitalfactory-rg"
}

# Location
variable "location" {
  description = "Azure location"
  type        = string
  default     = "East US"
}

# MySQL Database Settings
variable "mysql_admin_username" {
  description = "MySQL admin username"
  type        = string
  default     = "mysqladmin"
}

variable "mysql_admin_password" {
  description = "MySQL admin password"
  type        = string
}

# Container Image
variable "container_image" {
  description = "The container image URL to deploy"
  type        = string
}

# Scaling
variable "min_replicas" {
  description = "Minimum number of app replicas"
  type        = number
  default     = 1
}

variable "max_replicas" {
  description = "Maximum number of app replicas"
  type        = number
  default     = 10
}

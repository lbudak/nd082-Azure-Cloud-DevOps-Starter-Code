variable "prefix" {
    description = "The prefix which should be used for all resources"
    type = string
    default = "udacity-project-1"
}

variable "location" {
    description = "The Azure Region in which all resources should be created."
    type = string
    default = "West Europe"
}

variable "image_id" {
    description = "The identifier for vm source image built with Packer."
    type = object({
        managed_image_name = string
        managed_image_resource_group_name = string
    })
    default = {
        managed_image_name = "projectPackerImage"
        managed_image_resource_group_name = "udacity-demo-rg"
    }
}

variable "username" {
  type = string
  default = "udacity-lbudo"
}

variable "password" {
  type = string
  default = "$m0L_pp_P0w3r"
}

variable "num_of_instances" {
    type = number
    default = 2

    validation {
    condition     = var.num_of_instances > 0 && var.num_of_instances < 6
    error_message = "The number of instances must not be more than 5."
  }
}

variable "tagging" {
  type        = map
  default     = {
    "work" = "project"
    "owner" = "Budak"
  }
  description = "Tags to be used throughout the project"
}

variable "storage_account" {
  type        = string
  default     = "Standard_LRS"
  description = "The type of storage to use for the disk"
}

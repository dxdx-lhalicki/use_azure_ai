variable "resource_group_name" {
    description = "Name of the resource group"
    type        = string
}

variable "resource_group_location" {
    description = "Location of the resource group"
    type        = string
}

variable "vnet_name" {
    description = "Name of the virtual network"
    type        = string
}

variable "app_subnet_name" {
    description = "Name of the app subnet"
    type        = string
}

variable "functions_subnet_name" {
    description = "Name of the functions subnet"
    type        = string
}

variable "web_app_name" {
    description = "Name of the web app"
    type        = string
}

variable "functions_app_name" {
    description = "Name of the functions app"
    type        = string
}

variable "storage_account_name" {
    description = "Name of the storage account"
    type        = string
}

variable "queue_name" {
    description = "Name of the storage queue"
    type        = string
}

variable "blob_container_name" {
    description = "Name of the blob container"
    type        = string
}

variable "filesystem_storage_accounts" {
    description = "Map of filesystem storage accounts"
    type        = map(object({
        name = string
        primary_access_key = string
    }))
}

variable "function_apps" {
    description = "Map of function apps"
    type        = map(object({
        name                   = string
        storage_account_name   = string
        primary_access_key     = string
    }))
}

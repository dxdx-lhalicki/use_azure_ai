variable "name" {
    description = "Name of the resource group"
    type        = string
}

variable "resource_group_location" {
    description = "Location of the resource group"
    type        = string
}

variable "storage_account_name" {
    description = "Name of the storage account"
    type        = string
}

variable "function_app" {
    description = "Name of the function app"
    type        = map(object({
        name = string
    }))
}

variable "functions_file_system_storage_account_name" {
    description = "Name of the storage account for the function app"
    type        = string
}

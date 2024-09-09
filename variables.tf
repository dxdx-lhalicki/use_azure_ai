variable "tfc_azure_dynamic_credentials" {
    description = "Object containing Azure dynamic credentials configuration"
    type = object({
        default = object({
            client_id_file_path = string
            oidc_token_file_path = string
        })
        aliases = map(object({
            client_id_file_path = string
            oidc_token_file_path = string
        }))
    })
}


variable "vnet_name" {
    description = "Name of the virtual network"
    type        = string
}

variable "subnet_name" {
    description = "Name of the subnet"
    type        = string
}

variable "app_service_name" {
    description = "Name of the app service"
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
    description = "Map of file system storage accounts"
    type        = map(object({
        name               = string
        primary_access_key = string
    }))
}

variable "function_apps" {
    description = "Map of function apps"
    type        = map(object({
        name                  = string
        storage_account_name  = string
        primary_access_key    = string
    }))
}

variable "cosmosdb_name" {
    description = "Name of the Cosmos DB account"
    type        = string
}

variable "search_service_name" {
    description = "Name of the search service"
    type        = string
}

variable "search_index_name" {
    description = "Name of the search index"
    type        = string
}

variable "search_datasource_name" {
    description = "Name of the search datasource"
    type        = string
}

variable "sql_database_name" {
    description = "Name of the SQL database"
    type        = string
}

variable "sql_table_name" {
    description = "Name of the SQL table"
    type        = string
}

variable "sql_connection_string" {
    description = "Connection string for the SQL database"
    type        = string
}
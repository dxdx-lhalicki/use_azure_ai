# Create resource group
resource "azurerm_resource_group" "app_service_rg" {
    name     = var.resource_group_name
    location = var.resource_group_location
}

# Create virtual network
resource "azurerm_virtual_network" "app_service_vnet" {
    name                = var.vnet_name
    address_space       = ["10.0.0.0/16"]
    location            = azurerm_resource_group.app_service_rg.location
    resource_group_name = azurerm_resource_group.app_service_rg.name
}

# Create subnet
resource "azurerm_subnet" "app_service_subnet" {
    name                 = var.subnet_name
    resource_group_name  = azurerm_resource_group.app_service_rg.name
    virtual_network_name = azurerm_virtual_network.app_service_vnet.name
    address_prefixes     = ["10.0.1.0/24"]
}

# Create app service plan
resource "azurerm_app_service_plan" "app_service_plan" {
    name                = "${var.app_service_name}-plan"
    location            = azurerm_resource_group.app_service_rg.location
    resource_group_name = azurerm_resource_group.app_service_rg.name
    sku {
        tier = "Standard"
        size = "S1"
    }
}

# Create app service
resource "azurerm_app_service" "app_service" {
    name                = var.app_service_name
    location            = azurerm_resource_group.app_service_rg.location
    resource_group_name = azurerm_resource_group.app_service_rg.name
    app_service_plan_id = azurerm_app_service_plan.app_service_plan.id

    site_config {
        dotnet_framework_version = "v5.0"
        scm_type                 = "LocalGit"
    }

    app_settings = {
        "WEBSITE_RUN_FROM_PACKAGE" = "1"
    }

    identity {
        type = "SystemAssigned"
    }

    depends_on = [azurerm_subnet.app_service_subnet]
}

# Output the app service URL
output "app_service_url" {
    value = azurerm_app_service.app_service.default_site_hostname
}

# Create Azure Storage Account
resource "azurerm_storage_account" "queue_storage" {
    name                     = var.storage_account_name
    resource_group_name      = azurerm_resource_group.app_service_rg.name
    location                 = azurerm_resource_group.app_service_rg.location
    account_tier             = "Standard"
    account_replication_type = "LRS"
    account_kind             = "StorageV2"
}

# Create Azure Storage Queue
resource "azurerm_storage_queue" "queue" {
    name                  = var.queue_name
    storage_account_name  = azurerm_storage_account.queue_storage.name
}

resource "azurerm_role_assignment" "app_service_queue_contributor" {
    principal_id   = azurerm_app_service.app_service.identity.principal_id
    role_definition_name = "Storage Queue Data Contributor"
    scope          = azurerm_storage_account.queue_storage.id
}

# Create Azure Blob Storage
resource "azurerm_storage_container" "blob_container" {
    name                  = var.blob_container_name
    storage_account_name  = azurerm_storage_account.queue_storage.name
    container_access_type = "private"
}

resource "azurerm_role_assignment" "app_service_blob_contributor" {
    principal_id   = azurerm_app_service.app_service.identity.principal_id
    role_definition_name = "Storage Blob Data Contributor"
    scope          = azurerm_storage_account.queue_storage.id
}

# Create app service plan for functions
resource "azurerm_app_service_plan" "functions_plan" {
    name                = "functions-plan"
    location            = azurerm_resource_group.app_service_rg.location
    resource_group_name = azurerm_resource_group.app_service_rg.name
    sku {
        tier = "Standard"
        size = "S1"
    }
}

# Create Azure Storage Accounts for file storage
resource "azurerm_storage_account" "file_storage" {
    for_each = var.filesystem_storage_accounts

    name                     = each.value.name
    resource_group_name      = azurerm_resource_group.app_service_rg.name
    location                 = azurerm_resource_group.app_service_rg.location
    account_tier             = "Standard"
    account_replication_type = "LRS"
    account_kind             = "StorageV2"
}

# Create Azure Function App - analyze_function
resource "azurerm_function_app" "analyze_function" {
    for_each = var.function_apps

    name                       = each.value.name
    location                   = azurerm_resource_group.app_service_rg.location
    resource_group_name        = azurerm_resource_group.app_service_rg.name
    app_service_plan_id        = azurerm_app_service_plan.app_service_plan.id
    storage_account_name       = each.value.storage_account_name
    storage_account_access_key = each.value.primary_access_key
    version                    = "~3"
    os_type                    = "linux"
    app_settings = {
        FUNCTIONS_WORKER_RUNTIME = "python"
    }

    site_config {
        linux_fx_version = "python|3.9"
    }
}

resource "azurerm_cosmosdb_account" "cosmosdb" {
    name                = var.cosmosdb_name
    location            = azurerm_resource_group.example.location
    resource_group_name = azurerm_resource_group.example.name
    offer_type          = "Standard"
    kind                = "MongoDB"
    consistency_policy {
        consistency_level = "Session"
    }
    geo_location {
        location          = azurerm_resource_group.example.location
        failover_priority = 0
    }
}

# Create Azure Cognitive Search service
resource "azurerm_search_service" "cognitive_search" {
    name                = var.search_service_name
    location            = azurerm_resource_group.app_service_rg.location
    resource_group_name = azurerm_resource_group.app_service_rg.name
    sku = {
        name     = "standard"
        tier     = "Standard"
        capacity = 1
    }
}

# Create Azure Cognitive Search index
resource "azurerm_search_index" "cognitive_search_index" {
    name                  = var.search_index_name
    search_service_name   = azurerm_search_service.cognitive_search.name
    resource_group_name   = azurerm_resource_group.app_service_rg.name
    index_type            = "search"
    fields {
        name = "id"
        type = "Edm.String"
    }
    fields {
        name = "title"
        type = "Edm.String"
    }
    fields {
        name = "description"
        type = "Edm.String"
    }
}

# Create Azure Cognitive Search data source
resource "azurerm_search_datasource" "cognitive_search_datasource" {
    name                  = var.search_datasource_name
    search_service_name   = azurerm_search_service.cognitive_search.name
    resource_group_name   = azurerm_resource_group.app_service_rg.name
    type                  = "azuresql"
    container {
        name                  = var.sql_database_name
        query                 = "SELECT id, title, description FROM ${var.sql_table_name}"
        connection_string     = var.sql_connection_string
        data_change_detection = true
    }
}

# Create Azure Cognitive Search indexer
resource "azurerm_search_indexer" "cognitive_search_indexer" {
    name                  = var.search_indexer_name
    search_service_name   = azurerm_search_service.cognitive_search.name
    resource_group_name   = azurerm_resource_group.app_service_rg.name
    data_source_name      = azurerm_search_datasource.cognitive_search_datasource.name
    target_index_name     = azurerm_search_index.cognitive_search_index.name
    schedule {
        interval = "PT5M"
    }
    parameters {
        max_failed_items = 10
        max_failed_items_per_batch = 5
    }
}

# Output the search service URL
output "search_service_url" {
    value = azurerm_search_service.cognitive_search.endpoint
}
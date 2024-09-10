# Create a resource group for the AI use case
resource "azurerm_resource_group" "ai_usecase_rg" {
    name     = "${var.name}-rg"
    location = var.resource_group_location
}

# Create a service plan for hosting the web app and function apps
resource "azurerm_service_plan" "service_plan" {
    name                = "${var.name}-plan"
    resource_group_name = azurerm_resource_group.ai_usecase_rg.name
    location            = azurerm_resource_group.ai_usecase_rg.location
    os_type             = "Linux"
    sku_name            = "B1"
}

# Create a web app for hosting the AI web app
resource "azurerm_linux_web_app" "web_app" {
    name                      = "${var.name}-web-app"
    location                  = azurerm_resource_group.ai_usecase_rg.location
    resource_group_name       = azurerm_resource_group.ai_usecase_rg.name
    service_plan_id           = azurerm_service_plan.service_plan.id

# Enable the system-assigned managed identity for the web app
    identity {
        type = "SystemAssigned"
    }

# Configure the web app to use the latest
    site_config {
        always_on = false
    }

    depends_on = [
        azurerm_service_plan.service_plan
    ]
}

# Create a storage account for the web app
resource "azurerm_storage_account" "storage" {
    name                     = var.storage_account_name
    resource_group_name      = azurerm_resource_group.ai_usecase_rg.name
    location                 = azurerm_resource_group.ai_usecase_rg.location
    account_tier             = "Standard"
    account_replication_type = "LRS"
    account_kind             = "StorageV2"
}

# Create a storage queue for the web app
resource "azurerm_storage_queue" "queue" {
    name                  = "${var.name}-queue"
    storage_account_name  = azurerm_storage_account.storage.name
}

# Assign the Storage Queue Data Contributor role to the web app managed identity
resource "azurerm_role_assignment" "app_service_queue_contributor" {
    principal_id         = azurerm_linux_web_app.web_app.identity[0].principal_id
    role_definition_name = "Storage Queue Data Contributor"
    scope                = azurerm_storage_account.storage.id
    
    depends_on = [
        azurerm_linux_web_app.web_app,
        azurerm_storage_queue.queue
    ]
}

# Create a storage container for the web app
resource "azurerm_storage_container" "blob_container" {
    name                  = "${var.name}-blob-container"
    storage_account_name  = azurerm_storage_account.storage.name
    container_access_type = "private"
}

# Assign the Storage Blob Data Contributor role to the web app managed identity
resource "azurerm_role_assignment" "app_service_blob_contributor" {
    principal_id         = azurerm_linux_web_app.web_app.identity[0].principal_id
    role_definition_name = "Storage Blob Data Contributor"
    scope                = azurerm_storage_account.storage.id

    depends_on = [
        azurerm_linux_web_app.web_app,
        azurerm_storage_container.blob_container
    ]
}

# Create a storage account for the function apps file system
resource "azurerm_storage_account" "functions_file_system_storage" {
    name                     = var.functions_file_system_storage_account_name
    resource_group_name      = azurerm_resource_group.ai_usecase_rg.name
    location                 = azurerm_resource_group.ai_usecase_rg.location
    account_tier             = "Standard"
    account_replication_type = "LRS"
    account_kind             = "StorageV2"
}

# Create a function apps for ochestration
resource "azurerm_linux_function_app" "functions_app" {
    for_each = var.function_app

    name                       = each.value.name
    resource_group_name        = azurerm_resource_group.ai_usecase_rg.name
    location                   = azurerm_resource_group.ai_usecase_rg.location
    service_plan_id            = azurerm_service_plan.service_plan.id
    storage_account_name       = azurerm_storage_account.functions_file_system_storage.name
    storage_account_access_key = azurerm_storage_account.functions_file_system_storage.primary_access_key

    site_config {}

    depends_on = [
        azurerm_service_plan.service_plan,
        azurerm_linux_web_app.web_app
    ]
}

# Create a cognitive account with document intelligence model
resource "azurerm_cognitive_account" "document-intelligence" {
    name                = "${var.name}-document-intelligence"
    location            = azurerm_resource_group.ai_usecase_rg.location
    resource_group_name = azurerm_resource_group.ai_usecase_rg.name
    kind                = "FormRecognizer"

    sku_name = "S0"
}

# Create a user-assigned identity for the Cosmos DB account
resource "azurerm_user_assigned_identity" "identity" {
    name                = "${var.name}-cosmosDBidentity"
    resource_group_name = azurerm_resource_group.ai_usecase_rg.name
    location            = azurerm_resource_group.ai_usecase_rg.location
}

# Create a Cosmos DB account for storing metadata
resource "azurerm_cosmosdb_account" "cosmosDB" {
    name                  = "${var.name}cosmosdb"
    location              = azurerm_resource_group.ai_usecase_rg.location
    resource_group_name   = azurerm_resource_group.ai_usecase_rg.name
    default_identity_type = join("=", ["UserAssignedIdentity", azurerm_user_assigned_identity.identity.id])
    offer_type            = "Standard"
    kind                  = "MongoDB"

    capabilities {
        name = "EnableMongo"
    }

    consistency_policy {
        consistency_level = "Strong"
    }

    geo_location {
        location          = "westeurope"
        failover_priority = 0
    }

    identity {
        type         = "UserAssigned"
        identity_ids = [azurerm_user_assigned_identity.identity.id]
    }
}

# Create a search service for indexing
resource "azurerm_search_service" "search" {
    name                = "${var.name}-search"
    resource_group_name = azurerm_resource_group.ai_usecase_rg.name
    location            = azurerm_resource_group.ai_usecase_rg.location
    sku                 = "free"
    replica_count       = 1
    partition_count     = 1
}
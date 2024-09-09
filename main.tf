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
    name                 = var.app_subnet_name
    resource_group_name  = azurerm_resource_group.app_service_rg.name
    virtual_network_name = azurerm_virtual_network.app_service_vnet.name
    address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "functions_subnet" {
    name                 = var.functions_subnet_name
    resource_group_name  = azurerm_resource_group.app_service_rg.name
    virtual_network_name = azurerm_virtual_network.app_service_vnet.name
    address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_service_plan" "web_app_service_plan" {
    name                = "${var.web_app_name}-plan"
    resource_group_name = azurerm_resource_group.app_service_rg.name
    location            = azurerm_resource_group.app_service_rg.location
    os_type             = "Linux"
    sku_name            = "P1v2"
}

resource "azurerm_linux_web_app" "web_app" {
    name                      = var.web_app_name
    location                  = azurerm_resource_group.app_service_rg.location
    resource_group_name       = azurerm_resource_group.app_service_rg.name
    service_plan_id           = azurerm_service_plan.web_app_service_plan.id
    virtual_network_subnet_id = azurerm_subnet.app_service_subnet.id

    identity {
        type = "SystemAssigned"
    }

    site_config {}
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
    principal_id         = azurerm_linux_web_app.web_app.identity[0].principal_id
    role_definition_name = "Storage Queue Data Contributor"
    scope                = azurerm_storage_account.queue_storage.id
}

# Create Azure Blob Storage
resource "azurerm_storage_container" "blob_container" {
    name                  = var.blob_container_name
    storage_account_name  = azurerm_storage_account.queue_storage.name
    container_access_type = "private"
}

resource "azurerm_role_assignment" "app_service_blob_contributor" {
    principal_id         = azurerm_linux_web_app.web_app.identity[0].principal_id
    role_definition_name = "Storage Blob Data Contributor"
    scope                = azurerm_storage_account.queue_storage.id
}

resource "azurerm_service_plan" "functions_service_plan" {
    name                = "${var.functions_app_name}-plan"
    resource_group_name = azurerm_resource_group.app_service_rg.name
    location            = azurerm_resource_group.app_service_rg.location
    os_type             = "Linux"
    sku_name            = "Y1"
}

resource "azurerm_storage_account" "functions_file_system_storage" {
    for_each = var.filesystem_storage_accounts

    name                     = each.value.name
    resource_group_name      = azurerm_resource_group.app_service_rg.name
    location                 = azurerm_resource_group.app_service_rg.location
    account_tier             = "Standard"
    account_replication_type = "LRS"
    account_kind             = "StorageV2"
}

resource "azurerm_linux_function_app" "example" {
    for_each = var.function_apps

    name                       = each.value.name
    resource_group_name        = azurerm_resource_group.app_service_rg.name
    location                   = azurerm_resource_group.app_service_rg.location
    service_plan_id            = azurerm_service_plan.functions_service_plan.id
    virtual_network_subnet_id  = azurerm_subnet.functions_subnet.id
    storage_account_name       = each.value.storage_account_name
    storage_account_access_key = each.value.primary_access_key

    site_config {}
}
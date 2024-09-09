terraform {
    required_providers {
        azurerm = {
            source = "hashicorp/azurerm"
            version = "4.1.0"
        }
    }
}

provider "azurerm" {
    features {}
    // use_cli should be set to false to yield more accurate error messages on auth failure.
    use_cli              = true
    // use_oidc must be explicitly set to true when using multiple configurations.
    use_oidc             = true
    client_id_file_path  = var.tfc_azure_dynamic_credentials.default.client_id_file_path
    oidc_token_file_path = var.tfc_azure_dynamic_credentials.default.oidc_token_file_path
    subscription_id      = "394bdec4-d339-44c3-8ad8-82040c134713"
    tenant_id            = "75379e18-455d-45b0-b1c4-8cdd1dbb0d55"
}

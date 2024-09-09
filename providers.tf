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
}

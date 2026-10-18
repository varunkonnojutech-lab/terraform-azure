terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      # Keep the vault when the configuration is destroyed so secrets are not
      # lost by accident; remove the vault manually if you really want it gone.
      purge_soft_delete_on_destroy = false
    }
  }
}

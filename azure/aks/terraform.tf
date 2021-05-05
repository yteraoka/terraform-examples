terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.51.0"
    }
    random = {
      version = "=3.1.0"
    }
  }
}

provider "azurerm" {
  features {}
}


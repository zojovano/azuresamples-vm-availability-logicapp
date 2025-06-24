terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    # Backend configuration is provided via environment variables:
    # ARM_ACCESS_KEY (from STORAGE-ACCESS-KEY secret) for storage authentication
    # STATE_RESOURCE_GROUP -> resource_group_name
    # STATE_STORAGE_ACCOUNT -> storage_account_name  
    # STATE_CONTAINER -> container_name
    # key is set to a fixed value for this project
    key = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
  tenant_id = var.tenant_id
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = var.tags
}
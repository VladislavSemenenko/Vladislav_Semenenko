provider "azurerm" {
  features {}
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.65.0"
    }
  }
}

variable "azureuser_password" {
  description = "Please enter a harden password"
}

variable "location" {
  description = "The location where resources will be created"
  default = "germanywestcentral"
}

variable "common_tags" {
  description = "Common tags to apply all resources"
  type = map
  default = {
    Owner       = "Vladislav Semenenko"
    Project     = "2_WebServers_LB_project"
    CostCenter  = "666"
    Environment = "Kitchen"
  }
}

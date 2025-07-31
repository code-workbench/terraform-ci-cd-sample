# General Configuration
variable "location" {
  description = "The Azure Government region where all resources will be created"
  type        = string
  default     = "USGov Virginia"
  validation {
    condition = contains([
      "USGov Virginia",
      "USGov Iowa",
      "USGov Texas",
      "USGov Arizona",
      "USDoD East",
      "USDoD Central"
    ], var.location)
    error_message = "Location must be a valid Azure Government region."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Name of the project for tagging and naming resources"
  type        = string
  default     = "docker-app"
}

variable "azure_environment" {
  description = "Azure environment (public, usgovernment, china, german)"
  type        = string
  default     = "usgovernment"
  validation {
    condition     = contains(["public", "usgovernment", "china", "german"], var.azure_environment)
    error_message = "Azure environment must be one of: public, usgovernment, china, german."
  }
}

# Resource Group Configuration
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-docker-app"
}

# Container Registry Configuration
variable "container_registry_name" {
  description = "Name of the Azure Container Registry (must be globally unique)"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9]*$", var.container_registry_name))
    error_message = "Container registry name can only contain alphanumeric characters."
  }
}

variable "container_registry_sku" {
  description = "SKU for the Azure Container Registry"
  type        = string
  default     = "Basic"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.container_registry_sku)
    error_message = "Container registry SKU must be Basic, Standard, or Premium."
  }
}

# App Service Plan Configuration
variable "app_service_plan_name" {
  description = "Name of the App Service Plan"
  type        = string
  default     = "asp-docker-app"
}

variable "app_service_plan_sku" {
  description = "SKU for the App Service Plan"
  type        = string
  default     = "B1"
  validation {
    condition = contains([
      "F1", "D1", "B1", "B2", "B3",
      "S1", "S2", "S3",
      "P1", "P2", "P3", "P4",
      "P1V2", "P2V2", "P3V2", "P4V2", "P5V2",
      "P1V3", "P2V3", "P3V3", "P4V3", "P5V3"
    ], var.app_service_plan_sku)
    error_message = "App Service Plan SKU must be a valid Azure App Service Plan tier."
  }
}

# App Service Configuration
variable "app_service_name" {
  description = "Name of the App Service (must be globally unique)"
  type        = string
}

variable "app_service_always_on" {
  description = "Should the App Service be always on?"
  type        = bool
  default     = true
}

variable "health_check_path" {
  description = "Health check path for the App Service"
  type        = string
  default     = "/"
}

# Docker Configuration
variable "docker_image_name" {
  description = "Name of the Docker image (without registry URL)"
  type        = string
  default     = "my-app"
}

variable "docker_image_tag" {
  description = "Tag of the Docker image"
  type        = string
  default     = "latest"
}

variable "websites_port" {
  description = "Port that the container listens on"
  type        = string
  default     = "80"
}

# Additional App Settings
variable "additional_app_settings" {
  description = "Additional app settings for the App Service"
  type        = map(string)
  default     = {}
}

# Managed Identity Configuration
variable "enable_managed_identity_acr_access" {
  description = "Enable managed identity access to ACR (disable if using admin credentials)"
  type        = bool
  default     = true
}

# Custom Domain Configuration
variable "custom_domain" {
  description = "Custom domain for the App Service (optional)"
  type        = string
  default     = null
}

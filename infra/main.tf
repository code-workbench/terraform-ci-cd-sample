# Configure the Azure Provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }

  backend "azurerm" {
    environment = "usgovernment"
    # Configuration will be provided via -backend-config flags or backend config files
    # This allows different environments to use different state files
  }
}

# Configure the Microsoft Azure Provider for Azure Government
provider "azurerm" {
  environment = "usgovernment"
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Create Azure Container Registry
resource "azurerm_container_registry" "main" {
  name                = var.container_registry_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = var.container_registry_sku
  admin_enabled       = false # Changed from true to false

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Create App Service Plan
resource "azurerm_service_plan" "main" {
  name                = var.app_service_plan_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = var.app_service_plan_sku

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Create App Service (Web App)
resource "azurerm_linux_web_app" "main" {
  name                                           = var.app_service_name
  resource_group_name                            = azurerm_resource_group.main.name
  location                                       = azurerm_service_plan.main.location
  service_plan_id                                = azurerm_service_plan.main.id
  webdeploy_publish_basic_authentication_enabled = false
  ftp_publish_basic_authentication_enabled       = true
  site_config {
    always_on                               = var.app_service_always_on
    health_check_path                       = var.health_check_path
    container_registry_use_managed_identity = true

    application_stack {
      docker_image_name   = "${var.docker_image_name}:${var.docker_image_tag}"
      docker_registry_url = "https://${azurerm_container_registry.main.login_server}"
    }
  }

  app_settings = merge(
    {
      "DOCKER_REGISTRY_SERVER_URL"          = "https://${azurerm_container_registry.main.login_server}"
      "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
      "WEBSITES_PORT"                       = var.websites_port
      "DOCKER_ENABLE_CI"                    = "true"
      "DEMO_VALUE"                          = "Test value"
    },
    var.additional_app_settings
  )

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }

  depends_on = [azurerm_container_registry.main]
}

# Grant App Service access to Container Registry using managed identity
resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_web_app.main.identity[0].principal_id
}

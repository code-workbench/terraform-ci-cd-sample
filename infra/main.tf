# Configure the Azure Provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
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
  admin_enabled       = true

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
  name                = var.app_service_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_service_plan.main.location
  service_plan_id     = azurerm_service_plan.main.id

  site_config {
    always_on         = var.app_service_always_on
    health_check_path = var.health_check_path

    application_stack {
      docker_image_name   = "${azurerm_container_registry.main.login_server}/${var.docker_image_name}:${var.docker_image_tag}"
      docker_registry_url = "https://${azurerm_container_registry.main.login_server}"
    }
  }

  app_settings = merge(
    {
      "DOCKER_REGISTRY_SERVER_URL"          = "https://${azurerm_container_registry.main.login_server}"
      "DOCKER_REGISTRY_SERVER_USERNAME"     = azurerm_container_registry.main.admin_username
      "DOCKER_REGISTRY_SERVER_PASSWORD"     = azurerm_container_registry.main.admin_password
      "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
      "WEBSITES_PORT"                       = var.websites_port
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

# Optional: Grant App Service access to Container Registry using managed identity
resource "azurerm_role_assignment" "acr_pull" {
  count                = var.enable_managed_identity_acr_access ? 1 : 0
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_web_app.main.identity[0].principal_id
}

# Optional: Custom domain (if provided)
resource "azurerm_app_service_custom_hostname_binding" "main" {
  count               = var.custom_domain != null ? 1 : 0
  hostname            = var.custom_domain
  app_service_name    = azurerm_linux_web_app.main.name
  resource_group_name = azurerm_resource_group.main.name
}

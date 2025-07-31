# Resource Group Outputs
output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the created resource group"
  value       = azurerm_resource_group.main.location
}

# Container Registry Outputs
output "container_registry_name" {
  description = "Name of the Azure Container Registry"
  value       = azurerm_container_registry.main.name
}

output "container_registry_login_server" {
  description = "Login server URL for the Azure Container Registry"
  value       = azurerm_container_registry.main.login_server
}

output "container_registry_admin_username" {
  description = "Admin username for the Azure Container Registry"
  value       = azurerm_container_registry.main.admin_username
  sensitive   = true
}

output "container_registry_admin_password" {
  description = "Admin password for the Azure Container Registry"
  value       = azurerm_container_registry.main.admin_password
  sensitive   = true
}

# App Service Plan Outputs
output "app_service_plan_id" {
  description = "ID of the App Service Plan"
  value       = azurerm_service_plan.main.id
}

output "app_service_plan_name" {
  description = "Name of the App Service Plan"
  value       = azurerm_service_plan.main.name
}

# App Service Outputs
output "app_service_name" {
  description = "Name of the App Service"
  value       = azurerm_linux_web_app.main.name
}

output "app_service_default_hostname" {
  description = "Default hostname of the App Service"
  value       = azurerm_linux_web_app.main.default_hostname
}

output "app_service_url" {
  description = "URL of the App Service"
  value       = "https://${azurerm_linux_web_app.main.default_hostname}"
}

output "app_service_outbound_ip_addresses" {
  description = "Outbound IP addresses of the App Service"
  value       = azurerm_linux_web_app.main.outbound_ip_addresses
}

output "app_service_possible_outbound_ip_addresses" {
  description = "Possible outbound IP addresses of the App Service"
  value       = azurerm_linux_web_app.main.possible_outbound_ip_addresses
}

# Managed Identity Outputs
output "app_service_identity_principal_id" {
  description = "Principal ID of the App Service managed identity"
  value       = azurerm_linux_web_app.main.identity[0].principal_id
}

output "app_service_identity_tenant_id" {
  description = "Tenant ID of the App Service managed identity"
  value       = azurerm_linux_web_app.main.identity[0].tenant_id
}

# Docker Configuration Outputs
output "docker_image_full_name" {
  description = "Full Docker image name with registry"
  value       = "${azurerm_container_registry.main.login_server}/${var.docker_image_name}:${var.docker_image_tag}"
}

# Azure Government Environment Info
output "azure_environment" {
  description = "Azure environment (usgovernment)"
  value       = var.azure_environment
}

output "azure_government_endpoints" {
  description = "Azure Government specific endpoints"
  value = {
    portal                             = "https://portal.azure.us"
    management                         = "https://management.usgovcloudapi.net"
    resource_manager                   = "https://management.usgovcloudapi.net"
    sql_management                     = "https://management.core.usgovcloudapi.net:8443"
    batch_resource_id                  = "https://batch.core.usgovcloudapi.net/"
    gallery                            = "https://gallery.usgovcloudapi.net"
    active_directory                   = "https://login.microsoftonline.us"
    active_directory_graph_resource_id = "https://graph.windows.net/"
  }
}

# Deployment Information
output "deployment_info" {
  description = "Azure Government deployment information and next steps"
  value = {
    azure_environment  = "Azure Government"
    resource_group     = azurerm_resource_group.main.name
    registry_url       = azurerm_container_registry.main.login_server
    registry_domain    = ".azurecr.us"
    app_service_url    = "https://${azurerm_linux_web_app.main.default_hostname}"
    app_service_domain = ".azurewebsites.us"
    portal_url         = "https://portal.azure.us"
    next_steps = [
      "AZURE GOVERNMENT DEPLOYMENT:",
      "1. Ensure Azure CLI is configured for Azure Government: az cloud set --name AzureUSGovernment",
      "2. Login to Azure Government: az login",
      "3. Login to ACR: az acr login --name ${azurerm_container_registry.main.name}",
      "4. Build your Docker image: docker build -t your-local-image .",
      "5. Tag your image: docker tag your-local-image ${azurerm_container_registry.main.login_server}/${var.docker_image_name}:${var.docker_image_tag}",
      "6. Push your image: docker push ${azurerm_container_registry.main.login_server}/${var.docker_image_name}:${var.docker_image_tag}",
      "7. Access your application at: https://${azurerm_linux_web_app.main.default_hostname}",
      "8. Manage your resources in Azure Government Portal: https://portal.azure.us"
    ]
  }
}

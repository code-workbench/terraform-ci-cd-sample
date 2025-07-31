# Development environment variables
environment             = "dev"
project_name            = "terraform-ci-cd-sample"
resource_group_name     = "rg-terraform-sample-dev"
location                = "USGov Virginia"
container_registry_name = "acrtfsampledev"
container_registry_sku  = "Standard"
app_service_plan_name   = "asp-terraform-sample-dev"
app_service_plan_sku    = "S1"
app_service_name        = "app-terraform-sample-dev"
app_service_always_on   = true
health_check_path       = "/health"
docker_image_name       = "my-app"
docker_image_tag        = "latest"
websites_port           = "80"
additional_app_settings = {
  "ENVIRONMENT" = "dev"
  "LOG_LEVEL"   = "DEBUG"
}

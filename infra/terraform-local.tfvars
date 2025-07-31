# Local development variables
environment             = "local"
project_name            = "terraform-ci-cd-sample"
resource_group_name     = "rg-terraform-sample-local"
location                = "USGov Virginia"
container_registry_name = "acrtfsamplelocal"
container_registry_sku  = "Basic"
app_service_plan_name   = "asp-terraform-sample-local"
app_service_plan_sku    = "B1"
app_service_name        = "app-terraform-sample-local"
app_service_always_on   = false
health_check_path       = "/health"
docker_image_name       = "my-app"
docker_image_tag        = "latest"
websites_port           = "80"
additional_app_settings = {
  "ENVIRONMENT" = "local"
}

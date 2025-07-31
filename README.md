# Azure Government App Service with Docker Container from Azure Container Registry

This Terraform configuration creates the necessary Azure Government infrastructure to run a Docker container application using Azure App Service and Azure Container Registry in the Azure Government cloud.

## 🏛️ Azure Government Features

This configuration is specifically designed for **Azure Government** with:
- **Azure Government Cloud**: Uses `usgovernment` environment
- **Government Regions**: Supports USGov Virginia, Iowa, Texas, Arizona, and DoD regions
- **Government Domains**: Uses `.azurecr.us` for ACR and `.azurewebsites.us` for App Service
- **Compliance Ready**: Configured for FedRAMP and government compliance requirements
- **Secure by Design**: Enhanced security settings for government workloads

## Architecture

This configuration creates the following Azure Government resources:

- **Resource Group**: Container for all resources
- **Azure Container Registry (ACR)**: Private Docker registry with .azurecr.us domain
- **App Service Plan**: Compute resources for the App Service
- **Linux Web App**: App Service configured to run Docker containers with .azurewebsites.us domain
- **System-Assigned Managed Identity**: For secure access to ACR (optional)
- **Role Assignment**: Grants the App Service pull access to ACR (optional)

## Prerequisites

1. **Azure CLI**: Install and configure Azure CLI for Azure Government
   ```bash
   # Set Azure CLI to Azure Government cloud
   az cloud set --name AzureUSGovernment
   
   # Login to Azure Government
   az login
   
   # Set your subscription
   az account set --subscription "your-subscription-id"
   ```

2. **Terraform**: Install Terraform (>= 1.0)
   ```bash
   # Install Terraform using package manager or download from terraform.io
   ```

3. **Docker**: For building and pushing images to ACR
   ```bash
   # Install Docker from docker.com
   ```

## Azure Government Regions

This configuration supports the following Azure Government regions:
- **USGov Virginia** (default) - `"USGov Virginia"`
- **USGov Iowa** - `"USGov Iowa"`
- **USGov Texas** - `"USGov Texas"`
- **USGov Arizona** - `"USGov Arizona"`
- **USDoD East** - `"USDoD East"`
- **USDoD Central** - `"USDoD Central"`

## Quick Start

1. **Configure Azure CLI for Azure Government**
   ```bash
   # Set Azure CLI to Azure Government cloud
   az cloud set --name AzureUSGovernment
   
   # Login to Azure Government
   az login --use-device-code
   
   # Verify you're in the correct cloud
   az cloud show --query name
   ```

2. **Clone and Configure**
   ```bash
   git clone <your-repo-url>
   cd terraform-ci-cd-sample
   cp terraform.tfvars.example terraform.tfvars
   ```

3. **Edit terraform.tfvars for Azure Government**
   Update the values in `terraform.tfvars` with your specific configuration:
   ```hcl
   # Required: Must be globally unique (will use .azurecr.us domain)
   container_registry_name = "your-unique-acr-name"
   app_service_name       = "your-unique-app-name"  # will use .azurewebsites.us domain
   
   # Azure Government specific values
   location              = "USGov Virginia"  # or other gov regions
   azure_environment     = "usgovernment"
   environment          = "dev"
   docker_image_name    = "your-app-name"
   ```

4. **Deploy Infrastructure**
   ```bash
   # Use the deployment script (recommended)
   ./scripts/deploy-docker-app.sh deploy
   
   # Or deploy manually
   terraform init
   terraform plan
   terraform apply
   ```

5. **Build and Push Docker Image**
   ```bash
   # Login to ACR (Azure Government)
   az acr login --name your-acr-name
   
   # Build your Docker image (from the app directory)
   docker build -t your-app-name:latest ./app
   
   # Tag for ACR
   docker tag your-app-name:latest your-acr-name.azurecr.io/your-app-name:latest
   
   # Push to ACR
   docker push your-acr-name.azurecr.io/your-app-name:latest
   ```

5. **Access Your Application**
   Your application will be available at the URL provided in the Terraform output.

## Setting up CI/CD:

To setup CI/CD using the Github Worklow, you will need to take the following actions:

1. Create a service principal to assign to the github runner:

```
# Create the service principal
SUBSCRIPTION_ID="<The Guid ID of your azure subscription>"
az ad sp create-for-rbac --name "demo-terraform-ci-cd-sp" --role contributor --scopes /subscriptions/$SUBSCRIPTION_ID
```

You will get an output similar to this:

```
{
  "clientId": "your-service-principal-client-id",
  "clientSecret": "your-service-principal-client-secret",
  "subscriptionId": "your-azure-subscription-id",
  "tenantId": "your-azure-tenant-id"
}
```

Populate this into a GITHUB Secret named "AZURE_CREDENTIALS".

## Configuration Variables

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `container_registry_name` | Globally unique ACR name | `"myappacr001"` |
| `app_service_name` | Globally unique App Service name | `"myapp001"` |

### Optional Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `location` | `"East US"` | Azure region |
| `environment` | `"dev"` | Environment tag |
| `project_name` | `"docker-app"` | Project name for tagging |
| `container_registry_sku` | `"Basic"` | ACR SKU (Basic/Standard/Premium) |
| `app_service_plan_sku` | `"B1"` | App Service Plan SKU |
| `docker_image_name` | `"my-app"` | Docker image name |
| `docker_image_tag` | `"latest"` | Docker image tag |
| `websites_port` | `"80"` | Port your container listens on |
| `app_service_always_on` | `true` | Keep App Service always on |
| `health_check_path` | `"/"` | Health check endpoint |

## Security Options

### Option 1: Admin Credentials (Default)
Uses ACR admin username/password for authentication. Simpler setup but less secure.

```hcl
enable_managed_identity_acr_access = false
```

### Option 2: Managed Identity (Recommended)
Uses system-assigned managed identity for secure, credential-less access to ACR.

```hcl
enable_managed_identity_acr_access = true
```

If using managed identity, update your App Service configuration to remove admin credentials:
```hcl
app_settings = {
  "DOCKER_REGISTRY_SERVER_URL" = "https://your-acr-name.azurecr.io"
  # Remove username/password settings
}
```

## Custom Domain

To add a custom domain:

1. Set the variable:
   ```hcl
   custom_domain = "your-domain.com"
   ```

2. Configure DNS to point to your App Service:
   ```
   CNAME your-domain.com -> your-app-name.azurewebsites.net
   ```

## Monitoring and Troubleshooting

### View Application Logs
```bash
az webapp log tail --name your-app-name --resource-group your-rg-name
```

### Container Status
```bash
az webapp show --name your-app-name --resource-group your-rg-name --query "siteConfig.linuxFxVersion"
```

### ACR Repository List
```bash
az acr repository list --name your-acr-name
```

## Sample Dockerfile

Here's a basic Dockerfile for a Node.js application:

```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

EXPOSE 80

CMD ["npm", "start"]
```

## CI/CD Integration

This configuration works well with GitHub Actions, Azure DevOps, or other CI/CD systems. See the included workflow examples for automated deployment.

## Cost Optimization

- **Development**: Use `F1` (Free) or `D1` (Shared) App Service Plan
- **Production**: Use `B1` or higher for better performance
- **ACR**: Use `Basic` SKU for development, `Standard` or `Premium` for production

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

## Troubleshooting

### Common Issues

1. **ACR Name Already Exists**
   - ACR names must be globally unique
   - Try a different name with numbers or your organization prefix

2. **App Service Name Already Exists**
   - App Service names must be globally unique
   - Try a different name or add a unique suffix

3. **Container Won't Start**
   - Check if your container exposes the correct port (set in `websites_port`)
   - Verify your Docker image works locally
   - Check application logs for startup errors

4. **Authentication Issues**
   - For admin credentials: Ensure admin is enabled on ACR
   - For managed identity: Ensure role assignment is created

## Outputs

After deployment, Terraform provides useful outputs:

- ACR login server URL
- App Service URL
- Managed identity principal ID
- Next steps for deployment

## Support

For issues with this Terraform configuration, please check:

1. Azure provider documentation
2. Terraform Azure examples
3. Azure App Service documentation
4. Azure Container Registry documentation

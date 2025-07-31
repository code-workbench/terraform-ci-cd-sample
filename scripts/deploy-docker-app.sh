#!/bin/bash

# Azure App Service Docker Deployment Script
# This script helps deploy the Terraform configuration and Docker image

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if required tools are installed
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed. Please install Azure CLI first."
        exit 1
    fi
    
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    print_status "All prerequisites are installed ✓"
}

# Function to check Azure login
check_azure_login() {
    print_status "Checking Azure login status..."
    
    # Check if Azure CLI is configured for Azure Government
    local current_cloud=$(az cloud show --query name -o tsv 2>/dev/null || echo "")
    if [ "$current_cloud" != "AzureUSGovernment" ]; then
        print_warning "Azure CLI is not configured for Azure Government"
        print_status "Setting Azure CLI to Azure Government cloud..."
        az cloud set --name AzureUSGovernment
        print_status "Azure CLI configured for Azure Government ✓"
    else
        print_status "Azure CLI is configured for Azure Government ✓"
    fi
    
    if ! az account show &> /dev/null; then
        print_error "Not logged into Azure Government. Please run 'az login' first."
        print_status "Note: You need to login specifically to Azure Government."
        exit 1
    fi
    
    local subscription=$(az account show --query name -o tsv)
    local cloud=$(az cloud show --query name -o tsv)
    print_status "Logged into Azure subscription: $subscription"
    print_status "Current cloud environment: $cloud ✓"
}

# Function to initialize Terraform
init_terraform() {
    local environment="$1"
    print_status "Initializing Terraform for $environment environment..."
    
    # Get the script directory and project root
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
    INFRA_DIR="$PROJECT_ROOT/infra"
    
    # Change to the infra directory where Terraform files are located
    cd "$INFRA_DIR" || {
        print_error "Cannot change to Terraform directory: $INFRA_DIR"
        exit 1
    }
    
    # Check if backend config file exists
    local backend_config="backend-${environment}.tfbackend"
    if [ ! -f "$backend_config" ]; then
        print_error "Backend configuration file not found: $backend_config"
        print_error "Available environments: local, dev, prod"
        exit 1
    fi
    
    # Check if environment variable file exists
    local var_file="terraform-${environment}.tfvars"
    if [ ! -f "$var_file" ]; then
        print_error "Environment variables file not found: $var_file"
        print_error "Available environments: local, dev, prod"
        exit 1
    fi
    
    # Clean up any existing backend configuration
    rm -rf .terraform/
    
    # Initialize with environment-specific backend
    terraform init -backend-config="$backend_config"
    local current_workspace=$(terraform workspace show)
    print_status "Current workspace: $current_workspace"
}

# Function to manage local workspace for feature development
manage_local_workspace() {
    print_status "Managing local workspace..."
    
    # List existing workspaces
    local workspaces=$(terraform workspace list | grep -v "default" | sed 's/[* ]//g' | grep -v "^$")
    
    if [ -n "$workspaces" ]; then
        echo "Existing workspaces:"
        echo "$workspaces"
        echo
    fi
    
    # Get current branch name if in git repo
    local current_branch=""
    if git rev-parse --git-dir > /dev/null 2>&1; then
        current_branch=$(git branch --show-current 2>/dev/null || echo "")
    fi
    
    # Suggest workspace name based on current branch
    local suggested_workspace=""
    if [ -n "$current_branch" ] && [ "$current_branch" != "main" ] && [ "$current_branch" != "master" ]; then
        suggested_workspace="$current_branch"
    fi
    
    echo "Local environment workspace options:"
    echo "1) Use default workspace"
    if [ -n "$suggested_workspace" ]; then
        echo "2) Create/select workspace: $suggested_workspace (based on current git branch)"
        echo "3) Create/select a custom workspace"
    else
        echo "2) Create/select a custom workspace"
    fi
    echo
    
    read -p "Choose an option (1-3): " choice
    
    case $choice in
        1)
            terraform workspace select default
            print_status "Using default workspace ✓"
            ;;
        2)
            if [ -n "$suggested_workspace" ]; then
                workspace_name="$suggested_workspace"
            else
                read -p "Enter workspace name: " workspace_name
            fi
            
            if [ -n "$workspace_name" ]; then
                # Try to select existing workspace, create if it doesn't exist
                if terraform workspace select "$workspace_name" 2>/dev/null; then
                    print_status "Selected existing workspace: $workspace_name ✓"
                else
                    terraform workspace new "$workspace_name"
                    print_status "Created and selected new workspace: $workspace_name ✓"
                fi
            else
                print_warning "No workspace name provided, using default"
                terraform workspace select default
            fi
            ;;
        3)
            if [ -n "$suggested_workspace" ]; then
                read -p "Enter workspace name: " workspace_name
            else
                read -p "Enter workspace name: " workspace_name
            fi
            
            if [ -n "$workspace_name" ]; then
                if terraform workspace select "$workspace_name" 2>/dev/null; then
                    print_status "Selected existing workspace: $workspace_name ✓"
                else
                    terraform workspace new "$workspace_name"
                    print_status "Created and selected new workspace: $workspace_name ✓"
                fi
            else
                print_warning "No workspace name provided, using default"
                terraform workspace select default
            fi
            ;;
        *)
            print_warning "Invalid choice, using default workspace"
            terraform workspace select default
            ;;
    esac
    
    local current_workspace=$(terraform workspace show)
    print_status "Current workspace: $current_workspace"
}

# Function to plan Terraform deployment
plan_terraform() {
    local environment="$1"
    print_status "Planning Terraform deployment for $environment environment..."
    
    # Ensure we're in the infra directory where Terraform files are located
    cd "$INFRA_DIR" || {
        print_error "Cannot change to Terraform directory: $INFRA_DIR"
        exit 1
    }
    
    local var_file="terraform-${environment}.tfvars"
    terraform plan -var-file="$var_file" -out=tfplan
    print_status "Terraform plan completed ✓"
}

# Function to apply Terraform deployment
apply_terraform() {
    print_status "Applying Terraform deployment..."
    terraform apply tfplan
    print_status "Terraform deployment completed ✓"
}

# Function to get Terraform outputs
get_outputs() {
    print_status "Getting deployment outputs..."
    
    # Ensure we're in the infra directory where Terraform files are located
    cd "$INFRA_DIR" || {
        print_error "Cannot change to Terraform directory: $INFRA_DIR"
        exit 1
    }
    
    ACR_NAME=$(terraform output -raw container_registry_name)
    ACR_LOGIN_SERVER=$(terraform output -raw container_registry_login_server)
    APP_SERVICE_URL=$(terraform output -raw app_service_url)
    DOCKER_IMAGE_NAME=$(terraform output -raw docker_image_full_name)
    
    print_status "Deployment completed successfully!"
    echo
    echo "=== Deployment Information ==="
    echo "Container Registry: $ACR_NAME"
    echo "Login Server: $ACR_LOGIN_SERVER"
    echo "App Service URL: $APP_SERVICE_URL"
    echo "Docker Image: $DOCKER_IMAGE_NAME"
    echo
}

# Function to build and push Docker image
build_and_push() {
    if [ -z "$1" ]; then
        print_error "Please provide the path to your Dockerfile directory"
        echo "Usage: $0 build-push /path/to/dockerfile/directory"
        exit 1
    fi
    
    local dockerfile_dir="$1"
    
    # Resolve absolute path to dockerfile directory before changing directories
    dockerfile_dir="$(cd "$dockerfile_dir" && pwd)" || {
        print_error "Cannot access dockerfile directory: $1"
        exit 1
    }
    
    if [ ! -f "$dockerfile_dir/Dockerfile" ]; then
        print_error "Dockerfile not found in $dockerfile_dir"
        exit 1
    fi
    
    print_status "Building and pushing Docker image..."
    
    # Get the script directory and project root
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
    INFRA_DIR="$PROJECT_ROOT/infra"
    
    # Ensure we're in the infra directory where Terraform files are located
    cd "$INFRA_DIR" || {
        print_error "Cannot change to Terraform directory: $INFRA_DIR"
        exit 1
    }
    
    # Get outputs from Terraform
    ACR_NAME=$(terraform output -raw container_registry_name)
    ACR_LOGIN_SERVER=$(terraform output -raw container_registry_login_server)
    DOCKER_IMAGE_FULL_NAME=$(terraform output -raw docker_image_full_name)
    
    # Login to ACR
    print_status "Logging into Azure Container Registry..."
    az acr login --name "$ACR_NAME"
    
    # Build the image
    print_status "Building Docker image..."
    docker build -t "$DOCKER_IMAGE_FULL_NAME" "$dockerfile_dir"
    
    # Push the image
    print_status "Pushing Docker image to ACR..."
    docker push "$DOCKER_IMAGE_FULL_NAME"
    
    print_status "Docker image built and pushed successfully ✓"
    print_status "Your application should be available at: $(terraform output -raw app_service_url)"
}

# Function to show help
show_help() {
    echo "Azure App Service Docker Deployment Script"
    echo
    echo "Usage:"
    echo "  $0 [command] [environment] [options]"
    echo
    echo "Commands:"
    echo "  deploy <env>         Deploy infrastructure using Terraform"
    echo "  build-push <dir>     Build and push Docker image from directory"
    echo "  outputs              Show deployment outputs"
    echo "  destroy <env>        Destroy all infrastructure"
    echo "  help                 Show this help message"
    echo
    echo "Environments:"
    echo "  local               Local development environment"
    echo "  dev                 Development environment"
    echo "  prod                Production environment"
    echo
    echo "Examples:"
    echo "  $0 deploy local                # Deploy to local environment"
    echo "  $0 deploy dev                  # Deploy to dev environment"
    echo "  $0 deploy prod                 # Deploy to production environment"
    echo "  $0 build-push ./app           # Build and push from app directory"
    echo "  $0 build-push /path/to/app    # Build and push from specific directory"
    echo "  $0 outputs                    # Show deployment information"
    echo "  $0 destroy dev                # Destroy dev environment"
    echo
    echo "Note: For local development, you can create feature-specific workspaces:"
    echo "  terraform workspace new feature-branch-name"
    echo "  terraform workspace select feature-branch-name"
    echo
}

# Main script logic
case "${1:-help}" in
    "deploy")
        if [ -z "$2" ]; then
            print_error "Please specify an environment: local, dev, or prod"
            echo "Usage: $0 deploy <environment>"
            exit 1
        fi
        environment="$2"
        if [[ ! "$environment" =~ ^(local|dev|prod)$ ]]; then
            print_error "Invalid environment. Valid options: local, dev, prod"
            exit 1
        fi
        check_prerequisites
        check_azure_login
        init_terraform "$environment"
        plan_terraform "$environment"
        apply_terraform
        get_outputs
        ;;
    "build-push")
        check_prerequisites
        check_azure_login
        build_and_push "$2"
        ;;
    "outputs")
        get_outputs
        ;;
    "destroy")
        if [ -z "$2" ]; then
            print_error "Please specify an environment: local, dev, or prod"
            echo "Usage: $0 destroy <environment>"
            exit 1
        fi
        environment="$2"
        if [[ ! "$environment" =~ ^(local|dev|prod)$ ]]; then
            print_error "Invalid environment. Valid options: local, dev, prod"
            exit 1
        fi
        print_warning "This will destroy all infrastructure in the $environment environment. Are you sure? (y/N)"
        read -r response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            check_prerequisites
            check_azure_login
            init_terraform "$environment"
            # Get the script directory and project root
            SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
            PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
            INFRA_DIR="$PROJECT_ROOT/infra"
            
            # Ensure we're in the infra directory where Terraform files are located
            cd "$INFRA_DIR" || {
                print_error "Cannot change to Terraform directory: $INFRA_DIR"
                exit 1
            }
            local var_file="terraform-${environment}.tfvars"
            terraform destroy -var-file="$var_file"
            print_status "Infrastructure destroyed for $environment environment"
        else
            print_status "Destroy cancelled"
        fi
        ;;
    "help"|*)
        show_help
        ;;
esac

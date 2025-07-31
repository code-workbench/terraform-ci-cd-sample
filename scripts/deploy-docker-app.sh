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
    print_status "Initializing Terraform..."
    
    # Get the script directory and project root
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
    INFRA_DIR="$PROJECT_ROOT/infra"
    
    # Change to the infra directory where Terraform files are located
    cd "$INFRA_DIR" || {
        print_error "Cannot change to Terraform directory: $INFRA_DIR"
        exit 1
    }
    
    if [ ! -f "terraform.tfvars" ]; then
        print_warning "terraform.tfvars not found. Creating from example..."
        cp terraform.tfvars.example terraform.tfvars
        print_warning "Please edit terraform.tfvars with your specific values before continuing."
        exit 1
    fi
    
    terraform init
    print_status "Terraform initialized ✓"
}

# Function to plan Terraform deployment
plan_terraform() {
    print_status "Planning Terraform deployment..."
    
    # Ensure we're in the infra directory where Terraform files are located
    cd "$INFRA_DIR" || {
        print_error "Cannot change to Terraform directory: $INFRA_DIR"
        exit 1
    }
    
    terraform plan -out=tfplan
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
    echo "  $0 [command] [options]"
    echo
    echo "Commands:"
    echo "  deploy              Deploy infrastructure using Terraform"
    echo "  build-push <dir>    Build and push Docker image from directory"
    echo "  outputs             Show deployment outputs"
    echo "  destroy             Destroy all infrastructure"
    echo "  help                Show this help message"
    echo
    echo "Examples:"
    echo "  $0 deploy                    # Deploy infrastructure"
    echo "  $0 build-push ./app         # Build and push from app directory"
    echo "  $0 build-push /path/to/app  # Build and push from specific directory"
    echo "  $0 outputs                  # Show deployment information"
    echo
}

# Main script logic
case "${1:-help}" in
    "deploy")
        check_prerequisites
        check_azure_login
        init_terraform
        plan_terraform
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
        print_warning "This will destroy all infrastructure. Are you sure? (y/N)"
        read -r response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            # Get the script directory and project root
            SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
            PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
            INFRA_DIR="$PROJECT_ROOT/infra"
            
            # Ensure we're in the infra directory where Terraform files are located
            cd "$INFRA_DIR" || {
                print_error "Cannot change to Terraform directory: $INFRA_DIR"
                exit 1
            }
            terraform destroy
            print_status "Infrastructure destroyed"
        else
            print_status "Destroy cancelled"
        fi
        ;;
    "help"|*)
        show_help
        ;;
esac

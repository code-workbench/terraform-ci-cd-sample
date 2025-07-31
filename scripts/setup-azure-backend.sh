#!/bin/bash

# Azure Storage Account Setup for Terraform State with Azure AD Authentication
# This script sets up the storage account and assigns the necessary permissions

# Set variables
RESOURCE_GROUP_NAME="terraform-state-rg"
STORAGE_ACCOUNT_NAME="terraformstate$(openssl rand -hex 3)"  # Generates unique suffix
CONTAINER_NAME="tfstate"
LOCATION="usgovvirginia"

echo "Creating Azure Storage Account for Terraform State..."
echo "Resource Group: $RESOURCE_GROUP_NAME"
echo "Storage Account: $STORAGE_ACCOUNT_NAME"
echo "Container: $CONTAINER_NAME"
echo "Location: $LOCATION"
echo ""

# Get current user's object ID
CURRENT_USER_ID=$(az ad signed-in-user show --query objectId -o tsv)
echo "Current user ID: $CURRENT_USER_ID"

# Create resource group
echo "Creating resource group..."
az group create \
  --name $RESOURCE_GROUP_NAME \
  --location "$LOCATION"

# Create storage account
echo "Creating storage account..."
az storage account create \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $STORAGE_ACCOUNT_NAME \
  --sku Standard_LRS \
  --encryption-services blob \
  --https-only true \
  --allow-blob-public-access false

# Create blob container
echo "Creating blob container..."
az storage container create \
  --name $CONTAINER_NAME \
  --account-name $STORAGE_ACCOUNT_NAME \
  --auth-mode login

# Assign Storage Blob Data Contributor role to current user
echo "Assigning Storage Blob Data Contributor role to current user..."
az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee $CURRENT_USER_ID \
  --scope "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT_NAME"

echo ""
echo "Setup complete!"
echo ""
echo "Update your backend configuration files with these values:"
echo "resource_group_name  = \"$RESOURCE_GROUP_NAME\""
echo "storage_account_name = \"$STORAGE_ACCOUNT_NAME\""
echo "container_name       = \"$CONTAINER_NAME\""
echo ""
echo "For CI/CD pipelines, assign the 'Storage Blob Data Contributor' role to your service principal:"
echo "az role assignment create \\"
echo "  --role \"Storage Blob Data Contributor\" \\"
echo "  --assignee <SERVICE_PRINCIPAL_ID> \\"
echo "  --scope \"/subscriptions/\$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT_NAME\""
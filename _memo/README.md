```
$ az group create --resource-group $ACR_RESOURCE_GROUP --location $AZURE_LOCATION
$ az acr create --resource-group $ACR_RESOURCE_GROUP --name $ACR_NAME --sku Standard --location $AZURE_LOCATION
```
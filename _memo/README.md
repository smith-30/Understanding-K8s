## chap02

```bash
# acr 用の RESOURCE_GROUP
$ az group create --resource-group $ACR_RESOURCE_GROUP --location $AZURE_LOCATION
$ az acr create --resource-group $ACR_RESOURCE_GROUP --name $ACR_NAME --sku Standard --location $AZURE_LOCATION

$ cd chap02
$ az acr build --registry $ACR_NAME --image photo-view:v1.0 v1.0/
$ az acr build --registry $ACR_NAME --image photo-view:v2.0 v2.0/
$ az acr repository show-tags -n $ACR_NAME --repository photo-view

# aks 用の RESOURCE_GROUP
$ az group create --resource-group $AKS_RESOURCE_GROUP --location $AZURE_LOCATION

# cluster 作成
$ az aks create \
    --name $AKS_CLUSTER_NAME
    --resource-group $AKS_RESOURCE_GROUP
    --node-count 3 \
    --kubernetes-version 1.11.4 \
    --node-vm-size Standard_DS1_v2 \
    --generate-ssh-keys \
    --service-principal $APP_ID
    --client-secret $SP_PASSWORD
```
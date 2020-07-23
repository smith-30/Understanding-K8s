setup:
	brew update
	brew install azure-cli
	brew instell kebernetes-cli

initEnv:
	direnv allow .

auth:
	az login

setEnv:
	cp .envrc.dev .envrc
	direnv allow .

delete-resources:
	az group delete --name $ACR_RESOURCE_GROUP
	az group delete -name $AKS_RESOURCE_GROUP
	az ad sp delete --id=$(az ad sp show --id http://$SP_NAME --query appId --output tsv)
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

setup:
	brew update
	brew install azure-cli
	brew instell kebernetes-cli

setEnv:
	cp .envrc.dev .envrc
	direnv allow .

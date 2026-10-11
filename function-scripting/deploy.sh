deploy(){
	local app="$1"
	local environment="$2"
	echo "Deploying $app to $environment"
}
deploy "api" "production"

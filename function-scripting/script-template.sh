#!/bin/bash

set -euo pipefail
log(){
	printf '[%s] %s\n' "$(date '+%F %T')" "$*"
}

validate(){
	command -v docker >/dev/null 2>&1 || {
		echo "DOcker is required" >&2 
		return 1
	}
}

main(){
	validate
	log "Starting work..."
}
main "$@"

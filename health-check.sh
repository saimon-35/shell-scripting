#!/usr/bin/bash
set -uo pipefail
readonly DISK_THRESHOLD=80
readonly URL="${1:-http://localhost:8080/health}"

failures=0
log(){
	local level="$1"
	shift
	printf '[%s] %-5s %s\n'\
		"$(date '+%F %T')"\
		"$level"\
		"$*"
     }


require_command(){
	command -v "$1">/dev/null 2>&1||{
		log ERROR "Required command missing: $1"
		exit 2
	}
}
check_disk(){
	local usage
	usage=$(df -P /|awk 'NR==2 {gsub(/%/,"",$5); print $5}')

	if(( usage >= DISK_THRESHOLD )); then
		log ERROR "Disk usage ${usage}% >= ${DISK_THRESHOLD}%"
		((failures++))
	else
		log INFO "Disk usage ${usage}%"
	fi
}
check_memory(){
	local available
	available=$(free -m | awk '/Mem:/{print $7}')
	log INFO "Available memory: ${available} MB"
}

check_http(){
	local status
	status=$(curl -sS -o /dev/null -w '%{http_code}' "$URL" || true)
	if [[ "$status" == "200" ]]; then
		log INFO "HTTP health check passed: $URL"
	else
		log ERROR "HTTP health check failed: ${status:-request_failed} $URL"
		((failures++))
	fi
}

main(){
	require_command df
	require_command awk
	require_command free
	require_command curl
	log INFO "Starting health check"
	check_disk
	check_memory
	check_http
	if((failures > 0)); then
		log ERROR "$failures check(s) failed"
		return 1
	fi

	log INFO "All checks passed"
}

 main "$@"
 

#!/usr/bin/bash
set -uo pipefail

DISK_THRESHOLD=80
LOG_DIR="logs"
LOG_FILE="$LOG_DIR/health-check.log"
MAX_LOG_SIZE=1048576  # 1 MB

# Global variables
failures=0
JSON_MODE=false
URLS=()
disk_usage=0
memory_available=0
cpu_usage=0

# Argument parsing
for arg in "$@"; do
	case "$arg" in
		--json)
			JSON_MODE=true
			;;
		--threshold=*)
			DISK_THRESHOLD="${arg#*=}"
			;;

		http://*|https://*)
			URLS+=("$arg")
			;;
		*)
			echo "Unknown argument: $arg" >&2
			exit 2
			;;
	esac
done

setup_logging() {
	mkdir -p "$LOG_DIR"

	if [[ -f "$LOG_FILE" ]]; then
		local file_size
		file_size=$(stat -c %s "$LOG_FILE")

		if (( file_size >= MAX_LOG_SIZE )); then
			mv -f "$LOG_FILE" "$LOG_FILE.1"
		fi
	fi

	touch "$LOG_FILE"
}

# Logging function
log() {
	local level="$1"
	shift

	local message

	printf -v message '[%s] %-5s %s' \
		"$(date '+%F %T')" \
		"$level" \
		"$*"

	if [[ "$JSON_MODE" == true ]]; then
		printf '%s\n' "$message" >> "$LOG_FILE"
	else
		printf '%s\n' "$message" | tee -a "$LOG_FILE"
	fi
}

# Check required commands
require_command() {
	command -v "$1" >/dev/null 2>&1 || {
		echo "Required command missing: $1" >&2
			exit 2
		}
	}

# Disk check
check_disk() {
	local usage

	usage=$(df -P / | awk 'NR==2 {gsub(/%/, "", $5); print $5}')

	disk_usage="$usage"

	if (( usage >= DISK_THRESHOLD )); then
		log ERROR "Disk usage ${usage}% >= ${DISK_THRESHOLD}%"
		((failures += 1))
	else
		log INFO "Disk usage ${usage}%"
	fi
}

# Memory check
check_memory() {
	local available

	available=$(free -m | awk '/Mem:/ {print $7}')

	memory_available="$available"

	log INFO "Available memory: ${available} MB"
}

# CPU check
check_cpu() {
	local usage

	usage=$(top -bn5 -d 1 | grep "%Cpu" |
		awk '{
			for (i=1; i<=NF; i++) {
				if ($i ~ /^id/) {
					idle=$(i-1)
					gsub(/,/, "", idle)
					total += idle
					count++
				}
			}
		}
		END {
		if (count > 0)
			printf "%.1f", 100 - (total / count)
		else
			print "0"
		}')

		cpu_usage="$usage"

		log INFO "CPU Usage : ${usage}%"
	}
	# HTTP check
	check_http() {
		    for url in "${URLS[@]}"; do
			            local status

				            status=$(curl -sS -o /dev/null -w '%{http_code}' "$url" 2>/dev/null || true)

					            if [[ "$status" == "200" ]]; then
							                log INFO "HTTP health check passed: $url"
									        else
											            log ERROR "HTTP health check failed: ${status:-request_failed} $url"
												                ((failures += 1))
														        fi
															    done
														    }
# JSON output
json_output() {
	local status="success"

	if (( failures > 0 )); then
		status="failed"
	fi

	printf '{\n'
	printf '  "status": "%s",\n' "$status"
	printf '  "disk_usage": %s,\n' "$disk_usage"
	printf '  "memory_available_mb": %s,\n' "$memory_available"
	printf '  "cpu_usage": %s,\n' "$cpu_usage"
	printf '  "failures": %s\n' "$failures"
	printf '}\n'
}

# Main function
main() {
	setup_logging
	require_command df
	require_command awk
	require_command free
	require_command curl
	require_command grep
	require_command top

	log INFO "Starting health check"

	check_disk
	check_memory
	check_cpu
	check_http

	if [[ "$JSON_MODE" == true ]]; then
		json_output
	else
		if (( failures > 0 )); then
			log ERROR "$failures check(s) failed"
		else
			log INFO "All checks passed"
		fi
	fi

	if (( failures > 0 )); then
		return 1
	fi
}

main "$@"




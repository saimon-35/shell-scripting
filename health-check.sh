#!/usr/bin/bash
set -uo pipefail

readonly DISK_THRESHOLD=80

# Global variables
failures=0
JSON_MODE=false
URL="http://localhost:8080/health"

disk_usage=0
memory_available=0
cpu_usage=0

# Argument parsing
for arg in "$@"; do
    case "$arg" in
        --json)
            JSON_MODE=true
            ;;
        http://*|https://*)
            URL="$arg"
            ;;
        *)
            echo "Unknown argument: $arg" >&2
            exit 2
            ;;
    esac
done

# Logging function
log() {
    local level="$1"
    shift

    if [[ "$JSON_MODE" == false ]]; then
        printf '[%s] %-5s %s\n' \
            "$(date '+%F %T')" \
            "$level" \
            "$*"
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
    local idle
    local usage

    idle=$(top -bn1 | grep "%Cpu" |
        awk '{for (i=1; i<=NF; i++) if ($i ~ /^id/) print $(i-1)}' |
        tr -d ',')

    usage=$(awk -v idle="$idle" 'BEGIN {printf "%.1f", 100 - idle}')

    cpu_usage="$usage"

    log INFO "CPU Usage: ${usage}%"
}

# HTTP check
check_http() {
    local status

    status=$(curl -sS -o /dev/null -w '%{http_code}' "$URL" 2>/dev/null || true)

    if [[ "$status" == "200" ]]; then
        log INFO "HTTP health check passed: $URL"
    else
        log ERROR "HTTP health check failed: ${status:-request_failed} $URL"
        ((failures += 1))
    fi
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




#!/bin/bash
get_host(){
	local server="$1"
	echo "${server:-$(hostname)}"
}
host=$(get_host)
echo "Running on $host"
host=$(get_host "server1")
echo "Running on $host"

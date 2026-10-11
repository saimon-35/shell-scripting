#!/bin/bash
check_url(){
	local url="$1"
	curl -fsS "$url">/dev/null
}
if check_url "https://www.google.com"; then
	echo "PASS"
else
	echo "FAIL"
fi

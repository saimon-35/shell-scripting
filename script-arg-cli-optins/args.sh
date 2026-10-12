#!/bin/bash

echo "Script: $0"
echo "First: ${1:-<none>}"
echo "Count: $#"

for arg in "$@"; do
	echo "Arg: $arg"
done

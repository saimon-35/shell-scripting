#!/bin/bash

command="${1:-}"
shift || true

echo "Command: $command"
echo "Remaining args: $*"

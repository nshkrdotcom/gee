#!/bin/bash
# Quick script to clean any API keys from logs
# This is a simple safety measure for anyone working with the library

# Find any log files in the project
find . -name "*.log" -type f -exec sed -i 's/key=[A-Za-z0-9_\-]\{10,\}/key=*****REDACTED*****/g' {} \;
echo "Logs cleaned of any API keys"
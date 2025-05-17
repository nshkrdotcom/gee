#!/bin/bash
# Simple script to verify a Gemini API key works

if [ -z "$1" ]; then
  echo "Error: API key is required."
  echo "Usage: ./run_api_verification.sh YOUR_API_KEY"
  exit 1
fi

echo "Testing API key: $1"
GEMINI_API_KEY=$1 mix run verify_api_key.exs
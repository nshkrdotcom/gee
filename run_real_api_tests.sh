#!/bin/bash
# Script to run live API tests against the real Gemini API
# This bypasses the Tesla mock system

# Set mode to exit on error
set -e

# Print an explanation message
echo "Running API tests with real API connection..."

# Make sure we have an API key
if [ -z "$GEMINI_API_KEY" ]; then
  echo "ERROR: No GEMINI_API_KEY environment variable found."
  echo "Please set your API key: export GEMINI_API_KEY=your_api_key"
  exit 1
fi

# Force compile to ensure latest code is used
mix deps.get

# Set environment variables to enable live API mode
export GEMINI_LIVE_TEST=true

# Run only the specific API tests
# Include the tag "live_api" to run only the live API tests
mix test test/gemini/api_tests.exs --include live_api
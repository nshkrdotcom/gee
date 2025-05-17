#!/bin/bash
# Run a simple API test that minimizes quota usage

if [ -z "$GEMINI_API_KEY" ]; then
  echo "Error: GEMINI_API_KEY environment variable is not set."
  echo "Usage: GEMINI_API_KEY=your_api_key ./run_simple_test.sh"
  exit 1
fi

echo "Running simple API test with provided API key..."
GEMINI_API_KEY=$GEMINI_API_KEY mix test test/gemini/simple_api_test.exs
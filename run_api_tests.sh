#!/bin/bash
# Run API tests with Gemini 2.0 Flash model

if [ -z "$GEMINI_API_KEY" ]; then
  echo "Error: GEMINI_API_KEY environment variable is not set."
  echo "Usage: GEMINI_API_KEY=your_api_key ./run_api_tests.sh"
  exit 1
fi

echo "Running API tests with gemini-2.0-flash model..."
GEMINI_API_KEY=$GEMINI_API_KEY mix test test/gemini/api_tests.exs
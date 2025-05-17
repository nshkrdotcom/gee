#!/bin/bash
# Run live API tests that require a real Gemini API key

if [ -z "$GEMINI_API_KEY" ]; then
  echo "Error: GEMINI_API_KEY environment variable is not set."
  echo "Usage: GEMINI_API_KEY=your_api_key ./run_live_tests.sh"
  exit 1
fi

echo "Running live API tests with provided API key..."
GEMINI_API_KEY=$GEMINI_API_KEY mix test --only live_api
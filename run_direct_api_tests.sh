#!/bin/bash
# Run tests that make direct API calls to Gemini without using Tesla mocks

if [ -z "$GEMINI_API_KEY" ]; then
  echo "Error: GEMINI_API_KEY environment variable is not set."
  echo "Usage: GEMINI_API_KEY=your_api_key ./run_direct_api_tests.sh"
  exit 1
fi

# Check if httpoison is installed
if ! mix deps | grep -q "httpoison"; then
  echo "Installing httpoison for direct HTTP requests..."
  mix deps.get httpoison
fi

echo "Running direct API tests (bypassing Tesla mocks)..."
GEMINI_API_KEY=$GEMINI_API_KEY mix test test/gemini/real_api_test.exs --trace
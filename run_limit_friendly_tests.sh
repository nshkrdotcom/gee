#!/bin/bash
# Run tests that are less likely to hit API rate limits

if [ -z "$GEMINI_API_KEY" ]; then
  echo "Error: GEMINI_API_KEY environment variable is not set."
  echo "Usage: GEMINI_API_KEY=your_api_key ./run_limit_friendly_tests.sh"
  exit 1
fi

echo "Running rate-limit friendly tests with the provided API key..."
echo "Using model: gemini-1.5-flash (which has higher quotas than pro)"

# Export environment variables for the test
export GEMINI_API_KEY=$GEMINI_API_KEY
export GEMINI_DEFAULT_MODEL="gemini-1.5-flash"

# Run only basic API tests with minimal quota usage
mix test test/gemini/simple_api_test.exs
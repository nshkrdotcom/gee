#!/bin/bash
# Run embedding-specific tests which often have higher quota limits

if [ -z "$GEMINI_API_KEY" ]; then
  echo "Error: GEMINI_API_KEY environment variable is not set."
  echo "Usage: GEMINI_API_KEY=your_api_key ./run_embedding_tests.sh"
  exit 1
fi

echo "Running embedding API tests with provided API key..."
GEMINI_API_KEY=$GEMINI_API_KEY mix test test/gemini/features/embeddings_test.exs
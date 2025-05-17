#!/bin/bash
# Run only basic functionality tests

echo "Running basic functionality tests for Gemini client..."
mix test test/gemini/client_test.exs test/gemini/config_test.exs test/gemini/response_test.exs
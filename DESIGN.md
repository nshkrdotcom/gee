# Design Document: Gemini Elixir Client

## Overview

This document provides a technical overview of the Gemini Elixir client, including its architecture, key components, testing strategy, and API usage.

## Architecture

The Gemini Elixir client is structured as a modular Elixir library, designed to interact with the Google Gemini AI API. Key modules include:

*   **`Gemini`**: This is the main module that provides a high-level interface for interacting with the Gemini API. It exposes functions for generating content, counting tokens, and other operations.
*   **`Gemini.Client`**: This module handles the HTTP communication with the Gemini API. It uses the `Tesla` HTTP client library and manages API key authentication and request formatting.
*   **`Gemini.Config`**: This module manages the client's configuration, including the API key and default model settings. It supports setting the API key via application configuration, environment variables, or a `.env` file.
*   **`Gemini.Response`**: This module is responsible for parsing the responses from the Gemini API.
*   **`Gemini.Error`**: This module defines the error types that can be returned by the client.
*   **`Gemini.Features`**: This namespace contains modules for specific Gemini API features, such as:
    *   `Gemini.Features.Content`: Handles content generation requests.
    *   `Gemini.Features.Embeddings`: Handles text embedding requests.
    *   `Gemini.Features.Streaming`: Handles streaming content generation.
    *   `Gemini.Features.Tools`: Handles function calling.
    *   `Gemini.Features.Multimodal.Images`: Handles multimodal content with images.

## Testing Strategy

The Gemini Elixir client employs a comprehensive testing strategy that includes both mock-based tests and live API tests.

*   **Mock-Based Tests**: These tests use the `Tesla.Mock` adapter to simulate API responses. This allows for fast and reliable testing without requiring a real API key or network connection. The `Gemini.Test.MockClient` module provides helper functions for setting up mock responses.
*   **Live API Tests**: These tests interact with the real Gemini API. They require a valid API key and a network connection. Live API tests are tagged with the `:live_api` tag and can be run selectively using the `mix test --only live_api` command.

The test suite includes tests for:

*   Basic API functionality (e.g., generating content, counting tokens)
*   Error handling
*   Configuration
*   Live API connectivity

## Shell Scripts

The project includes several shell scripts for running tests:

*   **`run_api_tests.sh`**: Runs API tests using the `gemini-2.0-flash` model. Requires the `GEMINI_API_KEY` environment variable to be set.
*   **`run_mock_tests.sh`**: Runs all mock-based tests. Does not require an API key.
*   **`run_live_tests.sh`**: Runs live API tests. Requires the `GEMINI_API_KEY` environment variable to be set.
*   **`run_api_verification.sh`**: Verifies that a given API key is valid by making a simple API request.

## API Usage

The `Gemini` module provides a simple and intuitive API for interacting with the Gemini API. Here are some examples:

*   **Generating Content**:

    ```elixir
    {:ok, response} = Gemini.generate_content("Tell me a short story about robots.")
    IO.puts(response.text)
    ```

*   **Generating Content with Images**:

    ```elixir
    {:ok, response} = Gemini.generate_with_images(
      "What's in this image?",
      ["path/to/image.jpg"]
    )
    IO.puts(response.text)
    ```

*   **Counting Tokens**:

    ```elixir
    {:ok, token_count} = Gemini.count_tokens("Hello, world!")
    IO.puts("Token count: #{token_count}")
    ```

*   **Streaming Content Generation**:

    ```elixir
    {:ok, final_response} = Gemini.stream_content(
      "Generate a poem about programming",
      fn chunk ->
        IO.write(chunk.text)
      end
    )
    ```

## Key Considerations

*   **API Key Security**: The `Gemini.Client` module uses a `SecureLogger` to prevent API keys from being leaked in logs.
*   **Error Handling**: The client provides detailed error messages and logging to help diagnose issues.
*   **Live API Testing**: Live API tests should be run carefully to avoid exceeding API usage limits.

## Future Improvements

*   Add support for more Gemini API features.
*   Improve error handling and logging.
*   Add more comprehensive documentation.
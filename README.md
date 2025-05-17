# Gemini

An Elixir client library for Google's Gemini AI API, providing comprehensive access to the Gemini AI Studio features.

## Installation

This package can be installed by adding `gemini` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:gemini, "~> 0.1.0"}
  ]
end
```

## API Key

To use this library, you'll need a Google AI Studio API key. You can configure it in your application:

```elixir
# In your config/config.exs
config :gemini,
  api_key: "your_api_key"

# Or set it at runtime
Gemini.Config.set_api_key("your_api_key")
```

## Basic Usage

```elixir
# Generate text content
{:ok, response} = Gemini.generate_content("Tell me about the Elixir programming language")
IO.puts(response.text)

# Use structured output
schema = %{
  "type" => "object",
  "properties" => %{
    "pros" => %{
      "type" => "array",
      "items" => %{"type" => "string"}
    },
    "cons" => %{
      "type" => "array", 
      "items" => %{"type" => "string"}
    }
  }
}

{:ok, response} = Gemini.generate_content(
  "Compare Elixir and Ruby programming languages",
  structured_output: schema
)

IO.inspect(response.structured)
```

## Project Structure

The Gemini client library is organized into the following structure:

```
gemini/
├── lib/
│   ├── gemini.ex                    # Main entry point
│   └── gemini/
│       ├── client.ex                # HTTP client handling
│       ├── config.ex                # Configuration management
│       ├── error.ex                 # Error types and handling
│       ├── models.ex                # Model definitions and utilities
│       ├── response.ex              # Response parsing and handling
│       ├── features/                # Feature-specific modules
│       │   ├── content.ex           # Content generation
│       │   ├── streaming.ex         # Streaming responses
│       │   ├── embeddings.ex        # Embeddings generation
│       │   ├── tools.ex             # Function calling / tools
│       │   ├── multimodal/          # Multimodal capabilities
│       │   │   ├── images.ex        # Image processing
│       │   │   ├── audio.ex         # Audio processing
│       │   │   ├── video.ex         # Video processing
│       │   │   └── utils.ex         # Utilities for multimodal
│       │   └── chat/                # Chat features
│       │       ├── session.ex       # Chat session management
│       │       └── history.ex       # History management
│       ├── safety.ex                # Safety settings and handling
│       ├── token_counter.ex         # Token counting utilities
│       └── utils/                   # General utilities
│           ├── json.ex              # JSON handling
│           ├── mime.ex              # MIME type helpers
│           └── validation.ex        # Input validation
├── test/                            # Test files mirroring lib structure
│   ├── gemini_test.exs
│   └── gemini/
│       ├── client_test.exs
│       ├── config_test.exs
│       ├── features/
│       │   ├── content_test.exs
│       │   └── ...
│       └── ...
├── .formatter.exs
├── .gitignore
├── mix.exs
└── README.md
```

## Development Phases

This library is being developed in phases:

1. **Phase 1**: Core functionality - Text generation with generateContent
   - HTTP client infrastructure
   - Basic text generation
   - Configuration and error handling
   - Unit tests for core functionality

2. **Phase 2**: Structured output, system instructions, and safety settings
   - Schema validation for structured output
   - System instruction handling
   - Safety settings configuration
   - Expanded tests

3. **Phase 3**: Streaming and embeddings
   - Streaming content generation using dedicated gen_server
   - Embeddings API support
   - Additional test coverage

4. **Phase 4**: Advanced features
   - Function calling / tools integration
   - Chat session management
   - Comprehensive examples
   - Complete documentation

5. **Phase 5**: Multimodal support (images, audio, video)
   - Image input/output handling
   - Audio processing
   - Video processing
   - Examples and documentation

## Documentation

Full documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc) by running:

```
mix docs
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

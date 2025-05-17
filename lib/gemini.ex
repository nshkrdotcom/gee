defmodule Gemini do
  @moduledoc """
  Client for Google's Gemini AI API.

  This module provides a high-level interface for interacting with Google's Gemini AI models.
  """

  # Client alias moved to specific functions where needed
  alias Gemini.Config
  alias Gemini.Features
  alias Gemini.Features.Multimodal
  alias Gemini.Features.Content
  alias Gemini.Features.Streaming
  alias Gemini.Features.Embeddings

  @doc """
  Generates content from a text prompt using the Gemini API.

  ## Parameters

    * `prompt` - A string containing the text prompt to send to the model.
    * `opts` - A keyword list of options. Supported options:
      * `:model` - The model to use (defaults to config setting).
      * `:temperature` - Controls randomness in responses (0.0 to 1.0).
      * `:top_p` - Control diversity via nucleus sampling (0.0 to 1.0).
      * `:top_k` - Control diversity by limiting to top K tokens (1 to 40).
      * `:max_tokens` - The maximum number of tokens to generate.
      * `:structured_output` - JSON schema for structured output.
      * `:system_instruction` - System instructions for the model.
      * `:safety_settings` - List of safety settings to apply.
      * `:tools` - List of tool definitions for function calling.

  ## Examples

      {:ok, response} = Gemini.generate_content("Tell me a short story about robots.")
      IO.puts(response.text)

      # With structured output
      schema = %{
        "type" => "object",
        "properties" => %{
          "title" => %{"type" => "string"},
          "summary" => %{"type" => "string"}
        }
      }
      {:ok, response} = Gemini.generate_content("Summarize this article", structured_output: schema)
      IO.inspect(response.structured)
  """
  @spec generate_content(String.t(), keyword()) :: {:ok, Gemini.Response.t()} | {:error, Gemini.Error.t()}
  def generate_content(prompt, opts \\ []) do
    model = Keyword.get(opts, :model, Config.default_model())
    temperature = Keyword.get(opts, :temperature)
    top_p = Keyword.get(opts, :top_p)
    top_k = Keyword.get(opts, :top_k)
    max_tokens = Keyword.get(opts, :max_tokens)
    structured_output = Keyword.get(opts, :structured_output)
    system_instruction = Keyword.get(opts, :system_instruction)
    safety_settings = Keyword.get(opts, :safety_settings)
    tools = Keyword.get(opts, :tools)

    # Create content from prompt
    content = Content.content_from_text(prompt)

    # Build request parameters
    params = Content.prepare_params(
      temperature: temperature,
      top_p: top_p,
      top_k: top_k,
      max_tokens: max_tokens,
      structured_output: structured_output,
      system_instruction: system_instruction,
      safety_settings: safety_settings
    )
    
    # Add tools if provided
    params = if tools, do: Features.Tools.add_tools_to_params(params, tools), else: params
    
    # Generate content
    Content.generate(model, [content], params)
  end

  @doc """
  Generates content with multimodal inputs (text and images).

  ## Parameters

    * `text` - Text prompt to send to the model.
    * `image_paths` - List of image file paths to include.
    * `opts` - Additional options, same as `generate_content/2`.

  ## Examples

      {:ok, response} = Gemini.generate_with_images(
        "What's in this image?", 
        ["path/to/image.jpg"]
      )
      IO.puts(response.text)
  """
  @spec generate_with_images(String.t(), list(String.t()), keyword()) :: {:ok, Gemini.Response.t()} | {:error, Gemini.Error.t()}
  def generate_with_images(text, image_paths, opts \\ []) do
    model = Keyword.get(opts, :model, Config.default_model())
    
    # Create image parts from paths
    image_parts = Enum.map(image_paths, &Multimodal.Images.image_part_from_file/1)
    
    # Create multimodal content
    multimodal_content = Multimodal.Images.create_multimodal_content(text, image_parts)
    
    # Prepare parameters
    params = Content.prepare_params(
      temperature: Keyword.get(opts, :temperature),
      top_p: Keyword.get(opts, :top_p),
      top_k: Keyword.get(opts, :top_k),
      max_tokens: Keyword.get(opts, :max_tokens),
      structured_output: Keyword.get(opts, :structured_output),
      system_instruction: Keyword.get(opts, :system_instruction),
      safety_settings: Keyword.get(opts, :safety_settings)
    )
    
    # Generate content
    Content.generate(model, [multimodal_content], params)
  end

  @doc """
  Counts tokens in text using the Gemini API.

  ## Parameters

    * `text` - The text to count tokens for.
    * `model` - The model to use (optional, uses default).

  ## Examples

      {:ok, token_count} = Gemini.count_tokens("Hello, world!")
      IO.puts("Token count: \#{token_count}")
  """
  @spec count_tokens(String.t(), String.t() | nil) :: {:ok, integer()} | {:error, Gemini.Error.t()}
  def count_tokens(text, model \\ nil) do
    Gemini.TokenCounter.count_tokens(text, model)
  end

  @doc """
  Creates a tool definition for function calling.

  ## Parameters

    * `name` - The name of the function to call.
    * `description` - A description of what the function does.
    * `parameters` - The JSON schema for parameters.
    * `required_parameters` - List of required parameter names.

  ## Examples

      weather_tool = Gemini.create_tool(
        "get_weather",
        "Get the current weather for a location",
        %{
          "type" => "object",
          "properties" => %{
            "location" => %{"type" => "string"}
          }
        },
        ["location"]
      )
  """
  @spec create_tool(String.t(), String.t(), map(), list(String.t())) :: map()
  def create_tool(name, description, parameters, required_parameters \\ []) do
    Features.Tools.define_tool(name, description, parameters, required_parameters)
  end

  @doc """
  Extract function calls from a response.

  ## Parameters

    * `response` - The Gemini API response.

  ## Examples

      {:ok, response} = Gemini.generate_content("What's the weather in Paris?", tools: [weather_tool])
      function_calls = Gemini.extract_function_calls(response)
  """
  @spec extract_function_calls(Gemini.Response.t()) :: list(map())
  def extract_function_calls(response) do
    Features.Tools.extract_function_calls(response)
  end

  @doc """
  Stream content generation with a callback function.

  This allows processing the response as it's being generated, rather than waiting
  for the complete response.

  ## Parameters

    * `prompt` - The prompt to stream responses for.
    * `callback` - Function to call with each chunk of the response.
    * `opts` - Options to pass to the API (same as generate_content/2).

  ## Examples

      {:ok, final_response} = Gemini.stream_content(
        "Generate a poem about programming",
        fn chunk -> 
          IO.write(chunk.text)
        end
      )
  """
  @spec stream_content(String.t(), function(), keyword()) :: {:ok, Gemini.Response.t()} | {:error, Gemini.Error.t()}
  def stream_content(prompt, callback, opts \\ []) when is_function(callback, 1) do
    Streaming.stream_content(prompt, callback, opts)
  end

  @doc """
  Generate embeddings for text.

  Embeddings are vector representations of text that capture semantic meaning,
  useful for semantic search, clustering, and other ML applications.

  ## Parameters

    * `text` - The text to generate embeddings for.
    * `opts` - Options for embedding generation:
      * `:model` - The embedding model to use (defaults to "embedding-001").
      * `:task_type` - The type of task the embeddings will be used for.

  ## Examples

      {:ok, vector} = Gemini.embed_text("Programming in Elixir is fun!")
      vector_dimension = length(vector)
  """
  @spec embed_text(String.t(), keyword()) :: {:ok, list(float())} | {:error, Gemini.Error.t()}
  def embed_text(text, opts \\ []) do
    model = Keyword.get(opts, :model, "embedding-001")
    task_type = Keyword.get(opts, :task_type)
    
    Embeddings.embed_text(text, model, task_type)
  end

  @doc """
  Calculate similarity between two texts using embeddings.

  This is a convenience function that generates embeddings for both texts
  and computes their cosine similarity.

  ## Parameters

    * `text1` - First text.
    * `text2` - Second text.
    * `opts` - Options for embedding generation.

  ## Returns

    * `{:ok, similarity}` with a float between -1 and 1 (1 being most similar).
    * `{:error, error}` if embedding generation failed.

  ## Examples

      {:ok, similarity} = Gemini.text_similarity("cats", "dogs")
      IO.puts("Similarity: \#{similarity}")
  """
  @spec text_similarity(String.t(), String.t(), keyword()) :: {:ok, float()} | {:error, Gemini.Error.t()}
  def text_similarity(text1, text2, opts \\ []) do
    with {:ok, embedding1} <- embed_text(text1, opts),
         {:ok, embedding2} <- embed_text(text2, opts) do
      {:ok, Embeddings.cosine_similarity(embedding1, embedding2)}
    end
  end

  @doc """
  Batch process multiple texts to generate embeddings for each.

  This is useful when you need to generate embeddings for a collection of texts.

  ## Parameters

    * `texts` - List of texts to generate embeddings for.
    * `opts` - Options for embedding generation.

  ## Examples

      {:ok, vectors} = Gemini.batch_embed_text(["Hello", "World", "Elixir"])
      Enum.each(vectors, &IO.inspect/1)
  """
  @spec batch_embed_text(list(String.t()), keyword()) :: {:ok, list(list(float()))} | {:error, Gemini.Error.t()}
  def batch_embed_text(texts, opts \\ []) when is_list(texts) do
    model = Keyword.get(opts, :model, "embedding-001")
    task_type = Keyword.get(opts, :task_type)
    
    Embeddings.batch_embed(texts, model, task_type)
  end
end

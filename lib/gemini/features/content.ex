defmodule Gemini.Features.Content do
  @moduledoc """
  Module for handling content generation features of the Gemini API.

  This module provides functions to interact with the content generation
  capabilities of Gemini models.
  """

  alias Gemini.Client

  @doc """
  Constructs a content object with text parts.

  ## Parameters

    * `text` - String or list of strings to convert to content parts.

  ## Returns

    * A map representing the content object with parts.
  """
  @spec content_from_text(String.t() | [String.t()]) :: map()
  def content_from_text(text) when is_binary(text) do
    %{
      "parts" => [
        %{
          "text" => text
        }
      ]
    }
  end

  def content_from_text(texts) when is_list(texts) do
    parts = Enum.map(texts, fn text ->
      %{"text" => text}
    end)

    %{
      "parts" => parts
    }
  end

  @doc """
  Prepares parameters for generating content.

  ## Parameters

    * `opts` - Keyword list of options to include in the parameters.

  ## Returns

    * A map of parameters for the API request.
  """
  @spec prepare_params(keyword()) :: map()
  def prepare_params(opts \\ []) do
    temperature = Keyword.get(opts, :temperature)
    top_p = Keyword.get(opts, :top_p)
    top_k = Keyword.get(opts, :top_k)
    max_tokens = Keyword.get(opts, :max_tokens)
    structured_output = Keyword.get(opts, :structured_output)
    system_instruction = Keyword.get(opts, :system_instruction)
    safety_settings = Keyword.get(opts, :safety_settings)

    # Build request parameters
    params = %{}
    
    # Build generation config
    generation_config = %{}
    generation_config = if temperature, do: Map.put(generation_config, "temperature", temperature), else: generation_config
    generation_config = if top_p, do: Map.put(generation_config, "topP", top_p), else: generation_config
    generation_config = if top_k, do: Map.put(generation_config, "topK", top_k), else: generation_config
    generation_config = if max_tokens, do: Map.put(generation_config, "maxOutputTokens", max_tokens), else: generation_config
    
    # Add structured output schema if provided
    generation_config = if structured_output do
      Map.put(generation_config, "structuredOutputSchema", structured_output)
    else
      generation_config
    end
    
    # Add generationConfig to params if we have any config values
    params = if map_size(generation_config) > 0 do
      Map.put(params, "generationConfig", generation_config)
    else
      params
    end

    # Add system instructions if provided
    params = if system_instruction do
      system_content = content_from_text(system_instruction)
      Map.put(params, "systemInstruction", system_content)
    else
      params
    end

    # Add safety settings if provided
    params = if safety_settings, do: Map.put(params, "safetySettings", safety_settings), else: params
    
    params
  end

  @doc """
  Generate content with a model.

  ## Parameters

    * `model` - The model name to use for generation.
    * `contents` - The content objects to use as input.
    * `opts` - Additional parameters for the API.

  ## Returns

    * `{:ok, response}` or `{:error, error}`.

  ## Example
  
      model = "gemini-2.0-flash"
      content = Gemini.Features.Content.content_from_text("Hello")
      params = Gemini.Features.Content.prepare_params(temperature: 0.7)
      Gemini.Features.Content.generate(model, [content], params)
  """
  @spec generate(String.t(), list(map()), map()) :: {:ok, Gemini.Response.t()} | {:error, Gemini.Error.t()}
  def generate(model, contents, params \\ %{}) do
    params = Map.put(params, "contents", contents)
    Client.generate_content(model, params)
  end
end
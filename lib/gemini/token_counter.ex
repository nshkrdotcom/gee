defmodule Gemini.TokenCounter do
  @moduledoc """
  Utilities for counting tokens in content for the Gemini API.
  
  This module provides functions to estimate and get accurate token counts
  for different types of content, which is useful for managing context 
  length limits.
  """

  alias Gemini.Client

  @doc """
  Count tokens in text using the Gemini API.
  
  This makes a request to the Gemini API to get an accurate count of tokens
  for the given text content.
  
  ## Parameters
  
    * `text` - The text to count tokens for.
    * `model` - The model to use for token counting (optional, uses default model).
  
  ## Returns
  
    * `{:ok, token_count}` with the number of tokens, or
    * `{:error, error}` if the request failed.
  
  ## Examples
  
      {:ok, token_count} = Gemini.TokenCounter.count_tokens("Hello, world!")
      IO.puts("Token count: \#{token_count}")
  """
  @spec count_tokens(String.t(), String.t() | nil) :: {:ok, integer()} | {:error, Gemini.Error.t()}
  def count_tokens(text, model \\ nil) do
    model = model || Gemini.Config.default_model()
    
    content = %{
      "parts" => [
        %{
          "text" => text
        }
      ]
    }
    
    params = %{
      "contents" => [content]
    }
    
    case Client.count_tokens(model, params) do
      {:ok, response} ->
        total_tokens = get_in(response.raw, ["totalTokens"])
        {:ok, total_tokens}
        
      {:error, error} ->
        {:error, error}
    end
  end
  
  @doc """
  Estimate the number of tokens in text without making an API call.
  
  This method provides a rough estimate based on typical token patterns.
  It's useful for quick estimations when an API call isn't necessary.
  
  ## Parameters
  
    * `text` - The text to estimate token count for.
  
  ## Returns
  
    * An integer estimate of the token count.
  
  ## Examples
  
      token_count = Gemini.TokenCounter.estimate_tokens("Hello, world!")
      IO.puts("Estimated token count: \#{token_count}")
  """
  @spec estimate_tokens(String.t()) :: integer()
  def estimate_tokens(text) do
    # Simple estimation based on typical token patterns
    # For more precise counts, use count_tokens/2
    
    # Rough estimation: ~1.3 tokens per word in English
    words = text |> String.split(~r/\s+/) |> Enum.count()
    
    # Round up to the nearest token
    round(words * 1.3)
  end
  
  @doc """
  Checks if content is likely to fit within a token limit.
  
  ## Parameters
  
    * `text` - The text to check.
    * `limit` - The token limit to check against.
    * `buffer` - Buffer tokens to subtract from the limit (default 50).
  
  ## Returns
  
    * `true` if the content is likely to fit within the limit.
    * `false` if the content is likely to exceed the limit.
  
  ## Examples
  
      if Gemini.TokenCounter.within_limit?("Long text...", 2048) do
        # Content likely fits within limit
      else
        # Content likely exceeds limit
      end
  """
  @spec within_limit?(String.t(), integer(), integer()) :: boolean()
  def within_limit?(text, limit, buffer \\ 50) do
    estimate_tokens(text) <= (limit - buffer)
  end
  
  @doc """
  Estimate the token count for common media types.
  
  This provides rough estimates for images, audio, and video based on 
  the documentation from Google.
  
  ## Parameters
  
    * `type` - Media type (:image, :audio, or :video).
    * `duration_seconds` - For :audio and :video, the duration in seconds.
  
  ## Returns
  
    * An integer estimate of the token count.
  
  ## Examples
  
      image_tokens = Gemini.TokenCounter.estimate_media_tokens(:image)
      audio_tokens = Gemini.TokenCounter.estimate_media_tokens(:audio, 60)  # 1 minute
  """
  @spec estimate_media_tokens(atom(), number() | nil) :: integer()
  def estimate_media_tokens(type, duration_seconds \\ nil)
  
  def estimate_media_tokens(:image, _) do
    # Typical token usage for an image
    # ~260 tokens for a 1024x1024 image
    260
  end
  
  def estimate_media_tokens(:audio, duration_seconds) when is_number(duration_seconds) do
    # 32 tokens per second of audio
    round(duration_seconds * 32)
  end
  
  def estimate_media_tokens(:video, duration_seconds) when is_number(duration_seconds) do
    # Estimated tokens for video
    # ~32 tokens per second + token overhead for each frame
    round(duration_seconds * 40)
  end
end
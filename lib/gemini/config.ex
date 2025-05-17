defmodule Gemini.Config do
  @moduledoc """
  Configuration module for the Gemini client.
  
  This module provides functions for getting and setting configuration options
  for the Gemini client, including API keys and model settings.
  
  ## API Key Priority
  
  When retrieving the API key, the module checks the following sources in order:
  
  1. Application configuration (set via `set_api_key/1`)
  2. `GEMINI_API_KEY` environment variable
  3. `GOOGLE_API_KEY` environment variable
  4. `.env` file in the project root containing either `GEMINI_API_KEY` or `GOOGLE_API_KEY`
  
  If no API key is found, `nil` is returned.
  """

  @app :gemini
  @default_model "gemini-2.0-flash"
  @env_file ".env"

  @doc """
  Gets the API key using a cascade of fallbacks.
  
  Checks in order:
  1. Application environment
  2. GEMINI_API_KEY environment variable
  3. GOOGLE_API_KEY environment variable
  4. GEMINI_API_KEY in .env file
  5. GOOGLE_API_KEY in .env file
  
  Returns nil if no key is found.
  """
  @spec api_key() :: String.t() | nil
  def api_key do
    Application.get_env(@app, :api_key) ||
      get_env_var("GEMINI_API_KEY") ||
      get_env_var("GOOGLE_API_KEY") ||
      get_env_file_var("GEMINI_API_KEY") ||
      get_env_file_var("GOOGLE_API_KEY")
  end

  @doc """
  Sets the API key in the application configuration.
  """
  @spec set_api_key(String.t() | nil) :: :ok
  def set_api_key(key) when is_binary(key) do
    Application.put_env(@app, :api_key, key)
  end
  
  def set_api_key(nil) do
    # Handle nil case gracefully to avoid errors in tests
    :ok
  end

  @doc """
  Gets the default model from the application configuration.
  If not set, returns the default value.
  """
  @spec default_model() :: String.t()
  def default_model do
    Application.get_env(@app, :default_model, @default_model)
  end

  @doc """
  Sets the default model in the application configuration.
  """
  @spec set_default_model(String.t()) :: :ok
  def set_default_model(model) when is_binary(model) do
    Application.put_env(@app, :default_model, model)
  end
  
  # Helper function to get environment variables
  defp get_env_var(name) do
    System.get_env(name)
  end
  
  # Helper function to read variables from .env file
  defp get_env_file_var(name) do
    case File.read(@env_file) do
      {:ok, content} ->
        case extract_var_from_env_content(content, name) do
          nil -> nil
          value -> String.trim(value)
        end
      _ -> nil
    end
  end
  
  # Helper to extract a variable from .env file content
  defp extract_var_from_env_content(content, name) do
    pattern = ~r/#{name}=([^\r\n]+)/
    
    case Regex.run(pattern, content) do
      [_, value] -> value
      _ -> nil
    end
  end
end

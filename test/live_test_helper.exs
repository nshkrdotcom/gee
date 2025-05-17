defmodule LiveTestHelper do
  @moduledoc """
  Helper module for running tests against the live Gemini API.
  Provides utilities for handling API keys, configuring live HTTP clients,
  and managing rate limits.
  """
  
  require Logger
  
  @doc """
  Enables live API mode for the current process.
  This overrides the default test behavior of using mocks.
  """
  def enable_live_api do
    # Set a process dictionary flag to indicate live API mode
    Process.put(:use_live_api, true)
    :ok
  end
  
  @doc """
  Disables live API mode for the current process.
  """
  def disable_live_api do
    Process.delete(:use_live_api)
    :ok
  end
  
  @doc """
  Gets the API key from environment variables.
  """
  def get_api_key do
    System.get_env("GEMINI_API_KEY")
  end
  
  @doc """
  Handles rate limit errors by skipping tests if needed.
  """
  def handle_rate_limit_error(response) do
    if is_rate_limit_error?(response) do
      Logger.warning("Rate limit exceeded during live API test. Skipping test.")
      # Use a standard approach instead of skip
      {:error, :rate_limit_exceeded}
    else
      response
    end
  end
  
  @doc """
  Checks if a response indicates a rate limit error.
  """
  def is_rate_limit_error?(response) do
    case response do
      {:error, %{code: 429}} -> true
      {:error, %{message: message}} when is_binary(message) ->
        String.contains?(message, "rate limit") or
        String.contains?(message, "quota exceed")
      _ -> false
    end
  end
  
  @doc """
  Creates a test setup for live API tests.
  This performs necessary setup and checks API key availability.
  """
  def setup_live_api_test(context) do
    # Enable live API mode
    enable_live_api()
    
    # Get API key
    api_key = get_api_key()
    
    # Skip the test if no API key is available
    if is_nil(api_key) or api_key == "" do
      Logger.warning("No API key available for live API tests. Tests will be skipped.")
      
      # For ExUnit compatibility, return a map with api_key: nil instead of using :skip
      # This addresses the error in live tests where {:skip, reason} is not properly handled
      {:ok, Map.put(context, :api_key, nil)}
    else
      # Add API key to context for tests
      {:ok, Map.put(context, :api_key, api_key)}
    end
  end
  
  @doc """
  Creates a test setup for real API tests.
  Similar to setup_live_api_test but specifically for direct real API tests.
  """
  def setup_real_api_test do
    # Enable live API mode
    enable_live_api()
    
    # Get API key
    api_key = get_api_key()
    
    # Skip the test if no API key is available
    if is_nil(api_key) or api_key == "" do
      Logger.warning("No API key available for real API tests. Tests will be skipped.")
      # For ExUnit compatibility, return a map with api_key: nil
      {:ok, %{api_key: nil}}
    else
      # Add API key to context for tests
      {:ok, %{api_key: api_key}}
    end
  end

  @doc """
  Tears down the live API test environment.
  """
  def teardown_live_api_test(_context) do
    disable_live_api()
    :ok
  end
end
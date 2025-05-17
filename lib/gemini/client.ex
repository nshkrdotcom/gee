defmodule Gemini.Client do
  @moduledoc """
  HTTP client for making requests to the Gemini API.
  """

  use Tesla

  alias Gemini.Config
  alias Gemini.Response

  @base_url "https://generativelanguage.googleapis.com/v1"

  plug Tesla.Middleware.JSON
  plug Tesla.Middleware.PathParams
  # We'll use our own SecureLogger instead of Tesla's default Logger
  # to prevent API key leaks in logs

  @doc """
  Creates a new client with the given API key.
  If no API key is provided, it will use the one from the configuration.
  """
  def new(api_key \\ nil) do
    key = api_key || Config.api_key()

    middleware = [
      {Tesla.Middleware.BaseUrl, @base_url},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Query, [key: key]},
      Gemini.SecureLogger
    ]

    # Check if this is a live test or a mock test
    is_live_test = System.get_env("GEMINI_LIVE_TEST") == "true" || 
                   Process.get(:use_live_api, false)
    
    # Use different adapter depending on environment and live test flag
    adapter = if Mix.env() == :test && !is_live_test do
      # For normal tests, use mock adapter
      Tesla.Mock
    else
      # For production or live tests, use real HTTP client
      {Tesla.Adapter.Hackney, [recv_timeout: 30_000]}
    end

    Tesla.client(middleware, adapter)
  end

  @doc """
  Makes a request to the Gemini API to generate content.
  """
  @spec generate_content(String.t(), map()) :: {:ok, Response.t()} | {:error, map()}
  def generate_content(model, params) do
    client = new()
    test_context = Process.get(:test_context, %{module: "Unknown", test: "Unknown"})
    
    # Log request with masked parameters (no API key)
    require Logger
    Logger.debug("""
    [GENERATE_CONTENT REQUEST] 
    Context: #{test_context.module} - #{test_context.test}
    Model: #{model}
    Params: #{inspect(params, pretty: true)}
    """)

    # Disable Tesla's built-in logging temporarily to avoid leaking API keys
    original_tesla_logger = Application.get_env(:tesla, :logger, false)
    Application.put_env(:tesla, :logger, false)
    
    result = post(client, "/models/:model:generateContent", params, opts: [path_params: [model: model]])
    
    # Restore original logger setting
    Application.put_env(:tesla, :logger, original_tesla_logger)
    
    case result do
      {:ok, %{status: 200, body: body}} ->
        {:ok, Response.parse(body)}
        
      {:ok, %{status: status, body: body}} ->
        message = get_in(body, ["error", "message"]) || "Unknown error"
        
        # Enhanced error logging
        Logger.error("""
        [GENERATE_CONTENT ERROR]
        Context: #{test_context.module} - #{test_context.test}
        Status: #{status}
        Message: #{message}
        Model: #{model}
        Params: #{inspect(params, pretty: true)}
        Response: #{inspect(body, pretty: true)}
        """)
        
        {:error, %{message: message, code: status, details: body}}

      {:error, reason} ->
        # Enhanced error logging for connection failures
        Logger.error("""
        [GENERATE_CONTENT CONNECTION ERROR]
        Context: #{test_context.module} - #{test_context.test}
        Reason: #{inspect(reason)}
        Model: #{model}
        Params: #{inspect(params, pretty: true)}
        """)
        
        {:error, %{message: "Request failed", code: 0, details: reason}}
    end
  end

  @doc """
  Makes a request to embed content using the Gemini API.
  """
  @spec embed_content(String.t(), map()) :: {:ok, Response.t()} | {:error, map()}
  def embed_content(model, params) do
    client = new()
    test_context = Process.get(:test_context, %{module: "Unknown", test: "Unknown"})
    
    require Logger
    Logger.debug("""
    [EMBED_CONTENT REQUEST] 
    Context: #{test_context.module} - #{test_context.test}
    Model: #{model}
    Params: #{inspect(params, pretty: true)}
    """)

    with {:ok, %{status: 200, body: body}} <-
           post(client, "/models/:model:embedContent", params, opts: [path_params: [model: model]]) do
      {:ok, Response.parse(body)}
    else
      {:ok, %{status: status, body: body}} ->
        message = get_in(body, ["error", "message"]) || "Unknown error"
        
        # Enhanced error logging
        Logger.error("""
        [EMBED_CONTENT ERROR]
        Context: #{test_context.module} - #{test_context.test}
        Status: #{status}
        Message: #{message}
        Model: #{model}
        Params: #{inspect(params, pretty: true)}
        Response: #{inspect(body, pretty: true)}
        """)
        
        {:error, %{message: message, code: status, details: body}}

      {:error, reason} ->
        # Enhanced error logging for connection failures
        Logger.error("""
        [EMBED_CONTENT CONNECTION ERROR]
        Context: #{test_context.module} - #{test_context.test}
        Reason: #{inspect(reason)}
        Model: #{model}
        Params: #{inspect(params, pretty: true)}
        """)
        
        {:error, %{message: "Request failed", code: 0, details: reason}}
    end
  end

  @doc """
  Counts tokens for a given content using the Gemini API.
  """
  @spec count_tokens(String.t(), map()) :: {:ok, Response.t()} | {:error, map()}
  def count_tokens(model, params) do
    client = new()
    test_context = Process.get(:test_context, %{module: "Unknown", test: "Unknown"})
    
    require Logger
    Logger.debug("""
    [COUNT_TOKENS REQUEST] 
    Context: #{test_context.module} - #{test_context.test}
    Model: #{model}
    Params: #{inspect(params, pretty: true)}
    """)

    with {:ok, %{status: 200, body: body}} <-
           post(client, "/models/:model:countTokens", params, opts: [path_params: [model: model]]) do
      {:ok, Response.parse(body)}
    else
      {:ok, %{status: status, body: body}} ->
        message = get_in(body, ["error", "message"]) || "Unknown error"
        
        # Enhanced error logging
        Logger.error("""
        [COUNT_TOKENS ERROR]
        Context: #{test_context.module} - #{test_context.test}
        Status: #{status}
        Message: #{message}
        Model: #{model}
        Params: #{inspect(params, pretty: true)}
        Response: #{inspect(body, pretty: true)}
        """)
        
        {:error, %{message: message, code: status, details: body}}

      {:error, reason} ->
        # Enhanced error logging for connection failures
        Logger.error("""
        [COUNT_TOKENS CONNECTION ERROR]
        Context: #{test_context.module} - #{test_context.test}
        Reason: #{inspect(reason)}
        Model: #{model}
        Params: #{inspect(params, pretty: true)}
        """)
        
        {:error, %{message: "Request failed", code: 0, details: reason}}
    end
  end
end

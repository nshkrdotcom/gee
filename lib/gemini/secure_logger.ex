defmodule Gemini.SecureLogger do
  @moduledoc """
  Secure logger middleware for Tesla.
  Masks sensitive information like API keys before logging.
  """
  
  require Logger
  
  def call(env, next, _options) do
    # Create a sanitized version of the environment for logging before any processing
    sanitized_env = sanitize_env(env)
    
    # Log the sanitized request
    if Mix.env() == :test do
      test_context = Process.get(:test_context, %{module: "Unknown", test: "Unknown"})
      log_test_request(sanitized_env, test_context)
    else
      log_request(sanitized_env)
    end
    
    # Process the request with logging disabled to prevent key leaks
    original_logger_level = Logger.level()
    original_tesla_logger = Application.get_env(:tesla, :logger, false)
    
    # Temporarily disable all logging during the actual request to prevent leaking
    Logger.configure(level: :error)
    Application.put_env(:tesla, :logger, false)
    
    result = Tesla.run(env, next)
    
    # Restore original logging settings
    Logger.configure(level: original_logger_level)
    Application.put_env(:tesla, :logger, original_tesla_logger)
    
    case result do
      {:ok, response} ->
        # Create sanitized response
        sanitized_response = sanitize_response(response)
        
        # Log the sanitized response
        if Mix.env() == :test do
          test_context = Process.get(:test_context, %{module: "Unknown", test: "Unknown"})
          log_test_response(sanitized_response, test_context)
        else
          log_response(sanitized_response)
        end
        {:ok, response}
        
      {:error, error} ->
        # Log the sanitized error
        if Mix.env() == :test do
          test_context = Process.get(:test_context, %{module: "Unknown", test: "Unknown"})
          log_test_error(sanitized_env, error, test_context)
        else
          log_error(sanitized_env, error)
        end
        {:error, error}
    end
  end
  
  # Sanitize environment by masking sensitive data
  def sanitize_env(env) do
    %{env | 
      query: sanitize_query(env.query),
      url: sanitize_url(env.url),
      body: sanitize_body(env.body)
    }
  end
  
  # Sanitize response by masking sensitive data
  def sanitize_response(response) do
    %{response | 
      url: sanitize_url(response.url),
      body: sanitize_body(response.body)
    }
  end
  
  # Mask API key in query parameters
  def sanitize_query(query) when is_list(query) do
    Enum.map(query, fn
      {:key, api_key} when is_binary(api_key) -> 
        {:key, mask_api_key(api_key)}
      other -> other
    end)
  end
  def sanitize_query(query), do: query
  
  # Mask API key in URL if present - handle various formats
  def sanitize_url(url) when is_binary(url) do
    # Mask API key in query parameter format: key=AIzaSy...
    url = Regex.replace(~r/key=([^&]+)/, url, fn _, key -> "key=#{mask_api_key(key)}" end)
    # Mask API key in path format: /v1/models/gemini-2.0:generateContent?key=AIzaSy...
    url = Regex.replace(~r/\?key=([^&]+)/, url, fn _, key -> "?key=#{mask_api_key(key)}" end)
    # Mask any other formats where the API key might appear
    url = Regex.replace(~r/AIzaSy[a-zA-Z0-9_-]{33}/, url, fn key -> mask_api_key(key) end)
    url
  end
  def sanitize_url(url), do: url
  
  # Mask API key in the body if it's JSON with an API key
  def sanitize_body(body) when is_binary(body) do
    # First try to handle JSON strings that might contain an API key
    sanitized_body = case Jason.decode(body) do
      {:ok, decoded} ->
        decoded
        |> sanitize_api_key_in_map()
        |> Jason.encode!()
      _ -> body
    end
    
    # Additional regex checks for direct API keys in the content
    if is_binary(sanitized_body) do
      # Mask any API keys directly in the string content (AIzaSy followed by 33 chars)
      sanitized_body = Regex.replace(~r/AIzaSy[a-zA-Z0-9_-]{33}/, sanitized_body, fn key -> mask_api_key(key) end)
      # Mask any keys that might be in the "key":"value" format
      sanitized_body = Regex.replace(~r/"key"\s*:\s*"([^"]+)"/, sanitized_body, fn _, key -> "\"key\":\"#{mask_api_key(key)}\"" end)
      sanitized_body
    else
      sanitized_body
    end
  end
  def sanitize_body(body) when is_map(body) do
    sanitize_api_key_in_map(body)
  end
  def sanitize_body(body), do: body
  
  # Recursively look for API keys in nested maps
  def sanitize_api_key_in_map(map) when is_map(map) do
    Enum.map(map, fn
      {"key", value} when is_binary(value) ->
        {"key", mask_api_key(value)}
      {"api_key", value} when is_binary(value) ->
        {"api_key", mask_api_key(value)}
      {k, v} when is_map(v) ->
        {k, sanitize_api_key_in_map(v)}
      {k, v} when is_list(v) ->
        {k, Enum.map(v, fn
          item when is_map(item) -> sanitize_api_key_in_map(item)
          other -> other
        end)}
      other -> other
    end)
    |> Enum.into(%{})
  end
  
  # Mask the API key, showing only first 5 characters
  def mask_api_key(api_key) when is_binary(api_key) do
    if String.length(api_key) > 5 do
      "#{String.slice(api_key, 0, 5)}*****"
    else
      "*****"
    end
  end
  def mask_api_key(_), do: "*****"
  
  # Logging functions
  defp log_test_request(env, context) do
    # Additional sanitization for query parameters to ensure no keys are leaked
    sanitized_query = Enum.map(env.query || [], fn
      {:key, value} when is_binary(value) -> {:key, mask_api_key(value)}
      other -> other
    end)

    request_log = """
    [TEST REQUEST] #{env.method} #{env.url}
    [TEST CONTEXT] #{context.module} - #{context.test}
    [HEADERS] #{inspect(env.headers)}
    [QUERY] #{inspect(sanitized_query)}
    [BODY] #{inspect(env.body)}
    """
    Logger.debug(request_log)
  end
  
  defp log_test_response(response, context) do
    response_log = if response.status >= 400 do
      """
      [TEST ERROR RESPONSE] Status: #{response.status}
      [TEST CONTEXT] #{context.module} - #{context.test}
      [URL] #{response.url}
      [BODY] #{inspect(response.body)}
      """
    else
      """
      [TEST RESPONSE] Status: #{response.status}
      [TEST CONTEXT] #{context.module} - #{context.test}
      [URL] #{response.url}
      """
    end
    
    if response.status >= 400 do
      Logger.error(response_log)
    else
      Logger.debug(response_log)
    end
  end
  
  defp log_test_error(env, error, context) do
    error_log = """
    [TEST CONNECTION ERROR]
    [TEST CONTEXT] #{context.module} - #{context.test}
    [URL] #{env.url}
    [REASON] #{inspect(error)}
    """
    Logger.error(error_log)
  end
  
  defp log_request(env) do
    Logger.debug(fn ->
      """
      [REQUEST] #{env.method} #{env.url}
      [HEADERS] #{inspect(env.headers, pretty: true)}
      [QUERY] #{inspect(env.query, pretty: true)}
      [BODY] #{inspect(env.body, pretty: true)}
      """
    end)
  end
  
  defp log_response(response) do
    if response.status >= 400 do
      Logger.error(fn ->
        """
        [ERROR RESPONSE] Status: #{response.status}
        [URL] #{response.url}
        [BODY] #{inspect(response.body, pretty: true)}
        """
      end)
    else
      Logger.debug(fn ->
        """
        [RESPONSE] Status: #{response.status}
        [URL] #{response.url}
        """
      end)
    end
  end
  
  defp log_error(env, error) do
    Logger.error(fn ->
      """
      [CONNECTION ERROR]
      [URL] #{env.url}
      [REASON] #{inspect(error, pretty: true)}
      """
    end)
  end
end
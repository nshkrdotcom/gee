defmodule Gemini.SecureLoggerTest do
  use ExUnit.Case, async: true
  
  # Import the SecureLogger module
  alias Gemini.SecureLogger
  
  test "masks API key in URL" do
    # Test URL with API key
    url = "https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent?key=AIzaX1234567890abcdef"
    
    # Secure the URL
    secured_url = SecureLogger.sanitize_url(url)
    
    # Ensure the API key is masked
    assert secured_url == "https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent?key=AIzaX*****"
    assert !String.contains?(secured_url, "1234567890abcdef")
  end
  
  test "masks API key in query parameters" do
    # Test query params with API key
    query = [key: "AIzaX1234567890abcdef", other: "value"]
    
    # Secure the query
    secured_query = SecureLogger.sanitize_query(query)
    
    # Check that only the API key is masked
    assert secured_query == [key: "AIzaX*****", other: "value"]
  end
  
  test "masks API key in request body" do
    # Test body with API key
    body = %{
      "api_key" => "AIzaX1234567890abcdef",
      "contents" => [
        %{
          "parts" => [
            %{"text" => "Hello, world!"}
          ]
        }
      ],
      "nested" => %{
        "key" => "AIzaX1234567890abcdef"
      }
    }
    
    # Secure the body
    secured_body = SecureLogger.sanitize_body(body)
    
    # Check that all API keys are masked
    assert secured_body["api_key"] == "AIzaX*****"
    assert secured_body["nested"]["key"] == "AIzaX*****"
    assert secured_body["contents"] == body["contents"]
  end
  
  test "sanitizes environment for logging" do
    # Create a test environment
    env = %Tesla.Env{
      method: :post,
      url: "https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent?key=AIzaX1234567890abcdef",
      query: [key: "AIzaX1234567890abcdef"],
      body: %{"key" => "AIzaX1234567890abcdef"}
    }
    
    # Sanitize the environment
    sanitized_env = SecureLogger.sanitize_env(env)
    
    # Check that API keys are masked in all locations
    assert sanitized_env.url == "https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent?key=AIzaX*****"
    assert sanitized_env.query == [key: "AIzaX*****"]
    assert sanitized_env.body == %{"key" => "AIzaX*****"}
  end
end
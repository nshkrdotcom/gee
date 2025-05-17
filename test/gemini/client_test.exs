defmodule Gemini.ClientTest do
  use ExUnit.Case

  alias Gemini.Client
  alias Gemini.Config
  alias Gemini.Test.MockClient

  setup do
    if Gemini.TestContextHelper.use_live_api?() do
      # In live test mode, ensure we have a valid API key from environment
      # but don't set it here - let Config.api_key() pull it from env
      
      # Clear any previous config to ensure we use the env variable
      Application.delete_env(:gemini, :api_key)
      
      # Verify we have a valid key
      api_key = System.get_env("GEMINI_API_KEY") || System.get_env("GOOGLE_API_KEY")
      unless api_key do
        flunk("Live API testing enabled but no API key found! Set GEMINI_API_KEY environment variable.")
      end
    else
      # In mock mode, set a dummy key and initialize mocks
      Config.set_api_key("test_api_key")
      MockClient.setup_mock()
    end
    
    :ok
  end

  test "client can be created with API key" do
    client = Client.new("custom_api_key")
    assert client != nil
  end

  test "client can be created with default API key" do
    client = Client.new()
    assert client != nil
  end

  test "generate_content returns a successful response" do
    params = %{
      "contents" => [
        %{
          "parts" => [
            %{
              "text" => "Hello"
            }
          ]
        }
      ]
    }
    
    # Mock the text generation with a specific response
    MockClient.mock_text_generation("Test response")
    
    # Test the client function
    {:ok, response} = Client.generate_content("gemini-2.0-flash", params)
    
    assert response.text == "Test response"
    assert response.finish_reason == "STOP"
    assert response.candidate_index == 0
  end

  test "generate_content handles error responses" do
    # Mock an error response
    MockClient.mock_error_response(400, "Invalid request")
    
    # Test the error handling
    {:error, error} = Client.generate_content("error_case", %{})
    
    assert error.code == 400
    assert error.message == "Invalid request"
  end
  
  test "client can handle structured outputs" do
    # Mock a structured output response
    structured_data = %{
      "name" => "Gemini",
      "version" => "1.0.0",
      "features" => ["text", "images", "chat"]
    }
    
    MockClient.mock_structured_output(structured_data)
    
    params = %{"contents" => [%{"parts" => [%{"text" => "Give me structured data"}]}]}
    {:ok, response} = Client.generate_content("gemini-2.0-flash", params)
    
    assert response.structured == structured_data
  end
end

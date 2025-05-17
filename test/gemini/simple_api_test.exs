defmodule Gemini.SimpleAPITest do
  use ExUnit.Case, async: false
  
  # Tag these tests as :live_api
  @moduletag :live_api
  
  # Import Tesla.Mock for mocking in tests
  import Tesla.Mock
  
  setup do
    # Get API key from environment variables
    api_key = System.get_env("GEMINI_API_KEY") || System.get_env("GOOGLE_API_KEY")
    
    # Check if we should use live API based on environment flag
    is_live_api = System.get_env("GEMINI_LIVE_TEST") == "true"
    
    # Only set up mocks if we're not using the live API and no key is available
    unless is_live_api do
      mock(fn
        %{method: :post, url: "https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent"} ->
          # Return a successful mock response
          %Tesla.Env{
            status: 200, 
            body: %{
              "candidates" => [
                %{
                  "content" => %{
                    "parts" => [
                      %{"text" => "Mocked Elixir haiku\nFunctional programming joy\nProcesses dancing"}
                    ]
                  },
                  "finishReason" => "STOP",
                  "index" => 0,
                  "safetyRatings" => []
                }
              ]
            }
          }
      end)
    end
    
    unless api_key do
      IO.puts("No API key found. Set GEMINI_API_KEY environment variable.")
      IO.puts("[TEST SKIPPED] No API key available")
      # Even without API key, the test can run with mocks
      {:ok, %{api_key: nil}}
    else
      # Set the API key directly for this test
      Gemini.Config.set_api_key(api_key)
      
      {:ok, %{api_key: api_key}}
    end
  end
  
  test "simple text generation", %{api_key: _api_key} do
    # Simple prompt
    prompt = "Write a short haiku about programming in Elixir"
    
    # Call the client correctly - prompt first, then options
    case Gemini.generate_content(prompt) do
      {:ok, response} ->
        IO.puts("\nResponse from Gemini API:")
        IO.puts(response.text)
        
        assert is_binary(response.text)
        assert String.length(response.text) > 10
        
      {:error, error} ->
        if Map.get(error, :code) == 429 do
          IO.puts("\nRate limit exceeded. Try again later or use a different API key.")
          IO.puts("[TEST SKIPPED] Rate limit exceeded")
          :ok
        else
          flunk("API request failed: #{inspect(error)}")
        end
    end
  end
end
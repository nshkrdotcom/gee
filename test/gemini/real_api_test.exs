defmodule Gemini.RealAPITest do
  use ExUnit.Case, async: false
  
  # Tag these tests as :live_api and :real_api
  @moduletag :live_api
  @moduletag :real_api
  
  # Import the live test helper
  Code.require_file("../live_test_helper.exs", __DIR__)
  
  setup do
    LiveTestHelper.setup_real_api_test()
  end
  
  test "can generate text with real Gemini API", %{api_key: api_key} do
    # Skip test if no API key is available
    if api_key == nil do
      IO.puts("No API key found. Set GEMINI_API_KEY environment variable.")
      IO.puts("[TEST SKIPPED] No API key available")
      :ok
    else
      # Check adapter configuration
      config = Application.get_env(:tesla, :adapter)
      unless config == {Tesla.Adapter.Hackney, [recv_timeout: 30_000]} do
        IO.puts("\nWarning: Tesla adapter not properly configured for live tests")
        IO.puts("Current adapter: #{inspect(config)}")
      end
      
      # Simple prompt
      prompt = "Write a short haiku about Elixir programming language."
      
      # Make a direct call to the API
      url = "https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent"
      
      # Build the request body
      body = %{
        "contents" => [
          %{
            "parts" => [
              %{"text" => prompt}
            ]
          }
        ]
      }
      
      # Make the request using HTTPoison directly
      response = HTTPoison.post!(
        "#{url}?key=#{api_key}",
        Jason.encode!(body),
        [{"Content-Type", "application/json"}]
      )
      
      # Parse the response
      assert response.status_code == 200
      
      parsed = Jason.decode!(response.body)
      
      # Extract the text from the response
      text = get_in(parsed, ["candidates", Access.at(0), "content", "parts", Access.at(0), "text"])
      
      IO.puts("\nResponse from Gemini API:")
      IO.puts(text)
      
      # Validate the response
      assert is_binary(text)
      assert String.length(text) > 10
    end
  end
  
  test "can extract structured data from text", %{api_key: api_key} do
    # Skip test if no API key is available
    if api_key == nil do
      IO.puts("No API key found. Set GEMINI_API_KEY environment variable.")
      IO.puts("[TEST SKIPPED] No API key available")
      :ok
    else
      # Prompt that asks for structured data
      prompt = "Extract structured data from this text and return a JSON object: 'Sarah Johnson is a 42-year-old professor of physics at MIT with an email address of sarah.johnson@example.edu.' Include fields for name, age, job_title, institution, and email."
      
      # Make a direct call to the API
      url = "https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent"
      
      # Build the request body with lower temperature for more consistent responses
      body = %{
        "contents" => [
          %{
            "parts" => [
              %{"text" => prompt}
            ]
          }
        ],
        "generationConfig" => %{
          "temperature" => 0.1
        }
      }
      
      # Make the request using HTTPoison directly
      response = HTTPoison.post!(
        "#{url}?key=#{api_key}",
        Jason.encode!(body),
        [{"Content-Type", "application/json"}]
      )
      
      # Parse the response
      assert response.status_code == 200
      parsed = Jason.decode!(response.body)
      
      # Extract the text from the response
      text = get_in(parsed, ["candidates", Access.at(0), "content", "parts", Access.at(0), "text"])
      
      IO.puts("\nRaw response from Gemini API:")
      IO.puts(text)
      
      # Try to extract the JSON object from the response
      case Regex.run(~r/\{.*\}/s, text) do
        [json_str] ->
          case Jason.decode(json_str) do
            {:ok, data} ->
              IO.puts("\nParsed structured data:")
              IO.puts("Name: #{data["name"]}")
              IO.puts("Age: #{data["age"]}")
              IO.puts("Job: #{data["job_title"]} at #{data["institution"]}")
              IO.puts("Email: #{data["email"]}")
              
              # Verify the extracted data
              assert data["name"] == "Sarah Johnson"
              assert data["age"] == 42
              assert data["job_title"] == "professor of physics"
              assert data["institution"] == "MIT"
              assert data["email"] == "sarah.johnson@example.edu"
              
            {:error, error} ->
              flunk("Failed to parse JSON: #{inspect(error)}\nText: #{text}")
          end
          
        nil ->
          flunk("No JSON object found in response: #{text}")
      end
    end
  end
end
defmodule Gemini.APITests do
  use ExUnit.Case, async: false
  
  # Tag these tests as :live_api
  @moduletag :live_api
  
  # Import the LiveTestHelper module
  Code.require_file("../live_test_helper.exs", __DIR__)
  
  # Use the LiveTestHelper for setup
  setup context do
    LiveTestHelper.setup_live_api_test(context)
  end
  
  test "basic text generation", %{api_key: _api_key} do
    # Simple prompt
    prompt = "Write a haiku about programming in Elixir"
    
    # Call Gemini.generate_content with proper argument order (prompt first, then options)
    case Gemini.generate_content(prompt, model: "gemini-2.0-flash") do
      {:ok, response} ->
        IO.puts("\nResponse from Gemini API:")
        IO.puts(response.text)
        
        assert is_binary(response.text)
        assert String.length(response.text) > 10
        
      {:error, error} ->
        # Check for rate limit error using a safer pattern
        if is_map(error) && Map.get(error, :code) == 429 do
          IO.puts("\nRate limit exceeded. Try again later or use a different API key.")
          IO.puts("[TEST SKIPPED] Rate limit exceeded")
          :ok
        else
          flunk("API request failed: #{inspect(error)}")
        end
    end
  end
  
  test "structured data extraction", %{api_key: _api_key} do
    # Create a prompt that requests structured data
    prompt = "Extract the structured data from this text: 'John Smith is 35 years old and works as a software engineer at TechCorp. His email is john.smith@example.com.' Return ONLY a JSON object with fields: name, age, job_title, company, email."
    
    # Call the API with the parameters properly nested in generationConfig
    case Gemini.generate_content(prompt, [
      model: "gemini-2.0-flash"
    ]) do
      {:ok, response} ->
        IO.puts("\nRaw response:")
        IO.puts(response.text)
        
        # Try to extract the JSON object from the response
        case Regex.run(~r/\{.*\}/s, response.text) do
          [json_str] ->
            case Jason.decode(json_str) do
              {:ok, data} ->
                IO.puts("\nParsed structured data:")
                IO.puts("Name: #{data["name"]}")
                IO.puts("Age: #{data["age"]}")
                IO.puts("Job: #{data["job_title"]} at #{data["company"]}")
                IO.puts("Email: #{data["email"]}")
                
                assert data["name"] == "John Smith"
                assert data["age"] == 35
                assert data["job_title"] == "software engineer"
                assert data["company"] == "TechCorp"
                assert data["email"] == "john.smith@example.com"
                
              {:error, error} ->
                flunk("Failed to parse JSON: #{inspect(error)}\nText: #{response.text}")
            end
            
          nil ->
            flunk("No JSON object found in response: #{response.text}")
        end
        
      {:error, error} ->
        if error.code == 429 do
          IO.puts("\nRate limit exceeded. Try again later or use a different API key.")
          ExUnit.skip("Rate limit exceeded")
        else
          flunk("API request failed: #{inspect(error)}")
        end
    end
  end
  
  @tag :skip_streaming
  test "streaming implementation (skipped for now)", %{api_key: _api_key} do
    IO.puts("\nStreaming tests will be implemented with GenServer later")
    :ok
  end
end
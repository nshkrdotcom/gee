defmodule Gemini.APIExamplesTest do
  use ExUnit.Case, async: false
  
  # Tag these tests as :live_api and :examples
  @moduletag :live_api
  @moduletag :examples
  
  # Import Tesla.Mock for test mocks
  import Tesla.Mock
  
  setup do
    # Get API key from environment variables
    api_key = System.get_env("GEMINI_API_KEY") || System.get_env("GOOGLE_API_KEY")
    
    # Set up mocks for testing without an API key
    mock(fn
      %{method: :post, url: "https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent"} = env ->
        # Return different responses based on the request content (check for both real API and mocks)
        if api_key == nil do
          # If no API key, check the request body to see what we're requesting
          case Jason.decode(env.body) do
            {:ok, body} ->
              text = get_in(body, ["contents", Access.at(0), "parts", Access.at(0), "text"])
              
              if text && String.contains?(text, "Extract the structured data") do
                # Return structured data mock for data extraction
                %Tesla.Env{
                  status: 200, 
                  body: %{
                    "candidates" => [
                      %{
                        "content" => %{
                          "parts" => [
                            %{"text" => "```json\n{\n  \"name\": \"John Smith\",\n  \"age\": 35,\n  \"job_title\": \"software engineer\",\n  \"company\": \"TechCorp\",\n  \"email\": \"john.smith@example.com\"\n}\n```"}
                          ]
                        },
                        "finishReason" => "STOP"
                      }
                    ]
                  }
                }
              else
                # Return haiku mock for text generation
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
                        "finishReason" => "STOP"
                      }
                    ]
                  }
                }
              end
            _ ->
              # Fallback for parse errors
              %Tesla.Env{
                status: 200,
                body: %{
                  "candidates" => [
                    %{
                      "content" => %{
                        "parts" => [
                          %{"text" => "Default mock response"}
                        ]
                      },
                      "finishReason" => "STOP"
                    }
                  ]
                }
              }
          end
        else
          # When API key is present, pass through to real implementation
          nil
        end
    end)
    
    unless api_key do
      IO.puts "Skipping API examples tests - no API key available."
      IO.puts "Set GEMINI_API_KEY to run these tests."
      # Return map with nil key, but tests will run with mocks
      {:ok, %{api_key: nil}}
    else    
      # Configure the Gemini client with our API key
      Gemini.Config.set_api_key(api_key)
      
      %{api_key: api_key}
    end
  end
  
  test "simple text generation with Gemini API", %{api_key: _api_key} do
    IO.puts "\n=== Simple text generation ==="
    
    prompt = "Write a haiku about programming in Elixir"
    
    # Use our Gemini client to make the request (structure shown for reference)
    _params = %{
      "contents" => [
        %{
          "parts" => [
            %{"text" => prompt}
          ]
        }
      ]
    }
    
    # Use our Gemini module with proper parameter structure (prompt first, then options)
    case Gemini.generate_content(prompt, model: "gemini-2.0-flash") do
      {:ok, response} ->
        IO.puts "\nResponse:"
        IO.puts response.text
        
        assert is_binary(response.text)
        assert String.length(response.text) > 10
        
      {:error, error} ->
        flunk("API request failed: #{inspect(error)}")
    end
  end
  
  test "extracting structured data via prompt in Gemini API", %{api_key: _api_key} do
    IO.puts "\n=== Structured data via prompt ==="
    
    # Use prompt engineering to get structured output
    prompt = "Extract the structured data from this text: 'John Smith is 35 years old and works as a software engineer at TechCorp. His email is john.smith@example.com.' Return ONLY a JSON object with fields: name, age, job_title, company, email."
    
    # Example API structure (shown for reference)
    _params = %{
      "contents" => [
        %{
          "parts" => [
            %{"text" => prompt}
          ]
        }
      ],
      "generationConfig" => %{
        "temperature" => 0.1  # Low temperature for more deterministic outputs
      }
    }
    
    # Use our Gemini module with proper parameter structure (prompt first, then options)
    case Gemini.generate_content(prompt, [model: "gemini-2.0-flash", temperature: 0.1]) do
      {:ok, response} ->
        IO.puts "\nRaw response:"
        IO.puts response.text
        
        # Try to parse the JSON from the response
        case Regex.run(~r/\{.*\}/s, response.text) do
          [json_str] ->
            case Jason.decode(json_str) do
              {:ok, data} ->
                IO.puts "\nParsed structured data:"
                IO.puts "Name: #{data["name"]}"
                IO.puts "Age: #{data["age"]}"
                IO.puts "Job: #{data["job_title"]} at #{data["company"]}"
                IO.puts "Email: #{data["email"]}"
                
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
        flunk("API request failed: #{inspect(error)}")
    end
  end
  
  @tag :skip_streaming
  test "streaming test (skipped for now pending GenServer implementation)", %{api_key: _api_key} do
    IO.puts "\n=== Streaming test skipped ==="
    IO.puts "Streaming will be tested with GenServer implementation later"
    :ok
  end
end

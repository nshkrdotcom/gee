#!/usr/bin/env elixir
# Example of using the Gemini API directly

# First check if we have an API key
api_key = System.get_env("GEMINI_API_KEY")

unless api_key do
  IO.puts("ERROR: No GEMINI_API_KEY environment variable found.")
  IO.puts("Please set your API key: export GEMINI_API_KEY=your_api_key")
  System.halt(1)
end

# Start necessary applications
Application.ensure_all_started(:httpoison)
Application.ensure_all_started(:jason)

# Set up the request parameters
url = "https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent?key=#{api_key}"
headers = [{"Content-Type", "application/json"}]

# Create a prompt for testing
prompt = "Write a short poem about programming in Elixir."

# Create the request body
body = Jason.encode!(%{
  "contents" => [
    %{
      "parts" => [
        %{"text" => prompt}
      ]
    }
  ],
  "generationConfig" => %{
    "temperature" => 0.7,
    "topP" => 0.9,
    "maxOutputTokens" => 200
  }
})

IO.puts("Sending request to Gemini API...")
IO.puts("Prompt: #{prompt}")
IO.puts("---")

# Make the API request
case HTTPoison.post(url, body, headers) do
  {:ok, response} ->
    if response.status_code == 200 do
      # Parse the response
      case Jason.decode(response.body) do
        {:ok, data} ->
          # Extract the generated text
          text = case get_in(data, ["candidates", Access.at(0), "content", "parts", Access.at(0), "text"]) do
            nil -> "No text found in response"
            content -> content
          end
          
          # Print the response
          IO.puts("API Response:")
          IO.puts(text)
          
          # Print token usage if available
          if usage = data["usageMetadata"] do
            IO.puts("\nToken Usage:")
            IO.puts("  Prompt tokens: #{usage["promptTokenCount"]}")
            IO.puts("  Output tokens: #{usage["candidatesTokenCount"]}")
            IO.puts("  Total tokens:  #{usage["totalTokenCount"]}")
          end
          
        {:error, error} ->
          IO.puts("ERROR: Failed to parse JSON response")
          IO.puts("Error: #{inspect(error)}")
          IO.puts("Response body: #{response.body}")
      end
    else
      # Handle error response
      IO.puts("ERROR: API request failed with status code #{response.status_code}")
      
      # Try to extract error message
      case Jason.decode(response.body) do
        {:ok, error_data} ->
          message = get_in(error_data, ["error", "message"]) || "Unknown error"
          code = get_in(error_data, ["error", "code"]) || "?"
          IO.puts("Error #{code}: #{message}")
          
        {:error, _} ->
          IO.puts("Response body: #{response.body}")
      end
    end
    
  {:error, error} ->
    IO.puts("ERROR: HTTP request failed")
    IO.puts("Error: #{inspect(error)}")
end
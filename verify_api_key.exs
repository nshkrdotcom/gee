#!/usr/bin/env elixir

# Simple script to verify a Gemini API key works correctly
api_key = System.get_env("GEMINI_API_KEY")

unless api_key do
  IO.puts("No GEMINI_API_KEY environment variable found.")
  IO.puts("Please run this script with:")
  IO.puts("GEMINI_API_KEY=your_api_key mix run verify_api_key.exs")
  System.halt(1)
end

IO.puts("Testing API key: #{String.slice(api_key, 0, 10)}*****")

# Start required applications
Application.ensure_all_started(:hackney)
Application.ensure_all_started(:jason)

# Create a simple client
url = "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=#{api_key}"
headers = [{"Content-Type", "application/json"}]
body = Jason.encode!(%{
  "contents" => [
    %{
      "parts" => [
        %{"text" => "Hello, this is a test of the Gemini API. Please respond with a short greeting."}
      ]
    }
  ]
})

IO.puts("Making request to Gemini API...")

case :hackney.request(:post, url, headers, body, []) do
  {:ok, status, headers, client_ref} ->
    {:ok, response_body} = :hackney.body(client_ref)
    
    IO.puts("\nStatus code: #{status}")
    
    cond do
      status >= 200 and status < 300 ->
        IO.puts("SUCCESS! API key is valid.")
        
        # Try to parse the response
        case Jason.decode(response_body) do
          {:ok, decoded} ->
            # Extract text from response
            text = case get_in(decoded, ["candidates", Access.at(0), "content", "parts", Access.at(0), "text"]) do
              nil -> "No text found in response"
              content -> content
            end
            
            IO.puts("\nGemini API response:")
            IO.puts("#{text}")
            
          {:error, _} ->
            IO.puts("\nResponse received but couldn't parse JSON:")
            IO.puts(response_body)
        end
        
      status == 400 ->
        IO.puts("ERROR: Bad request (400)")
        
        # Try to parse the error
        case Jason.decode(response_body) do
          {:ok, decoded} ->
            error_msg = get_in(decoded, ["error", "message"]) || "Unknown error"
            IO.puts("Message: #{error_msg}")
            
          {:error, _} ->
            IO.puts(response_body)
        end
        
      status == 401 ->
        IO.puts("ERROR: Unauthorized (401) - Invalid API key")
        IO.puts("Please check your API key and try again.")
        
      status == 403 ->
        IO.puts("ERROR: Forbidden (403) - API key doesn't have required permissions")
        IO.puts("Your API key may need additional permissions or is for a different service.")
        
      status == 429 ->
        IO.puts("ERROR: Too Many Requests (429) - Rate limit exceeded")
        IO.puts("You've hit the rate limit for this API key. Try again later.")
        
      true ->
        IO.puts("ERROR: Unexpected status code #{status}")
        IO.puts(response_body)
    end
    
  {:error, reason} ->
    IO.puts("ERROR: HTTP request failed")
    IO.puts("Reason: #{inspect(reason)}")
end
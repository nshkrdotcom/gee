#!/usr/bin/env elixir

# Simple script to directly test a Gemini API key
# Run with: elixir test_api_key.exs <your_api_key>

api_key = List.first(System.argv())

unless api_key do
  IO.puts("Please provide your API key as a command line argument:")
  IO.puts("elixir test_api_key.exs YOUR_API_KEY")
  System.halt(1)
end

IO.puts("Testing API key: #{api_key}")

# Make a direct HTTP request to the Gemini API
url = "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=#{api_key}"
headers = [{"Content-Type", "application/json"}]
body = ~s({"contents":[{"parts":[{"text":"Hello, this is a direct test of the Gemini API."}]}]})

# Start inets and ssl for httpc
:inets.start()
:ssl.start()

# Make the request
IO.puts("Sending request to Gemini API...")
full_url = String.to_charlist(url)
content_type = 'application/json'
request = {full_url, [], content_type, body}

case :httpc.request(:post, request, [], []) do
  {:ok, {{_, 200, _}, _, response_body}} ->
    IO.puts("SUCCESS! API key is valid.")
    response = :erlang.list_to_binary(response_body)
    parsed = Jason.decode!(response)
    
    # Extract the text from the response
    text = case get_in(parsed, ["candidates"]) do
      [first | _] -> get_in(first, ["content", "parts", Access.at(0), "text"])
      _ -> "No text found in response"
    end
    
    IO.puts("\nGemini API response:")
    IO.puts("#{text}")
  
  {:ok, {{_, status, _}, _, response_body}} ->
    IO.puts("ERROR: API request failed with status #{status}")
    response = :erlang.list_to_binary(response_body)
    parsed = Jason.decode!(response)
    message = get_in(parsed, ["error", "message"])
    IO.puts("Message: #{message}")
  
  {:error, reason} ->
    IO.puts("ERROR: HTTP request failed")
    IO.puts("Reason: #{inspect(reason)}")
end
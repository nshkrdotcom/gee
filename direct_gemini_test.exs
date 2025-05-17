# Simple script to test Gemini API directly
# Run with: mix run direct_gemini_test.exs

# Get API key from environment
api_key = System.get_env("GEMINI_API_KEY")

unless api_key do
  IO.puts("ERROR: No GEMINI_API_KEY environment variable found.")
  IO.puts("Please set your API key: export GEMINI_API_KEY=your_api_key")
  System.halt(1)
end

# Ensure HTTPoison is started
Application.ensure_all_started(:hackney)
Application.ensure_all_started(:httpoison)

# Set up the request parameters
url = "https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent?key=#{api_key}"
headers = [{"Content-Type", "application/json"}]

# Create a prompt for testing
prompt = "Write a short haiku about programming in Elixir."

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
      data = Jason.decode!(response.body)
      
      # Extract the generated text
      text = get_in(data, ["candidates", Access.at(0), "content", "parts", Access.at(0), "text"])
      
      # Print the response
      IO.puts("API Response:")
      IO.puts(text)
    else
      # Handle error response
      IO.puts("ERROR: API request failed with status code #{response.status_code}")
      
      error_data = Jason.decode!(response.body)
      message = get_in(error_data, ["error", "message"]) || "Unknown error"
      IO.puts("Error: #{message}")
    end
    
  {:error, error} ->
    IO.puts("ERROR: HTTP request failed")
    IO.puts("Error: #{inspect(error)}")
end
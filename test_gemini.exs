# Simple test script to verify Gemini API works
# Run with: GEMINI_API_KEY=your_key mix run test_gemini.exs

# Get API key from environment
api_key = System.get_env("GEMINI_API_KEY")

unless api_key do
  IO.puts("ERROR: No GEMINI_API_KEY environment variable found.")
  IO.puts("Please set your API key: export GEMINI_API_KEY=your_api_key")
  System.halt(1)
end

IO.puts("Testing Gemini API with model: gemini-2.0-flash")
IO.puts("API Key: #{String.slice(api_key, 0, 5)}*****")

# Create a Tesla client for the Gemini API
middleware = [
  {Tesla.Middleware.BaseUrl, "https://generativelanguage.googleapis.com/v1"},
  Tesla.Middleware.JSON,
  {Tesla.Middleware.Query, [key: api_key]},
  Tesla.Middleware.Logger
]

client = Tesla.client(middleware)

# Define a simple prompt
prompt = "Write a short haiku about programming in Elixir."
IO.puts("\nPrompt: #{prompt}")

# Prepare request params
params = %{
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
}

# Make the API request
IO.puts("\nSending request...")
case Tesla.post(client, "/models/gemini-2.0-flash:generateContent", params) do
  {:ok, %{status: 200, body: body}} ->
    # Extract the response text
    text = get_in(body, ["candidates", Access.at(0), "content", "parts", Access.at(0), "text"])
    
    IO.puts("\nAPI Response:")
    IO.puts(text)
    
    # Print token usage if available
    if usage = body["usageMetadata"] do
      IO.puts("\nToken Usage:")
      IO.puts("  Prompt tokens: #{usage["promptTokenCount"]}")
      IO.puts("  Output tokens: #{usage["candidatesTokenCount"]}")
      IO.puts("  Total tokens:  #{usage["totalTokenCount"]}")
    end
    
  {:ok, %{status: status, body: body}} ->
    IO.puts("\nERROR: API request failed with status code #{status}")
    
    # Try to extract error message
    message = get_in(body, ["error", "message"]) || "Unknown error"
    IO.puts("Message: #{message}")
    
  {:error, error} ->
    IO.puts("\nERROR: HTTP request failed")
    IO.puts("Error: #{inspect(error)}")
end
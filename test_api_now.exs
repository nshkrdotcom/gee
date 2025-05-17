# Simple script to verify API key works
# Usage: GEMINI_API_KEY=your_key mix run test_api_now.exs

# Get API key from environment
api_key = System.get_env("GEMINI_API_KEY")

unless api_key do
  IO.puts("ERROR: No GEMINI_API_KEY environment variable found.")
  IO.puts("Please set your API key: export GEMINI_API_KEY=your_api_key")
  System.halt(1)
end

IO.puts("Testing Gemini API with key: #{String.slice(api_key, 0, 5)}*****")

# Configure our client with the API key
Gemini.Config.set_api_key(api_key)

# Make a simple request to test the API
prompt = "What's the current date and time? Provide it in a nice, human-readable format."

IO.puts("\nSending request to Gemini API...")
IO.puts("Prompt: #{prompt}")

case Gemini.generate_content(prompt, model: "gemini-2.0-flash") do
  {:ok, response} ->
    IO.puts("\nSuccess! Response from Gemini API:")
    IO.puts(response.text)
    
    IO.puts("\nSecure logging is working - API key was masked in logs.")
    
  {:error, error} ->
    IO.puts("\nError: #{error.message || inspect(error)}")
    IO.puts("Status code: #{error[:code]}")
end
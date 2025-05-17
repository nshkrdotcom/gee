#!/usr/bin/env elixir
# Example of extracting structured data from Gemini API

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

# Create a prompt asking for structured data
prompt = """
Extract the following information from this text as a JSON object:

Text: John Smith is a 42-year-old software engineer who works at TechCorp. 
He has 15 years of experience and specializes in backend development.
His email is john.smith@example.com and his phone number is (555) 123-4567.

Return ONLY a valid JSON object with these fields:
- name
- age
- job_title
- company
- experience_years
- specialization
- contact_info (an object with email and phone)
"""

# Create the request body with low temperature for more deterministic output
body = Jason.encode!(%{
  "contents" => [
    %{
      "parts" => [
        %{"text" => prompt}
      ]
    }
  ],
  "generationConfig" => %{
    "temperature" => 0.1,
    "topP" => 0.95,
    "maxOutputTokens" => 1024
  }
})

IO.puts("Sending structured data request to Gemini API...")
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
          
          # Print the raw response
          IO.puts("API Raw Response:")
          IO.puts(text)
          IO.puts("---")
          
          # Try to extract and parse the JSON
          case Regex.run(~r/\{.*\}/s, text) do
            [json_str] ->
              case Jason.decode(json_str) do
                {:ok, extracted_data} ->
                  IO.puts("\nExtracted JSON data:")
                  IO.puts(Jason.encode!(extracted_data, pretty: true))
                  
                  # Access some fields to demonstrate
                  if Map.has_key?(extracted_data, "contact_info") do
                    contact = extracted_data["contact_info"]
                    IO.puts("\nPerson: #{extracted_data["name"]}")
                    IO.puts("Contact: #{contact["email"]}, #{contact["phone"]}")
                  end
                  
                {:error, error} ->
                  IO.puts("ERROR: Failed to parse extracted JSON")
                  IO.puts("Error: #{inspect(error)}")
                  IO.puts("Text: #{json_str}")
              end
              
            nil ->
              IO.puts("ERROR: No JSON data found in the response")
          end
          
        {:error, error} ->
          IO.puts("ERROR: Failed to parse API response")
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
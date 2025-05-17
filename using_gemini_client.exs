# Example script showing how to use the Gemini Elixir client library
# Run with: GEMINI_API_KEY=your_key mix run using_gemini_client.exs

# Check if API key is available
api_key = System.get_env("GEMINI_API_KEY")

unless api_key do
  IO.puts("ERROR: No GEMINI_API_KEY environment variable found.")
  IO.puts("Please set your API key: export GEMINI_API_KEY=your_api_key")
  System.halt(1)
end

# Set the API key (can also be configured in config.exs)
Gemini.Config.set_api_key(api_key)

IO.puts("=== Using Gemini Elixir Client ===")

# Example 1: Simple text generation
IO.puts("\n1. Basic Text Generation")
prompt = "Explain the Elixir pipe operator (|>) in one paragraph."

case Gemini.generate_content(prompt, model: "gemini-2.0-flash") do
  {:ok, response} ->
    IO.puts("\nResponse:")
    IO.puts(response.text)
    
  {:error, error} ->
    IO.puts("\nError: #{error.message}")
end

# Example 2: Text generation with specific parameters
IO.puts("\n2. Text Generation with Parameters")
prompt = "Write a creative name for a coffee shop that specializes in programming-themed drinks."

case Gemini.generate_content(prompt, 
  model: "gemini-2.0-flash",
  temperature: 0.9,
  top_k: 40,
  top_p: 0.95,
  max_tokens: 30) do
  
  {:ok, response} ->
    IO.puts("\nResponse with higher creativity (temperature=0.9):")
    IO.puts(response.text)
    
  {:error, error} ->
    IO.puts("\nError: #{error.message}")
end

# Example 3: Structured output through prompt
IO.puts("\n3. Extracting Structured Data")
prompt = """
Extract structured data from this text and return ONLY a JSON object:

'Sarah Johnson is a 42-year-old professor of physics at MIT with an email address of sarah.johnson@mit.edu'

Include fields for: name, age, job_title, institution, and email.
"""

case Gemini.generate_content(prompt, 
  model: "gemini-2.0-flash",
  temperature: 0.1) do
  
  {:ok, response} ->
    IO.puts("\nStructured response (via prompt):")
    IO.puts(response.text)
    
    # Try to extract and parse JSON
    case Regex.run(~r/\{.*\}/s, response.text) do
      [json_str] ->
        case Jason.decode(json_str) do
          {:ok, data} ->
            IO.puts("\nParsed JSON data:")
            IO.puts("Name: #{data["name"]}")
            IO.puts("Age: #{data["age"]}")
            IO.puts("Job: #{data["job_title"]} at #{data["institution"]}")
            IO.puts("Email: #{data["email"]}")
            
          {:error, error} ->
            IO.puts("\nCould not parse JSON: #{inspect(error)}")
        end
        
      nil ->
        IO.puts("\nNo JSON data found in the response.")
    end
    
  {:error, error} ->
    IO.puts("\nError: #{error.message}")
end
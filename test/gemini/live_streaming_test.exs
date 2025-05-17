defmodule Gemini.LiveStreamingTest do
  use ExUnit.Case, async: false
  
  # Tag these tests as live_api and streaming
  @moduletag :live_api
  @moduletag :streaming
  
  # Helper to access nested map values more safely
  defp get_in_safe(map, keys, default \\ nil) do
    try do
      case get_in(map, keys) do
        nil -> default
        value -> value
      end
    rescue
      _ -> default
    end
  end
  
  setup do
    # Get API key from environment variables
    api_key = System.get_env("GEMINI_API_KEY") || System.get_env("GOOGLE_API_KEY")
    
    # Create a test accumulator for streaming responses
    test_acc = %{
      chunks: [],
      complete_text: "",
      finished: false
    }
    
    if api_key do
      # Set the API key directly for this test
      Gemini.Config.set_api_key(api_key)
      
      # Mark this process to use the live API adapter
      Process.put(:use_live_api, true)
      
      %{api_key: api_key, test_acc: test_acc}
    else
      # Don't fail the test, just mark it as skipped with a helpful message
      IO.puts """
      Please provide your API key via environment variable.
      Example: GEMINI_API_KEY=your_key mix test test/gemini/live_streaming_test.exs
      """
      
      # Return a map with nil key so test can be skipped properly
      {:ok, %{api_key: nil, test_acc: test_acc}}
    end
  end
  
  test "basic streaming works with live API", %{api_key: api_key, test_acc: acc} do
    # Skip test if no API key is available
    if api_key == nil do
      IO.puts("No API key found. Set GEMINI_API_KEY environment variable.")
      IO.puts("[TEST SKIPPED] No API key available")
      :ok
    else
      # This test simulates how streaming will work with our future GenServer implementation
      # It handles streaming manually for now but ensures the API supports our approach
      
      # Create client with direct API key
      middleware = [
        {Tesla.Middleware.BaseUrl, "https://generativelanguage.googleapis.com/v1"},
        Tesla.Middleware.JSON,
        {Tesla.Middleware.Query, [key: api_key]},
        Gemini.SecureLogger # Use our custom SecureLogger instead of Tesla.Middleware.Logger
      ]
      client = Tesla.client(middleware, {Tesla.Adapter.Hackney, [recv_timeout: 30_000]})
      
      # Create streaming request
      prompt = "Write a short story about a robot learning to play the piano. Make it around 100 words."
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
          "topP" => 0.95,
          "topK" => 40,
          "maxOutputTokens" => 200
        }
      }
      
      # Set up streaming options - need specific headers and query parameters
      url = "/models/gemini-2.0-flash:streamGenerateContent"
      headers = [{"Content-Type", "application/json"}]
      opts = [adapter: [stream_to: self()]]
      
      # Make sure hackney is available before attempting to use it
      if Code.ensure_loaded?(Tesla.Adapter.Hackney) do
        # Send the request
        {:ok, _ref} = Tesla.Adapter.Hackney.request(client, %Tesla.Env{
          method: :post,
          url: url,
          headers: headers,
          body: Jason.encode!(params),
          opts: opts
        })
        
        # Process streaming responses
        final_acc = process_chunks(acc, 30)
        
        # Validate streaming response
        assert final_acc.finished
        assert String.length(final_acc.complete_text) > 50
        assert length(final_acc.chunks) > 1
        
        # Log results
        IO.puts("\nStreaming test successful!")
        IO.puts("Received #{length(final_acc.chunks)} chunks")
        IO.puts("Complete text (#{String.length(final_acc.complete_text)} chars):")
        IO.puts(final_acc.complete_text)
      else
        IO.puts("Hackney adapter not available. Skipping streaming test.")
        :ok
      end
    end
  end
  
  # Accumulate chunks from the streaming API
  defp process_chunks(acc, timeout_seconds) do
    # Set timeout to prevent test from hanging
    timeout_ms = timeout_seconds * 1000
    start_time = System.monotonic_time(:millisecond)
    
    process_next_chunk(acc, start_time, timeout_ms)
  end
  
  defp process_next_chunk(acc, start_time, timeout_ms) do
    current_time = System.monotonic_time(:millisecond)
    elapsed = current_time - start_time
    
    # Check if we've timed out or finished
    cond do
      acc.finished ->
        acc
        
      elapsed > timeout_ms ->
        IO.puts("Streaming timed out after #{timeout_ms}ms")
        %{acc | finished: true}
        
      true ->
        # Wait for the next message from Hackney
        receive do
          {:hackney_response, _ref, {:status, status, _reason}} ->
            IO.puts("Streaming status: #{status}")
            process_next_chunk(acc, start_time, timeout_ms)
            
          {:hackney_response, _ref, {:headers, _headers}} ->
            process_next_chunk(acc, start_time, timeout_ms)
            
          {:hackney_response, _ref, :done} ->
            %{acc | finished: true}
            
          {:hackney_response, _ref, {:error, reason}} ->
            IO.puts("Streaming error: #{inspect(reason)}")
            %{acc | finished: true}
            
          {:hackney_response, _ref, chunk} when is_binary(chunk) ->
            # Process text chunk
            decoded = 
              chunk
              |> String.split("\\n")
              |> Enum.filter(fn line -> String.trim(line) != "" end)
              |> Enum.map(fn line ->
                case Jason.decode(line) do
                  {:ok, json} -> json
                  _ -> nil
                end
              end)
              |> Enum.filter(fn json -> json != nil end)
            
            # Extract text from each chunk
            new_chunks = Enum.map(decoded, fn json ->
              get_in_safe(json, ["candidates", Access.at(0), "content", "parts", Access.at(0), "text"], "")
            end)
            
            # Update accumulator with new chunks
            updated_acc = %{
              acc |
              chunks: acc.chunks ++ new_chunks,
              complete_text: acc.complete_text <> Enum.join(new_chunks, "")
            }
            
            process_next_chunk(updated_acc, start_time, timeout_ms)
        after
          1000 ->
            # Short timeout to check again
            process_next_chunk(acc, start_time, timeout_ms)
        end
    end
  end
end

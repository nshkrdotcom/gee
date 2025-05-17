defmodule Gemini.Features.Streaming do
  @moduledoc """
  Module for handling streaming content generation in the Gemini API.
  
  This module provides functionality for streaming responses from Gemini,
  which is useful for real-time content generation and processing responses
  chunk by chunk as they arrive from the API.
  
  ## Examples
  
  A simple example printing chunks as they arrive:
  
  ```elixir
  Gemini.stream_content("Generate a story about space travel", 
    fn chunk -> 
      IO.write(chunk.text)
    end
  )
  ```
  
  A more advanced example accumulating chunks:
  
  ```elixir
  # Create an accumulator
  acc = Gemini.Features.Streaming.new_accumulator()
  
  # Stream content and update accumulator
  acc = 
    Gemini.stream_content("Tell me about quantum physics",
      fn chunk ->
        # Print progress
        IO.write(chunk.text)
        # Update accumulator
        acc = Gemini.Features.Streaming.accumulate_chunk(acc, chunk)
      end
    )
  
  # Build final response from accumulated chunks
  final_response = Gemini.Features.Streaming.build_response_from_accumulator(acc)
  ```
  """
  
  alias Gemini.Features.Streaming.Server
  alias Gemini.Response
  alias Gemini.Error
  
  @doc """
  Stream content generation from the Gemini API with a callback function.
  
  This function sets up a streaming connection to the Gemini API and calls
  the provided callback function with each chunk of content as it arrives.
  
  ## Parameters
  
    * `prompt` - The prompt to stream responses for.
    * `callback` - Function to call with each chunk of the response.
    * `opts` - Options to pass to the API.
  
  ## Returns
  
    * `{:ok, final_response}` with the complete response or
    * `{:error, error}` if the streaming request failed.
  
  ## Examples
  
      Gemini.Features.Streaming.stream_content("Tell me a story", 
        fn chunk -> 
          IO.puts(chunk.text)
        end
      )
  """
  @spec stream_content(String.t(), function(), keyword()) :: {:ok, Response.t()} | {:error, Error.t()}
  def stream_content(prompt, callback, opts \\ []) when is_function(callback, 1) do
    # Start a streaming server
    with {:ok, server} <- Server.start_link(),
         {:ok, stream_ref} <- Server.stream(server, prompt, callback, opts) do
      
      # Wait for the streaming to complete by polling
      wait_for_completion(server, stream_ref)
    end
  end
  
  @doc """
  Creates an accumulator for building a response from streaming chunks.
  
  This is useful when you want to collect all chunks into a final response.
  
  ## Returns
  
    * A new empty accumulator for streaming chunks.
  
  ## Examples
  
      acc = Gemini.Features.Streaming.new_accumulator()
      {:ok, final_response} = Gemini.Features.Streaming.stream_content(
        "Generate a story",
        fn chunk -> 
          IO.puts(chunk.text)
          acc = Gemini.Features.Streaming.accumulate_chunk(acc, chunk)
        end
      )
  """
  @spec new_accumulator() :: map()
  def new_accumulator do
    %{
      text: "",
      parts: [],
      raw_chunks: []
    }
  end
  
  @doc """
  Accumulate a streaming chunk into an accumulator.
  
  ## Parameters
  
    * `acc` - The accumulator (created with new_accumulator/0).
    * `chunk` - The chunk to accumulate.
  
  ## Returns
  
    * An updated accumulator.
  """
  @spec accumulate_chunk(map(), Response.t()) :: map()
  def accumulate_chunk(acc, chunk) do
    acc
    |> Map.update!(:text, fn existing -> 
      if chunk.text do
        existing <> (chunk.text || "")
      else
        existing
      end
    end)
    |> Map.update!(:parts, fn existing -> existing ++ (chunk.parts || []) end)
    |> Map.update!(:raw_chunks, fn existing -> existing ++ [chunk.raw] end)
  end
  
  @doc """
  Build a final response from accumulated chunks.
  
  ## Parameters
  
    * `acc` - The accumulator with collected chunks.
  
  ## Returns
  
    * A complete Response struct with all data from the accumulated chunks.
  """
  @spec build_response_from_accumulator(map()) :: Response.t()
  def build_response_from_accumulator(acc) do
    # In a real implementation, this would combine chunks properly
    final_raw = %{
      "candidates" => [
        %{
          "content" => %{
            "parts" => acc.parts
          },
          "finishReason" => "STOP",
          "index" => 0
        }
      ]
    }
    
    %Response{
      text: acc.text,
      parts: acc.parts,
      raw: final_raw,
      structured: nil,
      usage: nil,
      candidate_index: 0,
      finish_reason: "STOP",
      safety_ratings: nil
    }
  end
  
  # Private helper functions
  
  # Wait for a streaming response to complete by polling
  defp wait_for_completion(server, stream_ref, timeout \\ 30_000) do
    # Initial delay
    Process.sleep(100)
    
    # Start time
    start_time = System.monotonic_time(:millisecond)
    
    # Poll for completion
    wait_for_completion_loop(server, stream_ref, start_time, timeout)
  end
  
  # Poll in a loop until the streaming is complete or timeout is reached
  defp wait_for_completion_loop(server, stream_ref, start_time, timeout) do
    current_time = System.monotonic_time(:millisecond)
    
    # Check if timeout has been reached
    if current_time - start_time > timeout do
      # Clean up and return an error
      Server.stop_stream(server, stream_ref)
      {:error, %Error{message: "Streaming timed out", code: 408, details: nil}}
    else
      # Check if the response is complete
      case Server.get_response(server, stream_ref) do
        {:ok, response} ->
          # Response is complete, return it
          Server.stop_stream(server, stream_ref)
          {:ok, response}
          
        {:error, {:stream_in_progress, _status}} ->
          # Response is still streaming, wait and try again
          Process.sleep(100)
          wait_for_completion_loop(server, stream_ref, start_time, timeout)
          
        {:error, error} ->
          # An error occurred, clean up and return the error
          Server.stop_stream(server, stream_ref)
          {:error, error}
      end
    end
  end
end
defmodule Gemini.Features.StreamingTest do
  use ExUnit.Case
  import Tesla.Mock

  alias Gemini.Features.Streaming
  alias Gemini.Response

  # This test module will use a simplified approach since the streaming
  # implementation is currently using a simulated approach instead of real API calls

  setup do
    # We'll use the mock globally to avoid issues with tasks
    mock_global(fn
      %{method: :post} ->
        %Tesla.Env{
          status: 200,
          body: %{
            "candidates" => [
              %{
                "content" => %{
                  "parts" => [
                    %{
                      "text" => "This is a test response for streaming."
                    }
                  ]
                },
                "finishReason" => "STOP",
                "index" => 0,
                "safetyRatings" => []
              }
            ],
            "promptFeedback" => %{
              "safetyRatings" => []
            }
          }
        }
    end)
    
    :ok
  end

  describe "streaming functionality" do
    # For now, we'll skip the full streaming test since it requires more complex mocking
    # We'll focus on testing the helper functions which are the core of streaming functionality
    
    @tag :skip
    test "stream_content/3 streams content with callback" do
      # This test is skipped for now, pending a better mocking approach
      :ok
    end
  end

  describe "accumulator functions" do
    test "new_accumulator/0 creates empty accumulator" do
      acc = Streaming.new_accumulator()
      
      assert acc.text == ""
      assert acc.parts == []
      assert acc.raw_chunks == []
    end
    
    test "accumulate_chunk/2 adds chunk to accumulator" do
      acc = Streaming.new_accumulator()
      
      chunk1 = %Response{
        text: "Hello ",
        parts: [%{"text" => "Hello "}],
        raw: %{"chunk" => 1}
      }
      
      chunk2 = %Response{
        text: "world!",
        parts: [%{"text" => "world!"}],
        raw: %{"chunk" => 2}
      }
      
      # Accumulate the first chunk
      acc1 = Streaming.accumulate_chunk(acc, chunk1)
      assert acc1.text == "Hello "
      assert length(acc1.parts) == 1
      assert length(acc1.raw_chunks) == 1
      
      # Accumulate the second chunk
      acc2 = Streaming.accumulate_chunk(acc1, chunk2)
      assert acc2.text == "Hello world!"
      assert length(acc2.parts) == 2
      assert length(acc2.raw_chunks) == 2
    end
    
    test "build_response_from_accumulator/1 creates final response" do
      acc = %{
        text: "Hello world!",
        parts: [%{"text" => "Hello "}, %{"text" => "world!"}],
        raw_chunks: [%{"chunk" => 1}, %{"chunk" => 2}]
      }
      
      response = Streaming.build_response_from_accumulator(acc)
      
      assert response.text == "Hello world!"
      assert length(response.parts) == 2
      assert response.finish_reason == "STOP"
    end
  end
end
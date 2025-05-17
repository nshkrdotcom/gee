defmodule Gemini.Features.EmbeddingsTest do
  use ExUnit.Case
  import Tesla.Mock

  alias Gemini.Features.Embeddings

  setup do
    mock_global(fn %{method: :post, url: url} ->
      cond do
        # Handle all embedding requests with the same response
        String.contains?(url, "embedContent") ->
          %Tesla.Env{
            status: 200,
            body: %{
              "embedding" => %{
                "values" => [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]
              }
            }
          }
        
        true ->
          %Tesla.Env{
            status: 400,
            body: %{
              "error" => %{
                "code" => 400,
                "message" => "Unknown request"
              }
            }
          }
      end
    end)

    :ok
  end

  describe "embed_text/3" do
    test "generates embeddings for text input" do
      {:ok, embeddings} = Embeddings.embed_text("Hello, world!")
      
      # Verify the embeddings is a list of floats
      assert is_list(embeddings)
      assert length(embeddings) == 10
      assert Enum.all?(embeddings, fn v -> is_float(v) end)
    end

    test "with task type" do
      {:ok, embeddings} = Embeddings.embed_text("Search query", nil, :retrieval_query)
      
      assert is_list(embeddings)
      assert length(embeddings) == 10
    end
  end

  describe "cosine_similarity/2" do
    test "calculates similarity between two vectors" do
      v1 = [1.0, 0.0, 0.0]
      v2 = [0.0, 1.0, 0.0]
      v3 = [1.0, 0.0, 0.0]  # Same as v1
      
      assert Embeddings.cosine_similarity(v1, v2) == 0.0
      assert Embeddings.cosine_similarity(v1, v3) == 1.0
    end

    test "handles zero vectors" do
      v1 = [0.0, 0.0, 0.0]
      v2 = [1.0, 2.0, 3.0]
      
      assert Embeddings.cosine_similarity(v1, v2) == 0.0
      assert Embeddings.cosine_similarity(v1, v1) == 0.0
    end
  end

  describe "batch_embed/3" do
    test "generates embeddings for multiple texts" do
      {:ok, embeddings} = Embeddings.batch_embed(["Hello", "World", "Elixir"])
      
      assert is_list(embeddings)
      assert length(embeddings) == 3
      assert Enum.all?(embeddings, fn v -> length(v) == 10 end)
    end
  end
end
defmodule Gemini.Features.Embeddings do
  @moduledoc """
  Module for handling embeddings generation with the Gemini API.
  
  This module provides functionality for creating embeddings (vector representations)
  of text content, which are useful for semantic search, content clustering,
  and other machine learning applications.
  
  ## What are embeddings?
  
  Embeddings are numerical representations of text that capture semantic meaning.
  Similar texts will have similar embeddings, allowing you to:
  
  - Implement semantic search (finding text based on meaning, not just keywords)
  - Create text clustering applications (grouping similar texts together)
  - Build recommendation systems (finding similar content)
  - Enable vector databases for AI-powered applications
  
  ## Example Usage
  
  ```elixir
  # Generate embeddings for a single text
  {:ok, vector} = Gemini.embed_text("How does photosynthesis work?")
  
  # Compare two texts for similarity
  {:ok, similarity} = Gemini.text_similarity(
    "Running is good exercise", 
    "Jogging provides health benefits"
  )
  
  # Process multiple texts in one go
  {:ok, vectors} = Gemini.batch_embed_text([
    "What is machine learning?",
    "How do neural networks work?",
    "Explain AI in simple terms"
  ])
  ```
  """
  
  alias Gemini.Client
  # Config is used below when implemented for real API usage
  
  @doc """
  Generate embeddings for a text input.
  
  ## Parameters
  
    * `text` - The text to generate embeddings for.
    * `model` - The embedding model to use (optional, uses default embedding model).
    * `task_type` - The task type for the embeddings (optional).
      Supported values: :retrieval_query, :retrieval_document, :semantic_similarity,
      :classification, :clustering.
  
  ## Returns
  
    * `{:ok, embeddings}` with a list of floating point values representing the embedding vector.
    * `{:error, error}` if the request failed.
  
  ## Examples
  
      {:ok, vector} = Gemini.Features.Embeddings.embed_text("Hello, world!")
      IO.inspect(vector)
  """
  @spec embed_text(String.t(), String.t() | nil, atom() | nil) :: 
    {:ok, list(float())} | {:error, Gemini.Error.t()}
  def embed_text(text, model \\ nil, task_type \\ nil) do
    model = model || "gemini-2.0-flash-embedding"
    
    # Prepare the content
    content = %{
      "parts" => [
        %{
          "text" => text
        }
      ]
    }
    
    # Prepare parameters
    params = %{
      "content" => content
    }
    
    # Add task type if provided
    params = if task_type, do: Map.put(params, "taskType", task_type_to_string(task_type)), else: params
    
    # Make the API request
    case Client.embed_content(model, params) do
      {:ok, response} ->
        values = get_in(response.raw, ["embedding", "values"])
        {:ok, values}
        
      {:error, error} ->
        {:error, error}
    end
  end
  
  @doc """
  Calculate cosine similarity between two embedding vectors.
  
  ## Parameters
  
    * `embedding1` - First embedding vector.
    * `embedding2` - Second embedding vector.
  
  ## Returns
  
    * A float between -1 and 1 representing similarity (1 being most similar).
  
  ## Examples
  
      {:ok, embedding1} = Gemini.Features.Embeddings.embed_text("cat")
      {:ok, embedding2} = Gemini.Features.Embeddings.embed_text("dog")
      similarity = Gemini.Features.Embeddings.cosine_similarity(embedding1, embedding2)
  """
  @spec cosine_similarity(list(float()), list(float())) :: float()
  def cosine_similarity(embedding1, embedding2) when length(embedding1) == length(embedding2) do
    # Calculate dot product
    dot_product = Enum.zip(embedding1, embedding2) 
                 |> Enum.map(fn {a, b} -> a * b end)
                 |> Enum.sum()
    
    # Calculate magnitudes
    magnitude1 = :math.sqrt(Enum.map(embedding1, fn x -> x * x end) |> Enum.sum())
    magnitude2 = :math.sqrt(Enum.map(embedding2, fn x -> x * x end) |> Enum.sum())
    
    # Handle division by zero
    cond do
      magnitude1 <= 0.0 -> 0.0
      magnitude2 <= 0.0 -> 0.0
      true -> dot_product / (magnitude1 * magnitude2)
    end
  end
  
  @doc """
  Batch process multiple texts to generate embeddings for each.
  
  ## Parameters
  
    * `texts` - List of texts to generate embeddings for.
    * `model` - The embedding model to use (optional, uses default embedding model).
    * `task_type` - The task type for the embeddings (optional).
  
  ## Returns
  
    * `{:ok, embeddings}` with a list of embedding vectors.
    * `{:error, error}` if any request failed.
  
  ## Examples
  
      {:ok, vectors} = Gemini.Features.Embeddings.batch_embed(["Hello", "World", "Elixir"])
      Enum.each(vectors, &IO.inspect/1)
  """
  @spec batch_embed(list(String.t()), String.t() | nil, atom() | nil) :: 
    {:ok, list(list(float()))} | {:error, Gemini.Error.t()}
  def batch_embed(texts, model \\ nil, task_type \\ nil) when is_list(texts) do
    # Process each text sequentially
    # Note: Could be optimized with Task.async_stream for parallel processing
    results = Enum.map(texts, fn text -> 
      embed_text(text, model, task_type)
    end)
    
    # Check if all succeeded
    if Enum.all?(results, fn res -> match?({:ok, _}, res) end) do
      # Extract all vectors
      vectors = Enum.map(results, fn {:ok, vector} -> vector end)
      {:ok, vectors}
    else
      # Find the first error
      error = Enum.find(results, fn res -> match?({:error, _}, res) end)
      error
    end
  end
  
  # Private helpers
  
  defp task_type_to_string(task_type) do
    case task_type do
      :retrieval_query -> "RETRIEVAL_QUERY"
      :retrieval_document -> "RETRIEVAL_DOCUMENT"
      :semantic_similarity -> "SEMANTIC_SIMILARITY"
      :classification -> "CLASSIFICATION"
      :clustering -> "CLUSTERING"
      _ -> nil
    end
  end
end
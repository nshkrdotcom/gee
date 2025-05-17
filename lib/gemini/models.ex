defmodule Gemini.Models do
  @moduledoc """
  Utilities for working with Gemini AI models.
  """

  @models %{
    "gemini-2.0-flash" => %{
      description: "The Gemini Pro 1.0 model for text generation.",
      supports: [:text, :images, :chat, :structured_output, :function_calling]
    },
    # "gemini-1.0-pro-vision" => %{
    #   description: "The Gemini Pro 1.0 Vision model for text and image inputs.",
    #   supports: [:text, :images, :chat, :structured_output]
    # },
    # "gemini-1.5-pro" => %{
    #   description: "The Gemini Pro 1.5 model for enhanced text and multimodal capabilities.",
    #   supports: [:text, :images, :audio, :video, :chat, :structured_output, :function_calling]
    # },
    # "gemini-1.5-flash" => %{
    #   description: "The Gemini Flash 1.5 model for fast, efficient responses.",
    #   supports: [:text, :images, :audio, :chat, :structured_output, :function_calling]
    # },
    "embedding-001" => %{
      description: "Text embedding model for generating vector representations.",
      supports: [:embeddings]
    }
  }

  @doc """
  Returns a list of available Gemini models.
  """
  @spec list() :: [String.t()]
  def list do
    Map.keys(@models)
  end

  @doc """
  Returns information about a specific model.
  """
  @spec info(String.t()) :: map() | nil
  def info(model) do
    Map.get(@models, model)
  end

  @doc """
  Checks if a given model supports a specific feature.
  """
  @spec supports?(String.t(), atom()) :: boolean()
  def supports?(model, feature) do
    with %{supports: features} <- info(model) do
      feature in features
    else
      _ -> false
    end
  end

  @doc """
  Checks if a model is valid.
  """
  @spec valid?(String.t()) :: boolean()
  def valid?(model) do
    Map.has_key?(@models, model)
  end

  @doc """
  Returns all models that support a given feature.
  """
  @spec with_feature(atom()) :: [String.t()]
  def with_feature(feature) do
    @models
    |> Enum.filter(fn {_model, %{supports: features}} -> feature in features end)
    |> Enum.map(fn {model, _info} -> model end)
  end
end

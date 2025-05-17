defmodule Gemini.Safety do
  @moduledoc """
  Utilities for working with Gemini AI safety settings.

  This module provides helper functions for configuring safety thresholds
  and handling safety ratings in responses.
  """

  @harm_categories [
    :harassment,
    :hate_speech,
    :sexually_explicit,
    :dangerous_content
  ]

  @harm_block_thresholds [
    :none,           # Block no content
    :low,            # Block low threshold and above
    :medium,         # Block medium threshold and above
    :high            # Block only high threshold content
  ]

  @doc """
  Creates a safety setting for a specific harm category.

  ## Parameters

    * `category` - The harm category to set a threshold for.
    * `threshold` - The blocking threshold for the category.

  ## Examples

      iex> Gemini.Safety.create_safety_setting(:harassment, :high)
      %{
        "category" => "HARM_CATEGORY_HARASSMENT",
        "threshold" => "BLOCK_ONLY_HIGH"
      }
  """
  @spec create_safety_setting(atom(), atom()) :: map()
  def create_safety_setting(category, threshold) 
      when category in @harm_categories and threshold in @harm_block_thresholds do
    %{
      "category" => category_to_string(category),
      "threshold" => threshold_to_string(threshold)
    }
  end

  @doc """
  Creates a list of safety settings with default thresholds.

  By default, sets all categories to the medium blocking threshold.

  ## Parameters

    * `threshold` - Optional default threshold to apply to all categories.

  ## Examples

      iex> Gemini.Safety.default_safety_settings()
      [
        %{"category" => "HARM_CATEGORY_HARASSMENT", "threshold" => "BLOCK_MEDIUM_AND_ABOVE"},
        %{"category" => "HARM_CATEGORY_HATE_SPEECH", "threshold" => "BLOCK_MEDIUM_AND_ABOVE"},
        %{"category" => "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold" => "BLOCK_MEDIUM_AND_ABOVE"},
        %{"category" => "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold" => "BLOCK_MEDIUM_AND_ABOVE"}
      ]
  """
  @spec default_safety_settings(atom()) :: list(map())
  def default_safety_settings(threshold \\ :medium) when threshold in @harm_block_thresholds do
    Enum.map(@harm_categories, fn category ->
      create_safety_setting(category, threshold)
    end)
  end

  @doc """
  Interprets safety ratings from a Gemini API response.

  ## Parameters

    * `safety_ratings` - The safety ratings list from a response.

  ## Returns

    * A list of maps with interpreted safety information.
  """
  @spec interpret_safety_ratings(list(map())) :: list(map())
  def interpret_safety_ratings(safety_ratings) when is_list(safety_ratings) do
    Enum.map(safety_ratings, fn rating ->
      category = Map.get(rating, "category", "")
      category_name = case category do
        "HARM_CATEGORY_HARASSMENT" -> :harassment
        "HARM_CATEGORY_HATE_SPEECH" -> :hate_speech
        "HARM_CATEGORY_SEXUALLY_EXPLICIT" -> :sexually_explicit
        "HARM_CATEGORY_DANGEROUS_CONTENT" -> :dangerous_content
        _ -> :unknown
      end

      probability = Map.get(rating, "probability", "")
      probability_value = case probability do
        "NEGLIGIBLE" -> :negligible
        "LOW" -> :low
        "MEDIUM" -> :medium
        "HIGH" -> :high
        _ -> :unknown
      end

      %{
        category: category_name,
        probability: probability_value,
        raw: rating
      }
    end)
  end
  def interpret_safety_ratings(_), do: []

  # Private helper functions

  defp category_to_string(:harassment), do: "HARM_CATEGORY_HARASSMENT"
  defp category_to_string(:hate_speech), do: "HARM_CATEGORY_HATE_SPEECH"
  defp category_to_string(:sexually_explicit), do: "HARM_CATEGORY_SEXUALLY_EXPLICIT"
  defp category_to_string(:dangerous_content), do: "HARM_CATEGORY_DANGEROUS_CONTENT"

  defp threshold_to_string(:none), do: "BLOCK_NONE"
  defp threshold_to_string(:low), do: "BLOCK_LOW_AND_ABOVE"
  defp threshold_to_string(:medium), do: "BLOCK_MEDIUM_AND_ABOVE"
  defp threshold_to_string(:high), do: "BLOCK_ONLY_HIGH"
end
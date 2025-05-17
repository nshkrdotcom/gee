defmodule Gemini.Response do
  @moduledoc """
  Represents a response from the Gemini API.
  """

  @type t :: %__MODULE__{
          text: String.t() | nil,
          parts: [map()],
          raw: map(),
          structured: map() | nil,
          usage: map() | nil,
          candidate_index: integer(),
          finish_reason: String.t() | nil,
          safety_ratings: [map()] | nil
        }

  defstruct [
    :text,
    :parts,
    :raw,
    :structured,
    :usage,
    :candidate_index,
    :finish_reason,
    :safety_ratings
  ]

  @doc """
  Parses a raw API response into a `Gemini.Response` struct.
  """
  @spec parse(map()) :: t()
  def parse(response = %{}) do
    candidates = Map.get(response, "candidates", [])
    candidate = List.first(candidates) || %{}
    
    content = Map.get(candidate, "content", %{})
    parts = Map.get(content, "parts", [])
    
    # Extract text from parts
    text = extract_text(parts)
    
    # Extract structured output if available
    structured = extract_structured_output(parts)
    
    # Extract other fields
    usage = Map.get(response, "usageMetadata")
    candidate_index = Map.get(candidate, "index", 0)
    finish_reason = Map.get(candidate, "finishReason")
    safety_ratings = Map.get(candidate, "safetyRatings")
    
    %__MODULE__{
      text: text,
      parts: parts,
      raw: response,
      structured: structured,
      usage: usage,
      candidate_index: candidate_index,
      finish_reason: finish_reason,
      safety_ratings: safety_ratings
    }
  end
  
  # Extract text from parts
  defp extract_text(parts) do
    parts
    |> Enum.filter(fn part -> Map.has_key?(part, "text") end)
    |> Enum.map(fn part -> Map.get(part, "text", "") end)
    |> Enum.join("\n")
    |> case do
      "" -> nil
      text -> text
    end
  end
  
  # Extract structured output if available
  defp extract_structured_output(parts) do
    function_call_part = Enum.find(parts, fn part -> Map.has_key?(part, "functionCall") end)
    
    case function_call_part do
      nil -> 
        # Check for inline JSON in text parts
        text = extract_text(parts)
        case extract_json_from_text(text) do
          {:ok, json} -> json
          _ -> nil
        end
      %{"functionCall" => function_call} ->
        name = Map.get(function_call, "name", "")
        args = Map.get(function_call, "args", %{})
        
        # Return args for both structured_output and json_object function calls
        if name == "json_object" || name == "structured_output" do
          args
        else
          nil
        end
    end
  end
  
  # Try to extract JSON from text (for structured output in text format)
  defp extract_json_from_text(nil), do: {:error, :no_text}
  defp extract_json_from_text(text) do
    # Look for JSON-like content in triple backticks
    case Regex.run(~r/```(?:json)?\s*({[\s\S]*?})\s*```/m, text) do
      [_, json_str] ->
        Jason.decode(json_str)
      nil ->
        # Try parsing the whole text as JSON
        Jason.decode(text)
    end
  end
end

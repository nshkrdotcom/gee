defmodule Gemini.Error do
  @moduledoc """
  Represents an error that occurred while making a request to the Gemini API.
  """

  @type t :: %__MODULE__{
          message: String.t(),
          code: integer(),
          details: any()
        }

  defstruct [:message, :code, :details]
end

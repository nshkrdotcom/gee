defmodule Gemini.Test.MockClient do
  @moduledoc """
  Provides mock functionality for testing the Gemini client.
  """

  @doc """
  Sets up Tesla mock for Gemini API responses.
  """
  def setup_mock do
    Tesla.Mock.mock(fn
      %{method: :post, url: url} ->
        cond do
          String.contains?(url, "generateContent") and not String.contains?(url, "error_case") ->
            # Mock successful response for generate_content
            %Tesla.Env{
              status: 200,
              body: %{
                "candidates" => [
                  %{
                    "content" => %{
                      "parts" => [
                        %{
                          "text" => "This is a test response from the Gemini API."
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
            
          String.contains?(url, "error_case") ->
            # Mock an error response
            %Tesla.Env{
              status: 400,
              body: %{
                "error" => %{
                  "code" => 400,
                  "message" => "Invalid request"
                }
              }
            }
            
          String.contains?(url, "countTokens") ->
            # Mock response for count_tokens
            %Tesla.Env{
              status: 200,
              body: %{
                "totalTokens" => 42
              }
            }
            
          String.contains?(url, "embedContent") ->
            # Mock response for embed_content
            %Tesla.Env{
              status: 200,
              body: %{
                "embedding" => %{
                  "values" => [0.1, 0.2, 0.3, 0.4]
                }
              }
            }
            
          true ->
            # Default response for other requests
            %Tesla.Env{status: 404, body: %{"error" => %{"message" => "Not found"}}}
        end
    end)
  end

  @doc """
  Mocks a successful response for text generation.
  """
  def mock_text_generation(text \\ "This is a test response from the Gemini API.") do
    Tesla.Mock.mock(fn
      %{method: :post} ->
        %Tesla.Env{
          status: 200,
          body: %{
            "candidates" => [
              %{
                "content" => %{
                  "parts" => [
                    %{
                      "text" => text
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
  end

  @doc """
  Mocks a structured output response.
  """
  def mock_structured_output(structured_data) do
    Tesla.Mock.mock(fn
      %{method: :post} ->
        %Tesla.Env{
          status: 200,
          body: %{
            "candidates" => [
              %{
                "content" => %{
                  "parts" => [
                    %{
                      "functionCall" => %{
                        "name" => "json_object",
                        "args" => structured_data
                      }
                    }
                  ]
                },
                "finishReason" => "STOP",
                "index" => 0,
                "safetyRatings" => []
              }
            ]
          }
        }
    end)
  end

  @doc """
  Mocks an error response.
  """
  def mock_error_response(code, message) do
    Tesla.Mock.mock(fn
      %{method: :post} ->
        %Tesla.Env{
          status: code,
          body: %{
            "error" => %{
              "code" => code,
              "message" => message
            }
          }
        }
    end)
  end
end
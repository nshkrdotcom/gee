defmodule Gemini.AdvancedFeaturesTest do
  use ExUnit.Case
  # Tesla.Mock is actually used in tests
  import Tesla.Mock

  # Removing unused Response alias
  # alias Gemini.Response
  alias Gemini.Features.Multimodal

  setup do
    # Mock the behavior for each test specifically to avoid conflicts
    :ok
  end
  
  # Set up multimodal mocks for the multimodal tests
  # We're going to use simpler direct mocks in each test
  
  setup do
    # Create a temporary image file for testing
    tmp_dir = System.tmp_dir!()
    img_path = Path.join(tmp_dir, "test_image.jpg")
    
    # Create an empty file
    File.write!(img_path, "FAKE IMAGE DATA")
    
    on_exit(fn ->
      # Clean up the file after test
      File.rm(img_path)
    end)
    
    {:ok, %{image_path: img_path}}
  end

  describe "Multimodal input" do
    test "generates content from text and images", %{image_path: image_path} do
      # Set up a universal mock that accepts all generate content calls
      Tesla.Mock.mock(fn %{method: :post, url: url} ->
        if String.contains?(url, "generateContent") do
          %Tesla.Env{
            status: 200,
            body: %{
              "candidates" => [
                %{
                  "content" => %{
                    "parts" => [
                      %{
                        "text" => "The image shows a landscape with mountains and trees."
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
        else
          %Tesla.Env{
            status: 400,
            body: %{
              "error" => %{
                "code" => 400,
                "message" => "Invalid request"
              }
            }
          }
        end
      end)
      
      {:ok, response} = Gemini.generate_with_images(
        "Describe this image",
        [image_path]
      )
      
      assert response.text =~ "The image shows a landscape"
      assert response.finish_reason == "STOP"
    end
    
    test "handles image part creation", %{image_path: image_path} do
      # Create an image part
      image_part = Multimodal.Images.image_part_from_file(image_path)
      
      # Check the structure
      assert Map.has_key?(image_part, "inlineData")
      assert Map.has_key?(image_part["inlineData"], "data")
      assert Map.has_key?(image_part["inlineData"], "mimeType")
    end
    
    test "creates multimodal content", %{image_path: image_path} do
      # Create image parts
      image_part = Multimodal.Images.image_part_from_file(image_path)
      
      # Create multimodal content
      content = Multimodal.Images.create_multimodal_content("Describe this image", [image_part])
      
      # Check structure
      assert is_map(content)
      assert Map.has_key?(content, "parts")
      assert length(content["parts"]) == 2
      assert Enum.at(content["parts"], 0)["text"] == "Describe this image"
      assert Map.has_key?(Enum.at(content["parts"], 1), "inlineData")
    end
  end
  
  describe "System instructions" do
    test "generates content with system instructions" do
      # Set up a universal mock for system instruction test
      Tesla.Mock.mock(fn %{method: :post, url: url} ->
        if String.contains?(url, "generateContent") do
          %Tesla.Env{
            status: 200,
            body: %{
              "candidates" => [
                %{
                  "content" => %{
                    "parts" => [
                      %{
                        "text" => "Response following the system instructions."
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
        else
          %Tesla.Env{
            status: 400,
            body: %{
              "error" => %{
                "code" => 400,
                "message" => "Invalid request"
              }
            }
          }
        end
      end)
      
      system_instruction = "You are a helpful assistant that speaks in a formal tone."
      
      {:ok, response} = Gemini.generate_content(
        "Tell me about yourself",
        system_instruction: system_instruction
      )
      
      assert response.text =~ "Response following the system instructions"
    end
  end
  
  describe "Safety settings" do
    test "generates content with custom safety settings" do
      # Set up a universal mock for safety settings test
      Tesla.Mock.mock(fn %{method: :post, url: url} ->
        if String.contains?(url, "generateContent") do
          %Tesla.Env{
            status: 200,
            body: %{
              "candidates" => [
                %{
                  "content" => %{
                    "parts" => [
                      %{
                        "text" => "Response with custom safety settings."
                      }
                    ]
                  },
                  "finishReason" => "STOP",
                  "index" => 0,
                  "safetyRatings" => []
                }
              ],
              "promptFeedback" => %{
                "safetyRatings" => [
                  %{
                    "category" => "HARM_CATEGORY_SEXUALLY_EXPLICIT",
                    "probability" => "NEGLIGIBLE"
                  },
                  %{
                    "category" => "HARM_CATEGORY_HATE_SPEECH",
                    "probability" => "NEGLIGIBLE"
                  }
                ]
              }
            }
          }
        else
          %Tesla.Env{
            status: 400,
            body: %{
              "error" => %{
                "code" => 400,
                "message" => "Invalid request"
              }
            }
          }
        end
      end)
      
      safety_settings = [
        %{
          "category" => "HARM_CATEGORY_SEXUALLY_EXPLICIT",
          "threshold" => "BLOCK_MEDIUM_AND_ABOVE"
        },
        %{
          "category" => "HARM_CATEGORY_HATE_SPEECH",
          "threshold" => "BLOCK_MEDIUM_AND_ABOVE"
        }
      ]
      
      {:ok, response} = Gemini.generate_content(
        "Tell me a story",
        safety_settings: safety_settings
      )
      
      assert response.text =~ "Response with custom safety settings"
      assert response.safety_ratings != nil
    end
  end
  
  describe "Token counting" do
    test "counts tokens in text" do
      # Set up a universal mock for token counting test
      Tesla.Mock.mock(fn %{method: :post, url: url} ->
        if String.contains?(url, "countTokens") do
          %Tesla.Env{
            status: 200,
            body: %{
              "totalTokens" => 42
            }
          }
        else
          %Tesla.Env{
            status: 400,
            body: %{
              "error" => %{
                "code" => 400,
                "message" => "Invalid request"
              }
            }
          }
        end
      end)
      
      {:ok, token_count} = Gemini.count_tokens("This is a test sentence to count tokens.")
      
      assert is_integer(token_count)
      assert token_count == 42
    end
  end
end
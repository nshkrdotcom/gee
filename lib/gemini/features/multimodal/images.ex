defmodule Gemini.Features.Multimodal.Images do
  @moduledoc """
  Module for handling image-related operations with the Gemini API.
  
  This module provides utilities for working with images in Gemini API requests,
  including encoding, preparing image parts for multimodal inputs, and handling
  image generation capabilities.
  """
  
  @doc """
  Creates a content part for an image from a file path.
  
  ## Parameters
  
    * `file_path` - Path to the image file.
    * `mime_type` - MIME type of the image (optional, will be inferred if not provided).
  
  ## Returns
  
    * A map representing an image content part for use in Gemini requests.
  
  ## Examples
  
      image_part = Gemini.Features.Multimodal.Images.image_part_from_file("path/to/image.jpg")
  """
  @spec image_part_from_file(String.t(), String.t() | nil) :: map()
  def image_part_from_file(file_path, mime_type \\ nil) do
    mime_type = mime_type || infer_mime_type(file_path)
    
    # Read the file and encode to base64
    data = File.read!(file_path) |> Base.encode64()
    
    # Create the image part
    %{
      "inlineData" => %{
        "mimeType" => mime_type,
        "data" => data
      }
    }
  end
  
  @doc """
  Creates a content part for an image from binary data.
  
  ## Parameters
  
    * `data` - Binary image data.
    * `mime_type` - MIME type of the image.
  
  ## Returns
  
    * A map representing an image content part for use in Gemini requests.
  
  ## Examples
  
      image_data = File.read!("path/to/image.jpg")
      image_part = Gemini.Features.Multimodal.Images.image_part_from_data(image_data, "image/jpeg")
  """
  @spec image_part_from_data(binary(), String.t()) :: map()
  def image_part_from_data(data, mime_type) when is_binary(data) do
    # Encode binary data to base64
    encoded_data = Base.encode64(data)
    
    # Create the image part
    %{
      "inlineData" => %{
        "mimeType" => mime_type,
        "data" => encoded_data
      }
    }
  end
  
  @doc """
  Creates a content part for an image from a URL.
  
  ## Parameters
  
    * `url` - URL of the image.
  
  ## Returns
  
    * A map representing an image content part for use in Gemini requests.
  
  ## Examples
  
      image_part = Gemini.Features.Multimodal.Images.image_part_from_url("https://example.com/image.jpg")
  """
  @spec image_part_from_url(String.t()) :: map()
  def image_part_from_url(url) when is_binary(url) do
    %{
      "fileData" => %{
        "fileUri" => url
      }
    }
  end
  
  @doc """
  Create a multimodal content object with text and images.
  
  ## Parameters
  
    * `text` - Text to include in the content.
    * `image_parts` - List of image parts to include.
  
  ## Returns
  
    * A map representing a multimodal content object for use in Gemini requests.
  
  ## Examples
  
      image_part = Gemini.Features.Multimodal.Images.image_part_from_file("image.jpg")
      content = Gemini.Features.Multimodal.Images.create_multimodal_content(
        "Describe this image:", 
        [image_part]
      )
  """
  @spec create_multimodal_content(String.t(), list(map())) :: map()
  def create_multimodal_content(text, image_parts) when is_binary(text) and is_list(image_parts) do
    parts = [%{"text" => text} | image_parts]
    
    %{
      "parts" => parts
    }
  end
  
  # Private helper functions
  
  @doc false
  defp infer_mime_type(file_path) do
    case Path.extname(file_path) |> String.downcase() do
      ".jpg" -> "image/jpeg"
      ".jpeg" -> "image/jpeg"
      ".png" -> "image/png"
      ".gif" -> "image/gif"
      ".webp" -> "image/webp"
      ".heic" -> "image/heic"
      ".heif" -> "image/heif"
      _ -> "application/octet-stream"
    end
  end
end
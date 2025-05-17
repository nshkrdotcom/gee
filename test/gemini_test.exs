defmodule GeminiTest do
  use ExUnit.Case
  doctest Gemini

  alias Gemini.Config
  alias Gemini.Test.MockClient

  setup do
    # Set a dummy API key for testing
    Config.set_api_key("test_api_key")
    Config.set_default_model("gemini-2.0-flash")
    
    # Set up mocks
    MockClient.setup_mock()
    
    :ok
  end

  test "generate_content with basic prompt" do
    # Specifically mock the text generation for this test
    MockClient.mock_text_generation("This is a test response from the Gemini API.")
    
    # Test the main API function
    {:ok, response} = Gemini.generate_content("Hello, Gemini!")
    
    assert is_binary(response.text)
    assert response.text == "This is a test response from the Gemini API."
    assert response.finish_reason == "STOP"
    assert response.candidate_index == 0
  end

  test "Gemini.Models lists available models" do
    models = Gemini.Models.list()
    
    assert is_list(models)
    assert "gemini-2.0-flash" in models
  end

  test "Gemini.Models.supports? checks model capabilities" do
    assert Gemini.Models.supports?("gemini-2.0-flash", :text)
    assert Gemini.Models.supports?("gemini-2.0-flash", :images)
    # assert Gemini.Models.supports?("gemini-2.0-flash", :audio)
    refute Gemini.Models.supports?("embedding-001", :audio)
    assert Gemini.Models.supports?("embedding-001", :embeddings)
  end
  
  test "safety settings can be created" do
    # This is a local test that doesn't hit the API
    setting = Gemini.Safety.create_safety_setting(:harassment, :medium)
    
    assert setting == %{
      "category" => "HARM_CATEGORY_HARASSMENT",
      "threshold" => "BLOCK_MEDIUM_AND_ABOVE"
    }
  end

  test "default safety settings include all harm categories" do
    settings = Gemini.Safety.default_safety_settings()
    
    assert length(settings) == 4
    assert Enum.all?(settings, fn setting -> 
      Map.has_key?(setting, "category") && Map.has_key?(setting, "threshold")
    end)
  end
end

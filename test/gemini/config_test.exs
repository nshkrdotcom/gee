defmodule Gemini.ConfigTest do
  use ExUnit.Case
  # Not using CaptureIO in these tests
  # import ExUnit.CaptureIO
  
  alias Gemini.Config
  
  describe "api_key/0" do
    setup do
      # Save original config and env values to restore later
      original_api_key = Application.get_env(:gemini, :api_key)
      
      # Clear application config for testing
      if original_api_key != nil do
        Application.delete_env(:gemini, :api_key)
      end
      
      on_exit(fn ->
        # Restore original config
        if original_api_key != nil do
          Application.put_env(:gemini, :api_key, original_api_key)
        else
          Application.delete_env(:gemini, :api_key)
        end
      end)
      
      %{original_api_key: original_api_key}
    end
    
    test "returns value from application config" do
      expected_key = "app_config_key"
      Config.set_api_key(expected_key)
      
      assert Config.api_key() == expected_key
    end
    
    test "returns nil when no key found anywhere" do
      # We need to mock the System.get_env function to ensure test reliability
      :meck.new(System, [:passthrough])
      :meck.expect(System, :get_env, fn name -> 
        case name do
          "GEMINI_API_KEY" -> nil
          "GOOGLE_API_KEY" -> nil
          _ -> System.get_env(name) # Pass through for other env vars
        end
      end)
      
      # Also mock File.read to prevent reading any actual .env file
      :meck.new(File, [:passthrough])
      :meck.expect(File, :read, fn ".env" -> {:error, :enoent} end)
      
      try do
        # Ensure app config is also cleared
        Application.delete_env(:gemini, :api_key)
        assert Config.api_key() == nil
      after
        :meck.unload(System)
        :meck.unload(File)
      end
    end
  end
  
  describe "default_model/0" do
    setup do
      # Save original config
      original_model = Application.get_env(:gemini, :default_model)
      
      on_exit(fn ->
        # Restore original config
        if original_model != nil do
          Application.put_env(:gemini, :default_model, original_model)
        else
          Application.delete_env(:gemini, :default_model)
        end
      end)
      
      %{original_model: original_model}
    end
    
    test "returns configured default model" do
      custom_model = "custom-model-name"
      Config.set_default_model(custom_model)
      
      assert Config.default_model() == custom_model
    end
    
    test "returns default gemini-2.0-flash model when not configured" do
      Application.delete_env(:gemini, :default_model)
      
      assert Config.default_model() == "gemini-2.0-flash"
    end
  end
  
  # Testing the env file reader helper functions using a temporary file
  describe "reading from env file" do
    setup do
      # Create a temporary .env file for testing
      temp_env_file = "test_temp.env"
      File.write!(temp_env_file, """
      GEMINI_API_KEY=test_gemini_key_from_file
      GOOGLE_API_KEY=test_google_key_from_file
      OTHER_KEY=some_other_value
      """)
      
      # Replace the module attribute with our test file
      original_env_file = :persistent_term.get({Config, :env_file}, ".env")
      :persistent_term.put({Config, :env_file}, temp_env_file)
      
      on_exit(fn ->
        # Clean up
        File.rm(temp_env_file)
        :persistent_term.put({Config, :env_file}, original_env_file)
      end)
      
      %{temp_env_file: temp_env_file}
    end
    
    # These tests are marked as pending since they would require mocking
    # the module attribute @env_file which is challenging
    @tag :pending
    test "can read from env file" do
      # This would be the implementation if we could override @env_file
      # Through some reflection or mocking
    end
  end
end
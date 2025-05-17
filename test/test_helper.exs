# Create a helper module for test context tracking
defmodule Gemini.TestContextHelper do
  @moduledoc """
  Helper module to track test context information for debugging.
  Also provides utility functions for testing against live or mock API.
  """
  
  # Check if we should use the live API
  def use_live_api? do
    # Check GEMINI_LIVE_TEST environment variable or command line arg
    System.get_env("GEMINI_LIVE_TEST") == "true" || 
      System.get_env("MIX_TEST_LIVE") == "true"
  end
  
  # Ensure we have a valid API key when using live API
  def validate_live_api_key do
    if use_live_api?() do
      api_key = System.get_env("GEMINI_API_KEY") || System.get_env("GOOGLE_API_KEY")
      
      unless api_key do
        raise """
        Error: Live API testing enabled but no API key provided!
        Please set GEMINI_API_KEY or GOOGLE_API_KEY environment variable with a valid API key.
        Example: GEMINI_LIVE_TEST=true GEMINI_API_KEY=your_api_key mix test
        """
      end
      
      # Return the key for use in tests
      api_key
    else
      "test_api_key" # Default mock key
    end
  end
  
  # Returns the appropriate adapter based on test mode
  def get_adapter do
    if use_live_api?() do
      {Tesla.Adapter.Hackney, [recv_timeout: 30_000]}
    else
      Tesla.Mock
    end
  end
  
  # Store test context in process dictionary
  def set_test_context(module, test) do
    Process.put(:test_context, %{
      module: to_string(module),
      test: to_string(test),
      live_api: use_live_api?()
    })
  end
  
  # Get test context from process dictionary
  def get_test_context do
    Process.get(:test_context, %{module: "Unknown", test: "Unknown", live_api: false})
  end
end

# Create a shared setup case for tests to use
defmodule Gemini.TestCase do
  @moduledoc """
  Shared test case to provide context tracking in all tests.
  """
  
  use ExUnit.CaseTemplate
  
  using do
    quote do
      setup context do
        # Track which test is running for detailed error logging
        Gemini.TestContextHelper.set_test_context(__MODULE__, context.test)
        :ok
      end
    end
  end
end
ExUnit.start()

# Use Tesla mock adapter for tests
Application.put_env(:tesla, :adapter, Tesla.Mock)

# Load support files
Code.require_file("support/mock_client.ex", __DIR__)

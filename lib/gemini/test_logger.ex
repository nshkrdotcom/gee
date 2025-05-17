defmodule Gemini.TestLogger do
  @moduledoc """
  Custom test logger middleware for Tesla.
  Provides enhanced logging during tests with contextual information about which test is running.
  """
  
  require Logger
  
  def call(env, next, _options) do
    # Get the current test context if we're in a test
    if Mix.env() == :test do
      # Process request info before sending
      test_context = Process.get(:test_context, %{module: "Unknown", test: "Unknown"})
      
      # Log detailed request information
      request_details = """
      [TEST REQUEST] #{env.method} #{env.url}
      [TEST CONTEXT] #{test_context.module} - #{test_context.test}
      [HEADERS] #{inspect(env.headers)}
      [QUERY] #{inspect(env.query)}
      [BODY] #{inspect(env.body, pretty: true)}
      """
      Logger.debug(request_details)
      
      # Track the result
      case Tesla.run(env, next) do
        {:ok, env} = result ->
          # Log response details for debugging
          response_log = if env.status >= 400 do
            # For errors, use error level logging
            """
            [TEST ERROR RESPONSE] Status: #{env.status}
            [TEST CONTEXT] #{test_context.module} - #{test_context.test}
            [URL] #{env.url}
            [BODY] #{inspect(env.body, pretty: true)}
            """
          else
            # For successful responses, use debug level
            """
            [TEST RESPONSE] Status: #{env.status}
            [TEST CONTEXT] #{test_context.module} - #{test_context.test}
            [URL] #{env.url}
            """
          end
          
          if env.status >= 400 do
            Logger.error(response_log)
          else
            Logger.debug(response_log)
          end
          
          result
          
        {:error, reason} = error ->
          # Log error details
          error_log = """
          [TEST CONNECTION ERROR]
          [TEST CONTEXT] #{test_context.module} - #{test_context.test}
          [URL] #{env.url}
          [REASON] #{inspect(reason)}
          """
          Logger.error(error_log)
          
          error
      end
    else
      # In non-test environments, just use regular Tesla.Middleware.Logger
      Tesla.Middleware.Logger.call(env, next, nil)
    end
  end
end
defmodule Gemini.Features.Tools do
  @moduledoc """
  Module for handling function calling (tools) with the Gemini API.
  
  This module provides functionality for working with Gemini's function
  calling capabilities, which enables the model to call user-defined
  functions based on prompts.
  """
  
  @doc """
  Defines a tool for function calling.
  
  ## Parameters
  
    * `name` - The name of the function to call.
    * `description` - A description of what the function does.
    * `parameters` - The JSON schema defining the parameters.
    * `required_parameters` - List of required parameter names.
  
  ## Returns
  
    * A map representing a tool definition for use in Gemini requests.
  
  ## Examples
  
      weather_tool = Gemini.Features.Tools.define_tool(
        "get_weather",
        "Get the current weather for a location",
        %{
          "type" => "object",
          "properties" => %{
            "location" => %{
              "type" => "string",
              "description" => "The city and state, e.g. San Francisco, CA"
            },
            "unit" => %{
              "type" => "string",
              "enum" => ["celsius", "fahrenheit"]
            }
          }
        },
        ["location"]
      )
  """
  @spec define_tool(String.t(), String.t(), map(), list(String.t())) :: map()
  def define_tool(name, description, parameters, required_parameters \\ []) do
    %{
      "functionDeclarations" => [
        %{
          "name" => name,
          "description" => description,
          "parameters" => Map.put(parameters, "required", required_parameters)
        }
      ]
    }
  end
  
  @doc """
  Add tools configuration to the request parameters.
  
  ## Parameters
  
    * `params` - The existing parameters map.
    * `tools` - List of tool definitions.
  
  ## Returns
  
    * An updated parameters map with tools configuration.
  
  ## Examples
  
      params = %{}
      tools = [weather_tool, calculator_tool]
      params_with_tools = Gemini.Features.Tools.add_tools_to_params(params, tools)
  """
  @spec add_tools_to_params(map(), list(map())) :: map()
  def add_tools_to_params(params, tools) when is_map(params) and is_list(tools) do
    # Combine all function declarations from all tools
    function_declarations = tools
    |> Enum.flat_map(fn tool -> 
      Map.get(tool, "functionDeclarations", [])
    end)
    
    # Add the tools configuration to params
    Map.put(params, "tools", [%{"functionDeclarations" => function_declarations}])
  end
  
  @doc """
  Extract function calls from a Gemini response.
  
  ## Parameters
  
    * `response` - The Gemini API response.
  
  ## Returns
  
    * List of extracted function calls with name and arguments.
  
  ## Examples
  
      {:ok, response} = Gemini.generate_content("What's the weather in Paris?", tools: [weather_tool])
      function_calls = Gemini.Features.Tools.extract_function_calls(response)
  """
  @spec extract_function_calls(Gemini.Response.t()) :: list(map())
  def extract_function_calls(response) do
    response.parts
    |> Enum.filter(fn part -> Map.has_key?(part, "functionCall") end)
    |> Enum.map(fn part -> 
      function_call = Map.get(part, "functionCall", %{})
      
      %{
        name: Map.get(function_call, "name"),
        arguments: Map.get(function_call, "args", %{})
      }
    end)
  end
  
  @doc """
  Create a tool response to send back to Gemini.
  
  ## Parameters
  
    * `name` - The name of the function that was called.
    * `response` - The response data from the function.
  
  ## Returns
  
    * A map representing the tool response part.
  
  ## Examples
  
      tool_response = Gemini.Features.Tools.create_tool_response(
        "get_weather", 
        %{"temperature" => 22, "condition" => "sunny"}
      )
  """
  @spec create_tool_response(String.t(), map()) :: map()
  def create_tool_response(name, response) when is_binary(name) and is_map(response) do
    %{
      "functionResponse" => %{
        "name" => name,
        "response" => %{
          "name" => name,
          "content" => response
        }
      }
    }
  end
end
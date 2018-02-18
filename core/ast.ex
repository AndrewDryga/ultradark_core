defmodule UltraDark.AST do
  require IEx
  @doc """
    AST lets us analyze the structure of the contract, this is used to determine
    the computational intensity needed to run the contract
  """
  @spec generate_from_source(String.t) :: Map
  def generate_from_source(source) do
    Execjs.eval("var e = require('esprima'); e.parse(`#{source}`)")
    |> ESTree.Tools.ESTreeJSONTransformer.convert
  end

  @doc """
    Recursively traverse the AST generated by ESTree, and add a call to the charge_gamma
    function before each computation.
  """
  @spec remap_with_gamma(ESTree.Program) :: list
  def remap_with_gamma(map) when is_map(map) do
    cond do
      Map.has_key?(map, :body) ->
        %{map | body: remap_with_gamma(map.body)}
      Map.has_key?(map, :value) ->
        %{map | value: remap_with_gamma(map.value)}
      true ->
        map
    end
  end
  def remap_with_gamma([component | rest], new_ast \\ []) do
    comp = remap_with_gamma(component)
    new_ast = [comp | new_ast]

    case comp do
      %ESTree.MethodDefinition{} -> remap_with_gamma(rest, new_ast)
      %ESTree.ClassDefinition{} -> remap_with_gamma(rest, new_ast)
      _ -> remap_with_gamma(rest, [generate_gamma_charge(comp) | new_ast])
    end
  end
  def remap_with_gamma([], new_ast), do: new_ast

  defp generate_gamma_charge(computation) do
    generate_from_source("UltraDark.Contract.charge_gamma(10)").body
    |> List.first
  end
end

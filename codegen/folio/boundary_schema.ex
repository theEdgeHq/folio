defmodule Folio.Codegen.BoundarySchema do
  @moduledoc false

  alias RustQ.Rustler.Schema

  @spec rust_items(module(), atom(), keyword()) :: [RustQ.Rust.AST.item()]
  def rust_items(owner, enum_name, opts \\ []) do
    excluded = MapSet.new(Keyword.get(opts, :exclude, []))
    overrides = Map.new(Keyword.get(opts, :overrides, []))
    names = Map.new(Keyword.get(opts, :names, []))

    nodes =
      owner.__folio_declarations__()
      |> Enum.reject(&MapSet.member?(excluded, &1.module))
      |> Enum.map(&schema_node(&1, overrides, names))

    variants = Enum.map(nodes, &elem(&1, 0))

    %Schema{
      module_prefix: owner,
      rust_prefix: "Ex",
      tag_field: :__struct__,
      nodes: nodes,
      enums: [{enum_name, variants: variants, unknown: Keyword.fetch!(opts, :unknown)}]
    }
    |> Schema.rust_items()
  end

  defp schema_node(declaration, overrides, names) do
    name = Map.get(names, declaration.module, declaration.name)

    fields =
      Enum.map(declaration.fields, fn {field, type} ->
        rust_type =
          Map.get_lazy(overrides, {declaration.module, field}, fn -> rust_type!(type) end)

        {field, rust_type, []}
      end)

    {name, fields, module: declaration.module}
  end

  defp rust_type!({{:., _, [{:__aliases__, _, [:String]}, :t]}, _, []}), do: :String

  defp rust_type!({{:., _, [{:__aliases__, _, [:Folio, :Content]}, :t]}, _, []}),
    do: :ExContent

  defp rust_type!([type]), do: {:vec, rust_type!(type)}
  defp rust_type!({:boolean, _, []}), do: :bool
  defp rust_type!({:float, _, []}), do: :f64
  defp rust_type!({:pos_integer, _, []}), do: :u32

  defp rust_type!({:|, _, _} = type) do
    members = flatten_union(type)
    non_nil = Enum.reject(members, &is_nil/1)

    if length(non_nil) == 1 and length(non_nil) < length(members) do
      {:option, rust_type!(hd(non_nil))}
    else
      raise ArgumentError, "unsupported boundary union: #{Macro.to_string(type)}"
    end
  end

  defp rust_type!({:.., _, _} = type) do
    raise ArgumentError,
          "integer ranges require an explicit Rust type override: #{Macro.to_string(type)}"
  end

  defp rust_type!(type) do
    raise ArgumentError, "unsupported boundary type: #{Macro.to_string(type)}"
  end

  defp flatten_union({:|, _, [left, right]}),
    do: flatten_union(left) ++ flatten_union(right)

  defp flatten_union(type), do: [type]
end

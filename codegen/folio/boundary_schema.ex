defmodule Folio.Codegen.BoundarySchema do
  @moduledoc false

  alias RustQ.Rustler.Schema

  @spec rust_items(Path.t(), module(), atom(), atom(), keyword()) :: [RustQ.Rust.AST.item()]
  def rust_items(path, owner, union_type, enum_name, opts \\ []) do
    excluded = MapSet.new(Keyword.get(opts, :exclude, []))
    overrides = Map.new(Keyword.get(opts, :overrides, []))
    names = Map.new(Keyword.get(opts, :names, []))
    expressions = source_expressions!(path, owner)
    module_bodies = nested_module_bodies(expressions, owner)

    nodes =
      expressions
      |> fetch_type!(union_type)
      |> flatten_union()
      |> Enum.map(&remote_module!(&1, owner))
      |> Enum.reject(&MapSet.member?(excluded, &1))
      |> Enum.map(&schema_node(&1, module_bodies, overrides, names))

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

  defp source_expressions!(path, owner) do
    case path |> File.read!() |> Code.string_to_quoted!(file: path) do
      {:defmodule, _, [module_ast, [do: body]]} ->
        if expand_alias(module_ast, nil) != owner do
          raise ArgumentError, "expected #{path} to define #{inspect(owner)}"
        end

        block_expressions(body)

      ast ->
        raise ArgumentError,
              "expected one outer defmodule in #{path}, got: #{Macro.to_string(ast)}"
    end
  end

  defp nested_module_bodies(expressions, owner) do
    expressions
    |> Enum.flat_map(fn
      {:defmodule, _, [module_ast, [do: body]]} ->
        [{expand_alias(module_ast, owner), block_expressions(body)}]

      _expression ->
        []
    end)
    |> Map.new()
  end

  defp schema_node(module, module_bodies, overrides, names) do
    name =
      Map.get_lazy(names, module, fn ->
        module |> Module.split() |> List.last() |> String.to_existing_atom()
      end)

    body = Map.fetch!(module_bodies, module)

    fields =
      body
      |> fetch_type!(:t)
      |> struct_fields!()
      |> Enum.map(fn {field, type} ->
        rust_type = Map.get_lazy(overrides, {module, field}, fn -> rust_type!(type) end)
        {field, rust_type, []}
      end)

    {name, fields, module: module}
  end

  defp fetch_type!(expressions, name) do
    Enum.find_value(expressions, fn
      {:@, _, [{:type, _, [{:"::", _, [{^name, _, _}, type]}]}]} -> type
      _expression -> nil
    end) || raise ArgumentError, "missing #{name}/0 typespec"
  end

  defp struct_fields!({:%, _, [_module, {:%{}, _, fields}]}), do: fields

  defp struct_fields!(type) do
    raise ArgumentError, "expected a struct typespec, got: #{Macro.to_string(type)}"
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

  defp remote_module!({{:., _, [{:__aliases__, _, parts}, :t]}, _, []}, owner),
    do: expand_alias({:__aliases__, [], parts}, owner)

  defp remote_module!(type, _owner) do
    raise ArgumentError, "expected a remote struct type, got: #{Macro.to_string(type)}"
  end

  defp expand_alias({:__aliases__, _, parts}, nil), do: Module.concat(parts)

  defp expand_alias({:__aliases__, _, [part]}, owner), do: Module.concat(owner, part)

  defp expand_alias({:__aliases__, _, parts}, _owner), do: Module.concat(parts)

  defp block_expressions({:__block__, _, expressions}), do: expressions
  defp block_expressions(expression), do: [expression]
end

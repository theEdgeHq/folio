defmodule Folio.Declaration do
  @moduledoc false

  defmacro __using__(opts) do
    union = Keyword.fetch!(opts, :union)
    owner = __CALLER__.module

    unless is_atom(union) do
      raise ArgumentError, ":union must be an atom"
    end

    Module.register_attribute(owner, :folio_variants, accumulate: true)
    Module.put_attribute(owner, :folio_union, union)

    quote do
      import Folio.Declaration, only: [defvariant: 2]
      @before_compile Folio.Declaration
    end
  end

  defmacro defvariant(name_ast, opts) do
    name = variant_name!(name_ast)
    doc = Keyword.fetch!(opts, :doc)
    type = Keyword.fetch!(opts, :type)
    fields = struct_fields!(type)
    owner = __CALLER__.module

    unless is_binary(doc) do
      raise ArgumentError, "#{inspect(name)} :doc must be a string"
    end

    declaration = %{
      name: name,
      module: Module.concat(owner, name),
      fields: fields
    }

    Module.put_attribute(owner, :folio_variants, declaration)

    field_names = Enum.map(fields, &elem(&1, 0))

    quote do
      defmodule unquote(name_ast) do
        @moduledoc unquote(doc)
        defstruct unquote(field_names)
        @type t :: unquote(type)
      end
    end
  end

  defmacro __before_compile__(env) do
    union = Module.get_attribute(env.module, :folio_union)
    variants = env.module |> Module.get_attribute(:folio_variants) |> Enum.reverse()
    metadata = [line: env.line]

    union_type =
      variants
      |> Enum.map(&remote_type(&1, metadata))
      |> Enum.reduce(fn type, acc -> {:|, metadata, [acc, type]} end)

    type_definition =
      {:@, metadata,
       [{:type, metadata, [{:"::", metadata, [{union, metadata, []}, union_type]}]}]}

    quote do
      unquote(type_definition)

      @doc false
      def __folio_declarations__, do: unquote(Macro.escape(variants))
    end
  end

  defp variant_name!({:__aliases__, _, [name]}) when is_atom(name), do: name

  defp variant_name!(name_ast) do
    raise ArgumentError,
          "variant name must be an unqualified alias, got: #{Macro.to_string(name_ast)}"
  end

  defp struct_fields!({:%, _, [{:__MODULE__, _, _}, {:%{}, _, fields}]}) do
    Enum.map(fields, fn
      {name, type} when is_atom(name) -> {name, type}
      field -> raise ArgumentError, "invalid struct field declaration: #{Macro.to_string(field)}"
    end)
  end

  defp struct_fields!(type) do
    raise ArgumentError,
          ":type must be a %__MODULE__{} typespec, got: #{Macro.to_string(type)}"
  end

  defp remote_type(%{name: name}, metadata) do
    {{:., metadata, [{:__aliases__, metadata, [name]}, :t]}, metadata, []}
  end
end

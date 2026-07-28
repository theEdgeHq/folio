unless Code.ensure_loaded?(Folio.Codegen.BoundarySchema) do
  Code.require_file("../codegen/folio/boundary_schema.ex", __DIR__)
  Code.require_file("../codegen/folio/content_nodes.ex", __DIR__)
  Code.require_file("../codegen/folio/styles.ex", __DIR__)
end

defmodule Folio.CodegenTest do
  use ExUnit.Case, async: true

  alias Folio.Codegen.{ContentNodes, Styles}
  alias RustQ.Rust.AST.Enum, as: RustEnum
  alias RustQ.Rust.AST.EnumVariant
  alias RustQ.Rust.AST.Struct, as: RustStruct
  alias RustQ.Rust.AST.StructField
  alias RustQ.Rust.AST.TypeOption
  alias RustQ.Rust.AST.TypePath
  alias RustQ.Rust.AST.TypeVec

  test "declarations generate structs, union types, and codegen metadata" do
    content = Folio.Content.__folio_declarations__()
    styles = Folio.Styles.__folio_declarations__()

    assert length(content) == 62
    assert length(styles) == 25

    assert %{module: Folio.Content.Text, fields: fields} =
             Enum.find(content, &(&1.name == :Text))

    assert Keyword.keys(fields) == [:text, :size, :weight, :fill, :tracking]
    assert %Folio.Content.Text{} == struct(Folio.Content.Text)

    assert %{child_fields: [:body, :attribution], tag: :quote} =
             Folio.Content.__folio_declaration__(%Folio.Content.Quote{})

    assert %{child_fields: [:title]} =
             Folio.Content.__folio_declaration__(%Folio.Content.Bibliography{})

    assert %{tag: :enum} =
             Folio.Content.__folio_declaration__(%Folio.Content.EnumList{})

    assert %{tag: :vspace} =
             Folio.Content.__folio_declaration__(%Folio.Content.VSpace{})

    assert %{tag: :hspace} =
             Folio.Content.__folio_declaration__(%Folio.Content.HSpace{})

    for declaration <- content ++ styles do
      assert declaration.fields |> Keyword.keys() |> Enum.sort() ==
               declaration.module
               |> struct()
               |> Map.delete(:__struct__)
               |> Map.keys()
               |> Enum.sort()
    end

    assert {:ok, [type: {:t, _type, []}]} = Code.Typespec.fetch_types(Folio.Content)
    assert {:ok, [type: {:rule, _type, []}]} = Code.Typespec.fetch_types(Folio.Styles)
  end

  test "derives the native content boundary from public content types" do
    items = ContentNodes.rust_items()

    assert %RustStruct{
             fields: [
               %StructField{name: :body},
               %StructField{name: :level, type: %TypePath{parts: [:u8]}}
             ]
           } = find_struct!(items, :ExHeading)

    assert %RustStruct{
             fields: [
               %StructField{name: :columns, type: %TypeOption{inner: %TypeVec{}}}
               | _
             ]
           } = find_struct!(items, :ExGrid)

    assert %RustEnum{variants: variants} =
             Enum.find(items, &match?(%RustEnum{name: :ExContent}, &1))

    refute Enum.any?(variants, &match?(%EnumVariant{name: :ShowRule}, &1))
    assert RustQ.valid?(RustQ.Rust.render_all(items), "folio_content.rs")
  end

  test "derives the native style boundary from public style types" do
    items = Styles.rust_items()

    assert %RustStruct{
             fields: [
               %StructField{name: :weight, type: %TypePath{parts: [:u16]}}
             ]
           } = find_struct!(items, :ExFontWeight)

    assert RustQ.valid?(RustQ.Rust.render_all(items), "folio_styles.rs")
  end

  defp find_struct!(items, name) do
    Enum.find(items, &match?(%RustStruct{name: ^name}, &1)) ||
      flunk("missing generated Rust struct #{name}")
  end
end

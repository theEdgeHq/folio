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

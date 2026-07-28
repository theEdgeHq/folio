defmodule Folio.Codegen.Styles do
  @moduledoc false

  alias Folio.Codegen.BoundarySchema

  @spec rust_items() :: [RustQ.Rust.AST.item()]
  def rust_items do
    BoundarySchema.rust_items(Folio.Styles, :Style,
      overrides: [{{Folio.Styles.FontWeight, :weight}, :u16}],
      unknown: :unknown_style_variant
    )
  end
end

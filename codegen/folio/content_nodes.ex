defmodule Folio.Codegen.ContentNodes do
  @moduledoc false

  alias Folio.Codegen.BoundarySchema

  @spec rust_items() :: [RustQ.Rust.AST.item()]
  def rust_items do
    BoundarySchema.rust_items(Folio.Content, :Content,
      exclude: [Folio.Content.ShowRule],
      names: [{Folio.Content.EnumList, :Enum}],
      overrides: [{{Folio.Content.Heading, :level}, :u8}],
      unknown: :unknown_content_variant
    )
  end
end

use RustQ.Config

require_file("lib/folio/declaration.ex")
require_file("lib/folio/content.ex")
require_file("lib/folio/styles.ex")
require_file("codegen/folio/boundary_schema.ex")
require_file("codegen/folio/content_nodes.ex")
require_file("codegen/folio/native.ex")
require_file("codegen/folio/styles.ex")

rust "native/folio_nif/src/generated_nifs.rs" do
  Folio.Codegen.Native.rust_nifs()
end

rust "native/folio_nif/src/generated_content_nodes.rs" do
  Folio.Codegen.ContentNodes.rust_items()
end

rust "native/folio_nif/src/generated_styles.rs" do
  Folio.Codegen.Styles.rust_items()
end

generate "lib/folio/native/generated_stubs.ex" do
  content(Folio.Codegen.Native.elixir_stubs())
end

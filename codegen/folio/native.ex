defmodule Folio.Codegen.Native do
  @moduledoc false

  alias RustQ.Rustler.Nif

  @source "native/folio_nif/src/lib.rs"
  @exports [
    parse_markdown: [schedule: :dirty_cpu],
    compile_pdf: [schedule: :dirty_cpu],
    compile_svg: [schedule: :dirty_cpu],
    compile_png: [schedule: :dirty_cpu],
    register_file: [],
    unregister_file: []
  ]

  @spec rust_nifs() :: [RustQ.Rust.AST.Function.t()]
  def rust_nifs do
    Nif.wrappers_from_source(@source, @exports)
  end

  @spec elixir_stubs() :: String.t()
  def elixir_stubs do
    Nif.stubs_from_source(@source, @exports, Folio.Native.GeneratedStubs)
  end
end

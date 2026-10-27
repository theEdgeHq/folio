defmodule Folio.Native do
  @moduledoc false

  alias Folio.Content
  alias Folio.Styles

  version = Mix.Project.config()[:version]

  use RustlerPrecompiled,
    otp_app: :folio,
    crate: :folio_nif,
    base_url: "https://github.com/dannote/folio/releases/download/v#{version}",
    force_build: true,
    targets: ~w(
      aarch64-apple-darwin
      aarch64-unknown-linux-gnu
      x86_64-apple-darwin
      x86_64-unknown-linux-gnu
    ),
    version: version

  @spec parse_markdown(String.t()) :: [Content.t()]
  @spec compile_pdf([Content.t()], [Styles.rule()], %{String.t() => binary()}) :: binary()
  @spec compile_svg([Content.t()], [Styles.rule()], %{String.t() => binary()}) :: [String.t()]
  @spec compile_png([Content.t()], [Styles.rule()], %{String.t() => binary()}, float()) :: [
          binary()
        ]
  @spec register_file(String.t(), binary()) :: :ok
  @spec unregister_file(String.t()) :: :ok

  use Folio.Native.GeneratedStubs
end

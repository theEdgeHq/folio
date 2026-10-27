defmodule Folio.CacheLifecycleTest do
  use ExUnit.Case, async: false

  test "concurrent documents render PDF and SVG while cache cleanup runs" do
    results =
      1..24
      |> Task.async_stream(
        fn index ->
          expected = "CACHE-LIFECYCLE-#{index}"
          assert {:ok, pdf} = Folio.to_pdf(expected)
          assert <<"%PDF-", _::binary>> = pdf
          assert {:ok, [svg]} = Folio.to_svg(expected)
          assert svg =~ "<svg"
          {index, byte_size(pdf)}
        end,
        max_concurrency: 4,
        timeout: 30_000
      )
      |> Enum.map(fn {:ok, result} -> result end)

    assert length(results) == 24
  end

  test "a failed compilation does not prevent the next document from rendering" do
    assert {:error, %Folio.CompileError{}} =
             Folio.to_pdf([Folio.DSL.text("invalid", size: "large-ish")])

    assert {:ok, <<"%PDF-", _::binary>>} = Folio.to_pdf("after error")
    assert {:ok, [_page]} = Folio.to_png("after error", dpi: 1.0)
  end
end

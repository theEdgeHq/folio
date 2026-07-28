# Folio

Print-quality PDF/SVG/PNG from Markdown + Elixir, powered by [Typst](https://typst.app)'s layout engine via Rustler NIF.

[![Hex.pm](https://img.shields.io/hexpm/v/folio.svg)](https://hex.pm/packages/folio)
[![Docs](https://img.shields.io/badge/docs-hex.pm-blue)](https://hexdocs.pm/folio)

## Why Folio

### Data-Driven Documents at Runtime

Typst reads static files. Folio builds content trees from live Elixir data — Ecto queries, API responses, GenServer state. A Phoenix app generates PDFs from the same data it renders in HTML, with zero intermediate files:

```elixir
defmodule Invoices do
  use Folio

  def invoice_pdf(order) do
    rows =
      Enum.map(order.line_items, fn item ->
        table_row([
          table_cell(item.name),
          table_cell(to_string(item.quantity)),
          table_cell(Money.to_string(item.price))
        ])
      end)

    Folio.to_pdf([
      heading(1, "Invoice #{order.number}"),
      table([gutter: "4pt"],
        do: [table_header(["Item", "Qty", "Price"]) | rows]
      )
    ])
  end
end
```

### Composable Document Fragments

DSL functions return plain structs — document pieces are first-class Elixir values. Build reusable components as regular functions, pattern-match on them, store them, pipe them:

```elixir
defmodule Reports.Components do
  use Folio

  def kpi_card(label, value, trend) do
    block([above: "12pt", below: "12pt"], do: [
      strong(label),
      parbreak(),
      text("#{value} (#{trend})"),
    ])
  end
end
```

### Structured Content Without Typst Templates

Folio's normal path constructs Typst content trees directly in Rust and feeds them to the layout engine. Markdown is parsed by Comrak, while DSL values remain structured data:

- **No generated Typst templates** — dynamic values are represented as typed content nodes
- **Structurally valid content** — the DSL does not concatenate source code
- **Explicit escape hatches** — math and `raw_typst/1` invoke Typst evaluation intentionally; only pass trusted source to `raw_typst/1`
- **Less parser overhead** — ordinary DSL content skips Typst markup parsing and evaluation

### Elixir-Native Concurrency for Batch Generation

With Typst CLI, generating 10,000 invoices means 10,000 process spawns. With Folio on dirty schedulers:

```elixir
results =
  Task.async_stream(
    orders,
    fn order -> Folio.to_pdf(build_invoice(order)) end,
    max_concurrency: System.schedulers_online()
  )
  |> Enum.to_list()
```

Fonts and layout data are loaded once and shared across compilations.

## Quick start

Add Folio to your dependencies:

```elixir
def deps do
  [{:folio, "~> 0.3"}]
end
```

Folio ships with precompiled NIFs for macOS (Intel & Apple Silicon) and Linux (x86_64 & aarch64, glibc). No Rust toolchain is required.

To build from source instead (e.g. for a custom target or during development):

```sh
FOLIO_BUILD=1 mix compile
```

Render Markdown to PDF with math and tables:

```elixir
use Folio

{:ok, pdf} = Folio.to_pdf("# Hello\n\n**Bold** and $x^2$ math.")
```

Or use the uppercase `~MD` sigil for static multi-line Markdown — the `p` modifier returns `{:ok, pdf_binary}` directly. As with other uppercase Elixir sigils, `~MD` does not interpolate:

```elixir
{:ok, pdf} = ~MD"""
# Report

Some **bold** content with inline $E = m c^2$ math.

| Metric | Value |
|--------|-------|
| A      | 1     |
| B      | 2     |
"""p
```

For dynamic values and full control, compose content with the DSL — every function returns a plain struct:

```elixir
{:ok, pdf} = Folio.to_pdf([
  heading(1, "Hello"),
  text("Normal "),
  strong("bold"),
  text(" and "),
  emph("italic"),
])
```

Style text inline, build shaped containers, and use full Typst track sizing in tables:

```elixir
{:ok, pdf} = Folio.to_pdf([
  rect(width: "100%", fill: "#6c63ff", radius: "8pt", inset: "20pt",
    body: [text("INVOICE", size: "24pt", weight: "bold", fill: "white")]
  ),
  table([columns: ["1fr", "1fr", "auto"], gutter: "8pt", inset: "10pt", fill: "#f8f8ff"],
    do: [
      table_header([table_cell("Item"), table_cell("Qty"), table_cell("Price")]),
      for item <- items do
        table_row([table_cell(item.name), table_cell("#{item.qty}"), table_cell(item.price)])
      end
    ]
  ),
])
```

Export to PDF, SVG, or PNG with configurable resolution:

```elixir
{:ok, pdf} = Folio.to_pdf("# Hello")          # PDF binary
{:ok, svgs} = Folio.to_svg("# Hello")         # [String.t()] per page
{:ok, pngs} = Folio.to_png("# Hello", dpi: 3) # [binary()] per page
```

Full API documentation at [hexdocs.pm/folio](https://hexdocs.pm/folio).

## Comparison with other Elixir PDF libraries

| | **Folio** | [**ChromicPDF**](https://hex.pm/packages/chromic_pdf) | [**pdf_generator**](https://hex.pm/packages/pdf_generator) | [**Imprintor**](https://hex.pm/packages/imprintor) | [**pdf**](https://hex.pm/packages/pdf) | [**PrawnEx**](https://hex.pm/packages/prawn_ex) |
|---|---|---|---|---|---|---|
| **Approach** | Typst layout engine via Rustler NIF | Headless Chrome → PDF | wkhtmltopdf or Chrome via shell | Typst templates via Rustler NIF | Raw PDF primitives in pure Elixir | Raw PDF primitives in pure Elixir |
| **Input format** | Markdown + Elixir DSL | HTML | HTML | Typst source strings | Programmatic API calls | Programmatic API calls |
| **Layout engine** | Typst (print-quality typesetting) | Chrome (CSS box model) | Chrome / wkhtmltopdf (CSS) | Typst (full Typst language) | None (manual positioning) | None (manual positioning) |
| **External deps** | None (precompiled NIFs) | Chromium + Ghostscript | Chromium/wkhtmltopdf + Node.js | Rust toolchain (compile-time only) | None | None |
| **Runtime overhead** | In-process NIF | External Chrome process | External process per PDF | In-process NIF | In-process | In-process |
| **Text layout** | Automatic (hyphenation, justification, ligatures, kerning) | Browser CSS | Browser CSS | Automatic (full Typst) | Manual `text_at(x, y)` | Manual `text_at(x, y)` |
| **Math** | `$E = mc^2$` via Typst math parser | No | No | `$E = mc^2$` via Typst math parser | No | No |
| **Tables** | Structured DSL with header/rowspan/colspan | HTML tables | HTML tables | Typst tables | Manual grid drawing | Basic row grid |
| **Bibliography** | Built-in (`.bib`, `.yaml`) | No | No | Via Typst packages | No | No |
| **Multi-page flow** | Automatic | Browser pagination | Browser pagination | Automatic | Manual page management | Manual page management |
| **Output formats** | PDF, SVG, PNG | PDF, PDF/A | PDF | PDF | PDF | PDF |
| **Template injection risk** | None in the structured API; `raw_typst/1` is an explicit trusted-input escape hatch | HTML injection possible | HTML injection possible | Typst code injection possible | N/A | N/A |
| **Batch performance** | Fonts shared, in-process NIF | Chrome session pool | Process spawn per PDF | In-process NIF | In-process | In-process |

### When to use what

- **Folio** — Data-driven documents (invoices, reports, certificates) from Elixir data at runtime. You want print-quality typography, math, and tables without external processes or template strings.
- **ChromicPDF** — You already have HTML/CSS that looks right in a browser and want it as PDF. Best option for Pixel-perfect HTML-to-PDF with PDF/A compliance.
- **Imprintor** — You want Typst's full language (templates, packages, scripting) and are comfortable with Typst syntax. Note: passes raw Typst source strings to the evaluator, so template injection is possible with untrusted input.
- **pdf / PrawnEx** — Simple PDFs with manual positioning (labels, receipts, badges) where you control every coordinate and don't need automatic text flow.

## License

MIT — see [LICENSE.md](LICENSE.md)

# Folio — Design

## Purpose

Folio produces print-quality PDF, SVG, and PNG output from Markdown and typed
Elixir content using Typst's layout engine through a Rustler NIF.

It supports three public input forms:

1. Markdown strings, parsed by Comrak.
2. Lists of `%Folio.Content.*{}` structs built with `Folio.DSL`.
3. `%Folio.Document{}` values containing content, styles, and attached files.

The uppercase `~MD` sigil is a convenience for static Markdown. It follows
Elixir's uppercase-sigil semantics and does not interpolate. Dynamic documents
should compose ordinary DSL values.

## Architecture

```text
Elixir                                      Rust NIF
──────                                      ────────
Markdown string ──────────────────────────▶ Comrak AST conversion
DSL content structs ──────────────────────▶ ExContent decoding
Style structs ────────────────────────────▶ ExStyle decoding
Attached files ───────────────────────────▶ compilation-scoped file store
                                                   │
                                                   ▼
                                           Typst Content + Styles
                                                   │
                                                   ▼
                                           layout_document()
                                            │      │      │
                                            ▼      ▼      ▼
                                           PDF    SVG    PNG
```

Folio does not generate Typst templates for its structured API. Most content is
constructed directly as Typst elements. Two explicit features invoke Typst
evaluation:

- math expressions are evaluated in Typst math mode;
- `raw_typst/1` evaluates trusted Typst markup as an escape hatch.

`raw_typst/1` must not receive untrusted source.

## Elixir API

```elixir
Folio.parse_markdown(markdown)
Folio.parse_markdown!(markdown)

Folio.to_pdf(source, opts)
Folio.to_svg(source, opts)
Folio.to_png(source, opts)
```

Compilation functions return `{:ok, output}` or
`{:error, %Folio.CompileError{}}`.

`Folio.Document` accumulates plain content nodes, style rules, and binary file
attachments. Strings passed to `Document.add_content/2` are plain text; callers
must parse Markdown explicitly when they want Markdown semantics.

## Boundary ownership

`Folio.Declaration` is the single source for public boundary variants. Each
`defvariant` declaration generates:

- the nested Elixir struct;
- its `t()` typespec;
- the owner module's union type;
- field, traversal, and variant metadata consumed by Folio and RustQ.

RustQ projects the declarations into checked-in Rust structs and enums. NIF
wrappers and Elixir fallback stubs are derived from the handwritten Rust NIF
implementations.

Policy remains explicit in `codegen/folio`: native exclusions, Rust integer
widths, renamed variants, scheduler choices, and unknown-variant errors are not
inferred.

## Native ownership

The following remain handwritten Rust because they contain domain behavior:

- Comrak AST conversion;
- `ExContent` to Typst element conversion;
- Typst world, fonts, files, layout, and export;
- panic containment and compilation-scoped cleanup.

Generated Rust is limited to schema-shaped boundary code and NIF wrappers.

## Files

```text
folio/
├── codegen/folio/               # RustQ schemas and boundary policy
├── lib/
│   ├── folio.ex                 # Public API and use macro
│   └── folio/
│       ├── content.ex           # Single-source content declarations
│       ├── declaration.ex       # Struct, union, and metadata generator
│       ├── document.ex          # Content, styles, and attached files
│       ├── dsl.ex               # Validating content constructors
│       ├── show.ex              # Elixir-side show-rule expansion
│       ├── sigil.ex             # Static ~MD sigil
│       └── styles.ex            # Style declarations and constructors
├── native/folio_nif/src/
│   ├── lib.rs                   # NIF implementations
│   ├── convert.rs               # ExContent → Typst Content
│   ├── mdex_bridge.rs           # Comrak nodes → ExContent
│   ├── world.rs                 # Typst World, layout, and export
│   └── generated_*.rs           # Checked RustQ output
└── rustq.exs                    # Checked-generation manifest
```

## Design principles

1. Structured data is preferred over generated source strings.
2. Public Elixir structs remain inspectable and composable.
3. Boundary facts have one owner and checked generated projections.
4. Validation and normalization stay in handwritten DSL constructors.
5. Domain-heavy Typst behavior stays in Rust.
6. Escape hatches are explicit and documented as trusted-input APIs.

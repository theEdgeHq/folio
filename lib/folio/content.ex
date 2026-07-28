defmodule Folio.Content do
  @moduledoc """
  Typed content nodes that map 1:1 to Typst elements.

  Each declaration generates its public struct and typespec, the `t()` union,
  and metadata that RustQ projects into the native boundary. Run
  `mix rustq.gen` after changing a native boundary type.
  """

  use Folio.Declaration, union: :t

  defvariant(Text,
    doc: "A plain text run. Fields: `text`, `size`, `weight`, `fill`, `tracking`.",
    type: %__MODULE__{
      text: String.t(),
      size: String.t() | nil,
      weight: String.t() | nil,
      fill: String.t() | nil,
      tracking: String.t() | nil
    }
  )

  defvariant(Space, doc: "Inter-word space.", type: %__MODULE__{})

  defvariant(Heading,
    doc: "A section heading. Fields: `body`, `level` (1-6).",
    type: %__MODULE__{body: [Folio.Content.t()], level: 1..6}
  )

  defvariant(Cite,
    doc: "A citation from a bibliography. Fields: `key`, `supplement`, `form`, `style`.",
    type: %__MODULE__{
      key: String.t(),
      supplement: [Folio.Content.t()] | nil,
      form: String.t() | nil,
      style: String.t() | nil
    }
  )

  defvariant(Bibliography,
    doc: "A bibliography listing. Fields: `sources`, `title`, `full`, `style`.",
    type: %__MODULE__{
      sources: [String.t()],
      title: [Folio.Content.t()] | nil,
      full: boolean(),
      style: String.t() | nil
    }
  )

  defvariant(Paragraph,
    doc: "A body paragraph. Field: `body`.",
    type: %__MODULE__{body: [Folio.Content.t()]}
  )

  defvariant(Strong, doc: "Bold text.", type: %__MODULE__{body: [Folio.Content.t()]})

  defvariant(Emph, doc: "Italic text.", type: %__MODULE__{body: [Folio.Content.t()]})

  defvariant(Strike, doc: "Strikethrough text.", type: %__MODULE__{body: [Folio.Content.t()]})

  defvariant(Underline, doc: "Underlined text.", type: %__MODULE__{body: [Folio.Content.t()]})

  defvariant(Highlight,
    doc: "Highlighted text.",
    type: %__MODULE__{body: [Folio.Content.t()], fill: String.t() | nil}
  )

  defvariant(Super, doc: "Superscript text.", type: %__MODULE__{body: [Folio.Content.t()]})

  defvariant(Sub, doc: "Subscript text.", type: %__MODULE__{body: [Folio.Content.t()]})

  defvariant(Smallcaps, doc: "Small capitals text.", type: %__MODULE__{body: [Folio.Content.t()]})

  defvariant(Image,
    doc: "An image. Fields: `src`, `width`, `height`, `fit`.",
    type: %__MODULE__{
      src: String.t(),
      width: String.t() | nil,
      height: String.t() | nil,
      fit: String.t() | nil
    }
  )

  defvariant(Figure,
    doc: "A figure with optional caption. Fields: `body`, `caption`, `placement`, `numbering`.",
    type: %__MODULE__{
      body: [Folio.Content.t()],
      caption: [Folio.Content.t()] | nil,
      placement: String.t() | nil,
      scope: String.t() | nil,
      numbering: String.t() | nil,
      separator: String.t() | nil
    }
  )

  defvariant(Table,
    doc: "A table grid. Fields: `children`, `gutter`, `stroke`, `align`, `inset`, `fill`.",
    type: %__MODULE__{
      columns: [String.t()] | nil,
      rows: String.t() | nil,
      children: [Folio.Content.t()],
      stroke: String.t() | nil,
      gutter: String.t() | nil,
      align: String.t() | nil,
      inset: String.t() | nil,
      fill: String.t() | nil
    }
  )

  defvariant(TableHeader,
    doc: "Table header row.",
    type: %__MODULE__{children: [Folio.Content.t()]}
  )

  defvariant(TableRow, doc: "Table data row.", type: %__MODULE__{children: [Folio.Content.t()]})

  defvariant(TableCell,
    doc: "Table cell.",
    type: %__MODULE__{
      body: [Folio.Content.t()],
      colspan: pos_integer() | nil,
      rowspan: pos_integer() | nil,
      align: String.t() | nil,
      fill: String.t() | nil,
      stroke: String.t() | nil
    }
  )

  defvariant(Columns,
    doc: "Multi-column layout.",
    type: %__MODULE__{count: pos_integer(), body: [Folio.Content.t()], gutter: String.t() | nil}
  )

  defvariant(Colbreak, doc: "Column break.", type: %__MODULE__{weak: boolean()})

  defvariant(Pagebreak, doc: "Page break.", type: %__MODULE__{weak: boolean()})

  defvariant(Parbreak, doc: "Paragraph break.", type: %__MODULE__{})

  defvariant(Linebreak, doc: "Line break.", type: %__MODULE__{})

  defvariant(Math,
    doc: "Math expression.",
    type: %__MODULE__{content: String.t(), block: boolean()}
  )

  defvariant(Link,
    doc: "Hyperlink.",
    type: %__MODULE__{url: String.t(), body: [Folio.Content.t()]}
  )

  defvariant(Raw,
    doc: "Raw/code text.",
    type: %__MODULE__{text: String.t(), lang: String.t() | nil, block: boolean()}
  )

  defvariant(Quote,
    doc: "Block quote.",
    type: %__MODULE__{
      body: [Folio.Content.t()],
      block: boolean(),
      attribution: [Folio.Content.t()] | nil
    }
  )

  defvariant(List,
    doc: "Bullet list.",
    type: %__MODULE__{children: [Folio.Content.t()], tight: boolean(), marker: String.t() | nil}
  )

  defvariant(ListItem, doc: "Bullet list item.", type: %__MODULE__{body: [Folio.Content.t()]})

  defvariant(EnumList,
    doc: "Numbered (ordered) list.",
    type: %__MODULE__{children: [Folio.Content.t()], tight: boolean(), start: pos_integer() | nil}
  )

  defvariant(EnumItem,
    doc: "Numbered list item.",
    type: %__MODULE__{body: [Folio.Content.t()], number: pos_integer() | nil}
  )

  defvariant(Label, doc: "Cross-reference label.", type: %__MODULE__{name: String.t()})

  defvariant(Ref,
    doc: "Cross-reference.",
    type: %__MODULE__{target: String.t(), supplement: [Folio.Content.t()] | nil}
  )

  defvariant(Align,
    doc: "Content alignment.",
    type: %__MODULE__{alignment: String.t(), body: [Folio.Content.t()]}
  )

  defvariant(Block,
    doc: "Block-level container.",
    type: %__MODULE__{
      body: [Folio.Content.t()],
      width: String.t() | nil,
      height: String.t() | nil,
      above: String.t() | nil,
      below: String.t() | nil,
      fill: String.t() | nil,
      inset: String.t() | nil,
      radius: String.t() | nil,
      stroke: String.t() | nil
    }
  )

  defvariant(Hide, doc: "Hidden content.", type: %__MODULE__{body: [Folio.Content.t()]})

  defvariant(Repeat, doc: "Repeating content.", type: %__MODULE__{body: [Folio.Content.t()]})

  defvariant(Place,
    doc: "Absolute placement.",
    type: %__MODULE__{
      alignment: String.t() | nil,
      body: [Folio.Content.t()],
      float: boolean() | nil
    }
  )

  defvariant(VSpace,
    doc: "Vertical spacing.",
    type: %__MODULE__{amount: String.t(), weak: boolean()}
  )

  defvariant(HSpace,
    doc: "Horizontal spacing.",
    type: %__MODULE__{amount: String.t(), weak: boolean()}
  )

  defvariant(Pad,
    doc: "Padding around content.",
    type: %__MODULE__{
      body: [Folio.Content.t()],
      left: String.t() | nil,
      right: String.t() | nil,
      top: String.t() | nil,
      bottom: String.t() | nil
    }
  )

  defvariant(Stack,
    doc: "Stacked layout.",
    type: %__MODULE__{dir: String.t(), children: [Folio.Content.t()], spacing: String.t() | nil}
  )

  defvariant(Rect,
    doc: "Rectangle shape.",
    type: %__MODULE__{
      body: [Folio.Content.t()],
      width: String.t() | nil,
      height: String.t() | nil,
      fill: String.t() | nil,
      inset: String.t() | nil,
      radius: String.t() | nil
    }
  )

  defvariant(Square,
    doc: "Square shape.",
    type: %__MODULE__{body: [Folio.Content.t()], size: String.t() | nil, fill: String.t() | nil}
  )

  defvariant(Circle,
    doc: "Circle shape.",
    type: %__MODULE__{body: [Folio.Content.t()], radius: String.t() | nil, fill: String.t() | nil}
  )

  defvariant(Ellipse,
    doc: "Ellipse shape.",
    type: %__MODULE__{
      body: [Folio.Content.t()],
      width: String.t() | nil,
      height: String.t() | nil,
      fill: String.t() | nil
    }
  )

  defvariant(Line,
    doc: "Line shape.",
    type: %__MODULE__{
      start: String.t() | nil,
      end: String.t() | nil,
      length: String.t() | nil,
      angle: String.t() | nil,
      stroke: String.t() | nil
    }
  )

  defvariant(Polygon,
    doc: "Polygon shape.",
    type: %__MODULE__{vertices: [String.t()], fill: String.t() | nil, stroke: String.t() | nil}
  )

  defvariant(Outline,
    doc: "Table of contents.",
    type: %__MODULE__{
      title: String.t() | nil,
      indent: String.t() | nil,
      depth: pos_integer() | nil
    }
  )

  defvariant(Title, doc: "Document title.", type: %__MODULE__{body: [Folio.Content.t()]})

  defvariant(TermList,
    doc: "Definition/term list.",
    type: %__MODULE__{children: [Folio.Content.t()], tight: boolean()}
  )

  defvariant(TermItem,
    doc: "Term list item.",
    type: %__MODULE__{term: [Folio.Content.t()], description: [Folio.Content.t()]}
  )

  defvariant(Footnote, doc: "Footnote.", type: %__MODULE__{body: [Folio.Content.t()]})

  defvariant(Divider, doc: "Horizontal divider.", type: %__MODULE__{})

  defvariant(Grid,
    doc:
      "Grid layout. Fields: `columns`, `rows`, `gutter`, `column_gutter`, `row_gutter`, `children`.",
    type: %__MODULE__{
      columns: [String.t()] | nil,
      rows: [String.t()] | nil,
      gutter: String.t() | nil,
      column_gutter: String.t() | nil,
      row_gutter: String.t() | nil,
      children: [Folio.Content.t()]
    }
  )

  defvariant(GridCell,
    doc: "Grid cell. Fields: `body`, `colspan`, `rowspan`, `align`, `fill`.",
    type: %__MODULE__{
      body: [Folio.Content.t()],
      colspan: pos_integer() | nil,
      rowspan: pos_integer() | nil,
      align: String.t() | nil,
      fill: String.t() | nil
    }
  )

  defvariant(LocalSet,
    doc: """
    Local style overrides for a content block.
    Mirrors Typst's `#set text(...)` within a scope.

    Fields:
    - `body` — child content
    - `hyphenate` — override text hyphenation for this block
    - `justify` — override paragraph justification
    - `first_line_indent` — override first-line indent (nil = no change)
    """,
    type: %__MODULE__{
      body: [Folio.Content.t()],
      hyphenate: boolean() | nil,
      justify: boolean() | nil,
      first_line_indent: float() | nil
    }
  )

  defvariant(RawTypst,
    doc: """
    Raw Typst source injected directly into the document.
    Use when Folio's abstraction isn't enough.

    Field: `source` — Typst markup/code string.
    """,
    type: %__MODULE__{source: String.t()}
  )

  defvariant(ShowRule,
    doc: """
    A show rule that transforms matching content elements before compilation.

    Applied on the Elixir side; never sent to Rust. The transform function
    receives the matched struct and returns replacement content.

    Targets are atoms matching content types: `:enum`, `:enum_item`, `:list`,
    `:list_item`, `:heading`, `:paragraph`, `:quote`, `:table`, `:grid`,
    `:block`, etc.
    """,
    type: %__MODULE__{
      target: atom(),
      transform: (struct() -> Folio.Content.t() | [Folio.Content.t()] | String.t())
    }
  )

  defvariant(Sequence, doc: "Content sequence.", type: %__MODULE__{children: [Folio.Content.t()]})

  @doc "Flatten nested Sequences."
  @spec flatten([t()]) :: [t()]
  def flatten(nodes) do
    Enum.flat_map(nodes, fn
      %Sequence{children: children} -> flatten(children)
      node -> [node]
    end)
  end

  @doc "Convert a value to a content list."
  @spec to_content(t() | String.t() | [t()] | nil) :: [t()]
  def to_content(nil), do: []
  def to_content(%_{} = node), do: [node]
  def to_content(str) when is_binary(str), do: [%Text{text: str}]
  def to_content(list) when is_list(list), do: Enum.flat_map(list, &to_content/1)

  def to_content(other) do
    raise ArgumentError,
          "expected a content struct, string, or list, got: #{inspect(other)}"
  end
end

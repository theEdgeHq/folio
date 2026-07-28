defmodule Folio.Styles do
  @moduledoc """
  Style rules for customizing document appearance.

      Folio.to_pdf("# Hello", styles: [
        Folio.Styles.page_size(width: 595, height: 842),
        Folio.Styles.page_margin(top: 40, bottom: 40, left: 50, right: 50),
        Folio.Styles.font_size(11),
        Folio.Styles.font_family(["Helvetica", "Arial"]),
        Folio.Styles.text_color("#333333"),
      ])
  """

  use Folio.Declaration, union: :rule

  defvariant(PageSize,
    doc: "Page dimensions in points. Fields: `width`, `height`.",
    type: %__MODULE__{width: float() | nil, height: float() | nil}
  )

  defvariant(PageMargin,
    doc: "Page margins in points. Fields: `top`, `right`, `bottom`, `left`.",
    type: %__MODULE__{
      top: float() | nil,
      right: float() | nil,
      bottom: float() | nil,
      left: float() | nil
    }
  )

  defvariant(FontSize,
    doc: "Base font size in points. Field: `size`.",
    type: %__MODULE__{size: float()}
  )

  defvariant(FontFamily,
    doc: "Font stack. Field: `families`.",
    type: %__MODULE__{families: [String.t()]}
  )

  defvariant(FontWeight,
    doc: "Font weight (100-900). Field: `weight`.",
    type: %__MODULE__{weight: 100..900}
  )

  defvariant(TextColor,
    doc: "Text fill color (hex, named, rgb). Field: `color`.",
    type: %__MODULE__{color: String.t()}
  )

  defvariant(ParJustify,
    doc: "Enable justified paragraphs. Field: `justify`.",
    type: %__MODULE__{justify: boolean()}
  )

  defvariant(ParIndent,
    doc: "First-line paragraph indent in points. Fields: `indent`, `all`.",
    type: %__MODULE__{indent: float(), all: boolean() | nil}
  )

  defvariant(PageNumbering,
    doc: "Page number format (e.g. `\"1\"`, `\"i\"`). Field: `pattern`.",
    type: %__MODULE__{pattern: String.t()}
  )

  defvariant(PageHeader,
    doc: "Page header content. Field: `content`.",
    type: %__MODULE__{content: [Folio.Content.t()]}
  )

  defvariant(PageFooter,
    doc: "Page footer content. Field: `content`.",
    type: %__MODULE__{content: [Folio.Content.t()]}
  )

  defvariant(HeadingNumbering,
    doc: "Heading number format (e.g. `\"1.\"`, `\"A.1\"`). Field: `pattern`.",
    type: %__MODULE__{pattern: String.t()}
  )

  defvariant(HeadingSupplement,
    doc: "Heading supplement text (e.g. `\"Chapter\"`). Field: `content`.",
    type: %__MODULE__{content: [Folio.Content.t()]}
  )

  defvariant(HeadingOutlined,
    doc: "Include heading in outline. Field: `outlined`.",
    type: %__MODULE__{outlined: boolean()}
  )

  defvariant(HeadingBookmarked,
    doc: "Include heading in PDF bookmarks. Field: `bookmarked`.",
    type: %__MODULE__{bookmarked: boolean()}
  )

  defvariant(Lang,
    doc: "Document language (ISO 639-1 code). Field: `lang`.",
    type: %__MODULE__{lang: String.t()}
  )

  defvariant(Hyphenate,
    doc: "Enable/disable hyphenation. Field: `hyphenate`.",
    type: %__MODULE__{hyphenate: boolean()}
  )

  defvariant(Leading,
    doc: "Line leading in em units. Field: `leading`.",
    type: %__MODULE__{leading: float()}
  )

  defvariant(ParSpacing,
    doc: "Paragraph spacing in em units. Field: `spacing`.",
    type: %__MODULE__{spacing: float()}
  )

  defvariant(EnumIndent,
    doc: "Enum list indent. Field: `indent`.",
    type: %__MODULE__{indent: float()}
  )

  defvariant(EnumBodyIndent,
    doc: "Enum list body indent. Field: `body_indent`.",
    type: %__MODULE__{body_indent: float()}
  )

  defvariant(EnumItemSpacing,
    doc: "Enum list item spacing in em. Field: `spacing`.",
    type: %__MODULE__{spacing: float()}
  )

  defvariant(ListIndent,
    doc: "Bullet list indent. Field: `indent`.",
    type: %__MODULE__{indent: float()}
  )

  defvariant(ListBodyIndent,
    doc: "Bullet list body indent. Field: `body_indent`.",
    type: %__MODULE__{body_indent: float()}
  )

  defvariant(ListItemSpacing,
    doc: "Bullet list item spacing in em. Field: `spacing`.",
    type: %__MODULE__{spacing: float()}
  )

  @spec page_size(keyword()) :: PageSize.t()
  def page_size(opts) when is_list(opts) do
    %PageSize{width: Keyword.get(opts, :width), height: Keyword.get(opts, :height)}
  end

  @spec page_margin(keyword()) :: PageMargin.t()
  def page_margin(opts) when is_list(opts) do
    %PageMargin{
      top: Keyword.get(opts, :top),
      right: Keyword.get(opts, :right),
      bottom: Keyword.get(opts, :bottom),
      left: Keyword.get(opts, :left)
    }
  end

  @spec font_size(number()) :: FontSize.t()
  def font_size(size) when is_number(size), do: %FontSize{size: size / 1}

  @spec font_family([String.t()]) :: FontFamily.t()
  def font_family(families) when is_list(families), do: %FontFamily{families: families}

  @spec font_weight(100..900) :: FontWeight.t()
  def font_weight(weight) when is_integer(weight) and weight >= 100 and weight <= 900,
    do: %FontWeight{weight: weight}

  @spec text_color(String.t()) :: TextColor.t()
  def text_color(color) when is_binary(color), do: %TextColor{color: color}

  @spec par_justify(boolean()) :: ParJustify.t()
  def par_justify(justify) when is_boolean(justify), do: %ParJustify{justify: justify}

  @spec par_indent(number(), keyword()) :: ParIndent.t()
  def par_indent(indent, opts \\ []) when is_number(indent) do
    %ParIndent{indent: indent / 1, all: Keyword.get(opts, :all)}
  end

  @spec page_numbering(String.t()) :: PageNumbering.t()
  def page_numbering(pattern) when is_binary(pattern), do: %PageNumbering{pattern: pattern}

  @spec page_header(Folio.Content.t() | [Folio.Content.t()] | String.t()) :: PageHeader.t()
  def page_header(content), do: %PageHeader{content: Folio.Content.to_content(content)}

  @spec page_footer(Folio.Content.t() | [Folio.Content.t()] | String.t()) :: PageFooter.t()
  def page_footer(content), do: %PageFooter{content: Folio.Content.to_content(content)}

  @spec heading_numbering(String.t()) :: HeadingNumbering.t()
  def heading_numbering(pattern) when is_binary(pattern), do: %HeadingNumbering{pattern: pattern}

  @spec heading_supplement(Folio.Content.t() | [Folio.Content.t()] | String.t()) ::
          HeadingSupplement.t()
  def heading_supplement(content),
    do: %HeadingSupplement{content: Folio.Content.to_content(content)}

  @spec heading_outlined(boolean()) :: HeadingOutlined.t()
  def heading_outlined(outlined) when is_boolean(outlined),
    do: %HeadingOutlined{outlined: outlined}

  @spec heading_bookmarked(boolean()) :: HeadingBookmarked.t()
  def heading_bookmarked(bookmarked) when is_boolean(bookmarked),
    do: %HeadingBookmarked{bookmarked: bookmarked}

  @spec lang(String.t()) :: Lang.t()
  def lang(lang) when is_binary(lang), do: %Lang{lang: lang}

  @spec hyphenate(boolean()) :: Hyphenate.t()
  def hyphenate(hyphenate) when is_boolean(hyphenate), do: %Hyphenate{hyphenate: hyphenate}

  @spec leading(number()) :: Leading.t()
  def leading(leading) when is_number(leading), do: %Leading{leading: leading / 1}

  @spec par_spacing(number()) :: ParSpacing.t()
  def par_spacing(spacing) when is_number(spacing), do: %ParSpacing{spacing: spacing / 1}

  @spec enum_indent(number()) :: EnumIndent.t()
  def enum_indent(indent) when is_number(indent), do: %EnumIndent{indent: indent / 1}

  @spec enum_body_indent(number()) :: EnumBodyIndent.t()
  def enum_body_indent(body_indent) when is_number(body_indent),
    do: %EnumBodyIndent{body_indent: body_indent / 1}

  @spec enum_item_spacing(number()) :: EnumItemSpacing.t()
  def enum_item_spacing(spacing) when is_number(spacing),
    do: %EnumItemSpacing{spacing: spacing / 1}

  @spec list_indent(number()) :: ListIndent.t()
  def list_indent(indent) when is_number(indent), do: %ListIndent{indent: indent / 1}

  @spec list_body_indent(number()) :: ListBodyIndent.t()
  def list_body_indent(body_indent) when is_number(body_indent),
    do: %ListBodyIndent{body_indent: body_indent / 1}

  @spec list_item_spacing(number()) :: ListItemSpacing.t()
  def list_item_spacing(spacing) when is_number(spacing),
    do: %ListItemSpacing{spacing: spacing / 1}
end

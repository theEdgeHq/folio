use std::str::FromStr;

use hayagriva::archive::ArchivedStyle;
use typst::model::NumberingPattern;
use typst::text::Lang;

use crate::convert::{
    parse_align, parse_angle, parse_axes, parse_color, parse_dir, parse_font_weight, parse_length,
    parse_rel, parse_sizing, parse_stroke,
};
use crate::types::{ExContent, ExStyle};

/// Validate the complete boundary tree before conversion so malformed authored
/// values cannot reach the converters' defensive fallbacks.
pub(crate) fn document(content: &[ExContent], styles: &[ExStyle]) -> Result<(), String> {
    content_nodes(content, "content")?;

    for (index, style) in styles.iter().enumerate() {
        style_rule(style, &format!("styles[{index}]"))?;
    }

    Ok(())
}

fn invalid(kind: &str, path: &str, value: &str) -> Result<(), String> {
    Err(format!("invalid {kind} for {path}: {value:?}"))
}

fn check(
    value: &str,
    path: &str,
    kind: &str,
    predicate: impl FnOnce(&str) -> bool,
) -> Result<(), String> {
    if predicate(value) {
        Ok(())
    } else {
        invalid(kind, path, value)
    }
}

fn optional(
    value: Option<&str>,
    path: &str,
    kind: &str,
    predicate: impl Fn(&str) -> bool,
) -> Result<(), String> {
    if let Some(value) = value {
        check(value, path, kind, predicate)?;
    }
    Ok(())
}

fn finite(value: f64, path: &str) -> Result<(), String> {
    if value.is_finite() {
        Ok(())
    } else {
        Err(format!("invalid number for {path}: {value}"))
    }
}

fn content_nodes(nodes: &[ExContent], path: &str) -> Result<(), String> {
    for (index, node) in nodes.iter().enumerate() {
        content_node(node, &format!("{path}[{index}]"))?;
    }
    Ok(())
}

fn content_node(node: &ExContent, path: &str) -> Result<(), String> {
    match node {
        ExContent::Text(text) => {
            optional(
                text.size.as_deref(),
                &format!("{path}.size"),
                "length",
                |v| parse_length(v).is_some(),
            )?;
            optional(
                text.tracking.as_deref(),
                &format!("{path}.tracking"),
                "length",
                |v| parse_length(v).is_some(),
            )?;
            optional(
                text.fill.as_deref(),
                &format!("{path}.fill"),
                "color",
                |v| parse_color(v).is_some(),
            )?;
            optional(
                text.weight.as_deref(),
                &format!("{path}.weight"),
                "font weight",
                |v| parse_font_weight(v).is_some(),
            )?;
        }
        ExContent::Heading(heading) => {
            if !(1..=6).contains(&heading.level) {
                return Err(format!(
                    "invalid heading level for {path}.level: {}",
                    heading.level
                ));
            }
            content_nodes(&heading.body, &format!("{path}.body"))?;
        }
        ExContent::Cite(cite) => {
            check(&cite.key, &format!("{path}.key"), "citation key", |v| {
                typst::foundations::Label::new(typst::utils::PicoStr::intern(v)).is_some()
            })?;
            if let Some(supplement) = &cite.supplement {
                content_nodes(supplement, &format!("{path}.supplement"))?;
            }
            optional(
                cite.form.as_deref(),
                &format!("{path}.form"),
                "citation form",
                |v| matches!(v, "normal" | "prose" | "full" | "author" | "year" | "none"),
            )?;
            optional(
                cite.style.as_deref(),
                &format!("{path}.style"),
                "CSL style",
                |v| ArchivedStyle::by_name(v).is_some(),
            )?;
        }
        ExContent::Bibliography(bibliography) => {
            if let Some(title) = &bibliography.title {
                content_nodes(title, &format!("{path}.title"))?;
            }
            optional(
                bibliography.style.as_deref(),
                &format!("{path}.style"),
                "CSL style",
                |v| ArchivedStyle::by_name(v).is_some(),
            )?;
        }
        ExContent::Paragraph(paragraph) => {
            content_nodes(&paragraph.body, &format!("{path}.body"))?;
        }
        ExContent::Strong(strong) => content_nodes(&strong.body, &format!("{path}.body"))?,
        ExContent::Emph(emph) => content_nodes(&emph.body, &format!("{path}.body"))?,
        ExContent::Strike(strike) => content_nodes(&strike.body, &format!("{path}.body"))?,
        ExContent::Underline(underline) => {
            content_nodes(&underline.body, &format!("{path}.body"))?;
        }
        ExContent::Highlight(highlight) => {
            content_nodes(&highlight.body, &format!("{path}.body"))?;
            optional(
                highlight.fill.as_deref(),
                &format!("{path}.fill"),
                "color",
                |v| parse_color(v).is_some(),
            )?;
        }
        ExContent::Super(superscript) => {
            content_nodes(&superscript.body, &format!("{path}.body"))?;
        }
        ExContent::Sub(subscript) => content_nodes(&subscript.body, &format!("{path}.body"))?,
        ExContent::Smallcaps(smallcaps) => {
            content_nodes(&smallcaps.body, &format!("{path}.body"))?;
        }
        ExContent::Image(image) => {
            optional(
                image.width.as_deref(),
                &format!("{path}.width"),
                "length",
                |v| v == "auto" || parse_rel(v).is_some(),
            )?;
            optional(
                image.height.as_deref(),
                &format!("{path}.height"),
                "sizing",
                |v| parse_sizing(v).is_some(),
            )?;
            optional(
                image.fit.as_deref(),
                &format!("{path}.fit"),
                "image fit",
                |v| matches!(v, "contain" | "cover" | "stretch"),
            )?;
        }
        ExContent::Figure(figure) => {
            content_nodes(&figure.body, &format!("{path}.body"))?;
            if let Some(caption) = &figure.caption {
                content_nodes(caption, &format!("{path}.caption"))?;
            }
            optional(
                figure.placement.as_deref(),
                &format!("{path}.placement"),
                "placement",
                |v| matches!(v, "auto" | "top" | "bottom" | "horizon" | "center"),
            )?;
            optional(
                figure.scope.as_deref(),
                &format!("{path}.scope"),
                "placement scope",
                |v| matches!(v, "column" | "parent"),
            )?;
            optional(
                figure.numbering.as_deref(),
                &format!("{path}.numbering"),
                "numbering pattern",
                |v| NumberingPattern::from_str(v).is_ok(),
            )?;
        }
        ExContent::Table(table) => {
            if let Some(columns) = &table.columns {
                for (index, value) in columns.iter().enumerate() {
                    check(value, &format!("{path}.columns[{index}]"), "sizing", |v| {
                        parse_sizing(v).is_some()
                    })?;
                }
            }
            optional(
                table.rows.as_deref(),
                &format!("{path}.rows"),
                "length",
                |v| parse_rel(v).is_some(),
            )?;
            optional(
                table.gutter.as_deref(),
                &format!("{path}.gutter"),
                "length",
                |v| parse_rel(v).is_some(),
            )?;
            optional(
                table.inset.as_deref(),
                &format!("{path}.inset"),
                "length",
                |v| parse_rel(v).is_some(),
            )?;
            optional(
                table.fill.as_deref(),
                &format!("{path}.fill"),
                "color",
                |v| parse_color(v).is_some(),
            )?;
            optional(
                table.stroke.as_deref(),
                &format!("{path}.stroke"),
                "stroke",
                |v| parse_stroke(v).is_some(),
            )?;
            optional(
                table.align.as_deref(),
                &format!("{path}.align"),
                "alignment",
                |v| parse_align(v).is_some(),
            )?;
            content_nodes(&table.children, &format!("{path}.children"))?;
        }
        ExContent::TableHeader(header) => {
            content_nodes(&header.children, &format!("{path}.children"))?;
        }
        ExContent::TableRow(row) => content_nodes(&row.children, &format!("{path}.children"))?,
        ExContent::TableCell(cell) => {
            content_nodes(&cell.body, &format!("{path}.body"))?;
            positive_optional(cell.colspan, &format!("{path}.colspan"))?;
            positive_optional(cell.rowspan, &format!("{path}.rowspan"))?;
            optional(
                cell.align.as_deref(),
                &format!("{path}.align"),
                "alignment",
                |v| parse_align(v).is_some(),
            )?;
            optional(
                cell.fill.as_deref(),
                &format!("{path}.fill"),
                "color",
                |v| parse_color(v).is_some(),
            )?;
            optional(
                cell.stroke.as_deref(),
                &format!("{path}.stroke"),
                "stroke",
                |v| parse_stroke(v).is_some(),
            )?;
        }
        ExContent::Columns(columns) => {
            if columns.count == 0 {
                return Err(format!("invalid column count for {path}.count: 0"));
            }
            content_nodes(&columns.body, &format!("{path}.body"))?;
            optional(
                columns.gutter.as_deref(),
                &format!("{path}.gutter"),
                "length",
                |v| parse_rel(v).is_some(),
            )?;
        }
        ExContent::Link(link) => {
            check(&link.url, &format!("{path}.url"), "URL", |v| {
                typst::model::Url::new(v).is_ok()
            })?;
            content_nodes(&link.body, &format!("{path}.body"))?;
        }
        ExContent::Quote(quote) => {
            content_nodes(&quote.body, &format!("{path}.body"))?;
            if let Some(attribution) = &quote.attribution {
                content_nodes(attribution, &format!("{path}.attribution"))?;
            }
        }
        ExContent::List(list) => content_nodes(&list.children, &format!("{path}.children"))?,
        ExContent::ListItem(item) => content_nodes(&item.body, &format!("{path}.body"))?,
        ExContent::Enum(list) => content_nodes(&list.children, &format!("{path}.children"))?,
        ExContent::EnumItem(item) => content_nodes(&item.body, &format!("{path}.body"))?,
        ExContent::Label(label) => {
            check(&label.name, &format!("{path}.name"), "label", |v| {
                typst::foundations::Label::new(typst::utils::PicoStr::intern(v)).is_some()
            })?;
        }
        ExContent::Ref(reference) => {
            check(&reference.target, &format!("{path}.target"), "label", |v| {
                typst::foundations::Label::new(typst::utils::PicoStr::intern(v)).is_some()
            })?;
            if let Some(supplement) = &reference.supplement {
                content_nodes(supplement, &format!("{path}.supplement"))?;
            }
        }
        ExContent::Align(align) => {
            check(
                &align.alignment,
                &format!("{path}.alignment"),
                "alignment",
                |v| parse_align(v).is_some(),
            )?;
            content_nodes(&align.body, &format!("{path}.body"))?;
        }
        ExContent::Block(block) => {
            content_nodes(&block.body, &format!("{path}.body"))?;
            optional(
                block.width.as_deref(),
                &format!("{path}.width"),
                "length",
                |v| v == "auto" || parse_rel(v).is_some(),
            )?;
            optional(
                block.height.as_deref(),
                &format!("{path}.height"),
                "sizing",
                |v| parse_sizing(v).is_some(),
            )?;
            for (name, value) in [
                ("above", block.above.as_deref()),
                ("below", block.below.as_deref()),
                ("inset", block.inset.as_deref()),
                ("radius", block.radius.as_deref()),
            ] {
                optional(value, &format!("{path}.{name}"), "length", |v| {
                    parse_rel(v).is_some()
                })?;
            }
            optional(
                block.fill.as_deref(),
                &format!("{path}.fill"),
                "color",
                |v| parse_color(v).is_some(),
            )?;
            optional(
                block.stroke.as_deref(),
                &format!("{path}.stroke"),
                "stroke",
                |v| parse_stroke(v).is_some(),
            )?;
        }
        ExContent::Hide(hide) => content_nodes(&hide.body, &format!("{path}.body"))?,
        ExContent::Repeat(repeat) => content_nodes(&repeat.body, &format!("{path}.body"))?,
        ExContent::Place(place) => {
            content_nodes(&place.body, &format!("{path}.body"))?;
            optional(
                place.alignment.as_deref(),
                &format!("{path}.alignment"),
                "alignment",
                |v| parse_align(v).is_some(),
            )?;
        }
        ExContent::VSpace(space) => {
            check(&space.amount, &format!("{path}.amount"), "length", |v| {
                parse_rel(v).is_some()
            })?;
        }
        ExContent::HSpace(space) => {
            check(&space.amount, &format!("{path}.amount"), "length", |v| {
                parse_rel(v).is_some()
            })?;
        }
        ExContent::Pad(pad) => {
            content_nodes(&pad.body, &format!("{path}.body"))?;
            for (name, value) in [
                ("left", pad.left.as_deref()),
                ("right", pad.right.as_deref()),
                ("top", pad.top.as_deref()),
                ("bottom", pad.bottom.as_deref()),
            ] {
                optional(value, &format!("{path}.{name}"), "length", |v| {
                    parse_rel(v).is_some()
                })?;
            }
        }
        ExContent::Stack(stack) => {
            check(&stack.dir, &format!("{path}.dir"), "direction", |v| {
                parse_dir(v).is_some()
            })?;
            optional(
                stack.spacing.as_deref(),
                &format!("{path}.spacing"),
                "length",
                |v| parse_rel(v).is_some(),
            )?;
            content_nodes(&stack.children, &format!("{path}.children"))?;
        }
        ExContent::Rect(rect) => {
            content_nodes(&rect.body, &format!("{path}.body"))?;
            validate_shape_lengths(
                path,
                [
                    ("width", rect.width.as_deref(), true),
                    ("height", rect.height.as_deref(), true),
                    ("inset", rect.inset.as_deref(), false),
                    ("radius", rect.radius.as_deref(), false),
                ],
            )?;
            optional(
                rect.fill.as_deref(),
                &format!("{path}.fill"),
                "color",
                |v| parse_color(v).is_some(),
            )?;
        }
        ExContent::Square(square) => {
            content_nodes(&square.body, &format!("{path}.body"))?;
            validate_shape_lengths(path, [("size", square.size.as_deref(), true)])?;
            optional(
                square.fill.as_deref(),
                &format!("{path}.fill"),
                "color",
                |v| parse_color(v).is_some(),
            )?;
        }
        ExContent::Circle(circle) => {
            content_nodes(&circle.body, &format!("{path}.body"))?;
            validate_shape_lengths(path, [("radius", circle.radius.as_deref(), true)])?;
            optional(
                circle.fill.as_deref(),
                &format!("{path}.fill"),
                "color",
                |v| parse_color(v).is_some(),
            )?;
        }
        ExContent::Ellipse(ellipse) => {
            content_nodes(&ellipse.body, &format!("{path}.body"))?;
            validate_shape_lengths(
                path,
                [
                    ("width", ellipse.width.as_deref(), true),
                    ("height", ellipse.height.as_deref(), true),
                ],
            )?;
            optional(
                ellipse.fill.as_deref(),
                &format!("{path}.fill"),
                "color",
                |v| parse_color(v).is_some(),
            )?;
        }
        ExContent::Line(line) => {
            optional(
                line.start.as_deref(),
                &format!("{path}.start"),
                "coordinate",
                |v| parse_axes(v).is_some(),
            )?;
            optional(
                line.end.as_deref(),
                &format!("{path}.end"),
                "coordinate",
                |v| parse_axes(v).is_some(),
            )?;
            optional(
                line.length.as_deref(),
                &format!("{path}.length"),
                "length",
                |v| parse_rel(v).is_some(),
            )?;
            optional(
                line.angle.as_deref(),
                &format!("{path}.angle"),
                "angle",
                |v| parse_angle(v).is_some(),
            )?;
            optional(
                line.stroke.as_deref(),
                &format!("{path}.stroke"),
                "stroke",
                |v| parse_stroke(v).is_some(),
            )?;
        }
        ExContent::Polygon(polygon) => {
            for (index, vertex) in polygon.vertices.iter().enumerate() {
                check(
                    vertex,
                    &format!("{path}.vertices[{index}]"),
                    "coordinate",
                    |v| parse_axes(v).is_some(),
                )?;
            }
            optional(
                polygon.fill.as_deref(),
                &format!("{path}.fill"),
                "color",
                |v| parse_color(v).is_some(),
            )?;
            optional(
                polygon.stroke.as_deref(),
                &format!("{path}.stroke"),
                "stroke",
                |v| parse_stroke(v).is_some(),
            )?;
        }
        ExContent::Outline(outline) => {
            optional(
                outline.indent.as_deref(),
                &format!("{path}.indent"),
                "length",
                |v| parse_rel(v).is_some(),
            )?;
            positive_optional(outline.depth, &format!("{path}.depth"))?;
        }
        ExContent::Title(title) => content_nodes(&title.body, &format!("{path}.body"))?,
        ExContent::TermList(list) => content_nodes(&list.children, &format!("{path}.children"))?,
        ExContent::TermItem(item) => {
            content_nodes(&item.term, &format!("{path}.term"))?;
            content_nodes(&item.description, &format!("{path}.description"))?;
        }
        ExContent::Footnote(footnote) => {
            content_nodes(&footnote.body, &format!("{path}.body"))?;
        }
        ExContent::Grid(grid) => {
            for (name, values) in [("columns", &grid.columns), ("rows", &grid.rows)] {
                if let Some(values) = values {
                    for (index, value) in values.iter().enumerate() {
                        check(value, &format!("{path}.{name}[{index}]"), "sizing", |v| {
                            parse_sizing(v).is_some()
                        })?;
                    }
                }
            }
            for (name, value) in [
                ("gutter", grid.gutter.as_deref()),
                ("column_gutter", grid.column_gutter.as_deref()),
                ("row_gutter", grid.row_gutter.as_deref()),
            ] {
                optional(value, &format!("{path}.{name}"), "length", |v| {
                    parse_rel(v).is_some()
                })?;
            }
            content_nodes(&grid.children, &format!("{path}.children"))?;
        }
        ExContent::GridCell(cell) => {
            content_nodes(&cell.body, &format!("{path}.body"))?;
            positive_optional(cell.colspan, &format!("{path}.colspan"))?;
            positive_optional(cell.rowspan, &format!("{path}.rowspan"))?;
            optional(
                cell.align.as_deref(),
                &format!("{path}.align"),
                "alignment",
                |v| parse_align(v).is_some(),
            )?;
            optional(
                cell.fill.as_deref(),
                &format!("{path}.fill"),
                "color",
                |v| parse_color(v).is_some(),
            )?;
        }
        ExContent::LocalSet(local) => {
            content_nodes(&local.body, &format!("{path}.body"))?;
            if let Some(indent) = local.first_line_indent {
                finite(indent, &format!("{path}.first_line_indent"))?;
            }
        }
        ExContent::Sequence(sequence) => {
            content_nodes(&sequence.children, &format!("{path}.children"))?;
        }
        ExContent::Space(_)
        | ExContent::Colbreak(_)
        | ExContent::Pagebreak(_)
        | ExContent::Parbreak(_)
        | ExContent::Linebreak(_)
        | ExContent::Math(_)
        | ExContent::Raw(_)
        | ExContent::Divider(_)
        | ExContent::RawTypst(_) => {}
    }

    Ok(())
}

fn validate_shape_lengths<const N: usize>(
    path: &str,
    values: [(&str, Option<&str>, bool); N],
) -> Result<(), String> {
    for (name, value, allow_auto) in values {
        optional(value, &format!("{path}.{name}"), "length", |v| {
            (allow_auto && v == "auto") || parse_rel(v).is_some()
        })?;
    }
    Ok(())
}

fn positive_optional(value: Option<u32>, path: &str) -> Result<(), String> {
    if value == Some(0) {
        Err(format!("invalid positive integer for {path}: 0"))
    } else {
        Ok(())
    }
}

fn style_rule(style: &ExStyle, path: &str) -> Result<(), String> {
    match style {
        ExStyle::PageSize(size) => {
            finite_options([size.width, size.height], path, &["width", "height"])?;
        }
        ExStyle::PageMargin(margin) => {
            finite_options(
                [margin.top, margin.right, margin.bottom, margin.left],
                path,
                &["top", "right", "bottom", "left"],
            )?;
        }
        ExStyle::FontSize(size) => finite(size.size, &format!("{path}.size"))?,
        ExStyle::FontWeight(weight) => {
            if !(100..=900).contains(&weight.weight) {
                return Err(format!(
                    "invalid font weight for {path}.weight: {}",
                    weight.weight
                ));
            }
        }
        ExStyle::TextColor(color) => {
            check(&color.color, &format!("{path}.color"), "color", |v| {
                parse_color(v).is_some()
            })?;
        }
        ExStyle::ParIndent(indent) => finite(indent.indent, &format!("{path}.indent"))?,
        ExStyle::PageNumbering(numbering) => {
            check(
                &numbering.pattern,
                &format!("{path}.pattern"),
                "numbering pattern",
                |v| NumberingPattern::from_str(v).is_ok(),
            )?;
        }
        ExStyle::PageHeader(header) => {
            content_nodes(&header.content, &format!("{path}.content"))?;
        }
        ExStyle::PageFooter(footer) => {
            content_nodes(&footer.content, &format!("{path}.content"))?;
        }
        ExStyle::HeadingNumbering(numbering) => {
            check(
                &numbering.pattern,
                &format!("{path}.pattern"),
                "numbering pattern",
                |v| NumberingPattern::from_str(v).is_ok(),
            )?;
        }
        ExStyle::HeadingSupplement(supplement) => {
            content_nodes(&supplement.content, &format!("{path}.content"))?;
        }
        ExStyle::Lang(lang) => {
            check(&lang.lang, &format!("{path}.lang"), "language code", |v| {
                Lang::from_str(v).is_ok()
            })?;
        }
        ExStyle::Leading(leading) => finite(leading.leading, &format!("{path}.leading"))?,
        ExStyle::ParSpacing(spacing) => finite(spacing.spacing, &format!("{path}.spacing"))?,
        ExStyle::EnumIndent(indent) => finite(indent.indent, &format!("{path}.indent"))?,
        ExStyle::EnumBodyIndent(indent) => {
            finite(indent.body_indent, &format!("{path}.body_indent"))?;
        }
        ExStyle::EnumItemSpacing(spacing) => {
            finite(spacing.spacing, &format!("{path}.spacing"))?;
        }
        ExStyle::ListIndent(indent) => finite(indent.indent, &format!("{path}.indent"))?,
        ExStyle::ListBodyIndent(indent) => {
            finite(indent.body_indent, &format!("{path}.body_indent"))?;
        }
        ExStyle::ListItemSpacing(spacing) => {
            finite(spacing.spacing, &format!("{path}.spacing"))?;
        }
        ExStyle::FontFamily(_)
        | ExStyle::ParJustify(_)
        | ExStyle::HeadingOutlined(_)
        | ExStyle::HeadingBookmarked(_)
        | ExStyle::Hyphenate(_) => {}
    }

    Ok(())
}

fn finite_options<const N: usize>(
    values: [Option<f64>; N],
    path: &str,
    names: &[&str; N],
) -> Result<(), String> {
    for (value, name) in values.into_iter().zip(names) {
        if let Some(value) = value {
            finite(value, &format!("{path}.{name}"))?;
        }
    }
    Ok(())
}

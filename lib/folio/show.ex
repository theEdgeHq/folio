defmodule Folio.Show do
  @moduledoc """
  Apply show rules to content trees before compilation.

  Show rules emulate Typst's `#show` mechanism by transforming
  matching content elements in Elixir before sending to Rust.

  They are applied bottom-up: children are transformed first,
  then the parent node is matched and replaced.

  Show rules found anywhere in the content tree are extracted
  and applied globally. Place them at the top level for clarity.
  """

  alias Folio.Content

  @doc """
  Extract all show rules from the content tree and apply them.

  Returns the transformed content with all show rules removed.
  """
  @spec apply([Content.t()]) :: [Content.t()]
  def apply(content) when is_list(content) do
    {rules, stripped} = extract_rules(content)
    apply_transforms(stripped, rules)
  end

  defp extract_rules(nodes) do
    {rules, stripped} =
      Enum.reduce(nodes, {[], []}, fn
        %Content.ShowRule{} = rule, {rules, nodes} ->
          {[{rule.target, rule.transform} | rules], nodes}

        node, {rules, nodes} ->
          {rules, [node | nodes]}
      end)

    {child_rules, cleaned} = extract_from_children(Enum.reverse(stripped))
    {Enum.reverse(rules) ++ child_rules, cleaned}
  end

  defp extract_from_children(nodes) do
    {rules, cleaned} =
      Enum.reduce(nodes, {[], []}, fn node, {rules, nodes} ->
        {child_rules, cleaned_node} = extract_from_node(node)
        {rules ++ child_rules, [cleaned_node | nodes]}
      end)

    {rules, Enum.reverse(cleaned)}
  end

  defp extract_from_node(node) when is_struct(node) do
    Enum.reduce(child_fields(node), {[], node}, fn field, {rules, node} ->
      case Map.get(node, field) do
        children when is_list(children) ->
          {child_rules, cleaned} = extract_rules(children)
          {rules ++ child_rules, Map.put(node, field, cleaned)}

        _other ->
          {rules, node}
      end
    end)
  end

  defp extract_from_node(node), do: {[], node}

  defp apply_transforms(nodes, rules) do
    Enum.flat_map(nodes, &apply_to_node(&1, rules))
  end

  defp apply_to_node(%Content.ShowRule{}, _rules), do: []

  defp apply_to_node(node, rules) when is_struct(node) do
    node = transform_children(node, rules)

    case List.keyfind(rules, node_type(node), 0) do
      {_type, transform} -> Content.to_content(transform.(node))
      nil -> [node]
    end
  end

  defp apply_to_node(node, _rules), do: [node]

  defp transform_children(node, rules) do
    Enum.reduce(child_fields(node), node, fn field, node ->
      case Map.get(node, field) do
        children when is_list(children) ->
          Map.put(node, field, apply_transforms(children, rules))

        _other ->
          node
      end
    end)
  end

  defp child_fields(node) do
    case Content.__folio_declaration__(node) do
      %{child_fields: fields} -> fields
      nil -> []
    end
  end

  defp node_type(node) do
    case Content.__folio_declaration__(node) do
      %{tag: tag} -> tag
      nil -> nil
    end
  end
end

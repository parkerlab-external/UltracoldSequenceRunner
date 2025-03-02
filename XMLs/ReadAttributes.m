function attr_out = ReadAttributes(node_parent, map_modifier)
  node_attrs = node_parent.getAttributes;
  attr_out = struct;
  for i_attr = 1:node_attrs.getLength
      node_attr_i = node_attrs.item(i_attr-1);
      name_i = string(char(node_attr_i.getNodeName));
      if ~map_modifier.isKey(name_i)
          warning(sprintf("Attribute %s is not currently supported. Consider remove it for now.", name_i));
          continue;
      end
      modi_i = map_modifier(name_i);
      attr_out.(name_i) = modi_i(node_attr_i.getNodeValue);
  end
end

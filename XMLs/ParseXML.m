function seq_symb = ParseXML(filename_xml, map_mod)
    
node_xml_root = xmlread(char(filename_xml));

seq_symb = struct('times',{},'data',{},'address',{},'params',{}, 'chanid', {}, 'typeid', {}, 'serialized', {}, 'mod_type', {});
module_types = map_mod.keys;
for i_type = 1 : numel(module_types)
    type_i = module_types{i_type};
    node_mods_i = node_xml_root.getDocumentElement.getElementsByTagName(type_i);
    for j_mod = 1:node_mods_i.getLength
        node_mod_ij = node_mods_i.item(j_mod - 1);
        if node_mod_ij.hasAttribute("enabled") && ~equals(node_mod_ij.getAttribute('enabled'), "true"); continue; end % skip disabled channels        
        seq_symb_ij = feval(map_mod(type_i).Parser, node_mod_ij);
        seq_symb_ij.mod_type = type_i;
        seq_symb(end+1) = seq_symb_ij;%#ok<AGROW>
    end
end
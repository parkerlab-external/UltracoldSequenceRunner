function seq_num = PrepFromXML(dicts, filename_xml, file_debug)
arguments (Input)
    dicts
    filename_xml    string
    file_debug      = 1;
end
arguments (Output)
    seq_num         % The numeric sequence
end
map_mod = mkmodmap("map_module.json");
% If i_mod string is passed, then it is an XML file and it needs to be parsed
seq_symb = ParseXML(filename_xml, map_mod);
seq_num = MakeNumericQueue(dicts, seq_symb, map_mod);

% Error check
time_last = max([seq_num.times]);
list_address = [seq_num.address];
assert(all(list_address >= 0 & list_address < intmax('uint8')), ...
        "Wrong address number: smaller than 0");
assert(numel(unique(list_address)) == numel(list_address), ...
        "Bad address or repeat address.");    
% Create the command list ready to be sent from the contained data
for i_mod = 1:length(seq_num)
    seq_num_i = seq_num(i_mod);
    mod_info_i = map_mod(seq_num_i.mod_type);
    builder_i = mod_info_i.CmdBuilder;
    cmdlist_u8_i = builder_i(seq_num_i, time_last, mod_info_i, file_debug);
    seq_num(i_mod).cmdlist_u8 = cmdlist_u8_i;
    seq_num(i_mod).params.checksum = sum(double(cmdlist_u8_i));
end

function seq_symb = ParseDigital(node_dig)

n_chan = 16;
n_col = 3;
params = struct();
params.chnames = ["Channel 00", ...
                  "Channel 01", ...
                  "Channel 02", ...
                  "Channel 03", ...
                  "Channel 04", ...
                  "Channel 05", ...
                  "Channel 06", ...
                  "Channel 07", ...
                  "Channel 08", ...
                  "Channel 09", ...
                  "Channel 10", ...
                  "Channel 11", ...
                  "Channel 12", ...
                  "Channel 13", ...
                  "Channel 14", ...
                  "Channel 15"  ];
params.mask_chan_active = true(1, n_chan);

attr_names      = ["address"  , "frequency", "enabled" ];
attr_modifier   = {@str2double, @str2double, @eval     };
map_attr = containers.Map(attr_names, attr_modifier);

params = extractfieldsall(ReadAttributes(node_dig, map_attr), params);
tab_data = ReadNodeCSV(node_dig, n_col);

chanid = uint8(cell2mat(evalparams(tab_data{1})));
n_row = size(chanid, 2);
seq_symb.chanid    = chanid;
seq_symb.typeid    =  ones([1 n_row]);
params.scale_range = zeros([1 n_row]);
seq_symb.times     = tab_data{2}';
seq_symb.data      = tab_data{3}';
seq_symb.address   = params.address;
seq_symb.params    = params;

tab_data_by_chan = cell([n_chan, 2]);
for i_ch = 1 : n_chan
    ch_i = i_ch - 1;
    mask_i = seq_symb.chanid == ch_i;
    time_i = seq_symb.times(mask_i);
    val_i  = seq_symb.data (mask_i);
    tab_data_by_chan{i_ch, 1} = time_i;
    tab_data_by_chan{i_ch, 2} = val_i;
end
seq_symb.serialized = genforsrl(n_chan, tab_data_by_chan, ["time", "value"], 2, seq_symb, "Digital");

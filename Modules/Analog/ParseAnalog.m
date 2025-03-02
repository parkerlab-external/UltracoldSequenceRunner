function seq_symb = ParseAnalog(node_anlg)

n_chan = 4;
n_col = 2;
name_col = ["times", "volts"];
params = struct();
params.chnames = ["Channel 0", "Channel 1", "Channel 2", "Channel 3"];
params.mask_chan_active = true(1, n_chan);


attr_names      = ["address"  , "frequency", "enabled" ];
attr_modifier   = {@str2double, @str2double, @eval     };
chan_attr_names    = ["chnum"     , "name", "voltrangemode"];
chan_attr_modifier = {@str2double , @char , @str2double    };
map_attr = containers.Map(attr_names, attr_modifier);
map_chan_attr = containers.Map(chan_attr_names, chan_attr_modifier);

params = extractfieldsall(ReadAttributes(node_anlg, map_attr), params);
[tab_data, tab_chan, n_row_tot, params.chnames, tab_info] = ReadChannels(node_anlg, map_chan_attr, n_col, n_chan);

arr_volt = cell([1, 0]);
arr_time = cell([1, 0]);
arr_chan = zeros([1,0]);
tab_gainmode = nan([1 n_chan]);

% Concatenate
for i_ch = 1 : n_chan
    rng_i = 1:n_row_tot(i_ch);
    arr_volt(end + rng_i) = tab_data{i_ch, 2};
    arr_chan(end + rng_i) = tab_chan(i_ch);
    arr_time(end + rng_i) = tab_data{i_ch, 1};
    tab_gainmode(i_ch) = tab_info{i_ch}.voltrangemode;
end

n_row_tot = size(arr_chan, 2);
params.scale_range = tab_gainmode(arr_chan + 1);
params.mode_G = tab_gainmode;
seq_symb.params = params;
seq_symb.chanid = arr_chan; % chanid range from 0 to 3
seq_symb.typeid = ones([1, n_row_tot]); % only one typeid, which is the amplitude
seq_symb.times = arr_time;
seq_symb.data = arr_volt;
seq_symb.address = params.address;

% create the table convenient for serialization
seq_symb.serialized = genforsrl(n_chan, tab_data, name_col, n_col, seq_symb, "Analog");

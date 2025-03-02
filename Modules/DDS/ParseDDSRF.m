function seq_symb = ParseDDSRF(node_dds)

n_chan = 4;
n_col = 5;
typeid = [nan 1 2 3 4]; % time amps freq unused dither
name_col = ["times", "amplitude", "frequency", "unused", "dither_amp"];

params = struct();
params.chnames = ["Channel 0", "Channel 1", "Channel 2", "Channel 3"];
params.mask_chan_active = true(1, n_chan);
params.ditherfreq = 1; % default

attr_names      = ["address"  , "frequency", "ddsamp"   , "ddsfreq"  , "ditherfreq", "enabled"];
attr_modifier   = {@str2double, @str2double, @str2double, @str2double, @str2double , @eval    };
chan_attr_names    = ["chnum"     , "name", "feature"];
chan_attr_modifier = {@str2double , @char , @char    };
map_attr = containers.Map(attr_names, attr_modifier);
map_chan_attr = containers.Map(chan_attr_names, chan_attr_modifier);

% Read nodes
params = extractfieldsall(ReadAttributes(node_dds, map_attr), params);
[tab_data, tab_chan, n_row_tot, params.chnames] = ReadChannels(node_dds, map_chan_attr, n_col, n_chan);

% Remove the empty cells
map_to_false = @(c) map_c(const('false'), c);
map_to_zeros = @(c) map_c(@(d) tern(isempty(d), '0', d), c);
tab_data(:, 4) = map_c(map_to_false, tab_data(:, 4));
tab_data(:, 5) = map_c(map_to_zeros, tab_data(:, 5));
% Concatenate
arr_data = cell([1, 0]);
arr_time = cell([1, 0]);
arr_chan = zeros([1,0]);
arr_type = nan([1,0]);
for c = 2 : n_col
for i_ch = 1 : n_chan
    rng_i = 1:n_row_tot(i_ch);
    arr_data(end + rng_i) = tab_data{i_ch, c};
    arr_chan(end + rng_i) = tab_chan(i_ch);
    arr_type(end + rng_i) = typeid(c);     
    arr_time(end + rng_i) = tab_data{i_ch, 1};
end
end
assert(~any(cell2mat(map_c(@isempty, arr_data))), "Should not have empty data cell at this point");

% Create symbolic sequence
params.scale_range = GetDDSScaling(arr_type, params.ddsamp, params.ddsfreq, params.ditherfreq);
% params.scale_range = @(x) GetDDSScaling(x, params.ddsamp, params.ddsfreq, params.ditherfreq);
seq_symb.params = params;
seq_symb.typeid = arr_type;
seq_symb.times = arr_time;
seq_symb.data = arr_data;
seq_symb.address = params.address;
seq_symb.chanid = arr_chan;

% Create the table convenient for serialization
seq_symb.serialized = genforsrl(n_chan, tab_data, name_col, n_col, seq_symb, "DDSRF");

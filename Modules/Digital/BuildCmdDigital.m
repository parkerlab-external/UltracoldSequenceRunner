function seq_cmd_u8 = BuildCmdDigital(seq_num, time_last, mod_info, file_debug) 

chan = seq_num.chanid; 
times = seq_num.times;
vals = seq_num.data;

times_rel = times - truncatecond(min(times), -Inf, 0);
times_uniq = unique([times_rel 0]);
n_chkpt = length(times_uniq) + 1;

vals_u16 = zeros(1, length(times_uniq), 'uint16');

[~, ord_t] = sort(times_rel);    
[times_ord, chan_ord, vals_ord] = mapvararg(@(arr) arr(ord_t), times_rel, chan, vals);

% Set the initial values
val_init = uint16(0);
for ch = 1 : 16
    idx_first_ch = find(chan_ord == uint8(ch-1),1);
    if isempty(idx_first_ch); continue; end
    val_init = bitset(val_init, ch, vals_ord(idx_first_ch));
end
vals_u16(1) = val_init;

% Set the updated values at every checkpoint
for t = 2 : n_chkpt-1
    vals_u16(t) = vals_u16(t-1);
    ids_to_update_t = find(times_ord - times_uniq(t) < 0.05);
    for u = 1:length(ids_to_update_t)
        idx_tu = ids_to_update_t(u);
        vals_u16(t) = bitset(   vals_u16(t), ...
                                chan_ord(idx_tu) + 1, ...
                                vals_ord(idx_tu)  );
    end
end


% Digital outputs need to run all the way to the end so that the start pin
% stays high (allow a few extra cycles for DDS RF channels to update)
times_uniq(end+1) = max(time_last + 10, times_uniq(end) + 1);
durs_u32 = uint32([diff(times_uniq) 1]);
% Jump to the initial value at the end of the sequence
vals_u16 = [vals_u16 vals_u16(1)];
chkpt_pos_u16 = uint16(1:n_chkpt) - 1;

cmd_cell = { {'E', n_chkpt}; ...                
             {'U', chkpt_pos_u16, durs_u32, vals_u16}; ...
             {'T'}  };

seq_cmd_u8 = toseqcmd(cmd_cell, mod_info, file_debug, seq_num.address);

function seq_cmd_u8 = BuildCmdAnalog(seq_num, time_last, mod_info, file_debug)
slotid = seq_num.chanid;
time_u8 = seq_num.times;
vals_u8 = seq_num.data;

n_chan = 4;

% Extract and sort range modes
% Slots are the same as channels for Analog.
list_slot = 0 : (n_chan-1);
mode_G = uint8(seq_num.params.mode_G);
slotid_uniq = unique(slotid);

% Has to have all channels
assert(length(union(list_slot, slotid_uniq)) == length(list_slot), ...
    'AnalogUpdate:MissingVRM', 'Did not specify the VRM for all channels to be updated.');

[~, goodchs] = intersect(list_slot, slotid_uniq);
mode_G = mode_G(goodchs);


tab_dur_i32 = zeros(n_chan, 1, 'int32');
tab_val_i32 = zeros(n_chan, 1, 'int32');
n_chkpt_E_u16   = zeros(1, numel(slotid_uniq),'uint16');
for c_chan = 1 : numel(slotid_uniq)
    chan_c = slotid_uniq(c_chan);    
    mask_c = slotid == chan_c;    
    [polydur_i, polyval_i] = GeneralPurposeRampCalc( ...
                time_u8(mask_c), vals_u8(mask_c), intmax('int16'));
    dur_final = int32(time_last) + 1 - max(int32(time_u8(mask_c)));
    n_chkpt_E_u16(c_chan)  = length(polydur_i) + 2;
    % Append -2 dur to bring it back to the start voltage in the end
    tab_dur_i32(c_chan, 1:n_chkpt_E_u16(c_chan)) = [polydur_i  dur_final     -2          ];
    tab_val_i32(c_chan, 1:n_chkpt_E_u16(c_chan)) = [polyval_i  0             polyval_i(1)];
end

slotid_U_u8     = zeros(1, 0, 'uint8');
chkpt_pos_U_u16 = zeros(1, 0, 'uint16');
polydurs_U_i32  = zeros(1, 0, 'int32');
polyvals_U_i32  = zeros(1, 0, 'int32');

for j_chan = 1 : n_chan
    chan_j = slotid_uniq(j_chan);
    width_new_j = n_chkpt_E_u16(j_chan);
    rng_chkpt_j = 1 : width_new_j;    
    slotid_U_u8       (end + rng_chkpt_j) = chan_j;
    chkpt_pos_U_u16   (end + rng_chkpt_j) = 0 : width_new_j-1;
    polydurs_U_i32    (end + rng_chkpt_j) = tab_dur_i32(j_chan, rng_chkpt_j);
    polyvals_U_i32    (end + rng_chkpt_j) = tab_val_i32(j_chan, rng_chkpt_j);
end
cmd_cell = { {'G', slotid_uniq, mode_G}; ...
             {'E', slotid_uniq, n_chkpt_E_u16}; ...                
             {'U', slotid_U_u8, chkpt_pos_U_u16, polydurs_U_i32, polyvals_U_i32}; ...
             {'T'}  };

seq_cmd_u8 = toseqcmd(cmd_cell, mod_info, file_debug, seq_num.address);
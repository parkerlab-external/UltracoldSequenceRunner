function seq_cmd_u8 = BuildCmdDDSRF(seq_num, time_last, mod_info, file_debug)
% Naming convention
% tab_<...> : n_slot × _
% is_<...>  : logical array, acting like a mask, but I don't want to name is mask because the name has been taken.
n_slot = 4;
% time-order everything
[~, ord_t] = sort(seq_num.times);    
[typeid, chanid, times, vals] = mapvararg(@(arr) arr(ord_t), ...
                                seq_num.typeid, ...
                                seq_num.chanid, ...
                                seq_num.times, ...
                                seq_num.data);
% The mask is a cartesian product of chanid and typeid.
% Later, multiple chanid can be set by bitor, but the typeid is unique for each mask. 
mask = bitshift(uint8(1), chanid+4) + uint8(typeid);
% All allowed masks.
% typeid for feedback is no longer supported                        |----- fb -----|
%                                                                  0x13 0x23 0x43 0x83 
list_mask         = uint8([0x11 0x21 0x41 0x81 0x12 0x22 0x42 0x82                     0x14 0x24 0x44 0x84]);
dt_mask           =       [   0    0    0    0    2    2    2    2                        6    6    6    6];
n_mask       = 12;
is_fb_related = typeid == 3; % remove feedback related.
[typeid, chanid, times, mask, vals] = mapvararg(@(arr) arr(~is_fb_related), typeid, chanid, times, mask, vals);

% get unique times
t_uniq = unique([0 times]);

% first and last value of each mask
% TODO: This part has problem: what if some masks do not present? then vals_m can not be accessed by index.
vals_head = zeros(1, n_mask, 'int32');
vals_tail = zeros(1, n_mask, 'int32');
for m_mask = 1 : n_mask
    is_m = list_mask(m_mask) == mask;
    vals_m  = vals(is_m);
    vals_head(m_mask) = vals_m(1);
    vals_tail(m_mask) = vals_m(end); 
end

% code here to find initial values and set them as final values
% append to set the initial and final points
% The initial points are appended after the final points, but maybe they
% are not actually included in the final sequence?
time_xtra     = double(time_last) + 1 + [dt_mask, dt_mask + 1];
mask_xtra     = [list_mask list_mask];
vals_xtra     = [vals_tail vals_head];

[~, ord_t] = sort(time_xtra);
times    = [times time_xtra(ord_t)];
mask     = [mask  mask_xtra(ord_t)];
vals     = [vals  vals_xtra(ord_t)];
t_uniq   = [t_uniq unique(time_xtra)];


% create output tables, n_slot x variable
tab_mask_u8 = zeros(n_slot,1,'uint8');
tab_val_i32 = zeros(n_slot,1,'int32');
tab_dur_i32 = zeros(n_slot,1,'int32');

% next available position in the output arrays
n_chkpt_E_u16 = ones(n_slot,1,'uint16');

% Now create tab_mask_u8, tab_val_i32 and tab_dur_i32
for t = 1 : length(t_uniq)
    tt = t_uniq(t); tt_in_sec = tt/seq_num.params.frequency;
    is_t = logical(times == tt);    
    mask_t = mask(is_t);
    vals_t = vals(is_t);
    n_rt = sum(is_t);
    % For each action that's at this time
    for r_t = 1 : n_rt
        val_rt = vals_t(r_t);
        mask_rt = mask_t(r_t);
        is_mask_rt = mask == mask_rt;
        sigchan_rt = maskgetchan(mask_rt);
        % simultaneous value check
        assert(sum(is_mask_rt & is_t) <= 1, ...
            "DDSRFUpdate:SimultaneousValues", ...
            "Multiple values for channel %d, address %d at time %f.\n", ...
            sigchan_rt, seq_num.address, tt_in_sec);
        % find the next frame with the same mask\5
        % TODO: But what if it is further down the line?
        idx_next_rt = find(is_mask_rt & times > tt, 1);
        % proceed only if the next frame with the same mask yields a different value
        if isempty(idx_next_rt); continue; end
        if val_rt == vals(idx_next_rt) && tt <= time_last; continue; end
        
        % yields the duration and delta of mini-steps
        dur_jump = ifthel(tt > time_last, -4, -2);
        [dur_mini, val_mini] = GeneralPurposeRampCalc(...
            [tt         times(idx_next_rt)],...
            [val_rt     vals(idx_next_rt)], ...
            intmax('int16'), dur_jump );
        
        dur_mini = dur_mini(2:end);
        val_mini = val_mini(2:end);
        n_mini   = numel(dur_mini);        
        
        % A jump takes one frame as well, the maximum duration for each
        % slot, this calculates the maximum time at upon `tt` 
        tab_dur_pos = replacecond(  @(dur) dur < 0, ...
                                    const(1), ...
                                    tab_dur_i32  );
        tab_time_max  = sum(tab_dur_pos, 2);
        
        done = false;
        % The primitive attempt
        % try to copy an existing ramp if applicable
        for j_slot = 1 : n_slot
            n_chkpt_jr = n_chkpt_E_u16(j_slot);
            if n_chkpt_jr <= n_mini; continue; end % leave this this slot for now
            rng_chkpt_jr = rng_u(n_chkpt_jr, [-n_mini, -1]);
            % check maximum time and length are ok
            if tab_time_max(j_slot) ~= times(idx_next_rt); continue; end
            % check ramp is an exact match
            if any(tab_dur_i32(j_slot,rng_chkpt_jr) ~= dur_mini); continue; end
            if any(tab_val_i32(j_slot,rng_chkpt_jr) ~= val_mini); continue; end
            % check channel type                    
            if bitand(hex2dec('F'),bitxor(tab_mask_u8(j_slot,rng_chkpt_jr(1)),mask_rt)); continue; end
            % The simplest case
            tab_mask_u8(j_slot, rng_chkpt_jr) = bitor(tab_mask_u8(j_slot,rng_chkpt_jr),mask_rt*ones(1,n_mini,'uint8'));
            tab_mask_u8(j_slot, end+1) = 0; %#ok<AGROW>
            tab_val_i32(j_slot, end+1) = 0; %#ok<AGROW>
            tab_dur_i32(j_slot, end+1) = 0; %#ok<AGROW>
            done = true;
        end
        % The complicated attempt
        if ~done
            % try again and look for an open ramp
            log_busy_chans = '';
            for k_slot = 1 : n_slot
                time_max_k = tab_time_max(k_slot);
                n_chkpt_k  = n_chkpt_E_u16(k_slot);
                % fail because there is no way to ramp that many things at
                % once
                if time_max_k > tt
                    % I don't get this part where the masks are summed
                    % rather than durations.
                    idx_last_empty_mask_k = find(tab_mask_u8(k_slot,:) == 0, true, 'last');
                    t_busy_start_k = sum( min ( tab_mask_u8(k_slot, 1 : idx_last_empty_mask_k-1), ...
                                              1 ) );
                    log_busy_chans = [  log_busy_chans ...
                                        sprintf('0x%X starting at %d ending at %d', ...
                                                tab_mask_u8(k_slot,n_chkpt_k-1), ...
                                                t_busy_start_k, ...
                                                time_max_k) newline  ]; %#ok<AGROW>
                    continue;
                end
                % if needed add blank space after the previous ramp
                if time_max_k < tt
                    tab_mask_u8(k_slot, n_chkpt_k) = 0;
                    tab_val_i32(k_slot, n_chkpt_k) = 0;
                    tab_dur_i32(k_slot, n_chkpt_k) = int32(tt) - time_max_k;
                    n_chkpt_k = n_chkpt_k + 1;
                end
                tab_mask_u8(k_slot, rng_u(n_chkpt_k, [0, n_mini-1])) = mask_rt; 
                tab_mask_u8(k_slot, n_chkpt_k + n_mini) = 0; 
                tab_val_i32(k_slot, rng_u(n_chkpt_k, [0, n_mini])) = [val_mini 0];
                tab_dur_i32(k_slot, rng_u(n_chkpt_k, [0, n_mini])) = [dur_mini 0];
                n_chkpt_E_u16(k_slot) = n_chkpt_k + n_mini;
                done = true;
                break; % from the k_slot loop
            end
        end
        if ~done
            % fail because there is no way to ramp that many things at
            % once
            error('DDSRFUpdate:SimultaneousRamps',...
                'DDSRFUpdate: more simultaneous ramps than allowed at address %d. Time is %d. Channels updated are:\n%sRamps in progress are:\n%sAborting.', ...
                seq_num.address, tt, sprintf('0x%X\n',double(mask_t)),log_busy_chans);
        end
    end
end

chkpt_pos_U_u16 = zeros(1, 0, 'uint16');
mask_U_u8       = zeros(1, 0, 'uint8');
polyval_U_i32   = zeros(1, 0, 'int32');
polydur_U_i32   = zeros(1, 0, 'int32');
slotid_U_u8     = zeros(1, 0, 'uint8');

% flatten the tables into sequences
for j_slot = 1 : n_slot
    n_chkpt_j = n_chkpt_E_u16(j_slot);
    rng_chkpt_j = 1 : n_chkpt_j;
    assert(n_chkpt_j > 0);
    slotid_U_u8    (end + rng_chkpt_j) = j_slot - 1;
    chkpt_pos_U_u16(end + rng_chkpt_j) = 0 : n_chkpt_j-1;
    mask_U_u8      (end + rng_chkpt_j) = [tab_mask_u8(j_slot, rng_chkpt_j)]; 
    polyval_U_i32  (end + rng_chkpt_j) = [tab_val_i32(j_slot, rng_chkpt_j)]; 
    polydur_U_i32  (end + rng_chkpt_j) = [tab_dur_i32(j_slot, rng_chkpt_j)]; 
end

n_row_E = length(n_chkpt_E_u16);
slotid_E_u8 = uint8(1:n_row_E)-1;
cmd_cell = { {'E', slotid_E_u8, n_chkpt_E_u16'}; ...
             {'U', slotid_U_u8, mask_U_u8, chkpt_pos_U_u16, polydur_U_i32, polyval_U_i32}; ...
             {'T'}  };
seq_cmd_u8 = toseqcmd(cmd_cell, mod_info, file_debug, seq_num.address);

end

% Get the data type from the mask, should be unique.
function ty = maskgettype(mask_u8)
    ty = mod(mask_u8, 0x0F);
end

% Get the largest channel number specified by this mask.
function ch = maskgetchan(mask_u8)
    ch = log(floor(double(mask_u8/0x10)))/log(2);
end

% select a range from a reference point of unsigned number
function rng = rng_u(ref_u, rng_rel)
    rng = ref_u + rng_rel(1) : ref_u + rng_rel(2);
    assert(all(double(ref_u) + rng_rel > 0), "negative value in unsigned range.");
end

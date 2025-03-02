function seq_num = MakeNumericQueue(dicts, seq_symb, map_mod)
arguments
    dicts            
    seq_symb
    map_mod
end

seq_num = seq_symb;
extractparams(dicts);


for i_mod = 1:length(seq_symb)
    seq_mod_i = seq_symb(i_mod);
    type_i = seq_mod_i.mod_type;
    scaler_i = map_mod(type_i).Scaler;
    if ~iscell(seq_mod_i.times); continue; end % for static modules, it doesn't care about on frequency
    % from now on, times is actually frames
    times_nat_mod_i = cell2mat(evalparams(seq_mod_i.times));
    times_mod_i = times_nat_mod_i * seq_mod_i.params.frequency;
    mask_valid_mod_i = times_mod_i >= 0;
    times_mod_i = times_mod_i(mask_valid_mod_i);
    times_nat_mod_i = times_nat_mod_i(mask_valid_mod_i);
    chanid_i = uint8(evalparams(seq_mod_i.chanid));
    typeid_i = uint8(evalparams(seq_mod_i.typeid));    
    seq_num(i_mod).chanid_i = chanid_i(mask_valid_mod_i);
    seq_num(i_mod).typeid_i = typeid_i(mask_valid_mod_i);
    scale_range_i = seq_mod_i.params.scale_range(:, mask_valid_mod_i);
    data_natural_mod_i = evalparams(seq_mod_i.data(mask_valid_mod_i));
    data_temp_mod_i = scaler_i( data_natural_mod_i, ...
                                scale_range_i);
    
    % serialize with numeric data
    srl = seq_mod_i.serialized;
    for i_sig = 1 : length(srl)
        seq_i = srl{i_sig}.seq;
        fn_i = fieldnames(seq_i);
        for j_f = 1 : length(fn_i)
            fn_ij = fn_i{j_f};
            col_ij = seq_i.(fn_ij);
            col_num_ij = evalparams(col_ij);
            seq_num(i_mod).serialized{i_sig}.seq.(fn_ij) = col_num_ij;
        end
    end
    % data to be fed to commands, turned numeric
    if isnumeric(data_temp_mod_i); data_temp_mod_i = uint32(data_temp_mod_i); end
    seq_num(i_mod).times = uint32(times_mod_i(mask_valid_mod_i));
    seq_num(i_mod).data = data_temp_mod_i;
    % numeric data in natural units
    seq_num(i_mod).time_natural = times_nat_mod_i;
    seq_num(i_mod).data_natural = cell2mat(data_natural_mod_i);
end

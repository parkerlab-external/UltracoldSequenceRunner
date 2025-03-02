% Generate a structure for serialization.
function forsrl = genforsrl(n_chan, tab_data, name_col, n_col, seq_symb, modtype)
forsrl = cell(1, n_chan);
for i_ch = 1 : n_chan
    ch_i = i_ch - 1;
    srl_i = struct();
    seq_i = struct();
    for c = 1 : n_col
        name_c = name_col(c);
        seq_i.(name_c) = tab_data{i_ch, c};
    end
    srl_i.chanid = ch_i;
    srl_i.name = seq_symb.params.chnames(i_ch);
    srl_i.modtype = modtype;
    srl_i.address = seq_symb.params.address;
    srl_i.seq = seq_i;
    forsrl{i_ch} = srl_i;
end

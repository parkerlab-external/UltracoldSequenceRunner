% From numeric sequence to a sequence containing command lists.
% for example:
% cmd_cell : {  {'E', 1 × 19, 1 × 19, 1 × 19},
%               {'U', 1 × 23, 1 × 23, 1 × 23, 1 × 23},
%               {'T'} }
function seq_cmd_u8 = toseqcmd(cmd_cell, mod_info, file_debug, address)
    fmt_cmdlist = mod_info.CommandList;
    seq_cmd_u8 = [];
    fprintf(file_debug, "▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁%s▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁ \n", repmat('▁', [1 strlength(mod_info.Name)]));
    fprintf(file_debug, "Command List for %s module at address 0x%02X (%03d) \n", mod_info.Name, address, address);
    for i_prefix = 1 : length(fmt_cmdlist)
        cmds_i = cmd_cell{i_prefix};
        fmt_i = fmt_cmdlist(i_prefix).Format;
        mask_word_i = fmt_i.length > 0;
        len_cmd_i = sum(fmt_i.length(mask_word_i));
        n_word = sum(mask_word_i);
        n_payload = sum(~mask_word_i);
        n_cmd_i = ifthel(size(cmds_i, 2) > 2, ...
                         @() size(cmds_i{2}, 2), ...
                         1 );
        tab_cmd_u8_i = zeros(len_cmd_i, n_cmd_i, 'uint8');
        tab_payload_u8_i = cell(n_payload, n_cmd_i);
        pt = 1;
        for j = 1 : n_word
            len_ij = fmt_i.length(j);
            signed_ij = fmt_i.signed(j);
            assert(len_ij > 0, "Variable length payload must be at the end of a command");
            vals_u8_ij = split_u8(cmds_i{j}, len_ij, signed_ij);
            tab_cmd_u8_i(pt : pt+len_ij-1, :) = vals_u8_ij;
            pt = pt + len_ij;
        end
        if n_payload > 0
            tab_payload_u8_i(1, :) = cmds_i{n_word + 1};
        end
        [str_fmt_head_i, str_fmt_body_i] = mkformatter(fmt_i.length, fmt_i.op, fmt_i.name, n_word, n_payload);
        seq_cmd_u8_i = printandflatten(file_debug, ...
                                       str_fmt_head_i, ...
                                       str_fmt_body_i, ...
                                       tab_cmd_u8_i, ...
                                       tab_payload_u8_i);
        seq_cmd_u8 = [seq_cmd_u8; seq_cmd_u8_i];
    end

end

function word_u8 = split_u8(word, len, signed)
    token = -len*signed + len*(~signed);
    switch token
    case  1 ; word_u8 = word;
    case  2 ; word_u8 = U16toU8(word);
    case  4 ; word_u8 = U32toU8(word);
    case -4 ; word_u8 = I32toU8(word);
    otherwise; error("Unsupported formatting");
    end
end

% Formatter for pretty printing.
% This works on a single block of command list where every one has the same prefix
function [str_fmt_head, str_fmt_body] = mkformatter(len_in_bytes, ops, names, n_word, n_payload)
    % Have to consider the weird situation where a single char is not in a
    % cell from the parser
    if ~iscell(ops) | ~iscell(names); assert(isscalar(ops)); ops = {ops}; names = {names}; end
    names_cmd = names(1 : n_word);
    min_span_name = strlength(names_cmd)' + 2;
    min_span_data = nan(1, n_word);
    for j_word = 1 : n_word
        fmt_atom = regexp(ops{j_word}, "(?<num>\d+)[Xi]", "names");
        if isempty(fmt_atom) && isequal(ops{j_word}, 'c'); min_span_data(j_word) = 3;
        else
            bytespan_j = str2double(fmt_atom.num) + 1;
            min_span_data(j_word) = bytespan_j * len_in_bytes(j_word) + 1;
        end
    end
    span = max([min_span_name; min_span_data]) + 2;
    str_fmt_head = [];
    str_fmt_body = [];
    for j_word = 1 : n_word
        name_j = names_cmd{j_word};
        op_j = multiops(ops(j_word), len_in_bytes(j_word));
        span_j = span(j_word);
        len_data_j = min_span_data(j_word);
        str_fmt_head = [str_fmt_head insertmid(span_j, strlength(name_j), ' ', '┄', name_j) ];
        str_fmt_body = [str_fmt_body insertmid(span_j, len_data_j       , '' , '░', op_j  ) ];
    end
    if n_payload > 0
        name_payload = names{n_word + 1};
        str_fmt_payload = multiops(ops(n_word + 1), len_in_bytes(n_word + 1));
        str_fmt_head = [str_fmt_head ' ' name_payload ' ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄'];
        str_fmt_body = [str_fmt_body ' ' str_fmt_payload];
    end
    str_fmt_head = [' ' str_fmt_head '\n'];
    str_fmt_body = [' ' str_fmt_body '\n'];
end

function ops_char = multiops(op, repeat)
    repeat = ifthel(repeat < 0, 1, repeat);
    ops_char = [' ' repmat(['%' char(op) ' '], [1 repeat])];
end

function full = insertmid(len_total, len_core, c_inner, c_outer, str)
    len_outer = len_total - len_core - 2*length(c_inner);
    assert(len_outer > 0, "Space is too little for the pretty print");
    inner = [c_inner char(str) c_inner];
    len_left = ceil(len_outer/2);
    len_right = len_outer - len_left;
    full = [repmat(c_outer, [1 len_left]) inner repmat(c_outer, [1 len_right])];
    assert(len_left + len_right + 2*length(c_inner) + len_core == len_total);
end

% Pretty print and concatenate.
function seq_cmd_u8 = printandflatten(file_debug, str_fmt_head, str_fmt_body, tab_cmd_u8, tab_payload_u8)
    n_row = unique([size(tab_cmd_u8, 2), size(tab_payload_u8, 2)]);
    assert(isscalar(n_row));
    fprintf(file_debug, str_fmt_head);
    % The normal case with no payload and fixed format
    if size(tab_payload_u8, 1) == 0
        seq_cmd_u8 = tab_cmd_u8(:);
        fprintf(file_debug, str_fmt_body, tab_cmd_u8);
    else
        seq_cmd_u8 = zeros([0, 1], 'uint8');
        for r = 1 : n_row
            tab_payload_display = replace(char(tab_payload_u8{r}), newline, " ⏎");
            fprintf(file_debug, str_fmt_body, tab_cmd_u8(:, r), tab_payload_display);
            seq_cmd_r_u8 = [tab_cmd_u8(:, r); tab_payload_u8{r}'];
            seq_cmd_u8 = [seq_cmd_u8; seq_cmd_r_u8];
        end
    end
end
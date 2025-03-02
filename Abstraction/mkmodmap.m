% Build a map that directs entry names to corresponding register functions
function map_tag = mkmodmap(filenames_reg)
    arguments
        filenames_reg            string
    end
    % Read info for each supported module
    maps = jsondecode(fileread(filenames_reg));    
    n_key = length(maps);
    key_type = {[1, n_key]}; val_info = cell([1, n_key]);
    for j_type = 1 : n_key
        key_type{j_type} = maps(j_type).Tag;
        val_info{j_type} = maps(j_type);
    end
    % Turn the strings to functions.
    for i_mod = 1 : n_key
        val_info{i_mod}.Parser     = evaltofun(val_info{i_mod}.Parser     );
        val_info{i_mod}.CmdBuilder = evaltofun(val_info{i_mod}.CmdBuilder );
        val_info{i_mod}.Scaler     = evaltofun(val_info{i_mod}.Scaler     );
    end
    map_tag = containers.Map(key_type, val_info);
end

function fun = evaltofun(str)
    fun = ifthel(isempty(str), ...
                 [], ...
                 @() eval("@" + string(str)));
end
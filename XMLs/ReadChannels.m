function [tab_data, tab_chan, n_row_tot, chnames, info] = ReadChannels(node_parent, map_attr, n_col, n_chan, tag)
arguments
    node_parent 
    map_attr 
    n_col 
    n_chan 
    tag         = 'channel'
end
tab_data = cell([n_chan, n_col]);
tab_chan = nan([n_chan, 1]);
n_row_tot = zeros([n_chan 1]);
chnames = strings([n_chan, 1]);
info = cell([n_chan, 1]);
node_channels = node_parent.getChildNodes;
for j_node = 1:node_channels.getLength
    node_chan_j = node_channels.item(j_node-1);
    % Parse the useful attribute nodes, since not all nodes are channels
    if ~isequal(char(node_chan_j.getNodeName), tag); continue; end

    info_j = ReadAttributes(node_chan_j, map_attr);    
    % Th channel id, or channel number, typically range within 0 ~ n_chan-1
    assert(all(isfield(info_j, ["chnum", "name"])), 'Attribute has to contain chnum and name');
    ch_j = info_j.chnum;
    idx_j = ch_j + 1;
    assert(ch_j < n_chan & ch_j >= 0);
    tab_chan(idx_j) = ch_j;
    chnames(idx_j) = info_j.name;
    info{idx_j} = info_j;
    if n_col == 0; continue; end
    tab_data(idx_j, :) = ReadNodeCSV(node_chan_j, n_col);
    n_row_tot(idx_j) = length(tab_data{idx_j,1});
end
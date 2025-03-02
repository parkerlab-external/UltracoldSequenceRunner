function data = ReadNodeCSV(node, n_col)
    node_csv = node.getChildNodes;
    data = cell([1, n_col]);
    % A #text child node can be separated into several chunks, e.g. by comments, we 
    % join the useful ones together
    for l_chunk = 1:node_csv.getLength
        node_csv_l = node_csv.item(l_chunk-1);
        csv_l = char(node_csv_l.getNodeValue);
        % skip comments
        if ~isequal(char(node_csv_l.getNodeName), '#text'); continue; end
        % skip the empty #text chunk
        if strlength(erase(csv_l, [string(newline), " "])) == 0; continue; end
        % format the csv string into data table
        data_l = SuperScanf(csv_l, repmat('%s', [1 n_col]));
        assert(size(data_l, 2) == n_col & ~isempty(data_l{1}));
        for col = 1 : n_col
            data{col} = [data{col}, data_l{col}'];
        end
    end
end
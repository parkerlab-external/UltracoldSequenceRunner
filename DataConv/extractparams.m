function extractparams(dict)

% extract variables defined in the struct params into current workspace

vars = fieldnames(dict);
for i = 1:numel(vars)
    assignin('caller', vars{i}, dict.(vars{i}));
end

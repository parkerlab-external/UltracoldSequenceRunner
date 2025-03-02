function out_data = evalparams(in_cell)
% Converts a string cell into a variable command that is evaluated in the
% workspace.  This allows the user to use variable names as datapoints,
% instead of hard-set numbers.  It can work with non-cell inputs, but it is
% strongly advised to use a cell input.
try
    % If it is a cell
    if iscell(in_cell)
        out_data = cell(1,length(in_cell));        
        for idx = 1:length(in_cell)
            out_data(idx) = {double(evalin('caller', in_cell{idx}))};
        end
    % If it is a matrix, but with strings, do the conversion as well
    elseif isstring(in_cell)
        out_data = nan(1, length(in_cell));
        for idx = 1:length(in_cell)
            out_data(idx) = double(evalin('caller', in_cell{idx}));
        end
    else
        % It's not really a cell or contains no strings, just return it
        out_data = in_cell(:)';
    end
catch ME
    % If we fail to evalin, throw an error that tells the user which
    % variable caused the failure
    badVar = in_cell{idx};
    baseException = MException('EvalParams:BadVariable', sprintf('Could not evaluate the variable: %s.', badVar));
    varException = MException('EvalParams:Variable', badVar);
    baseException = addCause(baseException, varException);
    throw(baseException)
end

end
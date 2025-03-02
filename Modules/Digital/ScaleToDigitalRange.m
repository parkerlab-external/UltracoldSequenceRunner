function out_scaled = ScaleToDigitalRange(in_dig, ~)

if isa(in_dig,'cell')
    in_dig = cell2mat(in_dig);
end

if isa(in_dig,'double')
    out_scaled = logical(in_dig);
elseif isa(in_dig,'uint32')
    out_scaled = double(in_dig);
else
    error('I couldn''t figure out how to scale something other than double or uint32');
end
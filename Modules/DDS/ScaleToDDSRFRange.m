function out_scaled = ScaleToDDSRFRange(in_dds, in_range)

if isa(in_dds,'cell')
    in_dds = cell2mat(in_dds);
end

if isa(in_dds,'double')
    out_scaled = uint32(in_dds.*in_range(2,:)+in_range(1,:));
    %these lines used to round the answer to the nearest integer value but
    %that's probably not needed
    %out_scaled(in_range(1,:) > 0) = bitand(out_scaled(in_range(1,:) > 0),uint32(2^32-2^16));
    %out_scaled = out_scaled + uint32(in_range(1,:));
elseif isa(in_dds,'uint32')
    out_scaled = (double(in_dds)-in_range(1,:))./in_range(2,:);
else
    error('I couldn''t figure out how to scale something other than double or uint32');
end
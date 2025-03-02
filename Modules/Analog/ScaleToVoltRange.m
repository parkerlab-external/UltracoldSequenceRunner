function out_scaled = ScaleToVoltRange(in_volt, in_range)

if isa(in_volt,'cell')
    in_volt = cell2mat(in_volt);
end

offset_factor = nan(size(in_range));
scale_factor = offset_factor;

% case 5: 0 to +5
offset_factor(in_range == 5) = 0;
scale_factor(in_range == 5) = 5;
% case 6: 0 to +10
offset_factor(in_range == 6) = 0;
scale_factor(in_range == 6) = 10;
% case 7: -5 to +5
offset_factor(in_range == 7) = 5;
scale_factor(in_range == 7) = 10;
% case 8: -10 to +10
offset_factor(in_range == 8) = 10;
scale_factor(in_range == 8) = 20;
if any(isnan(offset_factor))
    error('Unimplemented voltage range');
end

if isa(in_volt,'double')
    out_scaled = uint32(round(double(intmax('uint16'))*(in_volt+offset_factor)./scale_factor)*2^16+2^15);
elseif isa(in_volt,'uint32')
    out_scaled = (double(in_volt)-2^15)/(2^16*double(intmax('uint16'))).*scale_factor-offset_factor;
else
    error('I couldn''t figure out how to scale something other than double or uint32');
end
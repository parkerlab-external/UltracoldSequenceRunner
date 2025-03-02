function out_u8 = U16toU8(in_u16)

out_u8 = zeros([2,numel(in_u16)],'uint8');
out_u8(1,:) = uint8(bitand(bitshift(in_u16(:),-8,'uint16'),255));
out_u8(2,:) = uint8(bitand(in_u16(:),255));
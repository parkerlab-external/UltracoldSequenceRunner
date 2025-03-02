function out_u8 = U32toU8(in_u32)

out_u8 = zeros([4,numel(in_u32)],'uint8');
out_u8(1,:) = uint8(bitand(bitshift(in_u32(:),-24,'uint32'),255));
out_u8(2,:) = uint8(bitand(bitshift(in_u32(:),-16,'uint32'),255));
out_u8(3,:) = uint8(bitand(bitshift(in_u32(:),-8,'uint32'),255));
out_u8(4,:) = uint8(bitand(in_u32(:),255));
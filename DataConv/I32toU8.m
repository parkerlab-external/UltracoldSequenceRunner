function out_u8 = I32toU8(in_i32)

out_u8 = zeros([4,numel(in_i32)],'uint8');
out_u8(1,:) = uint8(bitand(bitshift(in_i32(:),-24,'int32'),255));
out_u8(2,:) = uint8(bitand(bitshift(in_i32(:),-16,'int32'),255));
out_u8(3,:) = uint8(bitand(bitshift(in_i32(:),-8,'int32'),255));
out_u8(4,:) = uint8(bitand(in_i32(:),255));
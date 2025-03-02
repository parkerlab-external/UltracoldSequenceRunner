function response = SerialStartDevice(sp, address)
arguments
    sp
    address
end

% close the previous device, write a new address
% if address is zero, don't open again

type_tx = 255;

cmdlist_u8 = uint8([ hex2dec('AA') 'S']);
len_cmdlist_u8 = U32toU8(uint32(length(cmdlist_u8)));
fwrite(sp, uint8([type_tx address len_cmdlist_u8' cmdlist_u8]), 'uint8');

response = fread(sp, 1 ,'uint8');
SerialEndMessage(sp)
address_last_start = address;
assignin("base", address_last_start);
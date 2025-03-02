function response = SerialWriteToDevice(sp, address, cmdlist_u8)
arguments
    sp                  internal.Serialport
    address             
    cmdlist_u8          
end

% Marking that this is the complete message.
type_tx = 1;
cmdlist_u8 = [hex2dec('AA'), cmdlist_u8(:)];
fopen(sp);
pause(0.1);
% Write the transmission type, address, and data to the repeater.
len_cmdlist_u8 = U32toU8(uint32(length(cmdlist_u8)))';
fwrite(sp, [type_tx, address, len_cmdlist_u8, cmdlist_u8], 'uint8');
% Check the UART tranmission status
response = fread(sp, 1, 'uint8');



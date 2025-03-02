function status = SerialEmergencyShutdown(sp, address)
arguments
    sp                  internal.Serialport
    address             
end

% Send only to the leader to shut down.
cmdlist_u8 = [hex2dec('AA'), uint8('A'), uint8('T')];
type_tx = 201;

fopen(sp);
pause(0.1);
% Write the transmission type, address, and data to the repeater.
len_cmdlist_u8 = U32toU8(uint32(length(cmdlist_u8)));
fwrite(sp,[type_tx, address, len_cmdlist_u8', cmdlist_u8'],'uint8');
% Check the UART tranmission status
status = fread(sp, 1, 'uint8'); 
    
    
    
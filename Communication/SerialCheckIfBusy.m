function status = SerialCheckIfBusy(sp)

type_tx = 0;

cmdlist_u8 = [hex2dec('AA'), uint8(0)];

fopen(sp);
pause(0.1);
% Write the transmission type, address (0), and data (also 0) to the repeater.
fwrite(t, uint8([type_tx, 0, cmdlist_u8]), 'uint8');
% Check the UART tranmission status
status = fread(t, 1, 'uint8');
fclose(t);



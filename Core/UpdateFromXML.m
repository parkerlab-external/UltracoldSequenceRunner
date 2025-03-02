function [seq_num, status] = UpdateFromXML(dicts, sp, filename_xml, fid_log)
arguments
    dicts
    sp              internal.Serialport
    filename_xml    string
    fid_log         = 1
end

% Generate the command lists from the sequence files
seq_num = PrepFromXML(dicts, filename_xml, fid_log);

% Write a message for each module and handle the response.
status = cell(length(seq_num), 1);
for i_mod = 1:length(seq_num)    
    cmdlist_u8_i = seq_num(i_mod).cmdlist_u8;
    address_i   = seq_num(i_mod).address;
    response_i = SerialWriteToDevice(sp, address_i, cmdlist_u8_i);
    status_i   = HandleResponse(address_i, response_i);
    status{i_mod} = tern(status_i == -1, -1, response_i);
end

% Clos off the connection
SerialEndMessage(sp);

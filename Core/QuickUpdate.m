% Update the sequence and start.
function seq_num = QuickUpdate(dicts, sp, address, filename_xml)
arguments
    dicts               struct
    sp                  internal.Serialport
    address     
    filename_xml        string
end

[seq_num, status] = UpdateFromXML(dicts, sp, filename_xml);

if all(cell2mat(map_c(@(s) s == 'K', status)))
    SerialStartDevice(sp, address); 
else
    fprintf(2,'Process aborted.\n');
end
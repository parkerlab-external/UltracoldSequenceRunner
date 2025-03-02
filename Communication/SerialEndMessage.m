function SerialEndMessage(sp, addr_unused)
arguments
    sp                  internal.Serialport
    addr_unused         = 5     % 5 is some random, unused address - in the future, this can be
                                % replaced with any 8-bit address that is not in use.
end
    % close the last address to prevent miscommunications due to noise
    len_u8 = U32toU8(uint32(0))';
    fwrite(sp, [uint8([0, addr_unused]) len_u8], 'uint8'); 
    fclose(sp);
    
end
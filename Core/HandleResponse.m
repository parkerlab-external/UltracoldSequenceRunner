function status = HandleResponse(address, response)
arguments
    address
    response          
end
status = response;
switch response
    case 'E'
        fprintf(2, 'Error in checksum for module at address %d.\n', address);
        status = -1;
    case 'K' % K for good transmission, no issues
        fprintf(1, 'UART Transmission successful for module at address %d.\n', address);
    case 'T' % T for timeout
        fprintf(2, 'UART timeout for module at address %d.  module may not be connected.\n', address);
    case 'W' % W for waiting, command is multiple transmits
        fprintf(2, 'Module at address %d expecting more packets than delivered.\n', address);
        status = -1;
    case 'B' % B for busy, start pin is high
        fprintf(1, '\n\nThe previous sequence has not finished.\n\n');
        status = -1;
    case 'G' % G for emergency shutdown successful
        fprintf('Emergency shutdown successful');
end
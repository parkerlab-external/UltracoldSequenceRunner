function [out_times, out_volts] = GeneralPurposeRampDisp(in_durs, in_vals)

neg_points = in_durs < 0;

out_times = 0:(sum(neg_points)-1+sum(in_durs(~neg_points)));
out_volts = out_times;

ramp_pos = 1;
old_ramp_pos = 1;
counter = 0;
for a = 1:length(out_times)
    if(in_durs(ramp_pos) == -2)
        out_volts(a) = in_vals(ramp_pos);
        ramp_pos = ramp_pos + 1;
    elseif(in_durs(ramp_pos == -1))
        out_volts(a) = 0;
        ramp_pos = ramp_pos + 1;
    else
        out_volts(a) = out_volts(a-1)+in_vals(ramp_pos);
        counter = counter-1;
        if(counter <= 0)
            ramp_pos = ramp_pos + 1;
        end
    end
    if ramp_pos > old_ramp_pos && ramp_pos <= length(in_durs)
        counter = in_durs(ramp_pos);
    end
    old_ramp_pos = ramp_pos;
end
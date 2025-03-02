function scaling = GetDDSScaling(typeid, in_amp, in_freq, in_dither_freq)
freq_max = 2^32;
rdw_scaling = 7;
num_steps = (in_freq/4)*(80/in_dither_freq-2)/80;

mask_amp    = typeid == 1;
mask_freq   = typeid == 2;
mask_fb     = typeid == 3;
mask_dither = typeid == 4;

scaling = zeros(2,numel(typeid));
scaling(2,:) = NaN;
scaling(1, mask_amp   ) = 2^15;
scaling(2, mask_amp   ) = in_amp*2^16;
scaling(2, mask_freq  ) = freq_max/in_freq;
scaling(2, mask_fb    ) = 1;
scaling(1, mask_dither) = 2^(rdw_scaling-1); 
scaling(2, mask_dither) = freq_max/in_freq*2^(rdw_scaling)/num_steps;
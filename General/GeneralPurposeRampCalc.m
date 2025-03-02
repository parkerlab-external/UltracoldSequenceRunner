function [durs, vals] = GeneralPurposeRampCalc(timings, values, error_limit, varargin)
if isempty(timings) || isempty(values) || numel(timings) ~= numel(values)
   error('Number of time points and voltage points is not equal or is zero!');
end

if nargin == 4
    target = varargin{1};
else
    target = -2;
end

[timings, unique_order] = unique(timings);
values = values(unique_order);

% Don't do this anymore because we assume it is cleaned already
%[timings, values] = cleanRamp(timings, values);

% initialize arrays to zero length
durs = int32(zeros([1 0]));
vals = int32(zeros([1 0]));

% loop over the sections
for a = 1:length(timings)
    % keyboard();
    % jump to the start position
    durs(end+1) = target; %#ok<AGROW>
    vals(end+1) = U32toI32(values(a)); %#ok<AGROW>
    
    if a >= length(timings)
        break;
    end
    
    error_amount = 0;
    start_point = values(a);
    error_point = timings(a);
    
    v_diff = double(values(a+1))-double(start_point);
    t_diff = double(timings(a+1)-error_point);
    
    r_rate_ideal = v_diff/t_diff;
    r_times_adj = 1:(t_diff-1);
    r_pts_ideal = double(start_point) + r_times_adj*r_rate_ideal;
    
    % only continue if the next point isn't 1 step ahead
    while timings(a+1) - error_point >= 2
        t_diff = double(timings(a+1)-error_point);
        
        r_times_adj = 1:(t_diff-1);
        % either make a best guess (0) or round one way or the other
        if error_amount == 0
            r_rate_real = round(r_rate_ideal);
        elseif error_amount > 0
            r_rate_real = floor(r_rate_ideal);
        else
            r_rate_real = ceil(r_rate_ideal);
        end
        
        r_rate_real = int32(r_rate_real);
        vals(end+1) = r_rate_real; %#ok<AGROW>
        r_pts_real = uint32(int64(r_times_adj)*int64(r_rate_real)+int64(start_point));
        
        % compare real and ideal points against error limit
        error_point_new = uint32(find( abs(double(r_pts_real) - r_pts_ideal ) ...
                                            >= error_limit, ...
                                       1) ...
                                 );
        if ~isempty(error_point_new)
            % in this case there is an error midway through the ramp
            % restart the ramp from the error point
            error_point_new = error_point_new - 1;
            error_amount = double(r_pts_real(error_point_new))-r_pts_ideal(error_point_new);
            r_pts_ideal = r_pts_ideal((error_point_new+1):end);
            start_point = r_pts_real(error_point_new);
            durs(end+1) = error_point_new; %#ok<AGROW>
            error_point = error_point + error_point_new;
        else
            % this case corresponds to no errors for the course of the ramp
            durs(end+1) = t_diff-1; %#ok<AGROW>
            break;
        end
    end
if(length(durs) ~= length(vals)); error("The length of duration and poly values should be the same.");end
end

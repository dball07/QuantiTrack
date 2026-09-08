function [ valid ] = is_valid_state( x,options )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

% preps
I_min = options.min_intensity;
n_y = options.size(1);
n_x = options.size(2);
n_z = options.size(3);
border = 4.5;

% output
valid = true;

% check intensity
if x(5) < I_min
    valid = false;
end
% check if inside the box
if x(1) < border || x(1) > n_y-border
    valid = false;
end
if x(2) < border || x(2) > n_x-border
    valid = false;
end
if x(3) < -1 || x(3) > n_z+1
    valid = false;
end


end


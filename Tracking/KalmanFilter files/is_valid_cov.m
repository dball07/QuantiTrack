function [ valid ] = is_valid_cov( H )
% Checks if the Hessian matrix evaluated at a point describes a valid
% minimum

% output variable 
valid = true;

% check for nan values
if any(isnan(H(:)))
    valid = false;
end
% check for infinities
if valid && any(isinf(H(:)))
    valid = false;
end
% check for positivity
if valid
    lambda = min(eig(H));
    if lambda <= 0
        valid = false;
    end
end



end


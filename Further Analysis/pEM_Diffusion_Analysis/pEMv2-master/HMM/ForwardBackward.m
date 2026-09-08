function [alpha,beta,scale] = ForwardBackward(p,a,b)
%---------------------------------------------------------
% This function calculates the forward and backward variables.
%
% Code written by:
%	Peter Koo
%	Yale University, Department of Physics, New Haven, CT, 06511
%---------------------------------------------------------

[K,T] = size(b);

% initialization
alpha = zeros(K,T);
beta = zeros(K,T);
scale = zeros(1,T);
 
% scaled forward recursion
alpha(:,1) = p.*b(:,1); 
scale(1) = 1;
for t = 2:T
    for j = 1:K
        alpha(j,t) = sum(alpha(:,t-1).*a(:,j))*b(j,t);
    end
    scale(t) = sum(alpha(:,t));
    alpha(:,t) = alpha(:,t)/scale(t);
end

% scaled backward recursion
beta(:,T) = 1; 
for t = T-1:-1:1
    for i = 1:K
        beta(i,t) = sum(a(i,:)'.*beta(:,t+1).*b(:,t+1))/scale(t+1);
        beta(i,t) = sum(a(i,:)'.*beta(:,t+1).*b(:,t+1))/scale(t+1);
        
    end
end

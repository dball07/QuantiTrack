function b = EmissionProbabilities(deltaX,sigma,lambda)
%---------------------------------------------------------------
% This function calculates the emission probabilities of observing
% the data given the parameters of a multivariate Guassian given 
% from the maximization step.
%
% Code written by:
%	Peter Koo
% 	Yale University, Department of Physics, New Havent, CT, 06511
%---------------------------------------------------------------

T = length(deltaX);
[D,dim] = size(deltaX{1});
K = size(sigma,3);

% just use likelihood for multivariate normal diffusion
b = zeros(K,T);
for j = 1:K
	% shrink covariance matrix towards diagonal if issues with inverse
    C = ShrinkCov(sigma(:,:,j), lambda);
    [logdetC,invC]= LogDeterminant(C);    
    for i = 1:dim
        for t = 1:T
            delta = deltaX{t}(:,i);
            L = -D/2*log(2*pi) -.5*logdetC - .5*delta'*invC*delta;
            b(j,t) = b(j,t) + L/dim; 
        end
    end
end

% rescale probabilities to avoid numerical overflow
MAX = max(b);
b = b - repmat(MAX,K,1);
b = exp(b)+MAX;
b(isnan(b)) = 0;
b = b./(ones(K,1)*sum(b));





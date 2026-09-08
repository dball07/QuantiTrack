function [gamma,xi,logL] = StateProbabilities(a,b,alpha,beta,scale)
%------------------------------------------------------------------------
% This function calculates the sufficient statistics of HMMs with the 
% HMM parameters from the expectation and maximization steps. These 
% statistics facilitate the calculation in the maximization step.
%
% Code written by:
% 	Peter Koo
%	Yale University, Department of Physics, New Haven, CT, 06511
%------------------------------------------------------------------------

[K,T] = size(b);

logalpha = log(alpha);
logbeta = log(beta);
loga = log(a);
logb = log(b);
logscale = log(scale);

% state occupation probability to be in state j at time t 
% gamma = alpha.*beta;
gamma = exp(logalpha + logbeta);

% state transition probability to be in state i at time t and in state j at time t+1 
xi = zeros(K,K,T-1);
for t = 1:T-1
    for i = 1:K
        for j = 1:K
%             xi(i,j,t) = alpha(i,t)*a(i,j)*b(j,t+1)*beta(j,t+1)/scale(t+1);
            xi(i,j,t) = logalpha(i,t) + loga(i,j) + logb(j,t+1) + logbeta(j,t+1) - logscale(t+1);
        end
    end
end
xi = exp(xi);

% log likelihood
logL = sum(logscale);






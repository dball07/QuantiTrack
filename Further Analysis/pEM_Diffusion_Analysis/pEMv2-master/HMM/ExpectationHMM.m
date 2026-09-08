function [est,L,gammank] = ExpectationHMM(p,a,b,splitIndex)
%-------------------------------------------------------------
% This function runs the expectation step for the HMMs.  
% Specifically, the forward and backward variables are calculated
% as well as the sufficient statistics for the state probabilities.
% 
%	Code written by:
% 		Peter Koo
%		Yale University, Department of Physics, New Haven, CT, 06511
%-------------------------------------------------------------
numTracks = splitIndex(end);

gammank = [];
est = struct;
L = 0;
for j = 1:numTracks
    index = find(splitIndex == j);        
    [alpha,beta,scale] = ForwardBackward(p(:,j),a,b(:,index));
    [gamma,xi,logL] = StateProbabilities(a,b(:,index),alpha,beta,scale);
    gammank = [gammank gamma];
    est(j).alpha = alpha;
    est(j).beta = beta;
    est(j).scale = scale;
    est(j).gamma = gamma;
    est(j).xi = xi;
    est(j).logL = logL;
    L = L + logL;
end

gammank = gammank';

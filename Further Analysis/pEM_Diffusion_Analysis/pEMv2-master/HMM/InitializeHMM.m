function hmmmodel = InitializeHMM(deltaX, pik, basevacf, prob)
%------------------------------------------------------------------
% This function initializes an HMM model which includes, the initial
% state vector, the initial transition matrix, and the parameters
% for the emission matrix which is parameterized by mu and sigma
%
% Code written by:
% 	Peter Koo
%	Yale University, Department of Physics, New Haven, CT, 06511
%------------------------------------------------------------------

[K,T] = size(basevacf);
D = length(deltaX{1});

% initial state
p = repmat(pik',1,length(deltaX));

% transition matrix
a = InitializeTransitionMatrix(K,prob);
    
% initial sigma
sigma = zeros(D,D,K);
for i = 1:K
    sigma(:,:,i) = toeplitz([basevacf(i,:) zeros(1,D-T)]);
end

% Emission probabilities
b = EmissionProbabilities(deltaX, sigma, 0);

% store HMM parameters in a structure
hmmmodel.p = p;
hmmmodel.a = a;
hmmmodel.b = b;
hmmmodel.sigma = sigma;


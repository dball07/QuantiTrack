function [p,a,b,sigma] = MaximizationHMM(splitX,gammank,est,K,trackInfo)
%-----------------------------------------------------------------------
% This function runs the maximization step of the EM algo for HMMs of 
% multivariate Guassians.  
%
% Code written by:
% 	Peter Koo
% 	Yale University, Department of Physics, New Haven, CT, 06511
%-----------------------------------------------------------------------

numTracks = length(est);
vacf_est = trackInfo.vacf_exp;
D = trackInfo.splitLength-1;
dim = trackInfo.dimensions;
T = trackInfo.numFeatures;
lambda = trackInfo.lambda;

% estimate transition matrix and initial state 
p = zeros(K,numTracks); 
Nk2 = 0; a = 0;
for n = 1:numTracks 

    gamma = est(n).gamma;
    xi = est(n).xi;
        
    % initial state
    p(:,n) = gamma(:,1); 

    % maximize for transition matrix
    a0 = sum(xi,3);
    a = a + a0;   
    Nk2 = Nk2 + sum(a0,2);
    
end

% normalize transition matrix
a = a./repmat(Nk2,1,K);
a = a./repmat(sum(a),K,1);

Nk = sum(gammank);

% diffusion coefficient maximization
vacf2 = zeros(K,T); 
for k = 1:K
    for j = 1:dim
        vacf2(k,:) = vacf2(k,:) + sum((gammank(:,k)*ones(1,T)).*(vacf_est(:,:,j)))./Nk(k);
    end
    vacf2(k,:) = vacf2(k,:)/dim;
end

sigma = zeros(D,D,K);
for k = 1:K
    sigma(:,:,k) = toeplitz([vacf2(k,:) zeros(1,D-T)]);
end

% mu = zeros(1,K);
b = EmissionProbabilities(splitX,sigma,lambda);





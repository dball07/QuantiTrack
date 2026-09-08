function a = InitializeTransitionMatrix(K,A)
%--------------------------------------------------------------------------
% This function initializes a transition matrix with the smae diagonal 
% elements and equal transition probabilities. 
%
% Code written by: 
%       Peter Koo
%       Yale University, Department of Physis, New Haven, CT, 06511  
%--------------------------------------------------------------------------

% initialize transmission matrix
a = diag(ones(1,K)*A) + (ones(K,K)-eye(K))*(1-A)/(K-1);
a = a./(sum(a,2)*ones(1,K));

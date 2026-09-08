function a = InitializeTransitionMatrix(K,A)
%--------------------------------------------------------
% This function generates a transition matrix where the
% diagional elements are all the same and the off-diagonal
% elements are constant with a value such that the sum of
% each row is equal to 1, i.e. normalized.
%
% Code written by:
%	Peter Koo
% 	Yale University, Department of Physics, New Haven, CT, 06511
%--------------------------------------------------------

% initialize transmission matrix
a = diag(ones(1,K)*A) + (ones(K,K)-eye(K))*(1-A)/(K-1);
a = a./(sum(a,2)*ones(1,K));

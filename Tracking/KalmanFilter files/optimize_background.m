function [ x,H ] = optimize_background( x_pre,P_pre,z,R_basis,R )
% This function optimizes the background intensity using explicit
% calculation rather than an iterative solver

% compute the sum off all elements of the inverse of R
temp = R_basis'*ones(size(R));
R4 = sum((temp./R).*temp);

% compute the solution of the linear equation system that is equivalent to
% the solution of the optimization problem
A = inv(P_pre);
A(4,4) = A(4,4)+R4;
b = P_pre\x_pre;
b(4) = b(4)+sum(R_basis*((R_basis'*z)./R));
x = A\b;

% compute the new covariance matrix as the local Hessian
H = inv(P_pre);
H(4,4) = H(4,4)+R4;

end


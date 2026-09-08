function [ mean,covariance ] = mixture_reduction2D( weights,means,covariances )
% Computes the mean and covariance of a multivariate Gaussian mixture.
%   weights: vector or array containing the weights of the mixture components
%   means: cell array containing the means of the mixture components
%   covariances: cell array containing the covariance matrices of the mixture components

% dimension of components
dim = length(means{1});

% number of components
num_comp = numel(weights);

% normalise the weights;
weights = weights/sum(weights(:));

% calculate the mean
mean = zeros(dim,1);
for i = 1:num_comp
    mean = mean+weights(i)*means{i};
end

% calculate the second moment
mean_square = zeros(dim,dim);
for i = 1:num_comp
    mean_square = mean_square+weights(i)*(covariances{i}+means{i}*means{i}');
end

% calculate covariance matrix
covariance = mean_square-mean*mean';

end


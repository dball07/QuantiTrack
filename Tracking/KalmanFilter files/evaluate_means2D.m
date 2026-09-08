function [ state,error ] = evaluate_means2D( data )
% Evaluates the existence probability from the data arrays obtained from
% forward filter only and from the smoother.
%   data: output structure of the filtering/smoothing algorithm containing
%   fields weights,means and covariances

% preparations
n_eff = size(data.means,2);

% compute filtering data state other intersting stuff 
state = zeros(4,n_eff);
error = zeros(4,n_eff);

% reset intensity values for off stats
for i = 1:n_eff
    data.means{i}{1,1}(4) = data.means{i}{1,2}(4);
    data.means{i}{2,1}(4) = data.means{i}{2,2}(4);
end

% iterate over data
for i = 1:n_eff
    [mean,covariance] = mixture_reduction2D(data.weights{i},data.means{i},data.covariances{i});
    state(:,i) = mean;
    error(:,i) = sqrt(diag(covariance));
end



end


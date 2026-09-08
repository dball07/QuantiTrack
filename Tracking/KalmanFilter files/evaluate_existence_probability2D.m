function [ existence_probability,log_likelihood ] = evaluate_existence_probability2D( data )
% Evaluates the existence probability from the data arrays obtained from
% forward filter only and from the smoother.
%   data: output structure of the filter/smoother


% preparations
n_eff = size(data.means,2);
existence_probability = zeros(2,n_eff);
log_likelihood = zeros(2,n_eff);

for i = 1:n_eff
% filtering
    % load data of time step i
    forward_weights = data.weights{i};
    forward_max_log_weight = data.max_log_weight(i);
    % calculate marginal and log likelihood
    marginal = sum(forward_weights)/sum(forward_weights(:));
    existence_probability(1,i) = marginal(2);
    log_likelihood(1,i) = forward_max_log_weight+log(sum(forward_weights(:)));
end


end


 function [output] = forward_filter( img_4d,options )
%switching terated extended kalman filtering for state reconstruction from 3d+time
%image sequence. uses additional information obtained from a deterministic
%detection method to improve the prior distribution
%   img_4d: time sequence of image stacks
%   x_0: starting state
%   P_0: starting covariance
%   Q: noise matrix of the hidden dynamics
%   param: paramaters (dimensions of the gaussian observation volume
% Version 3 
% - treats background and peak intensity as state variables 
% - uses only on gate that is large than in the previously
% - several candidates obtained from thresholding a filtered image as
%   starting points for the optimization procedure

%% preparations
n_t = size(img_4d,4);

% output data
output = struct;
output.means = cell(1,n_t);
output.covariances = cell(1,n_t);
output.weights = cell(1,n_t);
output.max_log_weight = zeros(1,n_t);

%% initialization
means = {options.initial_mean,options.initial_mean;options.initial_mean,options.initial_mean};
covariances = {options.initial_covariance,options.initial_covariance;options.initial_covariance,options.initial_covariance};
weights = 0.5*[options.initial_switch';options.initial_switch'];

% output message
msg = '';

%% iteration
fprintf('Performing forward update on frame ')
for i = 1:n_t
    % clear message
    delete_message = repmat('\b',[1,length(msg)]);
    fprintf(delete_message)
    % print state frame
    msg = sprintf('%d of %d',i,n_t);
    fprintf(msg);
    % get data 
    img_3d = squeeze(img_4d(:,:,:,i));
    % calculate the current center position and prepend it to the candidate list
    candidates = find_candidates(img_3d,means,weights,options);
    % set gate around last value and get roi
    [z,roi] = get_data_advanced(img_3d,candidates,options.boxsize);
    % perform indivdual updates for all possible transitions
    [means,covariances,weights,max_log_weight] = forward_update(means,covariances,...
        weights,candidates,roi,z,options);
    % save mean and covariances
    output.means{i} = means;
    output.covariances{i} = covariances;
    % save weights and max_log_weight
    output.weights{i} = weights;
    output.max_log_weight(i) = max_log_weight;
end


end


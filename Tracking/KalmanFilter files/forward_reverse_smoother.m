function [forward_data,backward_data,smoothed_data ] = forward_reverse_smoother( img_4d,options )
% smoother for the spot tracking algorithm based on the switching state
% space model 
%   img_4d: time sequence of image stacks
%   x_0: starting state
%   P_0: starting covariance
%   Q: noise matrix of the hidden dynamics
%   param: paramaters (dimensions of the gaussian observation volume
% This version is based on the combination of a forward and a reverse
% filter



%% perform forward, backward and smoothing passes

disp('Starting forward filtering')
[forward_data] = forward_filter( img_4d,options);
disp('Forward pass complete')
% backward pass
disp('Starting backward filtering')
%[backward_data] = backward_filter(img_4d,x_0,P_0,options,noise_map,candidate_list);
[backward_data] = [];
disp('Backward pass complete')
% smoothing pass
disp('Starting smoothing')
%[smoothed_data] = correction_smoother(img_4d,forward_data,backward_data,options,noise_map,candidate_list);
[smoothed_data] = [];
disp('Smoothing complete')




end

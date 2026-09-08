function [ candidates ] = find_candidates2D( img_3d,means,weights,options )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

%% preparations

% calculate the center
center = (weights(1,1)*means{1,1}+weights(2,1)*means{2,1}...
        +weights(1,2)*means{1,2}+weights(2,2)*means{2,2})/sum(weights(:));
    
% calculate the existence probability 
marginal = sum(weights)/sum(weights(:));

%% search for candidates

% last center is always candidate
candidates = {center(1:2)};

% adapt options for smaller search area
boxsize = options.boxsize;
options.boxsize = [17,17];
% get a local image arround the current center
[img_3d_local,reference] = get_img_local2D(img_3d,center,options);
% find candidate in reduced region
candidate = find_local_candidates2D(img_3d_local,options);
% output (if candidate found)
if ~isempty(candidate)
    % transform to gloabal coordinate system
    candidate = candidate+reference;
    % store candidate
    candidates = [candidates,{candidate}];
end
% restore boxsize
options.boxsize = boxsize;

% % if the current state is off, look for an additional global candidate
% if marginal(1) > 0.5
%     candidate = find_local_candidates(img_3d,options);
%     if ~isempty(candidate)
%         candidates = [candidates,{candidate}];
%     end
% end

% find global candidates
global_candidates = find_global_candidates2D(img_3d,options);
candidates = [candidates,global_candidates];
    

end

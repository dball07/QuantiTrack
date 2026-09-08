function [ candidates ] = find_global_candidates( img_3d,options )
% This function compares the current position with the pre-filtering
% estimate 
%   Detailed explanation goes here

%% preparations

% get some options
%cluster_size = options.cluster_size;
%cluster_size_tolerance = options.cluster_size_tolerance;
param = options.psf_parameters;
margin = options.border_margin;

% construct the border filter
border_filter = zeros(size(img_3d));
border_filter(margin+1:end-margin,margin+1:end-margin,:) = 1;


%% find candidate

%normalize frame
img_3d_norm = (img_3d-mean(img_3d(:)))/std(img_3d(:));
% perform Gaussian matched filtering
img_3d_filt = imgaussfilt3(img_3d_norm,param);
% background image
img_3d_bg = imboxfilt3(img_3d_norm,[25,21,5]);
% compute the deviation
img_3d_dev = sqrt((img_3d_filt-img_3d_bg).^2);
% binarize image
ind = (img_3d_dev>options.candidate_threshold)&(img_3d_filt>img_3d_bg);

% remove points that are too close to the boundary
ind = ind.*border_filter;
% remove single pixels
ind = bwareaopen(ind,3);
% find connected components
components = bwconncomp(ind);
% set up candidate list
candidates = cell(1,components.NumObjects);
% produce candidates
for i = 1:components.NumObjects
    % get indices of components
    cluster = components.PixelIdxList{i};
    % estimate position from weighted mean
    candidate = center_of_mass(img_3d_filt,cluster);
    candidates{i} = candidate;
end
    

% % set initials for cluster search
% min_threshold = 1;
% max_threshold = max(img_3d_filt(:));
% threshold = 0.5*(min_threshold+max_threshold);
% done = false;
% % perform cluster search
% max_iter = 20;
% cnt = 0;
% while (~done && cnt < max_iter)
%     num_el = sum(img_3d_filt(:)>=threshold);
%     if num_el > cluster_size+cluster_size_tolerance
%         min_threshold = threshold;
%         threshold = 0.5*(threshold+max_threshold);
%     elseif num_el < cluster_size-cluster_size_tolerance
%         max_threshold = threshold;
%         threshold = 0.5*(threshold+min_threshold);
%     else
%         done = true;
%     end
%     cnt = cnt+1;
% end
% % get selected points
% ind = img_3d_filt>threshold;
% % remove points that are too close to the boundary
% ind = ind.*border_filter;
% % remove single pixels
% ind = bwareaopen(ind,3);
% % find connected components
% components = bwconncomp(ind);
% % pick component with the largest mean intensity
% if components.NumObjects > 0
%     comp_intensity = zeros(components.NumObjects,1);
%     for j=1:components.NumObjects
%         cluster = components.PixelIdxList{j};
%         comp_intensity(j) = mean(img_3d_filt(cluster));
%     end
%     max_comp_ind = find(comp_intensity==max(comp_intensity));
%     ind = components.PixelIdxList{max_comp_ind(1)};
%     % get cluster center
%     candidate = center_of_mass(img_3d_filt,ind);
%     % get an intensity estimate
%     candidate = [candidate;max(img_3d(ind))];
% else
%     candidate = [];
% end
% 


end


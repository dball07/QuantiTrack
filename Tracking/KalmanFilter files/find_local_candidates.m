function [ candidate ] = find_local_candidates( img_3d,options )
% This function compares the current position with the pre-filtering
% estimate 
%   Detailed explanation goes here

%% preparations

% get some options
cluster_size = options.cluster_size;
cluster_size_tolerance = options.cluster_size_tolerance;
param = options.psf_parameters;

%% find candidate

%normalize frame
img_3d_filt = (img_3d-mean(img_3d(:)))/std(img_3d(:));
% perform Gaussian matched filtering
img_3d_filt = imgaussfilt3(img_3d_filt,param);
% normalize again
img_3d_filt = (img_3d_filt-mean(img_3d_filt(:)))/std(img_3d_filt(:));
% set initials for cluster search
min_threshold = 1;
max_threshold = max(img_3d_filt(:));
threshold = 0.5*(min_threshold+max_threshold);
done = false;
% perform cluster search
max_iter = 20;
cnt = 0;
while (~done && cnt < max_iter)
    num_el = sum(img_3d_filt(:)>=threshold);
    if num_el > cluster_size+cluster_size_tolerance
        min_threshold = threshold;
        threshold = 0.5*(threshold+max_threshold);
    elseif num_el < cluster_size-cluster_size_tolerance
        max_threshold = threshold;
        threshold = 0.5*(threshold+min_threshold);
    else
        done = true;
    end
    cnt = cnt+1;
end
% get selected points
ind = img_3d_filt>threshold;
% remove single pixels
ind = bwareaopen(ind,3);
% find connected components
components = bwconncomp(ind);
% pick component with the largest mean intensity
if components.NumObjects > 0
    comp_intensity = zeros(components.NumObjects,1);
    for j=1:components.NumObjects
        cluster = components.PixelIdxList{j};
        comp_intensity(j) = mean(img_3d_filt(cluster));
    end
    max_comp_ind = find(comp_intensity==max(comp_intensity));
    ind = components.PixelIdxList{max_comp_ind(1)};
    % get cluster center
    candidate = center_of_mass(img_3d_filt,ind);
else
    candidate = [];
end



end


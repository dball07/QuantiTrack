function [ obs,roi ] = get_data_advanced( img_3d,candidates,boxsize )
%Extracts data from a region of interest from a 3D input image
%   z: intensity values of the pixels of roi in vector form
%   img_3d: 3d image 
%   x: center of the region in continuous coordinates

% constants
z_depth = boxsize(3);
width = boxsize(1);
[n_y,n_x,n_z] = size(img_3d);

% initialise
roi = [];
obs = [];

for i = 1:length(candidates)
    % current candidate
    x = candidates{i};
    % center and box coordinates
    y_c = floor(x(1))+1;
    y_min = y_c-(width-1)/2;
    y_max = y_c+(width-1)/2;
    x_c = floor(x(2))+1;
    x_min = x_c-(width-1)/2;
    x_max = x_c+(width-1)/2;
    z_c = floor(x(3))+1;
    z_min = z_c-(z_depth-1)/2;
    z_max = z_c+(z_depth-1)/2;
    % correct if the box is outside ofthe image
    if y_min < 1
        y_min = 1;
        y_max = width-1;
    elseif y_max > n_y
        y_min = n_y-(width-1);
        y_max = n_y;
    end
    if x_min < 1
        x_min = 1;
        x_max = width-1;
    elseif x_max > n_x
        x_min = n_x-(width-1);
        x_max = n_x;
    end
    if z_min < 1
        z_min = 1;
        z_max = z_depth;
    elseif z_max > n_z
        z_min = n_z-(z_depth-1);
        z_max = n_z;
    end
    % generate 3d meshgrid
    y = x_min:x_max;
    x = y_min:y_max;
    z = z_min:z_max;
    [X,Y,Z] = meshgrid(y,x,z);
    % save in roi
    roi = [roi;[Y(:),X(:),Z(:)]];
    
    % select pixel values
    obs_points = img_3d(y_min:y_max,x_min:x_max,z_min:z_max);
    obs = [obs;obs_points(:)];

end

% only keep unique values
[roi,ind] = unique(roi,'rows','stable');
obs = obs(ind);
% transform to continuous coordinates
roi = roi-0.5;

end


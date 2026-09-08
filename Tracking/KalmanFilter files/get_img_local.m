function [ img_3d_local,reference ] = get_img_local( img_3d,center,options )
% Cuts out a local box from img_3d of dimensions options.box_size around
% center
%   Detailed explanation goes here

% get boxsize
boxsize = options.boxsize';

% adapt if image is very small
boxsize = min([boxsize,size(img_3d)'],[],2);

% find box borders
center = ceil(center(1:3));
lower = center-floor(0.5*boxsize);
upper = center+floor(0.5*boxsize);

% correct if out of image
correct = (1-lower).*(lower<1);
lower = lower+correct;
%upper = upper+correct;
correct = (size(img_3d)'-upper).*(upper>size(img_3d)');
%lower = lower+correct;
upper = upper+correct;

% reduce image 
img_3d_local = img_3d(lower(1):upper(1),lower(2):upper(2),lower(3):upper(3));

% set reference (allows to compute coordinates in large system)
reference = lower-1;


end


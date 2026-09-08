function [ center ] = center_of_mass2D( img_3d,ind )
% Calculates the center of mass of an image region
%   img_3d: input image array (3_d);
%   ind: linear indices of image points to consider

% calculate indices
[y,x] = ind2sub(size(img_3d),ind);

% determine weights from the image
weights = img_3d(ind);
weights = weights/sum(weights);

% evaluate the center of mass
center = sum([y,x].*weights)'-0.5;

end


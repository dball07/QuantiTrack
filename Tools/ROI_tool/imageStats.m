function im_stats = imageStats(imStack3d)

%generates an array of pixel parameters from the maximum projection of the
%input imStack3d. The parameters are in triplets of [I, Gmag, Gdir], where
%I is the intensity, Gmag is the gradient magnitude, and Gdir is the
%Gradient direction. These values are reported for the raw image (columns
%1-3), and the gaussian filtered image with width equal to 5, 11, 21, 101,
%and 201, for a total of 18 parameters. For use with machine learning
%training & prediction.

%D. Ball 09/2021


% maxP = max(imStack3d,[],3);
maxP = sum(imStack3d,3);

% maxP2 = double(maxP);
% maxP2 = wiener2(maxP2,[5 5]); 
% %perform a tophat operation to even out the illumination
% se = strel('disk',12);
% maxP2 = imtophat(maxP2,se);
% maxP = maxP2;
maxP_max = max(maxP(:));
maxP_min = min(maxP(:));

%normalize the image from 0 to 1
maxP_norm = (maxP - maxP_min)./(maxP_max - maxP_min);

%store the intensities
im_stats(:,1) = maxP_norm(:);
%calculate the gradient magnitude & direction
[Gmag, Gdir] = imgradient(maxP_norm);

im_stats(:,2) = Gmag(:);
im_stats(:,3) = Gdir(:);


%convolve the image with a gaussian with width 5
r = -round(5):round(5);
gaussian_kernel = normalize(exp(-(r/2).^2));
filtered5 = conv2(maxP_norm',gaussian_kernel','same');

res5 = max(filtered5,0);
res5 = res5';

[Gmag5, Gdir5] = imgradient(res5);
im_stats(:,4) = res5(:);
im_stats(:,5) = Gmag5(:);
im_stats(:,6) = Gdir5(:);

%convolve the image with a gaussian with width 11
r = -round(11):round(11);
gaussian_kernel = normalize(exp(-(r/2).^2));
filtered11 = conv2(maxP_norm',gaussian_kernel','same');

res11 = max(filtered11,0);
res11 = res11';

[Gmag11, Gdir11] = imgradient(res11);
im_stats(:,7) = res11(:);
im_stats(:,8) = Gmag11(:);
im_stats(:,9) = Gdir11(:);

%convolve the image with a gaussian with width 21
r = -round(21):round(21);
gaussian_kernel = normalize(exp(-(r/2).^2));
filtered21 = conv2(maxP_norm',gaussian_kernel','same');

res21 = max(filtered21,0);
res21 = res21';

[Gmag21, Gdir21] = imgradient(res21);
im_stats(:,10) = res21(:);
im_stats(:,11) = Gmag21(:);
im_stats(:,12) = Gdir21(:);

%convolve the image with a gaussian with width 51
r = -round(51):round(51);
gaussian_kernel = normalize(exp(-(r/2).^2));
filtered51 = conv2(maxP_norm',gaussian_kernel','same');

res51 = max(filtered51,0);
res51 = res51';

[Gmag51, Gdir51] = imgradient(res51);
im_stats(:,13) = res51(:);
im_stats(:,14) = Gmag51(:);
im_stats(:,15) = Gdir51(:);

%convolve the image with a gaussian with width 101
r = -round(101):round(101);
gaussian_kernel = normalize(exp(-(r/2).^2));
filtered101 = conv2(maxP_norm',gaussian_kernel','same');

res101 = max(filtered101,0);
res101 = res101';

[Gmag101, Gdir101] = imgradient(res101);
im_stats(:,16) = res101(:);
im_stats(:,17) = Gmag101(:);
im_stats(:,18) = Gdir101(:);



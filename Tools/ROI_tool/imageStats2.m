function im_stats = imageStats2(imStack3d)

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


%median filter with range of 5
res5 = medfilt2(maxP,[5,5]);

[Gmag5, Gdir5] = imgradient(res5);
im_stats(:,4) = res5(:);
im_stats(:,5) = Gmag5(:);
im_stats(:,6) = Gdir5(:);

%median filter with range of 11
res11 = medfilt2(maxP,[11,11]);

[Gmag11, Gdir11] = imgradient(res11);
im_stats(:,7) = res11(:);
im_stats(:,8) = Gmag11(:);
im_stats(:,9) = Gdir11(:);

%median filter with range of 21
res21 = medfilt2(maxP,[21,21]);

[Gmag21, Gdir21] = imgradient(res21);
im_stats(:,10) = res21(:);
im_stats(:,11) = Gmag21(:);
im_stats(:,12) = Gdir21(:);

%median filter with range of 51
res51 = medfilt2(maxP,[51,51]);

[Gmag51, Gdir51] = imgradient(res51);
im_stats(:,13) = res51(:);
im_stats(:,14) = Gmag51(:);
im_stats(:,15) = Gdir51(:);

%median filter with range of 101
res101 = medfilt2(maxP,[101,101]);

[Gmag101, Gdir101] = imgradient(res101);
im_stats(:,16) = res101(:);
im_stats(:,17) = Gmag101(:);
im_stats(:,18) = Gdir101(:);



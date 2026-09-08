
for j = 1:nImages
    
    tj = imStack(j).data;
    tj_d = double(tj);
    tj_D = (tj_d - min(tj_d(:)))./(max(tj_d(:)) - min(tj_d(:)));
    ROI_j = Results.Process.ROIimage(:,j);
    ROI_ji = zeros(size(tj));
    for i = 1:length(ROI_j)
        ROI_ji(ROI_j{i,:}) = 1;
    end
    B = bwperim(ROI_ji);
    im_r = tj_D;
    im_g = tj_D;
    im_b = tj_D;
    im_r(B > 0) = 1;
    im_rgb = cat(3,im_r,im_g,im_b);
    imwrite(im_rgb,'21_MMStack_488_ROIs_080117.tif','WriteMode','append');
end
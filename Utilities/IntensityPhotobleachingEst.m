function [PBDecayFitPar, Sum_int_avg, BG_int_avg] = IntensityPhotobleachingEst(files,tInterval)

nImages = 0;
nfiles = length(files);
for k = 1:length(files)
    load(files(k).name);
    ROI_im_all{k,:} = zeros(size(Results.Process.ROIimage{1,1}));
    for j = 1:length(Results.Process.ROIimage)
        ROI_im_all{k,:}(Results.Process.ROIimage{j,1} == 1) = 1;
    end
    for i = 1:Results.Data.nImages
        imstack{k,:}(:,:,i) = Results.Data.imageStack(i).data;
    end
    nImages = max(nImages,Results.Data.nImages);
end




npx_ROI = zeros(nImages,1);
npx_BG = zeros(nImages,1);
BG_int_sum = zeros(nImages,1);
Sum_int = zeros(nImages,1);
for i = 1:nImages
    for j = 1:nfiles
        curIm = imstack{j}(:,:,i);
        curROIs = ROI_im_all{j};
        npx_ROI(i) = npx_ROI(i) + sum(curROIs(:));
        BG_im = 1 - curROIs;
        npx_BG(i) = npx_BG(i) + sum(BG_im(:));
        BG_int_sum(i) = BG_int_sum(i) + sum(sum(curIm(BG_im == 1)));
        Sum_int(i) = Sum_int(i) + sum(sum(curIm(curROIs == 1)));
    end
end
Sum_int_avg = Sum_int./npx_ROI;
BG_int_avg = BG_int_sum./npx_BG;
Sum_int_avg_BG_corr = Sum_int_avg - BG_int_avg;
tvec = 0:tInterval:(nImages - 1).*tInterval;

PBDecayFitPar = ExpDecay_2Cmp_fit([tvec',Sum_int_avg_BG_corr],[1,0.1]);
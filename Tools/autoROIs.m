function ROIimage = autoROIs(RefImageStack,nImages)


%Create the sum of the image stack
RefStack_3d = zeros(size(RefImageStack(1).data,1),size(RefImageStack(1).data,2),nImages);
for i = 1:nImages
    RefStack_3d(:,:,i) = double(RefImageStack(i).data);
end
Ref_sum = max(RefStack_3d,[],3);
%Remove background with a tophat 
Ref_sum_bg = imtophat(Ref_sum,strel('disk',3));
%Get a general location for each ROI based on the sum image
th1 = multithresh(Ref_sum_bg,1);
C = imquantize(Ref_sum_bg,th1);
C2 = C;
C2(C2 < 2) = 0;
%Remove objects smaller than 6 pixels
CC = bwconncomp(C2);
Pix = cell(1,1);
ind = 1;
for i = 1:CC.NumObjects
    if length(CC.PixelIdxList{:,i}) > 5
        Pix{:,ind} = CC.PixelIdxList{:,i};
        ind = ind + 1;
    end
end
CC.PixelIdxList = Pix;
CC.NumObjects = length(Pix);
L = labelmatrix(CC);
C2 = L > 0;

C3 = imfill(C2,'holes');
C5 = imclose(C3,strel('disk',3));
C6 = imdilate(C5,strel('disk',2));

CC = bwconncomp(C6);
ROIimage_base = labelmatrix(CC);

% if CC.NumObjects == 0
%     %Get a general location for each ROI based on the sum image
%     th1 = multithresh(Ref_sum,2);
%     C = imquantize(Ref_sum,th1);
%     C2 = C;
%     C2(C2 < 3) = 0;
%     C3 = imfill(C2,'holes');
%     C4 = imerode(C3,strel('disk',3));
%     C5 = imdilate(C4,strel('disk',5));
%     CC = bwconncomp(C5);
%     ROIimage_base = labelmatrix(CC);
% end
for j = 1:CC.NumObjects
    curReg = uint16(zeros(size(Ref_sum)));
    curReg(CC.PixelIdxList{:,j}) = 1;
    for i = 1:nImages
        if i == 66
            bel = 1;
        end
        curRefIm = RefImageStack(i).data;
        curRefIm_bg = imtophat(curRefIm,strel('disk',3));
        curROIInt = curRefIm_bg.*curReg;
        
        th2 = multithresh(curROIInt,2);
        C_cur = imquantize(curROIInt,th2);
        
        ROIimage{j,i} = false(size(C_cur));
        ROIimage{j,i}(C_cur >= 3) = 1;
        CC2 = bwconncomp(ROIimage{j,i});
        Area = zeros(CC2.NumObjects,1);
%         for k = 1:CC2.NumObjects
%             Area(k,:) = length(CC2.PixelIdxList{:,k});
%         end
%         
%         if max(Area) < 10
%             ROIimage{j,i}(C_cur >= 2) = 1;
%         end
        ROIimage{j,i} = imdilate(ROIimage{j,i},strel('disk',1));
%         ROIimage{j,i} = imfill(ROIimage{j,i},'holes');
        ROIimage{j,i} = imclose(ROIimage{j,i},strel('disk',3));
        ROIimage{j,i} = imopen(ROIimage{j,i},strel('disk',1));
        ROIimage{j,i} = imdilate(ROIimage{j,i},strel('disk',3));
        
%         curIm = RefStack_3d(:,:,i);
%         tmp = ROIimage{j,i};
%         tmp2 = curIm(tmp > 0);
%         S(i,:) = std(double(tmp2(:)));
    end
%     S2 = medfilt1m(S,5);
%     
%     thS = multithresh(S,1);
%     
%     thS = 0.9*thS;
%     ROIimage_tmp = ROIimage{j,:};
%     
%     ROIimage(j,S2 < thS) = {zeros(size(ROIimage{1,1}))};
end
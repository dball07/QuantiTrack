function [ROIpos, ROIimage, Cent, ROIpos_all, ROIimage_all,t1,t2,t3] = autoROIs2(RefImageStack,nImages)

R = 3;
windowSz = 7;
currdisk = 5;

%create a mask for generating the ROI
mask = zeros(2*R+1);
centerXY = [R+1,R+1];
for i = 1:2*R+1
    for j = 1:2*R+1
        if sqrt((i-centerXY(1)).^2 + (j-centerXY(2)).^2) <=R
            mask(i,j) = 1;
        end
    end
end
%Create the sum of the image stack
RefStack_3d = zeros(size(RefImageStack(1).data,1),size(RefImageStack(1).data,2),nImages);
RefStack_filt = zeros(size(RefImageStack(1).data,1),size(RefImageStack(1).data,2),nImages);
filtStack_all = zeros(nImages*size(RefImageStack(1).data,1),size(RefImageStack(1).data,2));
timer1 = tic;
for i = 1:nImages
    RefStack_3d(:,:,i) = double(RefImageStack(i).data);
    RefStack_filt(:,:,i) = bpass(RefStack_3d(:,:,i),1,5);
    filtStack_all((i-1)*size(RefImageStack(1).data,1)+1:i*size(RefImageStack(1).data,1),:) = ...
        RefStack_filt(:,:,i);
end
t1 = toc(timer1);
Thresh = multithresh(filtStack_all,1);
Ref_sum = max(RefStack_3d,[],3);
%Remove background with a tophat 
Ref_sum_bg = imtophat(Ref_sum,strel('disk',currdisk));
%Get a general location for each ROI based on the sum image
th1 = multithresh(Ref_sum_bg,2);
C = imquantize(Ref_sum_bg,th1);
C2 = C;
C2(C2 < 3) = 0;
%Remove objects smaller than 6 pixels
CC = bwconncomp(C2);


Pix = cell(1,1);
ind = 1;
timer2 = tic;
for i = 1:CC.NumObjects
    if length(CC.PixelIdxList{:,i}) > 5
        Pix{:,ind} = CC.PixelIdxList{:,i};
        ind = ind + 1;
    end
end
CC.PixelIdxList = Pix;
CC.NumObjects = length(Pix);
while CC.NumObjects > 50 && currdisk < 20
    currdisk = currdisk + 2;
    Ref_sum_bg = imtophat(Ref_sum,strel('disk',currdisk));
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
end
L = labelmatrix(CC);
C2 = L > 0;

C3 = imfill(C2,'holes');
C5 = imclose(C3,strel('disk',3));
C6 = imdilate(C5,strel('disk',2));

CC = bwconncomp(C6);
ROIimage_base = labelmatrix(CC);
t2 = toc(timer2);

timer3 = tic;
for j = 1:CC.NumObjects
    curReg = uint16(zeros(size(Ref_sum)));
    curReg(CC.PixelIdxList{:,j}) = 1;
    ROIimage_all{j,1} = curReg;
    curReg_tmp = imdilate(curReg,strel('disk',1));
    [fr,fc] = find(curReg_tmp == 1,1,'first');
    B = bwtraceboundary(curReg_tmp,[fr,fc],'n');
    ROIpos_all{j,1} = [B(:,2),B(:,1)];
    
    [x,y] = ind2sub(size(curReg),CC.PixelIdxList{:,j});
    xlim = [min(x)-2,max(x)+2];
    ylim = [min(y)-2,max(y)+2];
%     Array_par(:,:,j) = zeros(nImages,6);
    for i = 1:nImages
        curRefIm = RefImageStack(i).data;
        curRefIm_filt = RefStack_filt(:,:,i);
        curRegIm = double(curRefIm_filt).*double(curReg);
        pks = pkfnd(curRegIm,Thresh,R);
        if ~isempty(pks)
            centroids = cntrd(curRegIm,pks,windowSz);
        else
            centroids = [0,0,0,0];
        end
        if isempty(centroids)
           centroids = [0,0,0,0];
        end 
        newROIim = false(size(curRefIm));
        ROIpos{j,i} = [];
        
        for k = 1:size(centroids,1)
            if centroids(k,1) > 0
%                 x_sub = round(centroids(k,1))-10:round(centroids(k,1))+10;
%                 y_sub = round(centroids(k,2))-10:round(centroids(k,2))+10;
                
%         [y_center, x_center] = find(curRegIm == max(curRegIm(:)),1,'first');
%         x_sub = x_center - 10:x_center + 10;
%         y_sub = y_center - 10:y_center + 10;
%                 sub_im = curRefIm(y_sub,x_sub);
%         
%                 coordinates = {x_sub,y_sub};
%                 [parFit,ssr] = gauss_fit2D_cov_orig(double(sub_im),coordinates);
%         parFit(5) = parFit(5) + ylim(1) - 1;
%         parFit(4) = parFit(4) + ylim(1) - 1;
%         Array_par(i,:,j) = [parFit,ssr];
                x1 = -1*R:0.1:R;
                x2 = -1*x1;
                y1 = sqrt(R.^2 - x1.^2);
                y2 = -1*y1;
                x = [x1';x2'];
                y = [y1'; y2'];
                x(end) = [];
                y(end) = [];
%                 x = x + parFit(4);
%                 y = y + parFit(5);
                x = x + centroids(k,1);
                y = y + centroids(k,2);
                newPos = [x,y];
%                 ROIpos{j,i} = [ROIpos{j,i};newPos];
        
                for m = round(min(x)):round(max(x))
                    for n = round(min(y)):round(max(y))
                        if sqrt((m - centroids(k,1)).^2 + (n - centroids(k,2)).^2) <= R
                        
%                         if sqrt((m - parFit(4)).^2 + (n - parFit(5)).^2) <= R
                            newROIim(n,m) = 1;
                        end
                    end
                end
            end
        end
        ROIimage{j,i} = newROIim;
        CC_final = bwconncomp(newROIim);
        stats = regionprops(CC_final,'Centroid');
        if i == 125
            nla = 1;
        end
        
        if centroids(k,1) ~= 0
            Cent{j,i} = centroids;
        else
            Cent{j,i} = [];
        end
        tmp = imdilate(newROIim,strel('disk',1));
        [fr,fc] = find(tmp == 1, 1, 'first');
        if ~isempty(fr)
            B = bwtraceboundary(tmp,[fr,fc],'n');
            ROIpos{j,i} = [B(:,2),B(:,1)];
        end
        
    end
end
t3 = toc(timer3);

        
function [ROIpos, ROIimage,ROIlabel] = QT_importROIs_ImageJ(ROIzipfile,imgSz,firstROInum)

%imports ROIs created and saved in ImageJ which are saved as a zip file


if nargin == 0 || isempty(ROIzipfile)
    [zipName,zipLocation] = uigetfile('*.zip','Select ImageJ ROI file','MultiSelect','off');

    if zipName == 0
        return
    else
        ROIzipfile = fullfile(zipLocation,zipName);
    end
end

if nargin < 2 || isempty(imgSz)
    imgSz = [256 256];
elseif numel(imgSz) == 1
    imgSz = [imgSz imgSz];
end

if nargin < 3 || isempty(firstROInum)
    firstROInum = 1;
end



%Read in the ROIs
ROIs = ReadImageJROI(ROIzipfile);
Regions = ROIs2Regions(ROIs,imgSz);

nROIs = length(Regions.PixelIdxList);

ROIpos = cell(nROIs,1);
ROIimage = cell(nROIs,1);
ROIlabel = cell(nROIs,1);

for i = 1:nROIs
    %create a generic label
    ROIlabel{i,1} = ['ROI',num2str(i+firstROInum-1)];
    
    %Create the masks
    ROIimageTmp = false(imgSz);
    ROIimageTmp(Regions.PixelIdxList{1,i}) = 1;
    ROIimage{i,1} = ROIimageTmp';

    tmp = imdilate(ROIimage{i,1},strel('disk',1));
    [fr,fc] = find(tmp == 1, 1, 'first');
    B = bwtraceboundary(tmp,[fr,fc],'n');
    ROIpos{i,1} = [B(:,2),B(:,1)];
end


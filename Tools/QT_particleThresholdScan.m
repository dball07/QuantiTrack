function [ks_stat, th_optimal] = QT_particleThresholdScan(rawStack,filterStack,ROIimage,imgParam,detParam,plotFlag)
% Inputs:
% RAWSTACK: raw tiff stack stored as a structure (generated with
% QuantiTrack)
% FILTERSTACK: bandpass-filtered stack obtained from QuantiTrack
% ROIimage: binary mask of the Regions of interest to track in
% IMGPARAM: structure containing imaging parameters with fields:
%   pxSize: pixel size in um (default: 0.144)
%   objNA: Numerical Aperture of the Objective lens (default: 1.49)
%   lambda: Emission wavelength of the tracked fluor in um(default: 0.675)
% DETPARAM: structure containing detection parameters with fields:
%   hiBP: Upper limit of the bandpass filter (default: 5)
%   windowSz: minimum separation in px below which spots are combined
%   (default: 3)
%   loThresh: lower bound of detection thresholds to try (default: 100)
%   hiThresh: upper bound of detection thresholds to try (default: 500)
%   ThStepSize: step size for the detection thresholds to try (default: 50)
%   useParallel: binary flag to use parallel processing (default: 0);
% PLOTFLAG: binary flag to plot the KS stat vs. Threshold
%
%D. Ball 10/2026

if nargin < 3 || isempty(rawStack) || isempty(filterStack) || isempty(ROIimage)
    errordlg('Must supply a raw imageStack, the filtered Stack, and a binary mask')
    return;
end
if nargin < 4 || isempty(imgParam)
    imgParam.pxSize = 0.144;
    imgParam.objNA = 1.49;
    imgParam.lambda = 0.675;
else
    if ~isfield(imgParam,'pxSize')
        imgParam.pxSize = 0.144;
    end
    if ~isfield(imgParam,'objNA')
        imgParam.objNA = 1.49;
    end
    if ~isfield(imgParam,'lambda')
        imgParam.lambda = 0.675;
    end
end
    


if nargin < 5 || isempty(detParam)
    detParam.hiBP = 5;
    detParam.windowSz = 3;
    detParam.loThresh = 100;
    detParam.hiThresh = 500;
    detParam.ThStepSize = 50;
    detParam.useParallel = 0;
else
    if ~isfield(detParam,'hiBP')
        detParam.hiBP = 5;
    end
    if ~isfield(detParam,'windowSz')
        detParam.windowSz = 3;
    end
    if ~isfield(detParam,'loThresh')
        detParam.loThresh = 100;
    end
    if ~isfield(detParam,'hiThresh')
        detParam.hiThresh = 1000;
    end
    if ~isfield(detParam,'ThStepSize')
        detParam.ThStepSize = 50;
    end
    if ~isfield(detParam,'useParallel')
        detParam.useParallel = 0;
    end
    
end

if nargin < 6 || isempty(plotFlag)
    plotFlag = 0;
end

ThreshVec = (detParam.loThresh:detParam.ThStepSize:detParam.hiThresh)';
ks_stat(:,1) = ThreshVec;

for ii = 1:length(ThreshVec)
    Centroid = findParticles(filterStack, ThreshVec(ii), detParam.hiBP,detParam.windowSz,detParam.useParallel);
    CentroidInRoi = InsideROIcheck2(Centroid, ROIimage);

    Centroid = CentroidInRoi;

    if isempty(Centroid)

        continue;
    end
    Particles = peak_fit_psf(rawStack,...
        Centroid,detParam.windowSz,detParam.windowSz,detParam.useParallel);
    Particles2 = InsideROIcheck2(Particles,ROIimage);
    Tracks = Particles2(:,[10 11 6 13]);

    Tracks(Tracks(:,1) == 0,:) = [];
    Tracks(Tracks(:,2) == 0,:) = [];


    params.lambda = imgParam.lambda;
    params.NA = imgParam.objNA;

    Tracks = AddAiryIntensity(Tracks, ...
        imgParam.pxSize, rawStack,params);
    % KS 2-sample statistic between signal and local background
    [~, ~, ks_stat(ii,2)] = kstest2(Tracks(:,5), Tracks(:,6));
end

if plotFlag == 1
    figure; plot(ks_stat(:,1),ks_stat(:,2),'k','LineWidth',1.5);
    xlabel('Detection Threshold')
    ylabel('KS (signal,bg)');
end

th_optimal = 0;
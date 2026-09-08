function loc_prec = calcHILO_precision_batch(trkFiles,pxSize)

if nargin < 1 || isempty(trkFiles)
    [trkFiles, trkPath] = uigetfile('*.mat','Select HILO tracking files',pwd,'MultiSelect','on');
     
end

if nargin < 2 || isempty(pxSize)
    pxSize = 0.144;
end

part_uncert_all = [];

for i = 1:length(trkFiles)
    load(fullfile(trkPath,trkFiles{i}));
    part_uncert_ci = calcHILO_precision(Results);
    part_uncert_all = [part_uncert_all; part_uncert_ci];
end

md_ci = median(pxSize.*part_uncert_all);

loc_prec = mc_ci./1.96;

    
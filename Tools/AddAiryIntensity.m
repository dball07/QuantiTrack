function [OutTracks_trad, OutTracks_intNbg] = AddAiryIntensity(InTracks,pixelSize, Stack,params)
%             Wl = 0.700; % Wavelength in microns
%             NA = 1.45;  % Numerical aperture of the objective

if nargin < 4
    params.lambda = 0.700;
    params.NA = 1.49;
end

if isempty(params) || ~isfield(params,'lambda')
    params.lambda = 0.700;
end

if isempty(params) || ~isfield(params,'NA')
    params.NA = 1.49;
end

radiusAiry = 0.61*params.lambda/params.NA/pixelSize;
%             radiusAiry = 3;
NPeaks = length(InTracks(:,1));
[height,width] = size(Stack(1).data);

[meshX, meshY] = meshgrid(1:width, 1:height);


if NPeaks == 0
    OutTracks_trad = [];
    OutTracks_intNbg = [];
else

    for i = 1:NPeaks
        Peak = InTracks(i,:);
        Frame = Peak(3);

        CheckMatrix = (Peak(1) - meshX).^2 + (Peak(2)-meshY).^2;
        idx = find (CheckMatrix<= radiusAiry^2);
        Npixel = length(idx);

        Intensity = sum(Stack(Frame).data(idx))/Npixel;

        idx = find (CheckMatrix > radiusAiry^2 & CheckMatrix <= (radiusAiry + 1)^2);
        idx2 = find (CheckMatrix > (radiusAiry + 2)^2 & CheckMatrix <= (radiusAiry + 3)^2);
        Npixel1 = length(idx);
        Npixel2 = length(idx2);
        bkg1 = sum(Stack(Frame).data(idx))/Npixel1;
        bkg_sigma1 = std(double(Stack(Frame).data(idx)));
        bkg2 = sum(Stack(Frame).data(idx2))/Npixel2;
        bkg_sigma2 = std(double(Stack(Frame).data(idx2)));

        OutTracks_trad(i,:) = [Peak, Intensity, bkg1];
        OutTracks_intNbg(i,:) = [Peak, Intensity, bkg1, bkg_sigma1,bkg2,bkg_sigma2];
    end

end
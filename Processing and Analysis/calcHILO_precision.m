function part_uncert_ci = calcHILO_precision(Results)

%calculates the uncertainty in particle localization from HILO tracking
%data. The output part_uncert_ci is the confidence interval and its are 
% pixels. So the output should be multiplied by the pixel size. To
% calculate the standard deviation, first get the median of part_uncert_ci,
% and then divide by 1.96.

if ~isfield(Results.Tracking,'Particles')
    part_uncert_ci = [];
else

    part_xy_uncert = Results.Tracking.Particles(:,17:18);
    part_xy_uncert(part_xy_uncert(:,1) == 0,:) = [];
    ci2 = part_xy_uncert.^2;
    ci2 = sum(ci2,2);
    part_uncert_ci = sqrt(ci2);
end
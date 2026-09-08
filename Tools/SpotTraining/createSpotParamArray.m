function [intensityVals, backgroundVals, bgstdVals, spotSigmaVals, posOffsetVals] = createSpotParamArray(stats, n)

intensityVals = normrnd(stats.mn_intensity,stats.S_intensity,n,1);
intensityVals(intensityVals < 0) = intensityVals(intensityVals < 0) - ceil(intensityVals(intensityVals < 0));

backgroundVals = normrnd(stats.mn_background,stats.S_background,n,1);

bgstdVals = normrnd(stats.mn_bgstd,stats.S_bgstd,n,1);

spotSigmaVals = normrnd(stats.mn_spotSigma,stats.S_spotSigma,n,1);
spotSigmaVals(spotSigmaVals < 0) = 10;

posOffsetVals(:,1) = normrnd(stats.mn_posOffset(1),stats.S_posOffset(1),n,1);
posOffsetVals(:,2) = normrnd(stats.mn_posOffset(2),stats.S_posOffset(2),n,1);


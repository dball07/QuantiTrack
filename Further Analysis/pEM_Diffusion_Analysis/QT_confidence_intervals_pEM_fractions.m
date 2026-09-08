function [popFracMat, ci] = QT_confidence_intervals_pEM_fractions(nResamples, alpha, trackID, splitID, optimalState, posteriorProb, deltaPP_thresh, states_deltaPP, props_deltaPP)
% This function uses the auxiliary function
% calculate_resampled_population_fraction to estimate the confidence
% interval on the pEM state fractions

% Initialize the matrix of population fractions
popFracMat = zeros(nResamples, length(states_deltaPP)); 
ci_wait = waitbar(0,'Resampling for CI calculation','Name','Confidence intervals');
pos = get(ci_wait,'Position');
pos(2) = pos(2) - 75;
set(ci_wait,'Position',pos);


for i=1:nResamples
    waitbar((i-1)/nResamples,ci_wait,['Resampling for CI calculation #', num2str(i), ' of ', num2str(nResamples)]);
    trackID_tmp     = datasample(trackID, length(trackID));

    popFracMat(i,:) = calculate_resampled_population_fraction(trackID_tmp,...
        splitID, optimalState, posteriorProb, deltaPP_thresh, states_deltaPP);

    

end
waitbar(1,ci_wait,['Resampling for CI calculation #', num2str(i), ' of ', num2str(nResamples)]);
lower_percentile    = (1-alpha)/2;
upper_percentile    = 1 - lower_percentile;

lowerIDX            = floor(lower_percentile*nResamples);
lowerIDX            = max(lowerIDX,1);
upperIDX            = floor(upper_percentile*nResamples);
upperIDX            = min(upperIDX,size(popFracMat,1));
sortedPopFrac       = sort(popFracMat, 1);

ciMat               = [sortedPopFrac(lowerIDX, :); sortedPopFrac(upperIDX, :)];
ciMat               = ciMat';
ci                  = zeros(size(ciMat));

ci(:,1)             = props_deltaPP - ciMat(:,1);
ci(:,2)             = ciMat(:,2) - props_deltaPP;

close(ci_wait);

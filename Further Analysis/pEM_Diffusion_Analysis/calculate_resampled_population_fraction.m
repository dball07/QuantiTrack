function popFrac = calculate_resampled_population_fraction(trackID, splitID, optimalState, posteriorProb, deltaPP_thresh, states_deltaPP)

% This function calculates the population fraction of a resampled dataset
% INPUTS: 
%       1. trackID:         vector of trackIDs
%       2. splitID:         original vector of splitIDs
%       3. optimalState:    vector of optimalStates
%       4. posteriorProb:   vector of posterior probabilities
%       5. deltaPP:         vector of difference between the top two
%                           posterior probabilities
%
% OUTPUT:
%       popFrac: Array of population fractions

% generate vector of deltaPP (the difference between the two top posterior
% probabilities

sort_pp         = sort(posteriorProb, 2, 'descend');
deltaPP         = sort_pp(:,1) - sort_pp(:,2);

% generate resampled trackID
%resampledTrackID    = datasample(trackID, length(trackID));

% generate resampled splitID, optimalState, and deltaPP 
resampledSplitID        = [];
resampledOptimalState   = [];
resampledDeltaPP        = [];

for i=1:length(trackID)

    splitIDX                = find(splitID == trackID(i));

    resampledSplitID        = [resampledSplitID; splitID(splitIDX)];
    resampledOptimalState   = [resampledOptimalState; optimalState(splitIDX)];
    resampledDeltaPP        = [resampledDeltaPP; deltaPP(splitIDX)];

end

[~, ~, popFrac_tmp] = groupcounts(resampledOptimalState(resampledDeltaPP>deltaPP_thresh));


% states_deltaPP(popFrac_tmp<5) = [];
% popFrac = popFrac_tmp(popFrac_tmp>5);

% if length(popFrac) < length(states_deltaPP)
%     popFrac(length(popFrac)+1:length(states_deltaPP)) = 0;
% end

existStates_tmp = unique(resampledOptimalState(resampledDeltaPP>deltaPP_thresh));
for i = 1:max(existStates_tmp)
    if ismember(i,existStates_tmp)
        popFrac_tmp2(i,:) = popFrac_tmp(existStates_tmp == i);
    end
end
popFrac_tmp = popFrac_tmp2;
popFrac = popFrac_tmp(states_deltaPP);
popFrac = popFrac'./sum(popFrac);




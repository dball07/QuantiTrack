

function [Pt, counts]     = pEM_calculate_transition_probability(trackID, splitID, optimalState, windowPos)

% This function calculates the transition probability for tracks with
% trackID containing subtracks with splitID ana a vector of optimal state
% assignment based on pEMv2
% INPUTS:   trackID: Vector containing a numeric ID for each track
%           splitID: Vector containing ID for each subtrack. A set of
%           subtracks belonging to the same parent track will have the same
%           splitID (equal to the trackID)
%           optimalState: Vector containing state assignment
%
% OUTPUT:   Pt: Array of transition probabilities. Pt(i,j) = probability to
%           transition from state i to state j. Rows sum to 1.

if nargin < 4
    windowPos = []; %back-compatible
end

counts  = zeros(length(unique(optimalState)));
for k = 1:length(trackID)
    idx = find(splitID==trackID(k));
    if length(idx) >= 3
        os = optimalState(idx);
        if isempty(windowPos)
            adj = true(length(os)-1,1);
        else
            wp = windowPos(idx);
            adj = diff(wp) == 1;
        end
        pairs = [os(1:end-1),os(2:end)];
        counts_tmp  = accumarray(pairs(adj,:), 1, ...
            [length(unique(optimalState)),length(unique(optimalState))]);
        counts = counts + counts_tmp;
    end
end

Pt  = counts./sum(counts,2);

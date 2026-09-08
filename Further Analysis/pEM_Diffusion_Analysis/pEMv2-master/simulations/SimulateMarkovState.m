function markovStateSeq = SimulateMarkovState(numTracks,N,Pindex,A)
%--------------------------------------------------------------------------
% This function simulates a markov state sequence following the transition 
% matrix A for length N. Pindex is the percent of tracks that start from a
% given state.
%
% Code written by: 
%       Peter Koo
%       Yale University, Department of Physis, New Haven, CT, 06511  
%--------------------------------------------------------------------------

% generate initial markov state
Nindex = round(numTracks*Pindex); 
numStates = size(A,2);
initialState = [];
for i = 1:numStates
    initialState = [initialState ones(1,Nindex(i))*i];
end
if length(initialState) < numTracks
    initialState = [ones(1,numTracks-length(initialState)) initialState];
end
initialMarkovState = initialState;

% map transition probabilities onto cumulative distribution
transitionCum = cumsum(A,2);

% underlying markov markovState sequences
markovStateSeq = cell(numTracks,1); 
for z = 1:numTracks
    
    % simulate transition probabilities for each protein trajectory
    markovStateChange = rand(N,1);

    % 
    markovState = zeros(N,1);
    markovState(1) = initialMarkovState(z);
    for t = 2:N
        markovState(t) = find(markovStateChange(t) < transitionCum(markovState(t-1),:),1);
    end
    markovStateSeq{z} = markovState;
end


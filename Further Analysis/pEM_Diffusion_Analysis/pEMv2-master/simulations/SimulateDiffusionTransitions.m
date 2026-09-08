function [X,markovStateSeq] = SimulateDiffusionTransitions(simParams,numTracks,N,dt,numSubSteps)
%--------------------------------------------------------------------------
% This function generates synthetics particle trajectories based on a 
% markov state sequence corresponding to different diffusive states. 
%
% Code written by: 
%       Peter Koo
%       Yale University, Department of Physis, New Haven, CT, 06511  
%--------------------------------------------------------------------------

% microstep times
microtime = dt/numSubSteps;
state = simParams.state;
A = simParams.A;
Pindex = simParams.Pindex;
locNoise = [state(:).locNoise]';

% generate Markov diffusion state sequence for each trajectory
markovStateSeq = SimulateMarkovState(numTracks,N,Pindex,A);

% simulate diffusion with transitions + static and dynamic localization noise
X = cell(numTracks,1);
parfor z = 1:numTracks    % more cores the better
    
    markovState = markovStateSeq{z};

    % initialize all true positions
    allTruePositions = zeros(N*numSubSteps,2);    
    
    % simulate positions
    lastState = markovState(1); 
    lastPosition = [0 0];   
    confineLocation = [];   
    k = 1;                  
    while k < N
        
        % find last state index with the same markov state
        lastIndex = find(markovState(k:end) ~= lastState,1,'first');
        if isempty(lastIndex)
            lastIndex = N;
        end
        
        % generate range of steps 
        range =  (k*numSubSteps-numSubSteps+1:(k+lastIndex-1)*numSubSteps);
        numSteps = length(range);

        % input current state's diffusion mode parameters
        D = state(lastState).D;
        alpha = state(lastState).A;
        v = state(lastState).v;
        L = state(lastState).L + randn(1)*state(lastState).Lnoise;   
        
        % generate simulated tracks 
        switch state(lastState).mode
            
            case 1 % normal diffusion
                deltaX = randn(numSteps,2).*sqrt(2*D*microtime);
                subPositions = cumsum([lastPosition; deltaX]);
            
            case 2 % confined diffusion    
                confineLocation = [confineLocation; lastPosition(1,1)-L lastPosition(1,1)+L lastPosition(1,2)-L lastPosition(1,2)+L];
                
                subPositions = zeros(numSteps+1,2);     
                subPositions(1,:) = lastPosition;
                for j = 2:numSteps + 1

                    % propose new position
                    proposedPosition = subPositions(j-1,:) + sqrt(2*D*microtime)*randn(1,2);

                    % impose reflecting boundary conditions
                    for i = 1:2
                        if proposedPosition(i) > confineLocation(end,i*2)
                            subPositions(j,i) = 2*confineLocation(end,i*2) - proposedPosition(i); 
                        elseif proposedPosition(i) < confineLocation(end,i*2-2+1)
                            subPositions(j,i) = 2*confineLocation(end,i*2-2+1) - proposedPosition(i); 
                        elseif proposedPosition(i) >= confineLocation(end,i*2-2+1) & proposedPosition(i) <= confineLocation(end,i*2)
                            subPositions(j,i) = proposedPosition(i);
                        end
                    end
                end
                
            case 3 % driven diffusion
                deltaX = randn(numSteps,2).*sqrt(2*D*microtime); 
                deltaX(:,1) = deltaX(:,1) + v*microtime;
                subPositions = cumsum([lastPosition; deltaX]);

            case 4 % fractional Brownian motion                
                model = 2*D;
                C = zeros(numSteps,numSteps);
                for n = 1:numSteps
                    for m = 1:numSteps
                        C(n,m) = model/2*(microtime)^alpha*(abs(n-m+1)^alpha - 2*abs(n-m)^alpha + abs(n-m-1)^alpha);
                    end
                end
                cholC = chol(C,'lower');
                
                deltaX = cholC*randn(numSteps,2);
                subPositions = cumsum([lastPosition; deltaX]);
        
            otherwise
        end
        
        % save true positions and state
        allTruePositions(range,:) = subPositions(2:end,:);
        
        if lastIndex == N
            k = N;   % falls out of loop
        else            
            % update new diffusive state
            lastState = markovState(k+lastIndex-1);  
            k = k + lastIndex - 1;
            lastPosition = subPositions(end,:);
        end
    end

    % find true positions every dt
    truePositions = allTruePositions(1:numSubSteps:N*numSubSteps,:);

    % average over true positions to get the motion blur 
    motionPositions = zeros(N,2);
    for i = 1:N
        range = i*numSubSteps-numSubSteps+1:i*numSubSteps;
        motionPositions(i,:) = mean(allTruePositions(range,:));
    end

    % simulate noise 
    positionNoise = randn(N,2).*repmat(locNoise(markovState),1,2);

    % get the observed displacements
    X{z} = motionPositions + positionNoise;
    
end
    





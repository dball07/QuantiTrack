function  results = pEMv2_SPT(deltaX,trackInfo,params)
%--------------------------------------------------------------------------
% This function runs pEMv2 on a set of particle tracks, X: rEM and then pEM
% to uncover the number of diffusive states and their properties, i.e.
% covariance structure and population fractions. This version assumes all
% tracks share the same length.  
%
% Code written by: 
%       Peter Koo
%       Yale University, Department of Physis, New Haven, CT, 06511  
%--------------------------------------------------------------------------

minStates = params.minStates;
maxStates = params.maxStates;
dt = trackInfo.dt;
numData = length(deltaX)*length(deltaX{1});

% BIC Model Selection Loop
state = struct([]);
BIC = zeros(maxStates,1); 
for numStates = minStates:maxStates
    disp('-------------------------------------------------------');
    disp([num2str(numStates) ' state model']);

    % random initialization
    [vacf0,P0] = RandomInitialization(numStates,trackInfo.vacf_exp,1);
    if params.verbose == 1
        disp(['Initial Guess: ' num2str((vacf0(:,1) + 2*vacf0(:,2))'/2/dt)]);
    end
    
    % run rEM
    [baseVacf,baseP,posteriorProb,logLmax,remTrial] = rEM(deltaX,vacf0,P0,params,trackInfo);    
    if params.verbose == 1
        disp(['rEM log-likelihood: ' num2str(logLmax)]);
    end
    
    % run pEM
    [baseVacf,baseP,posteriorProb,logLmax,pemTrial] = pEM(deltaX,baseVacf,baseP,params,trackInfo);
    if params.verbose == 1
        disp(['pEM log-likelihood: ' num2str(logLmax)]);
    end
    
    % calculate BIC
    nparams = numStates + numStates*trackInfo.numFeatures; 
    BIC(numStates) = logLmax/2 - nparams/2*log(numData);
    disp(['BIC: ' num2str(BIC(numStates))]);

    % store results
    state(numStates).numberOfStates = numStates;
    state(numStates).BIC = BIC(numStates);
    state(numStates).logL = logLmax;
    state(numStates).vacf = baseVacf;
    state(numStates).P = baseP;
    state(numStates).posteriorProb = posteriorProb;
    state(numStates).remTrial = remTrial;
    state(numStates).pemTrial = pemTrial;
    
    if BIC(numStates) < max(BIC)
        break;
    end
end

% store optimal results
[MAX,numStates] = max(BIC);
results.params = params;
results.trackInfo = trackInfo;
results.state = state;
results.optimalSize = numStates;
results.optimalVacf = state(numStates).vacf;
results.optimalP = state(numStates).P;
results.optimalL = state(numStates).logL;
results.posteriorProb = state(numStates).posteriorProb;
results.BIC = BIC;

function hmmmodel = HMMGMM(deltaX, trackInfo, params)
%--------------------------------------------------------------------
% This function runs the Hidden Markov Models of multivariate Gaussians
% to analyze a collection of single particle trajectories for a given
% model size.
%
% Code written by:
%	Peter Koo
% 	Yale University, Department of Physics, New Haven, CT, 06511
%--------------------------------------------------------------------

% initialize the HMM
hmmmodel = InitializeHMM(deltaX, params.pik, params.vacfk, params.transProb);

% optimization parameters
maxiter = params.maxiter;
tolerance = params.tolerance;
verbose = params.verbose;
splitIndex = trackInfo.splitIndex;

% model parameters
p = hmmmodel.p;
a = hmmmodel.a;
b = hmmmodel.b;
sigma = hmmmodel.sigma;
K = size(a,1);

pbest = p;
abest = a;
bbest = b;
sigmabest = sigma;
gammankbest = 0;

% HMM model parameters
Lold = -Inf;
for i = 1:maxiter
    
    % expectation step
    [est,Lnew,gammank] = ExpectationHMM(p,a,b,splitIndex);
    disp([num2str(i) ': ' num2str(Lnew)]);

    % maximization step
    [p,a,b,sigma] = MaximizationHMM(deltaX,gammank,est,K,trackInfo);
    
    % check percentage similar
    [MAX,index] = max(gammank,[],2);

    if (Lnew - Lold)/abs(Lold) < tolerance
        if verbose == 1
            disp('Converged...');
            disp(['iteration ' num2str(i) ': logL = ' num2str(Lnew)]);
        end
        break;
    else
        Lold = Lnew;
        pbest = p;
        abest = a;
        bbest = b;
        sigmabest = sigma;
        gammankbest = gammank;
    end
end

if i == maxiter
    if verbose == 1
        disp('Did not converge...');
    end
end

% store best parameters
hmmmodel.p = pbest;
hmmmodel.a = abest;
hmmmodel.b = bbest;
hmmmodel.sigma = sigmabest;
hmmmodel.gammank = gammankbest;
hmmmodel.logL = Lold;


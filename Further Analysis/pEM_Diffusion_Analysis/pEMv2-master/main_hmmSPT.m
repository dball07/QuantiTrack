%--------------------------------------------------------------------------
% This script runs perturbation expectation-maximization version 2 (pEMv2) 
% on a set of simulated particle tracks. The tracks have to be stored in a 
% mat file under the variable X, which is a cell that contains each
% trajectory X{1} = [x_1 y_1], X{2} = [x_2, y_2]... where x_i and y_i are
% vectors of the positions of the trajectories.  The results are then fed
% into a HMM of multivariate Gaussians to refine the estimates and also to
% introduce a transition matrix, which the HMM learns, resulting in less
% spurious transitions.  The output of pEMv2 is saved in a mat file in the 
% results folder.
% 
% Code written by: 
%       Peter Koo
%       Yale University, Department of Physis, New Haven, CT, 06511  
%--------------------------------------------------------------------------

clear all;
clc;
close all;
addpath('pEMv2');
addpath('HMM');
addpath('visualization')

%%  load file

[filename,dirpath] = uigetfile('*.mat','Select protein track positions mat file');
data = load(fullfile(dirpath,filename));
Xraw = data.X;

%% user set parameters

% movie parameters
dt = .032;              % time between steps
dE = .032;              % exposure time

% pEM parameters
minStates = 1;          % minimum number of states to explore
maxStates = 5;          % maximum number of states to explore
numReinitialize = 3;    % number of reinitialization trials
numPerturb = 20;        % number of perturbation trials
maxiter = 10000;        % maximum number of iterations within EM trial
convergence = 1e-5;     % convergence criteria for change in log-likelihood 
lambda = 0.0001;        % shrinkage factor (useful when numerical issues calculating
                        % inverse of covariance matrix, labmda = 0.0 for no correction 
                        % lambda = 0.001 for correction)

numFeatures = 5;        % number of covariance features to include (min=2 for
                        % normal diffusion, 3-5 for non-normal diffusion)
splitLength = 15;       % length of steps to split each track

%% run pEM version 2

% split tracks into equal bin sizes
[X,splitIndex] = SplitTracks(Xraw,splitLength);

% structure for track info
trackInfo.numberOfTracks = length(X);   % number of tracks
trackInfo.dimensions = size(X{1},2);    % particle track dimensions
trackInfo.numFeatures = numFeatures;    % number of features to retain in covariance matrix
trackInfo.splitLength = splitLength;    % length of each bin
trackInfo.splitIndex = splitIndex;      % index of each track
trackInfo.dt = dt;                      % frame duration
trackInfo.R = 1/6*dE/dt;                % motion blur coefficient
trackInfo.lambda = lambda;              % shrinkage factor

% structure for pEM
params.minStates = minStates;               % minimum number of states to try
params.maxStates = maxStates;               % maximum number of states to try
params.numFeatures = numFeatures;           % number of features in covariance elements
params.numReinitialize = numReinitialize;   % number of reinitialization trials
params.numPerturbation = numPerturb;        % number of perturbations trials
params.converged = convergence;             % convergence condition for EM
params.maxiter = maxiter;                   % maximum number of iterations for EM
params.verbose = 1;                         % display progress on command window (0,1)

% calculate the displacements for each particle track
deltaX = cell(trackInfo.numberOfTracks,1);
for i = 1:trackInfo.numberOfTracks
    deltaX{i} = diff(X{i});
end

% calculate relevant properties to enhance compuatational time
[trackInfo.vacf_exp,trackInfo.xbar_exp] = CovarianceProperties(deltaX,numFeatures);

% run pEMv2 
results = pEMv2_SPT(deltaX,trackInfo,params); 

% display results
optimalSize = results.optimalSize;
optimalVacf = results.optimalVacf;
optimalP = results.optimalP;
disp('-------------------------------------------------------');
disp(['OptimalSize: ' num2str(optimalSize) ' states']);
for i = 1:numFeatures
    disp(['Sigma_k(i,i+' num2str(i-1) '): ' num2str(optimalVacf(:,i)') ' um^2']);
end
disp(['pi_k: ' num2str(optimalP)]);
disp('-------------------------------------------------------');

% save results in Results/filename
[tmp, name] = fileparts(filename);
saveFolder = fullfile('results',name);
if ~isdir(saveFolder)
    mkdir(saveFolder)
end
disp(['Saving results: ' fullfile(saveFolder,['results.mat'])]); 
save(fullfile(saveFolder,['results.mat']),'results');

% train HMM
hmmparams.pik = optimalP;
hmmparams.vacfk = optimalVacf;
hmmparams.transProb = .99;
hmmparams.maxiter = 100;
hmmparams.tolerance = 1e-7;
hmmparams.verbose = 1;
hmmmodel = HMMGMM(deltaX, trackInfo, hmmparams);

% store HMM results
results.hmm.p = hmmmodel.p;
results.hmm.a = hmmmodel.a;
results.hmm.b = hmmmodel.b;
results.hmm.sigma = hmmmodel.sigma;
results.hmm.gammank = hmmmodel.gammank;
results.hmm.logL = hmmmodel.logL;

sigma = [];
for i = 1:optimalSize
    sigma = [sigma; hmmmodel.sigma(1,:,i)];
end
results.hmmVacf = sigma;

% get the state of each position
numTracks = splitIndex(end);
[MAX, state] = max(hmmmodel.gammank, [], 2);
stateSeq = cell(numTracks,1);
k = 1;
for i = 1:numTracks
    index = find(splitIndex == i);
    stateSeq{i} = [];
    for j = 1:length(index)
        stateSeq{i} = [stateSeq{i}; ones(splitLength,1)*state(k)];
        k = k + 1;
    end
end

numTracks = splitIndex(end);
pos = cell(numTracks,1);
for i = 1:numTracks
    index = find(splitIndex == i);
    pos{i} = [];
    for j = 1:length(index)
        pos{i} = [pos{i}; X{j}];
    end
end


results.hmmStateSeq = stateSeq;

% calculate transition matrix
transMatrix = zeros(optimalSize);
for i = 1:numTracks
    seq = stateSeq{i};
    for j = 1:length(seq)-1
        transMatrix(seq(j),seq(j+1)) = transMatrix(seq(j),seq(j+1)) + 1;
    end
end
norm = sum(transMatrix,2);
A = transMatrix./(norm*ones(1, optimalSize));
results.hmmA = A;

disp(['Saving results: ' fullfile(saveFolder,'results.mat')]); 
save(fullfile(saveFolder,'results.mat'),'results');


%% plot X (line 51) and color with stateSeq (line 132)

resTimes = cell(numStates,1);
for i = 1:numStates
    resTimes{i} = [];
end

for j = 1:length(stateSeq)
    seq = stateSeq{j};
    
    i = 1;
    laststate = seq(i);
    counter = zeros(1,numStates);
    while i <= length(seq)
        if seq(i) == laststate
            counter(laststate)=counter(laststate)+1;
        else   
            resTimes{laststate} = [resTimes{laststate}; counter(laststate)];
            counter(laststate) = 0;
            laststate = likelystates(i);
            counter(laststate) = counter(laststate) + 1;
        end
        i = i + 1;
    end
    resTimes{laststate} = [resTimes{laststate}; counter(laststate)];
end








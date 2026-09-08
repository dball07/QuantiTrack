function [pEMTable, results,save_path,pEM_save_file_name] = pEM_calcStates(varargin)

if ~isempty(varargin)
    trackTable = varargin{1};
    trackPath = varargin{2};
    trackFile = varargin{3};
    splitLength = varargin{4}; 
    minStates = varargin{5};
    maxStates = varargin{6};
    numFeatures = varargin{7};

    numReinitialize = varargin{8};
    numPerturb = varargin{9};
    maxiter = varargin{10};
    convergence = varargin{11};
    verbose = varargin{12};
    save_path = varargin{13};
else
    [trackFile, trackPath] = uigetfile('trackTable*.mat', 'Select the file with the trackTable table');

    load(fullfile(trackPath, trackFile),'trackTable'); % Load trackTable
    % Ask user to input additional parameters
    %%
    % * Minimum number of states: Set to 1
    % * Maximum number of states: Set to 10. This can be lowered to 7 for a first
    % pass but if the program converges to the maximum number of states as optimal,
    % re-run pEMv2 with a higher number of maxStates
    % * Number of features: Set this to 3 for e10ms_i200ms data and 5 for e12ms_i12ms
    % data.

    prompt = {'Enter the split length (frames):','Enter min number of states:','Enter max number of states:','Enter number of features:',...
        'Enter number of reinitializaiton trials:', 'Enter number of perturbation trials:',...
        'Enter max iterations per trial:', 'Enter convergence criterion:'};
    dlgtitle = 'Parameters for pEMv2 Analysis';
    dims = [1 35];
    definput = {'1','10','3','20','200','10000','1e-7'};
    answer = inputdlg(prompt,dlgtitle,dims,definput);
    if isempty(answer)
        return
    end
    splitLength = str2double(answer{1});
    minStates = str2double(answer{2});     % Minimum number of states
    maxStates = str2double(answer{3});     % Maximum number of states
    numFeatures = str2double(answer{4});   % Number of features
    numReinitialize = str2double(answer{5});
    numPerturb = str2double(answer{6});
    maxiter = str2double(answer{7});
    convergence = str2double(answer{8});

    verbose = 1;
    timestamp = datestr(now, 'yyyy-mm-dd_THHMM');

    mkdir(fullfile(trackPath, sprintf('pEM_results_%s', timestamp)));

    save_path = fullfile(trackPath, sprintf('pEM_results_%s', timestamp));

end


dt          = trackTable.interval(1);            % Acquisition interval
dE          = trackTable.exposure(1);            % Exposure time


%% 
%% 

%randomize the random number generator
rng("shuffle");

% Other parameters that should not be changed without good reason.

% numReinitialize = 20;%5;    % Number of reinitialization trials 20
% numPerturb = 200;%10;%150;       % Number of perturbation trials 200
% maxiter = 10000;        % Maximum number of iterations within an EM trial
% convergence = 1e-7;     % Convergence criterion for change in log-likelihood
lambda = 0.0;           % shrinkage factor (useful when numerical issues arise while calculating the inverse of the covariance matrix.
                        % lambda = 0.0 for no correction, lambda = 0.1 for correction
% Generate input vector for pEMv2
% In order to run pEMv2, we need to collate all of the tracks into a single 
% cell array that is fed to pEM
% 
% This section creates the following:
%% 
% * |X:| Cell array containing all of the track coordinates
% * |trackID:| 1D array containing indices for the tracks as assigned in |trackTable| 
% * |cellID:| 1D array linking trackID to cellID

X = {}; % Define the cell array
trackID = [];
cellID = [];
for i = 1:height(trackTable)
    X       = [X trackTable.X{i}];                                                    % Concatenate all the tracks from the table
    trackID = [trackID; trackTable.trackID{i}];                                       % Create a vector of trackIDs
    cellID  = [cellID; trackTable.cellID(i)*ones(1,length(trackTable.trackID{i})).']; % Create a vector of cellIDs that are matched to the trackIDs
end
% Run pEMv2

[splitX, splitIndex] = SplitTracks(X, splitLength); % Split the tracks into sub-tracks with length = splitLength

% Ordinal position of each window inside its parent raw track. Preserved
% through the NaN filter so transition analysis can detect the gaps left
% by dropped windows.
windowPos = zeros(numel(splitIndex), 1);
for si = unique(splitIndex).'
    m = splitIndex == si;
    windowPos(m) = 1:sum(m);
end
% pEMv2's diff -> covariance -> kmeans -> EM chain is not NaN-aware; NaN
% in deltaX poisons logL so the convergence check "logL(i)-logL(i-1)<eps"
% becomes NaN<eps = false and every EM call runs to maxiter (20-200x
% slowdown). Drop NaN windows at the QT/pEMv2 boundary; keep splitIndex
% and windowPos aligned so downstream transition analysis stays correct.
bad = cellfun(@(w) any(~isfinite(w(:))), splitX);
if any(bad)
    fprintf('pEM_calcStates: dropping %d/%d windows (%.2f%%) with NaN rows\n', ...
        sum(bad), numel(splitX), 100*sum(bad)/numel(splitX));
    splitX(bad) = [];
    splitIndex(bad) = [];
    windowPos(bad) = [];
end
assert(~isempty(splitX), 'pEM_calcStates: all windows contained NaN; nothing left to fit.');

trackInfo.numberOfTracks    = length(splitX);       % Number of tracks
trackInfo.dimensions        = size(splitX{1},2);    % Particle track dimensions
trackInfo.numFeatures       = numFeatures;          % Number of features
trackInfo.splitLength       = splitLength;          % Split length
trackInfo.splitIndex        = splitIndex;           % Split indices
trackInfo.windowPos         = windowPos;            %
trackInfo.dt                = dt;                   % Acquisition interval
trackInfo.R                 = 1/6*dE/dt;            % Motion blur coefficient
trackInfo.lambda            = lambda;


params.minStates            = minStates;            % Minimum number of states to try
params.maxStates            = maxStates;            % Maximum number of states to try
params.numFeatures          = numFeatures;          % Number of features in covariance elements
params.numReinitialize      = numReinitialize;      % Number of reinitialization trials
params.numPerturbation      = numPerturb;           % Number of perturbations trials
params.converged            = convergence;          % Convergence condition for EM
params.maxiter              = maxiter;              % Maximum number of iterations for EM
params.verbose              = verbose;                    % Display progress on command window (0,1)

% calculate the displacements for each particle track
deltaX = cell(trackInfo.numberOfTracks,1);
for i = 1:trackInfo.numberOfTracks
    deltaX{i} = diff(splitX{i});
end

% calculate relevant properties to enhance compuatational time
[trackInfo.vacf_exp,trackInfo.xbar_exp] = CovarianceProperties(deltaX,numFeatures);

% run pEMv2 
tic;
results = pEMv2_SPT(deltaX,trackInfo,params); 
toc;
% 
% Re-arrange states in ascending order of effective diffusivities
% Since pEM does not always produce states in any particular order, we can re-arrange 
% all of the states by their diffusivity, |optimalD| (calculated below)

% * |results —| Results from pEM. Are not ordered by diffusivity. Not used for 
% downstream analysis
% * |pEMTable —| Relevant results ordered by diffusivity of the state. Used 
% for downstream analysis

% Notes:

% * |pEMTable| contains an optimalState for each track that is based on the 
% maximum posterior probability, without any cutoff. The state with the |maxPosteriorProb| 
% is the state that the track is assigned to.

vacf                = results.optimalVacf;                                          % covariance matrix       
results.optimalD    = (vacf(:,1) + 2*vacf(:,2))/(2*trackInfo.dt);                   % optimal diffusivity of the states
results.optimalS    = sqrt((vacf(:,1) - 2*results.optimalD*dt*(1-2*trackInfo.R))/2);% localization precision

[D, idx] = sort(results.optimalD);                                  % Sort the optimalD array in order of diffusivity

pEMTable = table;                                                   % Initialize pEMTable
pEMTable.cell_protein{1}    = trackTable.cell_protein{1};           % Identifier for the cell line and protein
pEMTable.conditions{1}      = unique(trackTable.condition);         % All the conditions run together
pEMTable.numRawTracks(1)    = length(X);                            % Number of raw tracks
pEMTable.numSplitTracks(1)  = results.trackInfo.numberOfTracks;     % Number of split tracks
pEMTable.trackInfo{1}       = results.trackInfo;                    % TrackInfo
pEMTable.params{1}          = results.params;                       % pEM parameters
pEMTable.trackInfoFile{1}   = fullfile(trackPath, trackFile);       % Path to the trackTable file used for this
pEMTable.optimalSize(1)     = results.optimalSize(1);               % Optimal # states as determined by pEM
pEMTable.optimalD{1}        = D;                                    % Diffusivities of the different states
pEMTable.optimalS{1}        = results.optimalS(idx);                % Localization precision of the different states
pEMTable.optimalVacf{1}     = results.optimalVacf(idx, :);          % optimalVacf 
pEMTable.optimalP{1}        = results.optimalP(idx);               
pEMTable.optimalL(1)        = results.optimalL;
pEMTable.BIC{1}             = results.BIC(idx);
pEMTable.cellID{1}          = cellID;                               % Array of cell IDs for all the cells
pEMTable.X{1}               = X;                                    % Raw tracks 
pEMTable.splitX{1}          = splitX;                               % Split tracks
pEMTable.trackID{1}         = trackID;                              % Array of track IDs for all the cells
pEMTable.splitID{1}         = results.trackInfo.splitIndex;         % Split index for all the sub-tracks
pEMTable.windowPos{1}       = results.trackInfo.windowPos;
pEMTable.posteriorProb{1}   = results.posteriorProb(:,idx);         % Posterior probabilities for all states

posteriorProb                       = pEMTable.posteriorProb{1};    
[maxPosteriorProb, optimalState]    = max(posteriorProb, [], 2);    % Maximum posterior probabilities for each track

vacf        = pEMTable.trackInfo{1}.vacf_exp;                       % Autocorrelation function from pEM
dt          = pEMTable.trackInfo{1}.dt;                             % Exposure time

track_D     = mean(vacf(:,1,:) + 2*vacf(:,2,:),3)/2/dt;             % Diffusivities calculated from vacf per track

pEMTable.maxPosteriorProb{1}    = maxPosteriorProb;                 % Maximum posterior probability
pEMTable.optimalState{1}        = optimalState;                     % Optimal state as defined by maximum posteriorProb

pEMTable.track_D{1}             = track_D;                          % Diffusivity calculated for each sub-track
% 
% Save |results| and |pEMTable|

strpos = strfind(save_path,'pEM_results');
runpos = strfind(save_path,'_run');
if ~isempty(runpos)
    if runpos > strpos
        timestamp = save_path(strpos+12:end-5);
    else
        timestamp = save_path(strpos+12:end);
    end
else
    timestamp = save_path(strpos+12:end);
end

pEM_save_file_name = sprintf('pEM_results_Split%d_Feat%d_%s.mat', ...
    splitLength, numFeatures, timestamp);

save(fullfile(save_path,pEM_save_file_name), 'pEMTable', 'results','trackTable', '-v7.3');

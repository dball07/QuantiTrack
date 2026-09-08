%--------------------------------------------------------------------------
% This script generates simulated particle tracks undergoing transitions
% with static and dynamic localization noise, based on the parameters that
% the user selects.  
% 
% Code written by: 
%       Peter Koo
%       Yale University, Department of Physis, New Haven, CT, 06511  
%--------------------------------------------------------------------------

clear all;
clc;
close all;
addpath('simulations');

%% Simulate particle tracks that transition between different diffuison modes

filename = 'my_simulation';     % output .mat file that stores tracks
numTracks = 1000;               % number of particle tracks
N = 60;                         % length of particle tracks
dt = .032;                      % time between steps
numSubSteps = 22;               % number of micro-steps

Dindex = [.05 .2 .7];      % diffusion coefficients (um^s/s)
Sindex = [.04 .04 .04];     % static localization noise (um)
Lindex = [.13 0 0];           % confinement size (um)
LnoiseIndex = [.01 0 0];      % confinement size variability (um)
Vindex = [0 0 0];           % drift velocity (um/s)
Pindex = [.25 .35 .15];     % population fraction
Aindex = [1  1  1];        % anomalous exponents (note fBM takes a long time to simulate)

diagA = .985;              % transition matrix - diagonal terms
uniformA = 1;
if uniformA == 1
    % diagonal elements of transition matrix are same, and off diagonal
    % matrices are p_{i,j} = (1-diagA)/(numStates-1)
    A = InitializeTransitionMatrix(length(Dindex),diagA);
else
    % manually enter transition matrix (can be unnormalized)
    A = [.995 .001 .004 .010; 
         .001 .995 .004 .010; 
         .015 .015 .970 .010; 
         .010 .004 .010 .970];
    A = A./(sum(A,2)*ones(1,length(Dindex)));
end


% store simulation parameters in a structure to pass to
% SimulateDiffusionTransitions function
simParams = struct();
simParams.numStates = length(Dindex);

% get diffusion modes of each state
dmode = ones(1,simParams.numStates); % assume all states are normal diffusion (dmode = 1)
dmode(find(Lindex ~= 0)) = 2;       % find confined states (dmode = 2)
dmode(find(Vindex ~= 0)) = 3;       % find states with drift (dmode = 3)
dmode(find(Aindex ~= 1)) = 4;       % find states with anomalous exponents (dmode = 4)

% setup state sub-structure 
state = struct;
for i = 1:simParams.numStates
    state(i).mode = dmode(i);
    state(i).D = Dindex(i);
    state(i).locNoise = Sindex(i);
    state(i).L = Lindex(i);
    state(i).Lnoise = LnoiseIndex(i);
    state(i).v = Vindex(i);
    state(i).A = Aindex(i);
end
simParams.state = state;
simParams.Pindex = Pindex;
simParams.A = A;

% simulate diffusive states
disp(['Simulating particle tracks']);
[X,markovStateSeq] = SimulateDiffusionTransitions(simParams,numTracks,N,dt,numSubSteps);

% save tracks
savepath = 'data';
if ~isdir(savepath)
    mkdir(savepath);
end
disp(['Saving tracks in: ' fullfile(savepath,[filename '.mat'])]);
save(fullfile(savepath,[filename '.mat']),'X','markovStateSeq','simParams');

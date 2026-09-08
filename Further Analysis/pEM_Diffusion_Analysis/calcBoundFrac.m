function Ceq_prime = calcBoundFrac(diffStateID,ResFile_fullpath,pEMfile_fullpath,plotFlag)

%Calculates the bound fraction using the residence time analysis and the
%pEM analysis. Required input, diffStateID, is the ID number for the state(s) identified as
%diffusive. 


%parse inputs
if nargin < 4
    plotFlag = 0;
end

%Have the user specify the residence time analysis file
if nargin < 2 || isempty(ResFile_fullpath)
    [ResFile, ResPath] = uigetfile('*.mat','Select the residence time analysis file');
    if ResFile == 0
        return
    end
    ResFile_fullpath = fullfile(ResPath,ResFile);
end



%Have the user specify the pEM analysis file
if nargin < 3 || isempty(pEMfile_fullpath)
    [pEMfile, pEMpath] = uigetfile('*.mat','Select the pEM analysis file');

    if pEMfile == 0
        return
    end
    pEMfile_fullpath = fullfile(pEMpath,pEMfile);
end

%Load in the Residence Time analysis to get the total number of Particles
if isa(ResFile_fullpath,'char')
    IN_r = load(ResFile_fullpath);

    N_total = IN_r.Results.TotalMolecules;
else
    N_total = ResFile_fullpath;
end

IN_p = load(pEMfile_fullpath);

if ~isfield(IN_p,'pEMTable')
    errordlg('pEM results should have a variable called: pEMTable');
    return
end

%Load in the pEM results
pEMTable = IN_p.pEMTable;

nStates = pEMTable.optimalSize;

diffStateID(diffStateID > nStates) = [];

maxPostProb = pEMTable.maxPosteriorProb{1};
optState = pEMTable.optimalState{1};
splitLength = size(pEMTable.splitX{1}{1},1);

%Count the number of subtracks in each state, using a threshold on the
%posterior probability

%%%%%ADJUST THIS
thresh = 0;
%%%%%ADJUST THIS

sigState = optState(maxPostProb >= thresh); %only keep subtracks with a posterior 

binEdges = 0.5:nStates+0.5;

StateCounts = histcounts(sigState,binEdges);

N_pEM = splitLength.*sum(StateCounts); %this will be used in the calculation of bound fraction

N_diff_part = (splitLength.*sum(StateCounts(diffStateID)));

N_bound = N_pEM - N_diff_part;
N_diff = N_diff_part + (N_total - N_pEM);

Ceq_prime = N_bound./(N_bound + N_diff);

if plotFlag == 1
    figure; pie([Ceq_prime,(1-Ceq_prime)],[0,1],{[num2str(Ceq_prime,2),' Bound'],[num2str(1-Ceq_prime,2), ' Unbound']});
end

% if plotFlag 


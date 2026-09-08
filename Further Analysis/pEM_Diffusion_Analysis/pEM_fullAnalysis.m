function pEM_fullAnalysis(pxSize,frameTime,useParallel)
%Performs the full pEM analysis including generating trackTables, running
%pEM, and post processing. If multiple runs are present in the same folder,
%a comparison of the pEM runs is also performed.

if nargin < 1 || isempty(pxSize)
    pxSize = 0.104;

end

if nargin < 2 || isempty(frameTime)
    frameTime = 200;
end

%Get the directory where data is located
% parentpath = uigetdir(pwd, 'Select Cell/Protein directory where data are located');

[savename, parentpath] = uigetfile('trackTable_*.mat','Select trackTable to analyze');

if parentpath == 0
    return
end


if nargin < 3
    
    %Check if parallel computing toolbox is available
    VER = ver;
    
    for i = 1:length(VER)
        parCompToolExist = strcmp('Parallel Computing Toolbox',VER(i).Name);
        if parCompToolExist
            useParallel = 1;
            break
        end
    end
    if ~parCompToolExist
        useParallel = 0;
    end
end




%Check if there is an existing trackTable
% curD = pwd;
% cd(parentpath);

prompt = {'Split length (frames):','Min number of states:','Max number of states:','Features:',...
    'Reinitializaiton trials:', 'Perturbation trials:',...
    'Max iterations per trial:', 'Convergence criterion:', 'Min. value of  Max. Posterior Prob.:',...
    'Min. Difference between Posterior Prob. of best 2 states:','Points to fit MSD:',...
    'Resamples used in Bootstrap:',...
    'pEM runs to perform:'};
dlgtitle = 'pEM analysis parameters';
dims = [1 70];
definput = {'7','1', '10', '3','20','200','10000','1e-7','0', '0.2','3','1000','1'};

acqParam  = inputdlg(prompt, dlgtitle, dims, definput);
if isempty(acqParam)
    
    return
end

splitLength_base = str2double(acqParam{1});
minStates = str2double(acqParam{2});
maxStates = str2double(acqParam{3});
numFeatures = str2double(acqParam{4});
numReinitialize = str2double(acqParam{5});
numPerturb = str2double(acqParam{6});
maxiter = str2double(acqParam{7});
convergence = str2double(acqParam{8});
numRuns = str2double(acqParam{13});
nResamples = str2double(acqParam{12});
Min_maxPP = str2double(acqParam{9});
Min_deltaPP = str2double(acqParam{10});
fitLength = str2double(acqParam{11});
% oldTrkTbl = dir('trackTable_*');
d = waitbar(0,'','Name','pEM analysis');

IN = load(fullfile(parentpath,savename));
trackTable = IN.trackTable;

%get the current time to add to the save folder name
timestamp = datestr(now, 'yyyy-mm-dd_THHMM');

if numRuns == 1
    fprintf('\n Run # 1 of 1\n');
    waitbar(0.33,d,'Calculating pEM states');
    save_path = fullfile(parentpath, sprintf('pEM_results_%s', timestamp));
    mkdir(fullfile(parentpath, sprintf('pEM_results_%s', timestamp)));

    [pEMTable, results,save_path,pEM_save_file_name] = pEM_calcStates(trackTable,parentpath,savename,...
        splitLength_base,minStates,maxStates,numFeatures,numReinitialize,numPerturb,maxiter,convergence,1,save_path);
    
    waitbar(0.66,d,'Generating outputs and plots');
    pEM_postProcess(pEMTable,trackTable,pEM_save_file_name,save_path,Min_maxPP,Min_deltaPP,fitLength,nResamples);
else
    %generate pEM save folders


    for i = 1:numRuns
        save_path{i,:} = fullfile(parentpath, sprintf('pEM_results_%s_run%s', timestamp,num2str(i)));
        mkdir(fullfile(parentpath, sprintf('pEM_results_%s_run%s', timestamp,num2str(i))));
    end

    if useParallel
        waitbar(0.5,d,{'Calculating pEM states and generating outputs'; ['in parallel for ', num2str(numRuns), ' runs']});

        
        parfor i = 1:numRuns
            

            fprintf('\n Run # %.1d of %.1d\n', i, numRuns);
            
            
            
            [pEMTable, results,save_path2,pEM_save_file_name] = pEM_calcStates(trackTable,parentpath,savename,...
                splitLength_base,minStates,maxStates,numFeatures,numReinitialize,numPerturb,maxiter,convergence,0,save_path{i,:});
            
            pEM_postProcess(pEMTable,trackTable,pEM_save_file_name,save_path{i,:},Min_maxPP,Min_deltaPP,fitLength,nResamples);
        end
        waitbar(1,d,['Generating outputs and plots, Run ' num2str(numRuns), ' of ', num2str(numRuns)]);
    else
        for i = 1:numRuns
            wbar_length = 0.33 + 0.33*((i - 1)/numRuns);
            fprintf('\n Run # %.1d of %.1d\n', i, numRuns);
            waitbar(wbar_length,d,['Calculating pEM states, Run ' num2str(i), ' of ', num2str(numRuns)]);
            [pEMTable, results,save_path2,pEM_save_file_name] = pEM_calcStates(trackTable,parentpath,savename,...
                splitLength_base, minStates,maxStates,numFeatures,numReinitialize,numPerturb,maxiter,convergence,1,save_path{i,:});
            
            waitbar(wbar_length+0.165*((i - 1)/numRuns),d,['Generating outputs and plots, Run ' num2str(i), ' of ', num2str(numRuns)]);
            pEM_postProcess(pEMTable,trackTable,pEM_save_file_name,save_path{i,:},Min_maxPP,Min_deltaPP,fitLength,nResamples);
        end
        waitbar(1,d,['Generating outputs and plots, Run ' num2str(numRuns), ' of ', num2str(numRuns)]);
    end
    
end

%If we have performed multiple runs, generate the table comparing them

if numRuns > 1
    waitbar(1,d,'Comparing different pEM runs');
    check_pEM_runs_fun(parentpath)
end
delete(d);

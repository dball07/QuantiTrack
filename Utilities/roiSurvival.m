function [surv, allLifetimes] = roiSurvival(varargin)

%returns the survival curve of ROIs that were generated automatically

if isempty(varargin)
    [files, path] = uigetfile('*.mat','Select matTrack files','MultiSelect','on');
else
    files = varargin{1};
    path = varargin{2};
end

if ~iscell(files)
    files = {files};
end
if files{1} ~= 0
    
    defaults = {'1'};
    prompt = {'Enter the Imaging Interval in seconds'};
    dlgtitle = 'Frame interval';
    ImgParam = inputdlg(prompt,dlgtitle, 1, defaults);
    frameInterval = str2double(ImgParam{1});
    %ask to save data
    [f_out,p_out] = uiputfile('*.mat','Select Save location');
    
%     ROIs = [];
    allLifetimes = [];
    nFrames = 0;
    for i = 1:length(files)
        IN = load(fullfile(path,files{i}));
        ROIs =  IN.Results.Process.ROIpos;
        nFrames = max(nFrames,IN.Results.Data.nImages);
        nROIs = size(ROIs,1);
        for j = 1:nROIs
            curROI = ROIs(j,:);
            indEmpty = [];
            if size(curROI,2) == 1
                error(['File ', fullfile(path,files{i}), ...
                    ' was not generated with automatic ROIs, please retrack this file and try again']);
            
            end
            for k = 1:nFrames
                if isempty(curROI{k})
                    indEmpty = [indEmpty, k];
                end
            end
            curStarts = indEmpty + 1;
            curEnds = indEmpty - 1;
            curStarts = [1, curStarts];
            curEnds = [curEnds, nFrames];
            curDur = curEnds - curStarts;
            curDur(curDur < 0) = [];
            curDur = curDur + 1;
            allLifetimes = [allLifetimes; curDur(:)];
        end
    end
    allLifetimes = (allLifetimes - 1).*frameInterval;
    x = (1:nFrames)';
    x = (0:frameInterval:(nFrames - 1).*frameInterval)';
    n = hist(allLifetimes,x);
    N = n./sum(n);
    
    surv = cumsum(N,'reverse');
    
    surv = [x,surv'];
    figure; plot(surv(:,1),surv(:,2));
    xlabel('Time (s)');
    ylabel('Survival Probability');
    
    
    if f_out ~= 0
        save(fullfile(p_out,f_out),'surv','allLifetimes','files');
    end
            
            
        
end
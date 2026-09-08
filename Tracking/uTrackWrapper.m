function Tracks = uTrackWrapper(Particles,Params)

Tracks = [];
if ~isfield(Params,'linearMotion')
    Params.linearMotion = 0;
end
if ~isfield(Params,'minSearchRadius')
    Params.minSearchRadius = 2;
end
if ~isfield(Params,'brownStdMult')
    Params.brownStdMult = 3;
end
if ~isfield(Params,'nnWindow')
    Params.nnWindow = 5;
end
if ~isfield(Params,'brownScaling')
    Params.brownScaling = [0.5 0.01];
end
if ~isfield(Params,'ampRatioLimit')
    Params.ampRatioLimit = [0.5 2];
end
if ~isfield(Params,'linScaling')
    Params.linScaling = [1 0.01];
end
if ~isfield(Params,'maxAngleVV')
    Params.maxAngleVV = 30;
end
if ~isfield(Params,'gapPenalty')
    Params.gapPenalty = 1.5;
end
if ~isfield(Params,'diagnostics')
    Params.diagnostics = 0;
end
if ~isfield(Params,'mergeSplit')
    Params.mergeSplit = 0; %0-No Merge nor Split, 1-Merge and Split, 2-Only Merge, 3-Only Split
end
if ~isfield(Params,'saveResults')
    Params.saveResults = 0;
end
if ~isfield(Params,'verbose')
    Params.verbose = 0;
end

Params.probDim = 2;


nImages = max(Particles(:,7));

for i = 1:nImages
    movieInfo(i).xCoord = Particles(Particles(:,7) == i,1:2);
    movieInfo(i).yCoord = Particles(Particles(:,7) == i,3:4);
    movieInfo(i).amp = Particles(Particles(:,7) == i,5:6);
end

%Set up the cost matrices
%Linking
costMatrices(1).funcName = 'costMatRandomDirectedSwitchingMotionLink';
costMatrices(1).parameters = struct('linearMotion',Params.linearMotion,...
    'minSearchRadius',Params.minSearchRadius,...
    'maxSearchRadius',Params.maxSearchRadius,...
    'brownStdMult',Params.brownStdMult,...
    'useLocalDensity',1,...
    'nnWindow',Params.nnWindow,...
    'KalmanInitParam',[],...
    'diagnostics', 0);

%Closing Gaps
costMatrices(2).funcName = 'costMatRandomDirectedSwitchingMotionCloseGaps';
costMatrices(2).parameters = struct('linearMotion',Params.linearMotion,...
    'minSearchRadius',Params.minSearchRadius,...
    'maxSearchRadius',Params.maxSearchRadius,...
    'brownStdMult',repmat(Params.brownStdMult,Params.mem+1,1),...
    'useLocalDensity', 1,...
    'nnWindow', Params.nnWindow,...
    'brownScaling',Params.brownScaling,...
    'timeReachConfB', Params.mem+1, ...
    'ampRatioLimit',Params.ampRatioLimit,...
    'lenForClassify', Params.mem+1,...
    'linStdMult',repmat(Params.brownStdMult,Params.mem+1,1),...
    'linScaling',Params.linScaling, ...
    'timeReachConfL', Params.mem+1,...
    'maxAngleVV', Params.maxAngleVV,...
    'gapPenalty',Params.gapPenalty,...
    'resLimit',[],...
    'gapExcludeMS',0,...
    'strategyBD',0);

%Set the Gap Closing parameters
gapCloseParam = struct('timeWindow',Params.mem+1,...
    'mergeSplit',Params.mergeSplit,... %0-No Merge nor Split, 1-Merge and Split, 2-Only Merge, 3-Only Split
    'minTrackLen',Params.minTrackLen,...
    'diagnostics',0);

kalmanFunctions = struct('reserveMem','kalmanResMemLM',...
    'initialize','kalmanInitLinearMotion',...
    'calcGain', 'kalmanGainLinearMotion',...
    'timeReverse','kalmanReverseLinearMotion');

[tracksFinal,~,errFlag] = trackCloseGapsKalmanSparse(...
    movieInfo,costMatrices,gapCloseParam,kalmanFunctions,Params.probDim,...
    Params.saveResults,Params.verbose);

if isempty(errFlag)
    TrackStruct = tracksFinal;
    for i = 1:size(TrackStruct,1)
        
        nPts = size(TrackStruct(i).tracksFeatIndxCG,2);
%         TrackPtData = [];
%         tVec = [];
%         for j = 1:size(TrackStruct(i).tracksCoordAmpCG,1)
%             TrackPtData_tmp = reshape(TrackStruct(i).tracksCoordAmpCG(j,:),8,nPts);
%             seqEventsCur = TrackStruct(i).seqOfEvents(TrackStruct(i).seqOfEvents(:,3) == j,:);
%             tVec_cur = (seqEventsCur(seqEventsCur(:,2) == 1,1):seqEventsCur(seqEventsCur(:,2) == 2,1))';
%             n_tpoints = length(tVec_cur);
%             TrackPtData_tmp = TrackPtData_tmp(:,1:n_tpoints);
%             TrackPtData = [TrackPtData, TrackPtData_tmp];
%             tVec = [tVec; tVec_cur];
%             
%         end
        TrackPtData = reshape(TrackStruct(i).tracksCoordAmpCG,8,nPts);
        TrackPtData = TrackPtData';
        tVec = (TrackStruct(i).seqOfEvents(TrackStruct(i).seqOfEvents(:,2) == 1,1):TrackStruct(i).seqOfEvents(TrackStruct(i).seqOfEvents(:,2) == 2,1))';
        Tracks_tmp = zeros(nPts,5);
        
        Tracks_tmp(:,1) = TrackPtData(:,1); % x position
        Tracks_tmp(:,2) = TrackPtData(:,2); % y position
        Tracks_tmp(:,3) = tVec; % frame number
        Tracks_tmp(:,4) = i; % Particle Number
        Tracks = [Tracks; Tracks_tmp];
    end
    Tracks(isnan(Tracks(:,1)),:) = [];
    TrkPtsAdded = cell(max(Tracks(:,4)),1);
    for i = 1: max(Tracks(:,4))
        
        tempTrack = Tracks(Tracks(:,4) == i,:);
%         tempTrack(isnan(tempTrack(:,1)),:) = [];
        dt = tempTrack(2:end,3)-tempTrack(1:end-1,3);
        lIx = find (dt ~=1);
        if  ~isempty(lIx)
            for iGap = 1:length(lIx)
                
                for iFrame = 1:dt(lIx(iGap))-1
                    % catTrack(:,1) =  tempTrack(lIx(iGap),1) + iFrame*(tempTrack(lIx(iGap)+1,1) - tempTrack(lIx(iGap),1))/dt(lIx(iGap));
                    % catTrack(:,2) = tempTrack(lIx(iGap),2)+ iFrame*(tempTrack(lIx(iGap)+1,2) - tempTrack(lIx(iGap),2))/dt(lIx(iGap));
                    catTrack(:,1) = NaN;
                    catTrack(:,2) = NaN;
                    catTrack(:,3) = tempTrack(lIx(iGap),3) + iFrame;%round((tempTrack(lIx+1,3) + tempTrack(lIx,3))/diff(lIx));
                    catTrack(:,4) = tempTrack(lIx(iGap),4);
                    catTrack(:,5) = 0;
                    Tracks = [Tracks;catTrack];
                    %keep a note of which particle points were added
%                     TrkPtsAdded{i} = [TrkPtsAdded{i}; tempTrack(lIx(iGap),3) + iFrame];
                end
            end
            clear catTrack;
        end
        
        %     TrkPtsAdded{i} = (tempTrack(lIx+1,3) + tempTrack(lIx,3))/2;
    end
end
% Re-sort track with the filled gaps
Tracks=sortrows(Tracks, [4 3]);

%remove tracks that are shorter than the specified shortest track
ind = 1;
Tracks2 = [];

for i = 1:max(Tracks(:,4))
    tmp = Tracks(Tracks(:,4) == i,:);
    if size(tmp,1) >= Params.minTrackLen
        tmp(:,4) = ind;
        ind = ind+1;
        Tracks2 = [Tracks2;tmp];
    end
    
end
Tracks = Tracks2;

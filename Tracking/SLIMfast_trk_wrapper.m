function tracks = SLIMfast_trk_wrapper(Particles,imStack,options)

% %options.pxSize
% %options.frameSize
% %options.windowSz
% %options.psfStd
% %options.T_off
% %options.Dmax
% %options.searchExpFac
% %options.maxComp
% %options.intLawWeight
% %options.diffLawWeight
% %options.statWin
% %options.trackStart
% %options.trackEnd
% %options.roi
% %options.isThreshDensity = 0
% %options.isThreshSNR
% %options.isThreshLocPrec
% %options.hROI
%options.cntsPerPhoton
%options.minLoc
%options.maxLoc
%options.minSNR 
%options.maxSNR;

global tab_param ;
global tab_var ;
global tab_moy ;
global par_per_frame;
global t;
global t_red;
global sig_free;
global T;
settings.Width = imStack(1).width;
settings.Height = imStack(1).height;
settings.px2micron = options.pxSize;
settings.Delay = options.frameSize/1000;

errRate = options.errorRate;
seuil_detec_1vue = chi2inv(1-10^errRate,1);
settings.TrackingOptions.FinalDetectionTresh = seuil_detec_1vue;

wn = options.windowSz;
settings.TrackingOptions.SizeDetectionBox = options.windowSz;
r0 = options.psfStd;
settings.TrackingOptions.GaussianRadius = options.psfStd;

seuil_alpha = options.minIntensity;
settings.TrackingOptions.ValidationTresh =seuil_alpha;

T = options.statWin;
settings.TrackingOptions.AvaragingTimeWindow = T;

settings.TrackingOptions.NumberDeflationLoops = options.deflateLoops;

T_off = options.T_off;
settings.TrackingOptions.BlinkingProbability = options.T_off;
settings.TrackingOptions.MaxDiffusionCoefficient = options.maxD;

sig_free = sqrt(options.maxD)/(options.pxSize)^2*4*options.frameSize/1000;

Boule_free = options.searchExpFac;
settings.TrackingOptions.ResearchDiameter = Boule_free;

Nb_combi = options.maxComp;
settings.TrackingOptions.CombinationTresh = Nb_combi;

Poids_melange_aplha = options.intLawWeight;
settings.TrackingOptions.WeightUniformGaussianLaw = Poids_melange_aplha;

Poids_melange_diff = options.diffLawWeight;
settings.TrackingOptions.WeightMaxLocalDiffusion = Poids_melange_diff;


Nb_STK = max(Particles(:,7));
for i = 1:Nb_STK
    ctrsN(i,:) = size(Particles(Particles(:,7) == i,:),1);
end

t_red = T-T_off ;

im_t = imStack(1).data;

idx = [-1; cumsum(ctrsN)];

if options.trackStart == 1
    options.startPnt = 0;
else
    options.startPnt = idx(options.trackStart+1);
end %if
if isinf(options.trackEnd)
    options.trackEnd = numel(ctrsN);
    options.elements = inf;
else
    options.elements = idx(options.trackEnd+1)-...
        max(1,options.startPnt+1);
end %if
settings.Frames = options.trackEnd-...
    options.trackStart+1;

%get ROI
roi = options.roi;
data = preprocessData(options,[1 1 1 1 1 1 1 0 0 0 0 0],roi,Particles);
trackID = 1:size(data.signal,1);

hProgressbar = waitbar(0,'Tracking','Color', get(0,'defaultUicontrolBackgroundColor'));

for t = options.trackStart:options.trackEnd
    if t == options.trackStart
        %fake detection list
        ind_valid = data.frame == 1;
        par_per_frame(t) = sum(ind_valid);
        lest = [(1:par_per_frame(t))' data.ctrsY(ind_valid) data.ctrsX(ind_valid)...
            data.signal(ind_valid)*sqrt(pi).*data.radius(ind_valid)...
            data.noise(ind_valid).^2 data.radius(ind_valid) ones(par_per_frame(t),1)];
        
        %preallocate tables
        tab_param = zeros(par_per_frame(t), 1+7*(t_red+1));
        tab_var = tab_param;
        %tab_moy = zeros(ctrsN, 1+7*(t_red+1)) ;
        %% initialize parameter tables
        tab_param(:,1) = (1:par_per_frame(t))' ;
        tab_param(:,2+7*(t_red-1):1+7*(t_red)) = [ones(par_per_frame(t),1), ...
            lest(:,[2,3,4,6]), zeros(par_per_frame(t),1), Nb_STK*ones(par_per_frame(t),1)];
        tab_param(:,2+7*(t_red)) = 2*ones(par_per_frame(t),1) ;
        
        tab_var(:,1)   = (1:par_per_frame(t))' ;
        tab_var(:,2+7*(t_red-1):1+7*(t_red)) = [ones(par_per_frame(t),1), ...
            zeros(par_per_frame(t),4), lest(:,5), Nb_STK*ones(par_per_frame(t),1)];
        tab_var(:,2+7*(t_red)) = 2*ones(par_per_frame(t),1) ;
        tab_moy = tab_var ;
        %% set initial variance guess (20% by default) -> nested by CPR
        init_tab;
        
        %% initialize tracks
        trackList = cell(1,par_per_frame(t));
        for track = tab_param(:,1)'
            if tab_param(track,1+7*(t_red))>0
                trackList{trackID(track)}(1,:) =...
                    [tab_param(track,7*(t_red-1)+[4 3 2])...
                    trackID(track) tab_param(track,7*(t_red-1)+5)...
                    tab_var(track,7*(t_red-1)+[7 3 5])];
            end %if
        end %for
        
        continue
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%  CYCLE THROUGH ACTIVE TRAJECTORIES   %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    im_t = double(imStack(t).data);
    
    ind_valid = data.frame == t;
    
    par_per_frame(t) = sum(ind_valid);
    lest = [(1:sum(ind_valid))' data.ctrsY(ind_valid) data.ctrsX(ind_valid)...
        data.signal(ind_valid)*sqrt(pi).*data.radius(ind_valid)...
        data.noise(ind_valid).^2 data.radius(ind_valid) ones(par_per_frame(t),1)];
    
    nb_traj_active = 0 ;
    nb_traj_blink = 0 ;
    
    isClosed = (tab_param(:,7*(t_red-1)+8) == T_off);
    if any(isClosed)
        trackID(find(isClosed)) = [];
        tab_param(isClosed,:) = [];
        tab_var(isClosed,:) = [];
        tab_moy(isClosed,:) = [];
    end %if
    
    if ~isempty(tab_param)
        tab_param(:,1) = 1:size(tab_param,1);
        tab_var(:,1) = tab_param(:,1);
        tab_moy(:,1) = tab_param(:,1);
        
        %from longest ON to longest OFF(blink)
        [unused, part_ordre_blk] = sort(-tab_param(:,7*(t_red-1)+8)) ;
        
        for traj = part_ordre_blk'
            %% reconnection test
            if (tab_param(traj, 7*(t_red-1)+8) > T_off)
                part = reconnect_part(traj, t_red-1, lest, wn, Nb_combi, Boule_free,Poids_melange_aplha,Poids_melange_diff,T_off,im_t) ;
                nb_traj_active = nb_traj_active + 1 ;
                if part == 0
                    nb_traj_blink = nb_traj_blink + 1 ; %counts # of trajectories with BLINK status
                end%if
            else %no testing if trajectory is already terminated
                part = 0;
            end %if
            
            %% update tables
            if (part>0)
                tab_param(traj, 7*(t_red)+[3 4 5 6]) =...
                    lest(part, [2 3 4 6]);
                tab_var(traj, 7*(t_red)+7) = lest(part, 5);
                if (tab_param(traj, 7*(t_red-1)+8) > 0) %trajectory was not OFF
                    [LV_traj_part, flag_full_alpha] = rapport_detection(traj, t_red-1, lest, part, wn,Poids_melange_aplha,Poids_melange_diff,T_off,im_t) ;
                    %increase BLINK value by Nb_STK
                    tab_param(traj, 7*(t_red)+8) = tab_param(traj, 7*(t_red-1)+8) + Nb_STK ;
                    if (flag_full_alpha==1) %full ON
                        %increase BLINK value by 1
                        tab_param(traj, 7*(t_red)+8) = tab_param(traj, 7*(t_red)+8) + 1 ;
                    else
                        tab_param(traj, 7*(t_red)+8) = ...
                            tab_param(traj, 7*(t_red)+8) - mod(tab_param(traj, 7*(t_red)+8), Nb_STK);
                    end%if
                else
                    %set BLINK value to initial ON value
                    tab_param(traj, 7*(t_red)+8) = Nb_STK ;
                end %if
            else
                tab_param(traj, 7*(t_red)+[3 4 5 6]) =...
                    [tab_param(traj, 7*(t_red-1)+[3 4]) 0 0];
                tab_var(traj, 7*(t_red)+7) = 0;
                
                %decrease BLINK value
                if (tab_param(traj, 7*(t_red-1)+8) < 0)
                    tab_param(traj, 7*(t_red)+8) = tab_param(traj, 7*(t_red-1)+8)-1; %blink -1
                else
                    %set BLINK value to initial OFF value
                    tab_param(traj, 7*(t_red)+8) = -1 ;
                end %if
                
                %% test for ephemerid detection
                if (t>3)
                    if (tab_param(traj, 7*(t_red-2)+8) == 0)
                        tab_param(traj, 7*(t_red)+8) = T_off ;
                    end %if
                end %if
                
            end %if
            %take reconnected particle out of game
            if (part>0)
                lest(part, 2) = -lest(part, 2) ;
                lest(part, 3) = -lest(part, 3) ;
            end %if
        end %for
    end %if
    
    nb_traj_avant_new = size(tab_param, 1) ;
    %check on particles not assigned to an active trajectory
    %and in case initiate a new one
    nb_non_aff_detect = false(par_per_frame(t),1);
    
    for p=1:par_per_frame(t)
        if (lest(p, 2) > 0)
            glrt_1vue = rapport_detection(0, 0, lest, p, wn,Poids_melange_aplha,Poids_melange_diff,T_off,im_t) ;
            if ((glrt_1vue > seuil_detec_1vue) && (lest(p,4)/(sqrt(pi)*r0) > seuil_alpha))
                nb_non_aff_detect(p) = true;
            end %if
        end %if
    end %for
    new_traj = sum(nb_non_aff_detect) ;
    %     set(h.newTracksInfo,'String', sprintf('# initiated Trajectories: %g',new_traj))
    
    tab_param_new = [(1:new_traj)'+nb_traj_avant_new, zeros(new_traj,7*(t_red)),...
        [ones(new_traj,1)*t, lest(nb_non_aff_detect, [2 3 4 6]),...
        zeros(new_traj,1) ones(new_traj,1)*Nb_STK]]; %by CPR
    
    tab_param = [tab_param; tab_param_new];
    tab_var = [tab_var; zeros(new_traj,7*(t_red+1)+1)];
    tab_moy = [tab_moy; zeros(new_traj,7*(t_red+1)+1)];
    
    tab_var((1:new_traj)+nb_traj_avant_new, 7*(t_red)+7) =...
        lest(nb_non_aff_detect, 5) ; %sig2_b
    
    %% shift tables one step to the left
    new_nb_traj = size(tab_param, 1) ;
    tab_param = [tab_param(:,1), ...
        tab_param(:,2+7*(1):1+7*(t_red+1)), ...
        (t+1)*ones(new_nb_traj,1), zeros(new_nb_traj,6)] ;%correction arnauld
    
    tab_var = [tab_var(:,1), ...
        tab_var(:,2+7*(1):1+7*(t_red+1)), ...
        (t+1)*ones(new_nb_traj,1), zeros(new_nb_traj,6)] ;
    
    tab_moy = [tab_moy(:,1), ...
        tab_moy(:,2+7*(1):1+7*(t_red+1)), ...
        (t+1)*ones(new_nb_traj,1), zeros(new_nb_traj,6)] ;
    
    init_tab((1+nb_traj_avant_new):new_nb_traj) ; %nested by CPR;
    mise_a_jour_tab(Nb_STK,new_nb_traj,T_off); %nested by CPR;
    
    %% update tracks
    trackList = [trackList cell(1,new_traj)];
    
    for track = tab_param(:,1)'
        if tab_param(track,1+7*(t_red))>0
            trackList{trackID(track)}(end+1,:) =...
                [tab_param(track,7*(t_red-1)+[4 3 2])...
                trackID(track) tab_param(track,7*(t_red-1)+5)...
                tab_var(track,7*(t_red-1)+[7 3 5])];
        end %if
    end %for
    
    waitbar(t/Nb_STK,hProgressbar,'Tracking','Color',get(0,'defaultUicontrolBackgroundColor'));
    
end %%for



% tracks = trackList;
tracks = [];
trInd = 1;
for i = 1:length(trackList)
    
    curTrack = trackList{i}(:,1:3);
    if size(curTrack,1) >= options.goodTr
        curTrack(:,4) = trInd*ones(size(curTrack,1),1);
        curTrack(:,5) = zeros(size(curTrack,1),1);
        tracks = [tracks; curTrack];
        trInd = trInd + 1;
    end
end

TrkPtsAdded = cell(max(tracks(:,4)),1);
for i = 1: max(tracks(:,4))

    tempTrack = tracks(tracks(:,4) == i,:);
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
                tracks = [tracks;catTrack];
                %keep a note of which particle points were added
%                     TrkPtsAdded{i} = [TrkPtsAdded{i}; tempTrack(lIx(iGap),3) + iFrame];
            end
        end
        clear catTrack;
    end

    %     TrkPtsAdded{i} = (tempTrack(lIx+1,3) + tempTrack(lIx,3))/2;
end
% Re-sort track with the filled gaps
tracks=sortrows(tracks, [4 3]);

tracks(:,1:2) = tracks(:,1:2) + 1;
delete(hProgressbar)

clear global;
%%
function data = preprocessData(options,returnValue,roi,Particles)
varNames = {'ctrsX', 'ctrsY', 'signal', 'noise', 'offset', 'radius', 'frame',...
    'photons', 'precision', 'snr', 'sbr', 'cluster'};

%define data to load
loadValue = returnValue(1:7);
if returnValue(3)
    loadValue(6) = true;
end
if returnValue(8)
    loadValue([3 6]) = true;
end
if returnValue(9)
    loadValue([3 4 6]) = true;
end
if returnValue(10)
    loadValue([3 4 6]) = true;
end
if returnValue(11)
    loadValue([3 5]) = true;
end
if returnValue(12) || options.isThreshDensity
    loadValue([1 2 6 7]) = true;
end
if options.isThreshSNR || options.isThreshLocPrec
    loadValue([3 4 6]) = true;
end
if ~isempty(options.hROI)
    loadValue([1 2]) = true;
end

%load data from disk
for value = find(loadValue(1,:))
    if loadValue(1,value)
        %             fid = fopen([getappdata(fig,'pathname') getappdata(fig,'filename') '.' varNames{value}], 'r');
        %             if isinf(getappdata(fig,'elements')) %load complete list
        data.(varNames{value}) = Particles(:,value);
        %             else
        %                 fseek(fid, getappdata(fig,'startPnt')*8, 'bof');
        %                 data.(varNames{value}) = fread(fid,getappdata(fig,'elements'),'real*8');
        %             end %if
    end %if
    %         fclose(fid);
end %for

%remove points outside of ROI
if loadValue(1) && loadValue(2)
    good =...
        data.(varNames{1}) > roi(1) &...
        data.(varNames{1}) < roi(1)+roi(3) &...
        data.(varNames{2}) > roi(2) &...
        data.(varNames{2}) < roi(2)+roi(4);
    
    for value = find(loadValue)
        data.(varNames{value}) = data.(varNames{value})(good);
    end %for
end %if

if loadValue(3)
    %volume [photons]
    data.photons = data.(varNames{3})*2*pi.*data.(varNames{6}).^2/...
        options.countsPerPhoton; %[photons]
    
    %calculate loc. prec.
    if returnValue(9) || options.isThreshLocPrec
        data.precision = calcLocPrecision(...
            data.radius, options.pxSize,...
            data.photons, data.(varNames{4})/options.countsPerPhoton); %[?m]
    end %if
    
    %calculate snr
    if returnValue(10) || options.isThreshSNR
        data.snr = data.signal./data.noise;
    end %if
    
    %calculate sbr
    if returnValue(11)
        data.sbr = data.signal./data.offset;
    end %if
    
    %apply loc. prec. or snr threshold if selected
    if options.isThreshLocPrec || options.isThreshSNR
        if options.isThreshLocPrec && options.isThreshSNR
            good = data.precision > options.minLoc/1000 &...
                data.precision < options.maxLoc/1000 &...
                data.snr > options.minSNR &...
                data.snr < options.maxSNR;
        elseif options.isThreshLocPrec && ~options.isThreshSNR
            good = data.precision > options.minLoc/1000 &...
                data.precision < options.maxLoc/1000;
        elseif ~options.isThreshLocPrec && options.isThreshSNR
            good = data.snr > options.minSNR &...
                data.snr < options.maxSNR;
        end %if
        for value = find([loadValue 0 0 0 0 0] | returnValue)
            if isfield(data,(varNames{value}))
                data.(varNames{value}) = data.(varNames{value})(good);
            end %if
        end
    end %if
end %if

%apply density threshold if selected
% if options.isThreshDensity || returnValue(12)
%     if ~all([isappdata(fig,'clusterScore'),...
%             isappdata(fig,'clusterRadius'),...
%             isappdata(fig,'clusterWeights')])
%         [data,tree,clusterScore,...
%             clusterRadius,clusterWeights] =...
%             densitybasedClustering(data);
%         kdtree_delete(tree)
%         
%         setappdata(fig,'clusterScore',clusterScore)
%         setappdata(fig,'clusterRadius',clusterRadius)
%         setappdata(fig,'clusterWeights',clusterWeights)
%         setappdata(fig,'cluster',data.cluster)
%         
%         for value = find([loadValue 0 0 0 0 0] | returnValue)
%             if getappdata(fig,'clusterMode') == 1
%                 data.(varNames{value}) = data.(varNames{value})(data.cluster > 0);
%             else
%                 data.(varNames{value}) = data.(varNames{value})(data.cluster == 0);
%             end %if
%         end %for
%     else
%         cluster = getappdata(fig,'cluster');
%         if getappdata(fig,'startPnt') == 0
%             startPnt = 1;
%         else
%             startPnt = getappdata(fig,'startPnt');
%         end %if
%         if isinf(getappdata(fig,'elements'))
%             good = startPnt:numel(cluster);
%         else
%             good = startPnt:startPnt+getappdata(fig,'elements')-1;
%         end %if
%         for value = find([loadValue 0 0 0 0 0] | returnValue)
%             if getappdata(fig,'clusterMode') == 1
%                 data.(varNames{value}) = data.(varNames{value})...
%                     (cluster(good) > 0);
%             else
%                 data.(varNames{value}) = data.(varNames{value})...
%                     (cluster(good) == 0);
%             end %if
%         end %for
%     end %if
% end %if

%remove unnecessary variables
for value = find(~returnValue)
    if isfield(data,varNames{value})
        data = rmfield(data,varNames{value});
    end %if
end %for
%%
function precision =...
    calcLocPrecision(psfStd, pxSize, photons, noise)
%calculates the localization uncertainty based on
%   psfStd, pxSize, photons, noise. (Thompson and Webb)

psfStd = psfStd*pxSize; % px -> ?m
precision = sqrt((psfStd.^2+pxSize^2/12)./photons+...
    8*pi.*psfStd.^4.*noise.^2/pxSize^2./photons.^2); %[?m]

%%
function init_tab(new_traj)
% EN/ initialisation of tables of values
% mean of parameters and variances (std)
%
% if input new_traj non null
% then only this traj is init
% otherwise all trajectories are (at the beginning)

global tab_param ;
global tab_var ;
global tab_moy ;
global par_per_frame;
global t;
global t_red;
global sig_free;

if (nargin < 1)
    tab_traj = 1:par_per_frame(t) ;
    new = 0 ;
else
    tab_traj = new_traj ;
    new = 1 ;
end%if

%% boucle sur les particules
for iTraj = tab_traj
    
    %% alpha
    local_param = tab_param(iTraj, 7*(t_red-1)+5) ; % alpha
    tab_moy(iTraj, 7*(t_red-1)+5) = local_param + sqrt(-1)*local_param ;% moyenne,max
    tab_var(iTraj, 7*(t_red-1)+5) = 0.2*local_param ; % std
    
    %% r
    local_param = tab_param(iTraj, 7*(t_red-1)+6) ;
    tab_moy(iTraj, 7*(t_red-1)+6) = local_param ;
    tab_var(iTraj, 7*(t_red-1)+6) = 0.2*local_param ;
    
    %% i,j
    tab_var(iTraj, 7*(t_red-1)+3) = sig_free ;
    tab_var(iTraj, 7*(t_red-1)+4) = sig_free ;
    
    %% blink pour info
    tab_moy(iTraj, 7*(t_red-1)+8) = tab_param(iTraj, 7*(t_red-1)+8) ;
    tab_var(iTraj, 7*(t_red-1)+8) = tab_param(iTraj, 7*(t_red-1)+8) ;
    
    %% affection identique a (t_red-1)-1
    %% pour compat avec mise_a_jour_tab
    if (new)
        
        %% alpha
        local_param = tab_param(iTraj, 7*(t_red-1)+5) ; % alpha
        tab_moy(iTraj, 7*((t_red-1)-1)+5) = local_param + sqrt(-1)*local_param ;% moyenne,max
        tab_var(iTraj, 7*((t_red-1)-1)+5) = 0.2*local_param ; % std
        
        %% r
        local_param = tab_param(iTraj, 7*(t_red-1)+6) ;
        tab_moy(iTraj, 7*((t_red-1)-1)+6) = local_param ;
        tab_var(iTraj, 7*((t_red-1)-1)+6) = 0.2*local_param ;
        
        %% i,j
        tab_var(iTraj, 7*((t_red-1)-1)+3) = sig_free ;
        tab_var(iTraj, 7*((t_red-1)-1)+4) = sig_free ;
        
        %% blink pour info
        tab_moy(iTraj, 7*((t_red-1)-1)+8) = tab_param(iTraj, 7*(t_red-1)+8) ;
        tab_var(iTraj, 7*((t_red-1)-1)+8) = tab_param(iTraj, 7*(t_red-1)+8) ;
        
    end %if
    
    
end %for
        
function part = reconnect_part(traj, t, lest, wn,Nb_combi,Boule_free,Poids_melange_aplha,Poids_melange_diff,T_off,im_t)
% EN/ function that search/detect the particle
% among those pre-detected, which best corresponds
% to the given trajectory
% returns the number of the particle in lest

%% evite les allocations sur des constantes
% global tab_param ;
% global tab_var ;
% Nb_combi = evalin('base', 'Nb_combi');

%%% Pre-detection
%%% liste_param = [num, i, j, alpha, sig^2, rayon, ok]

%%% Estimation/Reconnexion
%%%              1    2  3     4       5          6          7      8
%%% tab_param = [num, t, i,    j,      alpha,     rayon,     m0,   ,blink]
%%% tab_var =   [num, t, sig_i,sig_jj, sig_alpha, sig_rayon, sig_b ,blink]

%% reconnexion de la particule num part

%search for particles inside search radius of trajectory
ind_boule = liste_part_boule([], traj, lest, t, Boule_free) ;
nb_part_boule = size(ind_boule, 1) ;


if (nb_part_boule == 0)
    %% set trajectory status to BLINK
    part = 0 ;
else
    %% plusieurs particule candidate
    %% on prend celle la plus probable
    
    %look up if other trajectory are in competition for one of the particles
    vec_traj_inter = liste_traj_inter(ind_boule, traj, lest, t, Boule_free) ;
    vec_traj = [traj; vec_traj_inter] ;
    nb_traj = size(vec_traj,1) ;
    
    %% limitation du nb de trajectoire
    %% en competition
    if (nb_traj > Nb_combi)
        %     fprintf('--> limitation combi for traj : traj %d\n', traj) ;
        vec_traj = limite_combi_traj_blk(vec_traj, t,Nb_combi) ;
        %%vec_traj = limite_combi_traj_dst(vec_traj, t) ;
        nb_traj = Nb_combi ;
    end %if
    
    %% prise en compte des particules
    %% qui seraient dans les boules de recherche
    %% des trajectoires en competition
    %% "On travail ici a l'ordre 1"
    ind_boule_O1 = ind_boule ;
    for ntraj = 2:nb_traj
        traj_inter = vec_traj(ntraj) ;
        ind_boule_O1 =  liste_part_boule(ind_boule_O1, traj_inter, lest, t,Boule_free) ;
    end %for
    nb_part_boule_O1 = size(ind_boule_O1, 1) ;
    
    %% passage a l_ordre 1
    ind_boule = ind_boule_O1 ;
    nb_part_boule = nb_part_boule_O1 ;
    
    %% limite du nb de particules
    %% en competition
    if (nb_part_boule > Nb_combi)
        %     fprintf('--> limitation combi for part : traj %d\n', traj) ;
        ind_boule = limite_combi_part_dst(traj,ind_boule,lest,t,Nb_combi) ;
        nb_part_boule = Nb_combi ;
    end %if
    
    %% recherche de la meilleur config par
    %% maximum de vraisemblance
    if nb_traj <= nb_part_boule
        %% pas le blink
        %% mais possiblilite de nouvelle particule (<)
        vec_part = ind_boule ;
    else
        %% nb_traj > nb_part_boule
        %% des particules ont blinkees
        vec_part = [ind_boule; zeros(nb_traj-nb_part_boule,1)] ;
    end %if
    
    part = best_config_reconnex(vec_traj, vec_part, t, lest, wn,Poids_melange_aplha,Poids_melange_diff,T_off,im_t);
    
    
end %if

function part = best_config_reconnex(vec_traj, vec_part, t, lest, wn,Poids_melange_aplha,Poids_melange_diff,T_off,im_t)%,T)
% EN/ This function looks for the best config
% according to the ML and sends back
% the most probable particle (O if blinked)
% The refering trace IS the first one
% of the list in vect_traj
%
% Caution with combinatory tests beyond nb_part = 4

% Exemple de calcul de Log-vraisemblance
% de reconnexion a 3 trajectoires/Particules
% reprenant les notations de la figure 3
%
%
% - T_domain = P_domain
% 3 trajectoires (a,k,b) pour 3 particules (1,2,3)
% on cherche la meilleure combinaison en comparant leur vraisemblance
% respective :
% L(a,1)  +  L(k,2)  +  L(b,3)  <>
% L(a,1)  +  L(k,3)  +  L(b,2)  <>
% L(a,2)  +  L(k,1)  +  L(b,3)  <>
%   etc.
%
% - T_domain > P_domain
% 3 trajectoires (a,k,b) pour 2 particules : On en cree une 3eme OFF
% (1,2,OFF).
% Alors les tests deviennent :
% L(a,1) + L(k,2)   + L(b,OFF)  <>
% L(a,1) + L(k,OFF) + L(b,2)    <>
% L(a,2) + L(k,1)   + L(b,OFF)  <>
%   etc.
% Dans ce cas, seulement 2 termes de vraisemblance sont
% presents car le troisieme L(T,OFF), probabilite de disparition d'une
% trajectoire, est identique pour toute trajectoires T.
%
% - T_domain < P_domain
% 2 trajectoires (a,k) pour 3 particules (1,2,3) : On cree une nouvelle
% trajectoire (a,k,NEW)
% Alors les tests deviennent :
% L(a,1) + L(k,2)  + L(NEW,3)  <>
% L(a,1) + L(k,3)  + L(NEW,2)  <>
% L(a,2) + L(k,1)  + L(NEW,3)  <>
%   etc.
% La encore, dans ce cas, seulement 2 termes de vraisemblance sont
% presents car le troisieme terme L(NEW,P), probabilite d'apparition
% d'une nouvelle trajectoire dans l'image, est suppose constant.
% Elle ne depend ni de la position, ni de l'intensite.

%% permutation circulaire sur vec_part
%% limite a la taille nb_traj
% nb_part = size(vec_part(:), 1) ;
nb_traj = size(vec_traj(:), 1) ;
best_part = vec_part(1) ;
vec_part_ref = vec_part(1:nb_traj) ;
vrais =  vrais_config_reconnex(vec_traj, vec_part_ref, t, lest, wn,Poids_melange_aplha,Poids_melange_diff,T_off,im_t);%,T)


tab_perms_vec_part = perms(vec_part)' ;
nb_perms = size(tab_perms_vec_part, 2) ;

for p=2:nb_perms
    vec_part_perm = tab_perms_vec_part(:,p) ;
    %% si plus de particules que de traj
    %% cas de nouvelle traj
    %% on test les nb_traj premiere
    vec_part_perm = vec_part_perm(1:nb_traj) ;
    vrais_tmp =  vrais_config_reconnex(vec_traj, vec_part_perm, t, ...
        lest, wn,Poids_melange_aplha,Poids_melange_diff,T_off,im_t);%, T) ;
    
    if (vrais_tmp > vrais)
        vrais = vrais_tmp ;
        best_part = vec_part_perm(1) ;
    end %if
end %for

part = best_part ;

function liste_part = liste_part_boule(liste_part_ref, traj, lest, t,Boule_free)
%finds particles inside search radius of trajectory
% si liste_par_ref == [] alors pas de ref

%% evite les allocations sur des constantes
global tab_param ;
% Boule_free = evalin('base', 'Boule_free');
% global tab_var ;

nb_part = size(lest, 1) ;
dim_liste = size(liste_part_ref,1) ;

if (dim_liste ~= 0)
    %% generation d_un masque
    masque_part_ref = ones(nb_part, 1) ;
    masque_part_ref(liste_part_ref) = 0 ;
end %if

%last spacecoordinates for trajectory
ic = tab_param(traj, 7*t+3) ;
jc = tab_param(traj, 7*t+4) ;
%calc search radius
boule = Boule_free * sigij_free_blink(traj, t) ;

icm = max(ic - boule, 0) ; % en ecart type sur i
icM = ic + boule ; % en ecart type
jcm = max(jc - boule, 0) ; % en ecart type sur j
jcM = jc + boule ; % en ecart type
%
% %% liste locale a la boule (carree!!) <<<====================================!!!
part_boule = ...
    (lest(:,2) < icM) & (lest(:,2) > icm) & ...
    (lest(:,3) < jcM) & (lest(:,3) > jcm) ;

% part_boule = sqrt((lest(:,2)-ic).^2+(lest(:,3)-jc).^2) <= boule; %CPR

%remove the ones already in ref list
if (dim_liste ~= 0)
    part_boule = part_boule & masque_part_ref ;
end %if

liste_new_part = find(part_boule) ;
liste_part = [liste_part_ref; liste_new_part] ;

%%
function sig_free_blk = sigij_free_blink(traj, t)
% EN/ if blink, increase of the std
% traj scalar or vector of trajectories

global tab_param ;
global sig_free;

traj = traj(:) ;
nb_traj = size(traj, 1) ;

%% offset
offset = tab_param(traj, 7*t+8) ;

%% offset de zone de blink nb_blink==(-offset)
%% offset = 0 si non_blink (>0)
%% idem sinon ;
nb_blink = - (offset .* (offset < 0))  ;

%% sigi = sigj
sig_free_blk = sig_free*ones(nb_traj, 1) ;

%% prise en compte du blink pour sig_i/j
sig_free_blk = sig_free_blk .* sqrt(1+nb_blink) ;

%%
function liste_traj = liste_traj_inter(liste_part, traj_ref, lest, t, Boule_free)
% function qui renvoie les trajectoires (non reconnectees)
% dont les boules (espace libre) de recherche intersecte
% au moins une des particules de la liste

global tab_param ;


%% init des trajectoires a tester
traj_boule = zeros(size(tab_param,1), 1) ;

nb_traj = size(tab_param, 1) ;
boules = Boule_free * sigij_free_blink(1:nb_traj, t) ;


for p = liste_part'
    
    ic = lest(p,2) ;
    jc = lest(p,3) ;
    
    %% fenetre de recherche des trajectoires
    %% boule de recherche en ecartype
    icm = max(ic - boules, 0) ;
    icM = ic + boules ;
    jcm = max(jc - boules, 0) ;
    jcM = jc + boules ;
    
    traj_boule = traj_boule | ...
        ((tab_param(:, 7*t+3) < icM) & (tab_param(:, 7*t+3) > icm) & ...
        (tab_param(:, 7*t+4) < jcM) & (tab_param(:, 7*t+4) > jcm)) ;
    
    %    traj_boule = traj_boule | ...
    %        (sqrt((tab_param(:, 7*t+3)-ic).^2+...
    %        (tab_param(:, 7*t+4)-jc).^2)-boules) <= 0; %CPR
    
end %for

%% trajectoires a tester
%% celles non encore reconnectees
traj_boule = traj_boule & (tab_param(:, 7*(t+1)+8) == 0)  ;

%% test 22 11 07 : celles qui ne sont pas blinkee
traj_boule = traj_boule & (tab_param(:, 7*t+8) > 0)  ;

%% on enleve la ref
traj_boule(traj_ref) = 0 ;

%% les trajectoires en question
liste_traj = find(traj_boule) ;


%%
function vrais = vrais_config_reconnex(vec_traj, vec_part, t, lest, wn,Poids_melange_aplha,Poids_melange_diff,T_off,im_t)%,T)
% function qui renvoie la vraisemblance
% d'une configuration de reconnexion/blink
% pour plusieurs trajectoires et particules
%
% les cardinaux des deux vecteurs d'entrees
% sont forcement egaux

% vec_part peut avoir des valeurs nulles
% correspondant aux particules blinkees
% la proba de blink est sans a priori
% et c'est la meme pour tout traj
% toute comparaison ce fera a nombre de
% blink egal, donc on fait rien

vrais = 0 ;
nb_part = size(vec_part(:), 1) ;
for p = 1:nb_part
    part = vec_part(p) ;
    traj = vec_traj(p) ;
    if part ~= 0
        vrais_p = rapport_detection(traj, t, lest, part, wn,Poids_melange_aplha,Poids_melange_diff,T_off,im_t) ;
        vrais = vrais + vrais_p ;
    end %if
end %for

%%
function [out, flag_full_alpha] = rapport_detection(traj, t, lest, part, wn,Poids_melange_aplha,Poids_melange_diff,T_off,im_t)%, T)
% EN/ returns the likelihood for reconnection between
% the particle num_test (in list lest) and the trajectory traj
%
% flag_full_alpha indicates if the particle
% is ON (FULL, belongs to the Gaussian)


%% evite les allocations sur des constantes
global tab_param ;
global tab_moy ;
global tab_var ;
% Poids_melange_aplha = evalin('base', 'Poids_melange_aplha');
% Poids_melange_diff = evalin('base', 'Poids_melange_diff');
% T_off = evalin('base', 'T_off');
% im_t = evalin('base', 'im_t');

N = wn*wn ;% carree

%% ==============================================
%% test glrt avec parametre estime pour new traj
%% ==============================================
%%
%% glrt_1vue : le meme que dans carte_H0H1
%% mais ici calcule pour les parametres estimes
%% pour les particules nouvelles

if (traj<=0)
    
    %% P(x|H1)
    %% deja calcule lors de l'estimation 1 vue
    sig2_H1 = lest(part, 5 ) ;
    LxH1 = -N/2*log(sig2_H1) ; % -N/2
    
    %% P(x|H0)
    %% probleme lors des deflations!!!
    Pi = round(lest(part, 2)) ;
    Pj = round(lest(part, 3)) ;
    di = (1:wn)+Pi-floor(wn/2) ;
    dj = (1:wn)+Pj-floor(wn/2) ;
    im_part = im_t(di, dj) ;
    %   im_part = im_t(dj, di) ;
    sig2_H0 = var(im_part(:)) ;
    LxH0 = -N/2*log(sig2_H0) ; % -N/2
    
    % glrt = -2*( LxH0 - LxH1 ) ;
    out = -2*( LxH0 - LxH1 ) ;
    return ;
    
end%if


%% ==============================================
%% vraisemblance de la reconnexion traj <-> part
%% ==============================================

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% proba de reapparition pendant un blink (blinch)
%% gaussienne > 0
%% nb_blink
if (tab_param(traj, 7*t+8) < 0)
    nb_blink = -tab_param(traj, 7*t+8)  ;
    sig_blink = -T_off/3 ;
    Pblink = 2*inv(sqrt(2*pi)*sig_blink) * exp(-inv(2*sig_blink^2)*nb_blink^2) ;
    Lblink = log(Pblink) ;
else
    % nb_blink = 0 ;
    Lblink = 0 ;
end %if

%%%%%%%%%%%%%%%%%%%%%
%% intensite des pics
%% P(alpha|H1)
%% c'est un melange de loi uniforme et gaussienne
%% on travail a tres faible nombre d'echantillons
%% estimer la proportion uni/gauss est tres difficile

%% ancienne version _old
%% on fait plutot un test de vraisemblance uni/gauss
%% on est don, soit gaussienne, soit uniforme

%% nouvelle version : la loi est une combinaison
%% d'une loi uniforme et gaussienne
%% en effet, l'estimation conjointe des parametres
%% avec melange n'est possible qu'a grand nombre d echantillons
%% ici : a nombre d echantillons reduits on test si
%% le comportement et plutot gaussien ou uniforme (MV)
%% si uniforme, on garde les anciens parametres
%% si gaussien, on met a jour moyenne et variance
%%
%% Attention, les para metres des lois (les stats m, var)
%% sont mis a jour par la fonction mise_a_jour_tab.m
%% dans les tableaux tab_moy et tab_var
%%
%% si modif verifer mise_a_jour_tab.m

alpha =  lest(part, 4 ) ;
alpha_moy = real(tab_moy(traj, 7*t+5)) ; %% sur tout l'echantillon
sig_alpha = tab_var(traj, 7*t+5) ; %% sur tout l'echantillon
%%alpha_max = imag(tab_moy(traj, 7*t+5)) ;
alpha_max = alpha_moy ;

%% gaussienne (1)
Palpha_gaus = inv(sqrt(2*pi)*sig_alpha) * exp(-inv(2*sig_alpha^2)*(alpha-alpha_moy)^2) ;
%% uniforme (2)
if (alpha < alpha_max)
    Palpha_univ = 1/alpha_max ;
else
    Palpha_univ = 0.0 ;
end%if

poids = Poids_melange_aplha ;
Lalpha = log(poids*Palpha_gaus + (1-poids)*Palpha_univ) ;

if (Palpha_gaus > Palpha_univ)
    flag_full_alpha = 1 ;
else
    flag_full_alpha = 0 ;
end%if


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% vraisemblance de traj a intensitee full
%% nb_alpha_full = mod(tab_param(traj,7*t+8), Nb_STK);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% vraisemblance position / mvt brownien (libre/confine)
%% P(n0|H1)
i0 = lest(part, 2) ;
j0 = lest(part, 3) ;
ic = tab_param(traj, 7*t+3) ; % derniere position
jc = tab_param(traj, 7*t+4) ;
% sig_ij_ref = tab_var(traj, 7*t+3);
sig_ij_ref = sigij_blink(traj, t) ;%% avec blk
sig_free_blk = sigij_free_blink(traj, t) ;%% avec blk  !!!

poids = Poids_melange_diff ; %% entre gaussienne ref et gaussienne libre
Pn_ref =  inv(2*pi*sig_ij_ref^2) * exp(- inv(2*sig_ij_ref^2) * ((i0-ic)^2 + (j0-jc)^2)) ;
Pn_free = inv(2*pi*sig_free_blk^2) * exp(- inv(2*sig_free_blk^2) * ((i0-ic)^2 + (j0-jc)^2)) ;
Ln0 = log(poids*Pn_ref + (1-poids)*Pn_free);

%%%%%%%%%%
%% P(r|H1)
r =  lest(part, 6) ;
r_ref = tab_moy(traj, 7*t+6) ;
sig_r_ref = tab_var(traj, 7*t+6) ;
if (sig_r_ref ~= 0)
    Lr = -0.5*log(sig_r_ref) - inv(2*sig_r_ref^2) * (r-r_ref)^2;
else
    Lr = 0 ;
end%if

%% vraisemblance
out = Lalpha + Ln0 + Lblink + 0*Lr;

%%
function sig_blk = sigij_blink(traj, t)
% EN/ if blink, increase of the std

global tab_param ;
global tab_var ;

%% offset de zone de blink nb_blink==(-offset)
if (tab_param(traj, 7*t+8) < 0)
    offset = tab_param(traj, 7*t+8)  ;
else
    offset = 0 ;
end %if

%% sigi = sigj
sig_blk = tab_var(traj, 7*t+3)  ;  %% sur i

%% prise en compte du blink pour sig_i/j
if (offset < 0)
    sig_blk = sig_blk * sqrt(1-offset) ;
end %if


%%
function mise_a_jour_tab(Nb_STK,new_nb_traj,T_off)
% EN/ update of the tables of values
% mean of parameters and variances (std)
global tab_param;
global t_red;
global tab_moy;
global tab_var;
global T;
global sig_free;
%fprintf(stderr,"in maj\n");
%% boucle sur les particules
for iTraj=1:new_nb_traj
    if (tab_param(iTraj, 7*(t_red-1)+8)>T_off)
        %% alpha
        %% modif le 12-11-07
        %% compatibilite avec rapport_detection
        %% suite a la prise en compte de la loi
        %% uniforme + gaussien pour alpha
        %% si modif verifer rapport_detection.m
        %%
        %%param = 5 ;
        %%[moy, sig] = calcul_reference(iTraj, (t_red-1), param, T) ;
        %%tab_moy(iTraj, 7*(t_red-1)+param) = moy ;%% test modif 160307
        %%tab_var(iTraj, 7*(t_red-1)+param) = sig ;
        [moy, sig_alpha] = calcul_reference(5,iTraj,Nb_STK) ;
        alpha_moy = real(moy) ;
        alpha_max = imag(moy) ;
        %% on ne met a jour des stats mean var
        %% que si on est en hypothese gaussienne
        %% sinon on bloque les stats
        %% determination du mode par vraisemblance
        LV_uni = -T*log(alpha_max) ;
        LV_gauss = -T/2*(1+log(2*pi*sig_alpha^2)) ;
        
        if (LV_gauss > LV_uni)
            %% gaussienne (1)
            tab_moy(iTraj, 7*(t_red-1)+5) = alpha_moy + sqrt(-1)*alpha_max ;
            tab_var(iTraj, 7*(t_red-1)+5) = sig_alpha ;
        else
            %% uniforme (2)
            tab_moy(iTraj, 7*(t_red-1)+5) = tab_moy(iTraj, 7*((t_red-1)-1)+5) ;
            tab_var(iTraj, 7*(t_red-1)+5) = tab_var(iTraj, 7*((t_red-1)-1)+5) ;
        end%if
        
        
        %% r
        [moy, sig] = calcul_reference(6,iTraj,Nb_STK) ;
        tab_moy(iTraj, 7*(t_red-1)+6) = moy ;
        tab_var(iTraj, 7*(t_red-1)+6) = sig ;
        
        %% i,j
        [moy, sig_i] = calcul_reference(3,iTraj,Nb_STK) ;
        [moy, sig_j] = calcul_reference(4,iTraj,Nb_STK) ;
        %%tab_moy(iTraj, 7*(t_red-1)+4) = moy ;  %% inutile
        sig_ij = sqrt(0.5*(sig_i^2+sig_j^2)) ;
        if (sig_free < sig_ij)
            %% borne a diff libre
            sig_ij = sig_free ;
        end%if
        tab_var(iTraj, 7*(t_red-1)+3) = sig_ij ;
        tab_var(iTraj, 7*(t_red-1)+4) = sig_ij ;
        
        %% blink pour info
        tab_moy(iTraj, 7*(t_red-1)+8) = tab_param(iTraj, 7*(t_red-1)+8) ;
        tab_var(iTraj, 7*(t_red-1)+8) = tab_param(iTraj, 7*(t_red-1)+8) ;
        
    end %if
end %for
function [param_ref, sig_param] = calcul_reference(param,iTraj,Nb_STK)
%% determine la reference (parametre moyen)
%% et ecart type du param
%% determine sur la derniere zone de non blink
%% et limite a une longueur T
%% moy_alpha et sig_alpha (resp r) gardent leur valeur pendant un blink
%% moy_i/j ne sert pas
%% sig_i/j
%% sig_i/j voient leur valeur augmenter pendant le blink
%% en suivant la variation sqrt(nb_blink)*sig_i_avant_blink
%% pris en compte dans sigij_blink
%% param = 5 : alpha
%% param = 6 : r
%% param = 3 : i
%% param = 4 : j

global tab_param;
global t_red;
global T;
global tab_moy;
global tab_var;
%% offset de zone de blink nb_blink==(-offset)
if (tab_param(iTraj, 7*(t_red-1)+8) < 0)
    offset = tab_param(iTraj, 7*(t_red-1)+8)  ;
else
    offset = 0 ;
end %if

%% duree de la derniere partie ON de la iTraj
nb_on = floor(tab_param(iTraj, 7*((t_red-1)+offset)+8)  / Nb_STK) ; %% correct bug suite modif
if (nb_on > T)
    nb_on = T ;
end %if

seuil = 3+1 ; %T/2

if (nb_on >= seuil)
    
    n=0:(nb_on-1) ;
    local_param = tab_param(iTraj, 7*((t_red-1)+offset-n)+param) ;
    sum_param = sum(local_param) ;
    sum_param2 = sum(local_param.^2) ;
    param_max = max(local_param) ; %% 160307
    param_ref = sum_param / nb_on ;
    sig_param = sqrt( sum_param2 / nb_on - param_ref^2) ;
    
    %% si alpha, il faut aussi la valeur max
    %% en plus de la valeur moyenne
    %% on le met sur l'axe imaginaire! 160307
    if (param == 5)
        param_ref = param_ref + sqrt(-1)*param_max ;
    end%if
    
else
    %% On bloque la valeur a la derniere valeur avant zone de blink
    %% la derniere info valable dans le passe
    if (offset == 0)
        pos_info = 1 ;% la valeur precedente
    else
        pos_info = -offset ; % la derniere valeur avant blink
    end%if
    
    param_ref = tab_moy(iTraj, 7*((t_red-1)-pos_info)+param) ;
    sig_param = tab_var(iTraj, 7*((t_red-1)-pos_info)+param) ;
    
end %if

%%
function vec_traj_out = limite_combi_traj_blk(vec_traj_in, t,Nb_combi)
% limite le nombre de traj
% a celle les plus anciennes (en blink)
% au nombre Nb_combi (global)
% la premiere reste : ref

global tab_param ;
% Nb_combi = evalin('base', 'Nb_combi');

tab_blk = tab_param(vec_traj_in(2:end), 7*t+8) ;
[blk,indice] = sort(tab_blk, 'descend') ;
vec_traj_out = [vec_traj_in(1); vec_traj_in(indice(1:(Nb_combi-1))+1)] ;

%%
function vec_part_out = limite_combi_part_dst(traj, vec_part_in, lest, t,Nb_combi)
% limite le nombre de part
% a celle les plus proche de la ref traj
% au nombre Nb_combi (global)

global tab_param ;
% Nb_combi = evalin('base', 'Nb_combi');

ic = tab_param(traj, 7*t+3) ;
jc = tab_param(traj, 7*t+4) ;
tabi = lest(vec_part_in, 2) ;
tabj = lest(vec_part_in, 3) ;
indice = N_plus_proche(ic, jc, tabi, tabj, Nb_combi) ;
vec_part_out = vec_part_in(indice) ;

%%
function [indice, dist2] = N_plus_proche(ic, jc, liste_i, liste_j, N)
% renvoie les indices des N point les plus proche
% de C(ic,jc)
% dans l'ordre d'eloignement

dim_liste = size(liste_i(:),1) ;
%% distances au point C
sq_dist = (liste_i-ic).^2 + (liste_j-jc).^2 ;
%% classement
[sq_dist_classe, ind_classe] = sort(sq_dist) ;
if (dim_liste > N)
    indice = ind_classe(1:N) ;
    dist2 = sq_dist_classe(1:N) ;
else
    indice = ind_classe ;
    dist2 = sq_dist_classe ;
end%if


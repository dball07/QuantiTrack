function [allProfiles,currentProfileID] = QuantiTrack_ReTrack(hpass,threshold,windowSz,maxJump,shTrack,closeGaps,useParallel,allProfiles,currentProfileID,figH,varargin)
% Redoes the tracking on Mat files that have previously been tracked.
% This allows to easily change the parameters for a group of files without
% the need to load in each one seperately.


[fnamesIn,pnamesIn] = uigetfile('*.mat','Select the MatTrack files to retrack','','MultiSelect','on');


if ~iscell(fnamesIn)
    temp{1,:} = fnamesIn;
    fnamesIn = temp;
end
if ~iscell(pnamesIn)
    temp{1,:} = pnamesIn;
    pnamesIn = temp;
end


if fnamesIn{1} ~= 0
    if nargin < 7
        useParallel = 0;
    end
    if nargin < 8
        savefold = uigetdir(pwd,'Select a save location');
    else
        %setup to save to the database
        %Call the save application to set up
        trackingSaveDir = allProfiles(currentProfileID).trackingSaveDir;
        lastCellProtein = allProfiles(currentProfileID).lastCellProtein;
        lastCondition = allProfiles(currentProfileID).lastCondition;
        lastSession = allProfiles(currentProfileID).lastSession;
        lastName = fnamesIn{1,:};

        qt_save = QuantiTrack_SaveToDatabase(trackingSaveDir,lastCellProtein,...
            lastCondition,lastSession,lastName,figH,get(figH,'Position'));
        waitfor(qt_save);


        save_vars = getappdata(figH,'QuantiTrack_SavePars');
        if isempty(save_vars{1})
            return
        end
        %update the default values
        allProfiles(currentProfileID).trackingSaveDir = save_vars{1};
        allProfiles(currentProfileID).lastCellProtein = save_vars{2};
        allProfiles(currentProfileID).lastCondition  = save_vars{3};
        allProfiles(currentProfileID).lastSession  = save_vars{4};
        % allProfiles(currentProfileID).lastName = [save_vars{5}, '.mat'];

        % allProfiles(currentProfileID).frameTime = frameInterval;
        % allProfiles(currentProfileID).objNA = NA;
        % allProfiles(currentProfileID).pixelSize = pxSize;
        % allProfiles(currentProfileID).lambda = lambda;

        profile = allProfiles(currentProfileID);
        savefold_part = fullfile(profile.trackingSaveDir,profile.lastCellProtein, ...
            profile.lastCondition);
        save_session{1,:} = profile.lastSession;

    end
    %Create a the list of movie filenames and paths if a trackTable is
    %loaded
    if length(fnamesIn) == 1
        IN = load(fullfile(pnamesIn{1,:},fnamesIn{1,:}));
        if isfield(IN,'trackTable')
            for i = 1:height(IN.trackTable)
                fnames{i,:} = IN.trackTable.name{i,:};
                pnames{i,:} = [profile.trackingSaveDir, filesep, IN.trackTable.cell_protein{i,:},...
                    filesep, IN.trackTable.condition{i,:}, filesep, IN.trackTable.session{i,:}];
                save_session{i,:} = IN.trackTable.session{i,:};

            end
        else
            fnames = fnamesIn;
            pnames = pnamesIn;
        end
    else
        
        for i = 1:length(fnamesIn)
            fnames{i,:} = fnamesIn{i};
            pnames{i,:} = pnamesIn{1,:};
            save_session{i,:} = save_session{1,:};
        end
    end

    threshold_spec = threshold;
    windowSz_spec = windowSz;
    maxJump_spec = maxJump;
    shTrack_spec = shTrack;
    closeGaps_spec = closeGaps;



    fprogBar = waitbar(0,'Retracking Files','Name', 'Batch ReTracking','Color', get(0,'defaultUicontrolBackgroundColor'),'Units','pixels');
    pos = get(fprogBar,'Position');
    pos(2) = pos(2) + pos(4) + 30;
    set(fprogBar,'Position',pos);

    for i = 1:length(fnames)
        clear trackingIN
        trackingIN = load([pnames{i,:}, filesep,fnames{i,:}]);
        TrackROIsepAns = 'Yes';
        %         if i == 1 && size(trackingIN.Results.Process.ROIpos,1) > 1
        %             TrackROIsepAns = questdlg('Do you expect particles to move from one ROI to another?','ROI Particle Tracking','Yes','No','Yes');
        %         elseif i == 1
        %             TrackROIsepAns = 'No';
        %         end
        
        %Get the final form of the save folder
        if nargin >= 8
            savefold = fullfile(savefold_part,save_session{i,:});
        end
        
        %Find Particles
        waitbar((i-1)/length(fnames),fprogBar,'Retracking Files - Finding Particles');
        if threshold_spec > 0 && windowSz_spec > 0
            trackingIN.Results.Tracking.Centroids = findParticles(trackingIN.Results.Process.filterStack, threshold, hpass,windowSz,useParallel);

            if trackingIN.Results.isFitPSF
                CentroidInRoi = InsideROIcheck2_ReTrack(trackingIN.Results.Tracking.Centroids, trackingIN.Results.Process.ROIimage);

                Centroid = CentroidInRoi;
                if ~isempty(Centroid)
                    Particles = peak_fit_psf(trackingIN.Results.Data.imageStack,...
                        Centroid,windowSz,windowSz,useParallel);
                    Particles2 = InsideROIcheck2_ReTrack(Particles,trackingIN.Results.Process.ROIimage);
                    trackingIN.Results.Tracking.Particles = Particles2;
                else
                    trackingIN.Results.Tracking.Particles = zeros(1,13);
                end
            end
            % trackingIN.Results.Tracking.Peaks = peaks;
        end
        %         if closeGaps_spec == 0
        %             closeGaps = trackingIN.Results.Parameters.Tracking(6);
        %         else
        closeGaps = closeGaps_spec;
        %         end
        if shTrack_spec == 0
            shTrack = trackingIN.Results.Parameters.Tracking(7);
        else
            shTrack = shTrack_spec;
        end
        if maxJump_spec == 0
            maxJump = trackingIN.Results.Parameters.Tracking(5);
        else
            maxJump = maxJump_spec;

        end
        Trackparam.mem = closeGaps;
        Trackparam.good = shTrack;
        Trackparam.dim         =  2;
        Trackparam.quiet       =  0;

        if trackingIN.Results.isFitPSF % if particle position has been evaluated via PSF fitting
            Particles = trackingIN.Results.Tracking.Particles(:,[10 11 6 13]);
        else
            Particles = trackingIN.Results.Tracking.Centroids(:,[1 2 6 7]);
        end

        if ~isempty(varargin)
            Part_tmp1 = Particles(Particles(:,3) >= varargin{1}(1),:);
            Part_tmp2 = Part_tmp1(Part_tmp1(:,3) <= varargin{1}(2),:);
            Particles = Part_tmp2;
        end
        waitbar((i-1)/length(fnames),fprogBar,'Retracking Files - Tracking Particles');
        if strcmp(TrackROIsepAns,'No')
            %testing tracking individual ROIs separately

            Tracks = cell(max(Particles(:,4)),1);
            TrkPtsAdded = cell(max(Particles(:,4)),1);
            errorcode = zeros(max(Particles(:,4)),1);
            nTrkPtsAdd = 0;
            ROIstring = trackingIN.Results.Process.ROIlabel;
            for m = 1:max(Particles(:,4))
                Particles2Track = Particles(Particles(:,4) == m,1:3);
                if ~isempty(Particles2Track)
                    fprintf('Performing Tracking on %s\n',ROIstring{m,:});
                    fprintf('--------------------------\n');
                    [Tracks{m,:}, TrkPtsAdded{m,:}, errorcode(m,:)] = trackfunctIG(Particles2Track,maxJump,Trackparam);
                    nTrkPtsAdd = nTrkPtsAdd + size(TrkPtsAdded{m,:},1);
                else
                    fprintf('No particles found in %s, so we cannot track in this ROI\n',ROIstring{m,:});
                    Tracks{m,:} = [];
                    TrkPtsAdded{m,:} = [];
                    errorcode(m,:) = 1;
                end
            end

            Tracks_all = [];
            Track_ind = 1;
            % TrkPtsAdded2 = [];
            % for i = 1: size(TrkPtsAdded,1)
            %     TrkPtsAdded2 = [TrkPtsAdded2;TrkPtsAdded{i,:}];
            % end
            for m = 1:size(Tracks,1)
                Tracks{m,:}(:,5) = m*ones(size(Tracks{m,:},1),1);
                Tracks_tmp = Tracks{m,:};

                for j = 1:max(Tracks_tmp(:,4))
                    iTrack = Tracks_tmp(Tracks_tmp(:,4) == j,:);
                    if ~isempty(iTrack)
                        iTrack(:,4) = Track_ind;
                        Track_ind = Track_ind + 1;
                        Tracks_all = [Tracks_all;iTrack];
                        TrkPtsAdded2{Track_ind,:} = TrkPtsAdded{m,:}{j,:};
                    end
                end

                %     TrackPtsAdded2{init_TrkPt:fin_TrkPt,:} = TrkPtsAdded{i,:};

            end

            if ~isempty(Tracks_all)
                Tracks_all2 = sortrows(Tracks_all,3);
                test2 = [];
                used = [];
                t_ind = 1;
                TrkPtsAdded = TrkPtsAdded2;
                TrkPtsAdded2 = cell(size(TrkPtsAdded));
                for m = 1:size(Tracks_all2,1)
                    if isempty(find(Tracks_all2(m,4) == used))
                        test = Tracks_all2(Tracks_all2(:,4) == Tracks_all2(m,4),:);
                        test(:,4) = t_ind;
                        TrkPtsAdded2{t_ind,:} = TrkPtsAdded{Tracks_all2(:,4),:};
                        t_ind = t_ind +1;
                        test2 = [test2;test];

                        used = [used; Tracks_all2(m,4)];
                    end
                end
                TrkPtsAdded = TrkPtsAdded2;
                Tracks = test2;
            else
                TrkPtsAdded = [];
                Tracks = [];
            end
        else
            Particles(Particles(:,1) == 0,:) = [];
            if ~isempty(varargin)
                Particles(:,3) = Particles(:,3) - varargin{1}(1) + 1;
            end
            Part_tmp = [];
            for m = 1:max(Particles(:,3))
                PartInCurFrame = Particles(Particles(:,3) == m,:);
                if ~isempty(PartInCurFrame)
                    Part_tmp = [Part_tmp; PartInCurFrame];
                else
                    addvec = [0 0 m 0];
                    Part_tmp = [Part_tmp; addvec];
                end
            end
            Particles = Part_tmp;

            if ~isempty(Particles)
                [Tracks, TrkPtsAdded, errorcode] = trackfunctIG(Particles(:,1:3),maxJump,Trackparam);
            else
                Tracks = [];
                errorcode = 1;
            end

            %             parameters.Gv = 8;
            %             parameters.Gd = 8;
            %             parameters.Twin = 3;
            %             parameters.shTr = 2;
            %             parameters.gaps = 3;
            %             [Tracks,TrkPtsAdded] = ngaTracking(Particles,parameters);
            %             errorcode = 0;
        end
        if min(errorcode) == 0 && ~isempty(Tracks)
            Tracks = InsideROIcheck2_ReTrack(Tracks,trackingIN.Results.Process.ROIimage);
            trackingIN.Results.Tracking.Tracks = Tracks;
            if trackingIN.Results.isFitPSF
                ParticlesNew = trackingIN.Results.Tracking.Particles;

                x_ind = 10;
                y_ind = 11;
            else
                ParticlesNew = trackingIN.Results.Tracking.Centroids;
                x_ind = 1;
                y_ind = 2;
            end
            Particles = ParticlesNew;
            if ~isempty(varargin)
                Part_tmp1 = Particles(Particles(:,6) >= varargin{1}(1),:);
                Part_tmp2 = Part_tmp1(Part_tmp1(:,6) <= varargin{1}(2),:);
                Particles = Part_tmp2;
                Particles(:,6) = Particles(:,6) - varargin{1}(1) + 1;
                nImages = varargin{1}(2) - varargin{1}(1) + 1;
            else
                nImages = trackingIN.Results.Data.nImages;
            end
            for j = 1:size(Tracks,1)
                x_pos = Tracks(j,1);
                y_pos = Tracks(j,2);
                frame_num = Tracks(j,3);

                pIx1 = find(Particles(:,x_ind) == x_pos & ...
                    Particles(:,y_ind) == y_pos & ...
                    Particles (:,6) == frame_num);
                if isempty(pIx1)
                    ParticleAdd(:,1) = x_pos;
                    ParticleAdd(:,2) = y_pos;
                    ParticleAdd(:,6) = frame_num;
                    if trackingIN.Results.isFitPSF
                        ParticleAdd(:,10:11) = ParticleAdd(:,1:2);
                        ParticleAdd(:,12) = 0;
                        if isfield(trackingIN.Results.Process,'ROIpos')
                            ParticleAdd(:,13) = 0;
                        end
                    else
                        if isfield(trackingIN.Results.Process,'ROIpos')
                            ParticleAdd(:,7) = 0;
                        end
                    end
                    ParticlesNew = [ParticlesNew(:,1:13); ParticleAdd];
                end


            end
            ParticlesNew = InsideROIcheck2_ReTrack(ParticlesNew,trackingIN.Results.Process.ROIimage);
            if trackingIN.Results.isFitPSF
                ParticlesNew = sortrows(ParticlesNew,[6,13]);
                trackingIN.Results.Tracking.Particles = ParticlesNew;
            else
                ParticlesNew = sortrows(ParticlesNew,[6,7]);
                trackingIN.Results.Tracking.Centroids = ParticlesNew;
            end


            %PreAnalysis
            waitbar((i-1)/length(fnames),fprogBar,'Retracking Files - Processing');
            Tracks = trackingIN.Results.Tracking.Tracks;
            %             if trackingIN.Results.isFitPSF
            %                 Particles = trackingIN.Results.Tracking.Particles;
            %             else
            %                 Particles = trackingIN.Results.Tracking.Centroids;
            %             end
            if isfield(trackingIN.Results.Process,'ROICentroid')
                trackingIN.Results.Tracking.TracksROI = [];

                for k = 1:max(trackingIN.Results.Tracking.Tracks(:,4))
                    curTrack = trackingIN.Results.Tracking.Tracks(trackingIN.Results.Tracking.Tracks(:,4) == k,:);
                    curTrack2 = curTrack;
                    curROI = curTrack(1,5);
                    ROICentroid = trackingIN.Results.Process.ROICentroid(curROI,:);
                    %             for j = 1:length(ROICentroid)
                    %                 if ~isempty(ROICentroid{:,j})
                    %                     ROICenter(j,:) = ROICentroid{:,j};
                    %                 else
                    %                     ROICenter(j,:) = [0,0];
                    %                 end
                    %             end
                    %             curTrackROI = ROICenter(curTrack(:,3),:);
                    %
                    %             curTrack2(:,1) = curTrack(:,1) - curTrackROI(:,1);
                    %             curTrack2(:,2) = curTrack(:,2) - curTrackROI(:,2);

                    for j = 1:size(curTrack2,1)

                        im_num = curTrack2(j,3);
                        curPt = curTrack2(j,1:2);
                        ROICenter = ROICentroid{:,im_num};
                        if isempty(ROICenter)
                            ROICenter = [0,0];
                        end
                        CentDist = sqrt((curPt(1,1) - ROICenter(:,1)).^2 + (curPt(1,2) - ROICenter(:,2)).^2);

                        %                 outline = imdilate(handles.Process.ROIimage{curROI,im_num},strel('disk',1)) - handles.Process.ROIimage{curROI,im_num};
                        %                 [x,y] = find(outline > 0);
                        %                 EdgeDist = sqrt((curPt(1,1) - y).^2 + (curPt(1,2) - x).^2);
                        ind = find(CentDist == min(CentDist));
                        %                 x1 = x(ind);
                        %                 y1 = y(ind);
                        curTrack2(j,1) = curTrack2(j,1) - ROICenter(ind,1);
                        curTrack2(j,2) = curTrack2(j,2) - ROICenter(ind,2);
                    end
                    trackingIN.Results.Tracking.TracksROI = [trackingIN.Results.Tracking.TracksROI; curTrack2];
                end
            end
            if isfield(trackingIN.Results.Tracking,'TracksROI')
                TracksROIs = trackingIN.Results.Tracking.TracksROI;
            else
                TracksROIs = [];
            end

            [trackingIN.Results.PreAnalysis.Tracks_um, trackingIN.Results.PreAnalysis.NParticles, trackingIN.Results.PreAnalysis.IntensityHist] = preProcess_noGUI(Tracks,trackingIN.Results.Data.imageStack,...
                trackingIN.Results.Tracking.Particles, trackingIN.Results.Parameters.Acquisition.pixelSize, nImages, trackingIN.Results.Data.fileName,trackingIN.Results.Process.ROIpos);
            if ~isempty(TracksROIs)
                trackingIN.Results.PreAnalysis.TrackROIs_um = trackingIN.Results.PreAnalysis.Tracks_um;
                trackingIN.Results.PreAnalysis.TrackROIs_um(:,1:2) = TracksROIs(:,1:2).*0.117;
            end
            trackingIN.Results.isFitPSF = trackingIN.Results.isFitPSF;
            trackingIN.Results.Analysis = [];
            trackingIN.Results.Parameters.Tracking = [1, hpass, threshold_spec, windowSz_spec, maxJump_spec,closeGaps_spec,shTrack_spec];
            Results = trackingIN.Results;

            Version = 2;
            save([savefold, filesep,fnames{i}(1:end-4),'_Retracked_preprocess.mat'],'Results','Version','-v7.3');
            profile.lastName = [fnames{i}(1:end-4),'_Retracked_preprocess.mat'];
            profile.lastSession = save_session{i,:};

            %set the acquistion parameters to those used in the original
            %file.
            if isfield(trackingIN.Results.Parameters.Acquisition,'pixelSize')
                profile.pixelSize = trackingIN.Results.Parameters.Acquisition.pixelSize;
            end
            
            if isfield(trackingIN.Results.Parameters.Acquisition,'exposureTime')
                profile.exposureTime = trackingIN.Results.Parameters.Acquisition.exposureTime;
            end

            if isfield(trackingIN.Results.Parameters.Acquisition,'frameTime')
                profile.frameTime = trackingIN.Results.Parameters.Acquisition.frameTime;
            end

            if isfield(trackingIN.Results.Parameters.Acquisition,'NA')
                profile.objNA = trackingIN.Results.Parameters.Acquisition.NA;
            end

            if isfield(trackingIN.Results.Parameters.Acquisition,'EmWavelength')
                profile.lambda = trackingIN.Results.Parameters.Acquisition.EmWavelength;
            end

            trackTable = generateTrackTable(Results,profile);
            tt_saveLoc = fullfile(profile.trackingSaveDir,profile.lastCellProtein);

            %Check if there is an existing trackTable for this cell/protein
            preExistingTrackTable = dir(fullfile(tt_saveLoc,'*trackTable*'));

            if ~isempty(preExistingTrackTable)
                input = load(fullfile(tt_saveLoc,preExistingTrackTable(1).name));
                t = input.trackTable;
                last_cellID = t.cellID(height(t));
                last_trackID = t.trackID{height(t)}(end);
                last_movieID = t.movieID(height(t));

                trackTable.cellID = trackTable.cellID + last_cellID;
                trackTable.movieID = trackTable.movieID + last_movieID;
                for j = 1:height(trackTable)
                    trackTable.trackID{j} = trackTable.trackID{j} + last_trackID;
                end

                trackTable = [t; trackTable];
                save(fullfile(tt_saveLoc,preExistingTrackTable(1).name),'trackTable','-v7.3');
            else
                savename  = sprintf('trackTable_%s_%s.mat', profile.lastCellProtein, ...
                    datestr(now, 'yyyy-mm-dd_THHMM'));
                save(fullfile(tt_saveLoc,savename),'trackTable','-v7.3');

            end
        end
        waitbar(i/length(fnames),fprogBar,'Retracking Files');

    end
    delete(fprogBar);
end
function trackTable = generateTrackTable(Results,Defaults)
% creates a track table where each row has the data for a single ROI.
% The output table has the following fields:
%
% cell_protein: name of cell_protein
% condition: name of the condition
% session: name of the session (i.e. date)
% name: name of the tracking mat file
% pixelSize: size of pixels in um
% exposure: exposure time in seconds
% interval: frame interval of the recorded movie in seconds
% trackinParam: parameters used for tracking. format: [lower limit, upper
%       limit, threshold, window size, max jump, shortest track, max. gap]
% X: cell array, with each element the x,y coordinates for the track
% xyt: same as X, but also contains the frame number in column 3
% trackID: unique identifiers across all entries of the tracks
% ROI_ID: id of the ROIs inside of the movie
% ROI_name: string used for the name of the ROI
% ROI_class: class name of the ROI. If no class is specified, this will be
% an empty string.
% cell_ID: unique identifiers across all entries of the ROIs
% movie_ID: unique identifier for the movie that the data came from (maybe
%       unnecessary)
% Loc_precision: localization precision in um for the identified particles
% NParticles: number of particles detected in the ROI over time
% NParticlesTracked: number of tracked particles over time
% Particle_SNR: signal-to-noise ratio of all tracked particles
% Track_JumpDist1: distance each particle jumped from one frame to the next
% Track_nextNearestD: distance to the 2 closest detections in the
%       subsequent frame for all tracked particles

tic
%determine how many ROIs are present
ROIs = unique(Results.Tracking.Tracks(:,5));
nROIs = length(ROIs);

%initialize the different variables
cell_protein = cell(nROIs,1);
condition = cell(nROIs,1);
session = cell(nROIs,1);
name = cell(nROIs,1);
pixelSize = zeros(nROIs,1);
exposure = zeros(nROIs,1);
interval = zeros(nROIs,1);
trackingParam = cell(nROIs,1);
X = cell(nROIs,1);
xyt = cell(nROIs,1);
trackID = cell(nROIs,1);
ROI_ID = zeros(nROIs,1);
ROI_name = cell(nROIs,1);
ROI_class = cell(nROIs,1);
cellID = zeros(nROIs,1);
movieID = zeros(nROIs,1);
NParticles = cell(nROIs,1);
NParticlesTracked = cell(nROIs,1);
Particle_SNR = cell(nROIs,1);
Track_JumpDist = cell(nROIs,1);
Track_nearest2Dist = cell(nROIs,1);
Loc_precision = zeros(nROIs,1);


track_counter = 1;
ROI_counter = 1;
for i = 1:length(ROIs)
    %get tracks and particles only from the current ROI
    tracks_um = Results.PreAnalysis.Tracks_um(Results.PreAnalysis.Tracks_um(:,5) == ROIs(i),:);
    if ~isfield(Results.Tracking,'CheckTracks')
        tracks = Results.Tracking.Tracks(Results.Tracking.Tracks(:,5) == ROIs(i),:);
    else
        if isempty(Results.Tracking.CheckTracks)
            tracks = Results.Tracking.Tracks(Results.Tracking.Tracks(:,5) == ROIs(i),:);
        else
            tracks_check = Results.Tracking.CheckTracks(Results.Tracking.CheckTracks(:,5) == ROIs(i),:);
            tracks_raw = Results.Tracking.Tracks(Results.Tracking.Tracks(:,5) == ROIs(i),:);
            if size(tracks_um,1) == size(tracks_check,1)
                tracks = tracks_check;
            else
                tracks = tracks_raw;
            end
        end
    end

    %add the preanalysis parts
    
    tracks = [tracks, tracks_um(:,6:end)];

    particlesROI = Results.Tracking.Particles(Results.Tracking.Particles(:,13) == ROIs(i),:);
    particles = Results.Tracking.Particles;

    cell_protein{i,:} = Defaults.lastCellProtein;
    condition{i,:} = Defaults.lastCondition;
    session{i,:} = Defaults.lastSession;
    name{i,:} = Defaults.lastName;
    pixelSize(i,:) = Defaults.pixelSize;

    exposure(i,:) = Defaults.exposureTime;
    interval(i,:) = Defaults.frameTime;
    trackingParam{i,:} = Results.Parameters.Tracking;


    %reformat the tracks into a cell array
    trackIDs_present = unique(tracks(:,4));
    trackID_vec = [];

    for j = 1:length(trackIDs_present)

        curROItracks = tracks(tracks(:,4) == trackIDs_present(j),1:3);
        X{i,:}{j} = curROItracks(:,1:2).*pixelSize(1);
        xyt{i,:}{j} = [X{i,:}{j}, curROItracks(:,3)];
        trackID_vec = [trackID_vec; track_counter];
        track_counter = track_counter + 1;
    end

    trackID{i,:} = trackID_vec;
    ROI_ID(i,:) = ROIs(i);
    ROI_name{i,:} = Results.Process.ROIlabel{ROIs(i),:};
    if (length(Results.Process.ROIClass) < nROIs || ~iscell(Results.Process.ROIClass{1}))
        ROI_class{i,:} = '';
    else
        tmp = Results.Process.ROIClass{ROIs(i),:};
        if iscell(tmp)
            tmp = tmp{1,:};
        end
        ROI_class{i,:} = tmp;
    end
    cellID(i,:) = ROI_counter;
    ROI_counter = ROI_counter + 1;
    movieID(i,:) = 1;
    
    %get the number of particles detected and tracked
    NParticles{i,:} = Results.PreAnalysis.NParticles(:,ROIs(i)+1);
    nFrames = length(NParticles{i,:});
    if ~isfield(Results.PreAnalysis,'NParticlesTracked')
        NParticlesTracked{i,:} = CalculateTrackedParticles(tracks,nFrames);
    else
        NParticlesTracked{i,:} = Results.PreAnalysis.NParticlesTracked(:,ROIs(i)+1);
    end

       
    %calculate the SNR for the ROI's tracks
    
    Particle_SNR{i,:} = (tracks(:,6) - tracks(:,7))./sqrt(tracks(:,6));
    
    %calculate the tracked particles' jump distance and other nearest
    %neighbor
    [Track_JumpDist{i,:},Track_nearest2Dist{i,:}] = calcTrack_NN(tracks,particles);
    if size(particlesROI,2) > 13
        %calculate the localization precision
        CI95_xy_px = particlesROI(:,17:18);
        CI95_xy_px(CI95_xy_px(:,1) == 0 | CI95_xy_px(:,2) == 0,:) = [];
        CI95_px = CI95_xy_px.^2;
        CI95_px = sum(CI95_px,2);
        CI95_px = sqrt(CI95_px);
    
        md_CI95_px = median(CI95_px);
        %convert 95% confidence interval to standard deviation (assumes a
        %normal distribution)
        loc_prec_px = md_CI95_px./1.96;
        
    
        Loc_precision(i,:) = loc_prec_px.*pixelSize(i,:);
    else
        Loc_precision(i,:) = 0;
    end
    
end

trackTable  = table(cell_protein, condition, session, name, pixelSize,...
    exposure,interval,Loc_precision, trackingParam, X, xyt, trackID, ...
    ROI_ID, ROI_name, ROI_class, cellID, movieID,NParticles, ...
    NParticlesTracked, Particle_SNR, ...
    Track_JumpDist, Track_nearest2Dist);

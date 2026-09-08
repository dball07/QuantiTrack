function [tlist, rlist, JDH,jd1] = calculateJDH(tracks, nJumps,bin_edges,timeStep)
% Calculate JDH
% Calculate the Jump histogram distibution from experimental tracks.
% The calculation is calculated for different time lags (DeltaT,
% 2DeltaT,...).
% INPUT:
% tracks: tracks as produced by the track.m routine. In brief
%         tracks(:,1) =  x_coordinate (in microns)
%         tracks(:,2) =  y_coordinate (in microns)
%         tracks(:,3) =  frame identifier
%         tracks(:,4) =  particle identifier
%
% nJumps: longest time window for jumps calculation
%         (i.e. nJumps = 10 calculates the jumps for
%          up to 10 frames time interval)
%
% bin_edges: vector containing the edges of the Jump distance histogram
%            bins
%
% timeStep: scalar the time between different frames
%
% Normalize Flag: if 0 each jump is equally contributing to the histogram
%               : if 1 the jump contribute as 1/(LT-n) (with LT being the
%                      length of the track and n being the number of frames
%                      for which the current jump is calculated.
%                      This allow to prevent overweighting of the Jump
%                      Histograms at shorter intervals (which produce more
%                      jumps).
%
% Plot Flag: if 0 no plot is produced
%           if 1 a xyz plot is produced
%           if 2 an "heat map" plot is produced
%
% OUTPUT
% tlist = [t1; t2; ...t_maxFrameN)
% rList is a column vector vector with the coordinates corresponding to the centers of
% the histogram bins: rlist = [r1; r2; ...]
% JDH is a matrix with the Jump distance histograms with the following
% structure:
%
%           |  JDH(r1, t1)      JDH(r2, t1)    ...      JDH(rmax, t1)   |
%           |  JDH(r1, t2)      JDH(r2, t2)    ...      JDH(rmax, t2)   |
%  JDH    = |      ...              ...        ...           ...        |
%           |  JDH(r1, tmax)    JDH(r2, tmax)   ...     JDH(rmax, tmax) |
%
%--------------------------------------------------------------------------


% CALCULATE JUMP HISTOGRAM DISTRIBUTION

% Initialize useful variables
jd = [];                                    % temp variable containing the jumps;
JDH = zeros(nJumps, length(bin_edges)-1);     % Initialize Jump histogram distribution;
nTracks = max(tracks(:,4));                 % number of tracks;
TrackLength = zeros(nTracks, 1);            % Initialize vector containing track length;

nJump4D = 1;

jd1 = [];
for j = 1:nJumps    % for loop on different jump sizes
    % (1 frame, 2 frames, etc)

    for i = 1:nTracks       % loop on the different tracks.

        idx = find(tracks(:,4) == i);       % find the track identified by i
        TrackLength(i) = length(idx);       % compute the length of the i-th track

        if  TrackLength(i) >j

            jd_temp_x = tracks(idx,1);      % Calculate jumps for the i-th
            jd_temp_y = tracks(idx,2);      % track with the j-th interval

            jd_temp = sqrt((jd_temp_x(j+1:end)- jd_temp_x(1:end-j)).^2 + ...
                (jd_temp_y(j+1:end)- jd_temp_y(1:end-j)).^2);

            jd =  cat(1,jd,jd_temp);




        end


    end

    if ~isempty(jd) % if Normalize flag is set to zero

        JDH(j,:) = histcounts(jd,  bin_edges);           % calculate the JDH for
        % each interval at the
    end                                             % end of the loop on the
    % different tracks
    if j == nJump4D
        jd1 = jd;
    end
    jd = [];

end


% CALCULATE r AND t;

rlist = bin_edges(1:end-1)+(bin_edges(2)-bin_edges(1))/2;
rlist = rlist';
tlist = (1:nJumps)*timeStep;
tlist = tlist';

end
function [lags,msd,num_lag_tracks] = msdcalc_new(tracks,segment_length)
% [x1,msd,num_lag_tracks] = msdcalc_new(tracks)
% Function to calculate msds of unevenly sampled data (e.g. MINFLUX)
% Input
%   tracks: array of minflux tracks
%           column 1,2 are the x-y coordinates 
%           column 3 is the time stamps
%           column 4 is the particle id
%  
% Output:
%           lags: vector of timelags
%           msd: mean squared displacement
%           num_lag_tracks: number of track segments averaged over per lag

num_particles = max(tracks(:,4)); % number of particles tracked in the file
track_msd = {};
num_lags={};
k=1;
idx = find(tracks(:,4)==1);
[interv,ndt] = mode(diff(tracks(:,3))); % find the likely sampling interval
if(ndt>0.1*length(idx))
    interval = interv; % if dt is roughly quantized
else
    interval = 0.250e-3; % else force an interval of 250 microseconds
end
if nargin < 2
    segment_length = 2; % data is split into 2 second chunks. Can specify longer but pdist would produce
                    %  an n_sample*n_sample matrix that increases quadratically in size for longer segments
end

for ipart = 1:num_particles
    idx = find(tracks(:,4)==ipart);
    if(length(idx)>10) % track should be at least 10 frames long
        vec=tracks(idx,1:3);
        vec(:,3) = vec(:,3)-vec(1,3);
        maxtime = vec(end,3); % length of track in seconds
        nseg = floor(maxtime/segment_length)+1; % number of segments in the track
        sprintf('computing for track %d, number of segments %d',ipart,nseg)
        for iseg = 1:nseg
            idx = find(vec(:,3)>segment_length*(iseg-1) & vec(:,3) < segment_length*iseg);
            if(length(idx)>10) %make sure that the remaining segment is long enough
                Dx=pdist(vec(idx,1)); % calculate pairwise jump for each position from a different position
                Dy=pdist(vec(idx,2)); %
                D=(Dx.^2+Dy.^2);
                dt=pdist(vec(idx,3)); % calculate time interval for each displacement
                nbins=floor(max(dt)/interval)+2;
                sprintf('max dt %f and number of bins %d in segment %d in particle %d',max(dt),nbins,iseg,ipart)
                [N,edges,bin]=histcounts(dt,linspace(0,(nbins-1)*interval,nbins)); % bin all time increments
                m=1;
                for ii=1:length(edges)-1
                    track_msd{k}(m)=sum(D((bin==ii))); % accumulate displacements belonging to each time-lag bin
                    num_lags{k}(m)= N(m);
                    m = m+1;
                end
                k=k+1;
            end
        end
    end
end
npts = floor((segment_length+interval)/interval);
e_msd=zeros(npts,1);
num_lag_tracks=zeros(npts,1);
%e_var=[];
for itrack=1:k-1
    for lagtime=1:length(track_msd{itrack})
        e_msd(lagtime)=e_msd(lagtime)+track_msd{itrack}(lagtime); % ensemble average (<ave> = n_seg1*msd_1+...n_segn*msd_n/(nseg_1...+nseg_n))
        %e_var(lagtime)=e_var(lagtime)+(num_lags{itrack}(lagtime)-1)*track_std{itrack}(lagtime);
        num_lag_tracks(lagtime) = num_lag_tracks(lagtime)+num_lags{itrack}(lagtime);
    end
end
edges = linspace(0,segment_length+interval,npts);
lags = 0.5*(edges(1:end-1)+edges(2:end));
lags = lags(1:floor(0.9*npts));
msd = e_msd(1:floor(0.9*npts))./num_lag_tracks(1:floor(0.9*npts));
%e_var = sqrt(e_var)./(num_lags_tracks-k-1);
% msd_err(:,igroup) = 2.576*e_var; %99% confidence interval

end


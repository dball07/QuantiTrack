function [vanHove,jumps] = RL_vanHoveCorrCalc(tracks, lagtime, nbins, jump_thresh, maxBin, filtImmobile_flag, immobileThresh, minTrackLengthImm)

% calculates van Hove correlation at a lag lagtime
% van Hove correlation is defined as G(r,tau) =
% <delta(r-\vert(r(tau+t_0)-r(tau)\vert)> where the average is over the initial
% positions of the particle in the trajectory and delta is the Dirac delta
% function
%
% Required Inputs: 
%       tracks: cell array with (x,y) positions of tracked particles
%       lagtime: index of desired lag
%        
% Optional Inputs:
%       nbins: number of points the vanHove curve will have (default: 200)
%       jump_thresh: minumum distance that molecule must move in order to
%           be considered in the vanHove calculation (default: 0.002 um)
%       maxBin: distance used in the last bin of the vanHocve curve. Note
%           that the actual last bin is [maxBin*lagtime]. (default: 0.4 um) 
%       filtImmobile_flag : flag to determine whether immobile tracks should be 
%           removed from analysis(default: 0)
%       immobileThresh: minimum msd to be considered immobile. Typically 
%           2-4x localization precision^2 (default: 0.0019 um^2)
%       minTrackLengthImm: minimum track length to consider immobility. If
%       a track is less than this length, it is impossible to determine.
%       (default: 7)
%       
%        
% Output: 
%       vanHove: vanHove correlation (first column is the bins, second
%       column is the correlation values
%       jumps: array of displacements

%parse inputs and set missing parameters to the default
if nargin < 3 || isempty(nbins)
    nbins = 200;
end

if nargin < 4 || isempty(jump_thresh)
    jump_thresh = 2e-3; %2 nm
end

if nargin < 5 || isempty(maxBin)
    maxBin = 0.4; %400 nm
end

if nargin < 6 || isempty(filtImmobile_flag)
    filtImmobile_flag = 0;
end

if nargin < 7 || isempty(immobileThresh)
    immobileThresh = 0.0019;
end

if nargin < 8 || isempty(minTrackLengthImm)
    minTrackLengthImm = 7;
end


vH = zeros(1,nbins); %unnormalized vanHove correlation

edges=linspace(jump_thresh,maxBin,nbins+1); % set up edges of bins to be from jump_thresh to maxBin

jumps=[];

%filter out immobile molecules if desired
immobile_tracks=[];
if filtImmobile_flag == 1
    k=1;
    
    for i=1:length(tracks)
        if size(tracks{i},1) >= minTrackLengthImm
            x=tracks{i}(:,1);
            y=tracks{i}(:,2);
            rsq = ((x(lagtime+1:end)-x(1:end-lagtime)).^2+(y(lagtime+1:end)-y(1:end-lagtime)).^2);
            mrsq=mean(rsq);
            if mrsq <= immobileThresh
                immobile_tracks(k) = i;
                k=k+1;
            end
        end
    end
end

%Perform the calculation
for i=1:length(tracks)
    if length(tracks{i})>lagtime && isempty(find(immobile_tracks==i,1,'first'))
        x = tracks{i}(:,1); %in um
        y = tracks{i}(:,2); %in um
        r = sqrt((x(lagtime+1:end)-x(1:end-lagtime)).^2+(y(lagtime+1:end)-y(1:end-lagtime)).^2);
        jumps = [jumps;r];
        r_good = r(r > jump_thresh);
        if ~isempty(r_good)
            [vanHove,bins] = histcounts(r_good,edges); % bin the jumps for each track (discard all jumps that are close to localization precision)
            vH = vH + vanHove/length(r_good); % accumulate the histogram after averaging for the number of initial positions
        end
    end
end

bins = 0.5*(bins(2:end)+bins(1:end-1)); % bin centers
vH = vH./(2*pi*bins); % for radial van Hove, need to divide by 2\pi r  ;
vanHove = vH/(trapz(bins,2*pi*bins.*vH)); % convert to PDF by normalizing
vanHove = [bins(:),vanHove(:)];
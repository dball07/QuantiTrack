function computed_quantities = RL_TrackAnalysis(tracks, interval, lagtime, nbins, jump_thresh, maxBin, filtImmobile_flag, immobileThresh, minTrackLength, Niter, MSDmin, MSDmax, MSDnBins)
% Driver function for the Richardson Lucy algorithm
% Inputs:
%       tracks: cell array of tracks (in Kaustubh's format)
%       lagtime: lag to calculate RL analysis 
%
% Outputs:
%       
%       computed_quantities: struct containing 
%       - P1norm: P(MSD)
%       - vanHove: van Hove Correlation with bins in first column
%       - lagtime: lag used to perform analysis
%       - Gs: estimated vHC
%       - classified_tracks: state that each track falls into
%       - msd: ensamble MSD curve for all tracks
%       - msderr: standard error for the MSD curve
%       - fits: fits of the MSD curves for the RL groups to power-law
%       - fitci: 95% confidence intervals for the MSD fits
%


%Parse inputs and set missing parameters to the default

if nargin < 3 || isempty(lagtime)
    lagtime = 5;
end
if nargin < 4 || isempty(nbins)
    nbins = 200;
end
if nargin < 5 || isempty(jump_thresh)
    jump_thresh = 2e-3; %2 nm
end
if nargin < 6 || isempty(maxBin)
    maxBin = 0.4; %400 nm
end
if nargin < 7 || isempty(filtImmobile_flag)
    filtImmobile_flag = 0;
end
if nargin < 8 || isempty(immobileThresh)
    immobileThresh = 0.0019;
end
if nargin < 9 || isempty(minTrackLength)
    minTrackLength = 7;
end
if nargin < 10 || isempty(Niter)
    Niter = 50000;
end
if nargin < 11 || isempty(MSDmin)
    MSDmin = 1e-4;
end
if nargin < 12 || isempty(MSDmax)
    MSDmax = 0.25;
end
if nargin < 13 || isempty(MSDnBins)
    MSDnBins = 400;
end

d = waitbar(0,'Calculating van Hove Correlation ','Name','RL analysis');

%Calculate the van Hove Correlation for the tracks
vanHove = RL_vanHoveCorrCalc(tracks, lagtime, nbins, jump_thresh, maxBin, filtImmobile_flag, immobileThresh, minTrackLength);

%Use the RL algorithm to fit the vanHove correlation to a composition of
%multiple diffusion states
waitbar(0.25,d,'Fitting van Hove Correlation');
[P1norm,Gs] = RL_fitVanHove(vanHove,Niter,MSDmin,MSDmax,MSDnBins);

%Classify each track to be the differnt states extracted from fitting the
%van Hove corrleation
waitbar(0.5,d,'Classifying Tracks');
classified_tracks = RL_classifyTracks(tracks,P1norm,lagtime, minTrackLength); %classify tracks based on the RL P(MSD) distribution

%Calculate the MSD curves for the different groups
classIDs = unique(classified_tracks);

waitbar(0.75,d,'Calculating MSDs');
for i = 1:length(classIDs)
    tracks_class = tracks(classified_tracks == classIDs(i));
    for j = 1:length(tracks_class)
        curTrack = tracks_class{j};
        T = (0:interval:(size(curTrack,1)-1)*interval)';
        tracks_class{j} = [T, curTrack];
    end
    ma = msdanalyzer(2, 'µm', 's');     % Initialize the msdanalyzer class
    ma = ma.addAll(tracks_class);
    ma = ma.computeMSD;

    mmsd = ma.getMeanMSD;
    t = mmsd(:,1);
    x  = mmsd(:,2);
    dx  = mmsd(:,3)./sqrt(mmsd(:,4));
    msd{i,:} = [t(:), x(:)];
    msd_err{i,:} = dx;

    [Pwr_Coef, Pwr_Sigma] = PwrLawGrowth_nlinfit([t(2:end,:),x(2:end,:)],1);
    fits(i,:) = Pwr_Coef;
    fitci(i,:) = Pwr_Sigma;
%     Power Law Fit is to F(t) = Pwr_Coef(2)*t^(Pwr_Coef(1)). Ifany downstream code
%     used the parameters in a different order uncomment below

%     fits(i,:) = [Pwr_Coef(2), Pwr_Coef(1)]; 
%     fitci(i,:) = [Pwr_Sigma(2), Pwr_Sigma(1)];


end

% Returning a structure with different fields so
% one does not need to compute everything all over again.

computed_quantities.lagtime = lagtime; %lagtime for computation

computed_quantities.vanHove = vanHove; % van Hove correlation
computed_quantities.P1norm = P1norm; % P(M)
computed_quantities.Gs = Gs; % estimated vHC
computed_quantities.classified_tracks = classified_tracks; %cell array of classified tracks
computed_quantities.msd = msd; % mean squared displacement of all tracks for all groups
computed_quantities.msderr = msd_err; % error in msd
computed_quantities.fits = fits; %msd fits
computed_quantities.fitci = fitci; % confidence interval of fits

waitbar(1,d,'Calculating MSDs');
delete(d);

function pEM_overlayMovieFromSummary(summary_table,summary_path,deltaPP_th,maxPP_th,movieFPS,windowSz,minTrackLength,minBright,maxBright)

%generates a movie of single molecules overlaid with the tracks color-coded
%with the pEM state

if nargin < 2 || isempty(summary_table) || isempty(summary_path)
    [summary_file, summary_path]    = uigetfile('*.mat','Select Summary table to open');
    if summary_file == 0
        return;
    end

    IN = load(fullfile(summary_path, summary_file));
    if isfield(IN,'meta_analysis')
        summary_table = IN.meta_analysis;
    elseif isfield(IN,'summary_table')
        summary_table = IN.summary_table;
    else
        errordlg('Movies can currently only be calculated on meta_analysis or summary table variables');
        return;
    end

end

if nargin < 3 || isempty(deltaPP_th)
    deltaPP_th = 0.2;
end

if nargin < 4 || isempty(maxPP_th)
    maxPP_th = 0;
end
if nargin < 5 || isempty(movieFPS)
    movieFPS = 10;
end
if nargin < 6 || isempty(windowSz)
    windowSz = 16;
end


if nargin < 7 || isempty(minTrackLength)
    minTrackLength = 100;
end


if nargin < 8 || isempty(minBright)
    minBright = 1000;
end

if nargin < 9 || isempty(maxBright)
    maxBright = 6000;
end



%go through each entry in the summary_table
for i = 1:height(summary_table)
    %load in pEM results file which should include the trackTable
    pemFile = summary_table.pEMFile{i,:};
    states_deltaPP = summary_table.states_deltaPP{i,:};
    pemLocation = dir(fullfile(summary_path,'**',pemFile));
    
    %if we don't automatically find in hte current folder, we will need to
    %manually select it
    if isempty(pemLocation)
        [pemFile, pemFolder] = uigetfile(pemFile,'Select pEM_results.mat file',pemFile);
        if pemFile == 0
            continue
        end
        pEM_in = load(fullfile(pemFolder,pemFile));
    else
        pEM_in = load(fullfile(pemLocation(1).folder,pemLocation(1).name));
        pEMFolder = pemLocation(1).folder;
    end
    trackTable = pEM_in.trackTable;
    pEMTable = pEM_in.pEMTable;

    pEM_overlayMovie(pEMTable,trackTable,pEMFolder,deltaPP_th,maxPP_th,movieFPS,windowSz,states_deltaPP,minTrackLength,minBright,maxBright);
end


end
function compileMSD_Batch(varargin)

%Calculates the MSD for tracks in files that are selected by the user.
%Saves a mat file containing the relevant statistics for each file selected

if isempty(varargin)
    prec = 5;
else
    prec = varargin{1};
end

[files, path] = uigetfile('*.mat','Select Tracking files to analyze with MSD','','MultiSelect','on');

if ~iscell(files)
    files_tmp{1} = files;
    files = files_tmp;
end

if files{1} == 0
    return;
end
outpath = uigetdir(path,'Choose the location to save the MSD data');
for i = 1:length(files)
    fprintf('Computing MSD for file %d of %d ...\n ', i, length(files));
    IN = load(fullfile(path,files{i}));
    if isfield(IN,'tracks')
        tracks = IN.tracks;
    else
        tracks = IN.Results.PreAnalysis.Tracks_um;
        tracks(:,1:2) = tracks(:,1:2)*1e-6;
        tracks(:,3) = tracks(:,3)*0.2;
    end
    fprintf('Number of Tracks = %d\n',max(tracks(:,4)));
    
    MSD = compileDisplacements(tracks,prec);
    
    savename = [files{i}(1:end-4),'_MSD_data.mat'];
    
    save(fullfile(outpath,savename),'MSD');
end

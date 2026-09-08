function [Tracks, NParticles, ROIChoice, n_ROIs, NParticlesTracked, Particle_SNR, Track_JumpDist1, Track_nextNearestD, Particles, pixelSize,maxJump,Loc_prec] = compileTracksFromFiles(filenames,path_in,maxTimeIn,fig_h,filetype_str)

if nargin > 4
    progTitleStr = ['Loading in ', filetype_str, ' Files'];
else
    progTitleStr = 'Loading in Files';
end

nFiles = length(filenames);

% get the tracks of the selected files
% open each mat-files and retrieve useful information
ROIChoice = {};
ROIorClass = -1; % -1: not chosen, 0: ROI name, 1: Class Name

n_ROIs = 0;
Tracks = cell(nFiles,1);
Particles = cell(nFiles,1);
NParticles = cell(nFiles,1);
if ~isempty(fig_h)
    d = uiprogressdlg(fig_h,'Title',progTitleStr);
    d.Value = 0;
else
    d = waitbar(0,['Reading File 1 of ', num2str(nFiles)],'Name',progTitleStr);
end
for i = 1:nFiles
    %Display the appropriate type of progress bar
    if ~isempty(fig_h)
        d.Message = ['Reading File ', num2str(i), ' of ', num2str(nFiles)];
    else
        waitbar((i-1)/nFiles,d,['Reading File ', num2str(i), ' of ', num2str(nFiles)]);
    end
    
    ROIidx = 0;

    Temp = load([path_in,filenames{i}],'Results');
    if i == 1
        maxJump = Temp.Results.Parameters.Tracking(5);
        pixelSize = Temp.Results.Parameters.Acquisition.pixelSize;
    end

    if isfield(Temp.Results, 'PreAnalysis') && ...
            isfield(Temp.Results.PreAnalysis, 'Tracks_um')
        if maxTimeIn == 0
            maxTime = Temp.Results.Data.nImages;
        else
            maxTime = maxTimeIn;
        end

        
        if isfield(Temp.Results.PreAnalysis,'TrackROIs_um')
            Tracks{i} = Temp.Results.PreAnalysis.TrackROIs_um(Temp.Results.PreAnalysis.TrackROIs_um(:,3) <= maxTime,:);
        else
            Tracks{i} = Temp.Results.PreAnalysis.Tracks_um(Temp.Results.PreAnalysis.Tracks_um(:,3) <= maxTime,:);
        end
        if Temp.Results.isFitPSF
            Particles{i} = Temp.Results.Tracking.Particles(Temp.Results.Tracking.Particles(:,6) <= maxTime,:);
        else
            Particles{i} = Temp.Results.Tracking.Centroids(Temp.Results.Tracking.Particles(:,6) <= maxTime,:);
        end
        NParticles{i} = Temp.Results.PreAnalysis.NParticles(Temp.Results.PreAnalysis.NParticles(:,1) <= maxTime,:);
        
        %Get the number of particles tracked over time if available
        if isfield(Temp.Results.PreAnalysis,'NParticlesTracked')
            NParticlesTracked{i} = Temp.Results.PreAnalysis.NParticlesTracked(Temp.Results.PreAnalysis.NParticlesTracked(:,1) <= maxTime,:);
        else
            NParticlesTracked{i} = -1;
        end

        %Get the Signal to Noise ratio of the tracked particles if
        %available
        if isfield(Temp.Results.PreAnalysis,'Particle_SNR')
            Particle_SNR{i} = Temp.Results.PreAnalysis.Particle_SNR(Temp.Results.PreAnalysis.Tracks_um(:,3) <= maxTime,:);
        else
            Particle_SNR{i} = -1;
        end
        
        %Get the 1-frame jump distance in px if available
        if isfield(Temp.Results.PreAnalysis,'Track_JumpDist1')
            Track_JumpDist1{i} = Temp.Results.PreAnalysis.Track_JumpDist1;
        else
            Track_JumpDist1{i} = -1;
        end

        %Get the 2nd nearest neighbor values
        if isfield(Temp.Results.PreAnalysis,'Track_nextNearestD')
            Track_nextNearestD{i} = Temp.Results.PreAnalysis.Track_nextNearestD;
        else
            Track_nextNearestD{i} = -1;
        end
        
        if isfield(Temp.Results.Tracking,'LocPrecision_px')
            Loc_prec(i) = Temp.Results.Tracking.LocPrecision_px(1).*pixelSize;
        else

            if size(Particles{i},2) > 13
                %calculate the localization precision
                CI95_xy_px = Particles{i}(:,17:18);
                CI95_xy_px(CI95_xy_px(:,1) == 0 | CI95_xy_px(:,2) == 0,:) = [];
                CI95_px = CI95_xy_px.^2;
                CI95_px = sum(CI95_px,2);
                CI95_px = sqrt(CI95_px);

                md_CI95_px = median(CI95_px);
                %convert 95% confidence interval to standard deviation (assumes a
                %normal distribution)
                loc_prec_px = md_CI95_px./1.96;


                Loc_prec(i) = loc_prec_px.*pixelSize(i,:);
            else
                Loc_prec(i) = 0;
            end
        end

            
        
        if isfield(Temp.Results,'Process') %check that the strcutures exist
            if isfield(Temp.Results.Process,'ROIlabel')
                if isfield(Temp.Results.Process,'AllROIClasses') && ROIorClass == -1
                    ROIClass =  questdlg('Do you want to separate data based on ROI names or Class Names?','ROI or Class','ROI','Class','Class');
                    if strcmp(ROIClass,'ROI')
                        ROIorClass = 0;
                    else
                        ROIorClass = 1;
                    end
                elseif ~isfield(Temp.Results.Process,'AllROIClasses')
                    ROIorClass = 0;
                end
                if ROIorClass == 0
                    roiLabels = Temp.Results.Process.ROIlabel;
                elseif ROIorClass == 1
                    if ~isfield(Temp.Results.Process,'AllROIClasses')
                        errordlg(['File does not contain Class data: ,' filenames{i}]);
                    else
                        roiLabels = Temp.Results.Process.AllROIClasses;
                    end
                end
                if size(roiLabels,1) > 1 || ~isempty(ROIChoice)
                    if ~isempty(ROIChoice) %if a named ROI was selected before check to see if an ROI with that name exists in this dataset
                        if sum(strcmp(ROIChoice,'All')) == 0
                            for j = 1:length(ROIChoice)
                                for k = 1:length(roiLabels)
                                    if strcmpi(ROIChoice{j},roiLabels{k})
                                        ROIidx = k;
                                        break
                                    end
                                end
                            end
                        else
                            ROIidx = size(roiLabels,1) + 1000; % If all was selected before, just set the index to something greater than the number of ROIs
                        end
                    end

                    if ROIidx == 0 %if nothing has been found automatically, provide the user with a dialog box to select the ROI

                        ROIstring = roiLabels;
                        ROIstring{end+1,1} = 'All';
                        if ROIorClass == 0
                            ROIidx = ROIchooseDlg(ROIstring);
                        else
                            ROIidx = ROIClassChooseDlg(ROIstring);
                        end

                    end
                    %Update the Tracks & NParticles data
                    if ROIidx <= size(roiLabels,1)
                        if ROIorClass == 0
                            if size(Tracks{i},2) < 8
                                Tracks{i} = Tracks{i}(Tracks{i}(:,5) == ROIidx,:);
                            elseif size(Tracks{i},2) == 8
                                Tracks{i} = Tracks{i}(Tracks{i}(:,6) == ROIidx,:);
                            else
                                Tracks{i} = Tracks{i}(Tracks{i}(:,9) == ROIidx,:);
                            end
                            NParticles{i} = [NParticles{i}(:,1) NParticles{i}(:,ROIidx+1)];
                            ROIChoice{end+1,1} = Temp.Results.Process.ROIlabel{ROIidx};
                            n_ROIs = n_ROIs + 1;
                            


                        else
                            roiAct = [];
                            tracks_tmp = Tracks{i};
                            tracks_tmp(:,5) = tracks_tmp(:,5) - min(tracks_tmp(:,5)) + 1;
                            Tracks{i} = [];
                            for m = 1:length(Temp.Results.Process.ROIClass)
                                if iscell(Temp.Results.Process.ROIClass{m,:})
                                    tmp = Temp.Results.Process.ROIClass{m,:};
                                    Temp.Results.Process.ROIClass{m,:} = tmp{1,:};
                                end
                                if strcmpi(roiLabels{ROIidx,:},Temp.Results.Process.ROIClass{m,:})
                                    if size(Tracks{i},2) < 8
                                        Tracks{i} = [Tracks{i}; tracks_tmp(tracks_tmp(:,5) == m,:)];
                                    elseif size(Tracks{i},2) == 8
                                        Tracks{i} = [Tracks{i}; tracks_tmp(tracks_tmp(:,6) == m,:)];
                                    else
                                        Tracks{i} = [Tracks{i}; tracks_tmp(tracks_tmp(:,9) == m,:)];
                                    end
                                    roiAct = [roiAct;m];
                                end

                            end
                            tmp = NParticles{i}(:,roiAct+1);
                            n_ROIs = n_ROIs + size(tmp,2);

                            NParticles{i} = [NParticles{i}(:,1) sum(tmp,2)];
                            ROIChoice{end+1,1} = Temp.Results.Process.AllROIClasses{ROIidx};
                        end

                    else
                        tmp = NParticles{i}(:,2:size(Temp.Results.Process.ROIlabel,1)+1);
                        n_ROIs = n_ROIs + size(tmp,2);
                        NParticles{i} = [NParticles{i}(:,1) sum(tmp,2)];
                        ROIChoice{end+1,1} = 'All';
                    end
                else
                    ROIChoice{end+1,1} = roiLabels{1};
                    if ROIorClass == 1
                        tmp = NParticles{i}(:,2:size(NParticles{i},2));
                        NParticles{i} = [NParticles{i}(:,1) sum(tmp,2)];
                        n_ROIs = n_ROIs + size(tmp,2);
                    else
                        n_ROIs = n_ROIs + 1;
                    end
                end
            else
                ROIChoice{end+1,1} = '';
            end
        else
            ROIChoice{end+1,1} = '';
        end
        if ~isempty(fig_h)
            d.Value = i/nFiles;
        else
            waitbar(i/nFiles,d);
        end
    else
        Tracks = [];
        NParticles = [];
        NParticlesTracked = [];
        Particle_SNR = [];
        Track_JumpDist1 = [];
        Track_nextNearestD = [];
        ROIChoice = [];
        n_ROIs = 0;
        errordlg(['Some of the files have not been preprocessed: ',path_in,filenames{i}]);
        if ~isempty(fig_h)
            close(d);
        else
            delete(d);
        end
        return
    end
end
if ~isempty(fig_h)
    close(d);
else
    delete(d);
end

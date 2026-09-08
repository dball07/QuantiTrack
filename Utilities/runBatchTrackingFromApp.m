function app = runBatchTrackingFromApp(app)

%main code that does the full tracking workflow on a set of files

%set up the values that are constant
IMfiles = app.imFilesRaw;
IMpaths = app.imPaths;
app.imFilesTrack = cell(size(app.imFilesRaw));
app.imFilesRef = cell(size(app.imFilesRaw));

%Split & Align
channelOrderStr = app.ChannelOrderinMoviesEditField.Value;
trackChanStr = app.PrimaryChanneltoTrackEditField.Value;
RefChanStr = app.ReferenceImageChannelEditField.Value;

RegMat = app.RegMat;
Reg_wls = app.RegLambdas;
if size(Reg_wls,1) == 3
    wl = [Reg_wls(1,1);Reg_wls(1,2);Reg_wls(2,2)];
elseif size(Reg_wls,1) == 1
    wl = [Reg_wls(1,1);Reg_wls(1,2)];
end
% app.useParallel = 0;
%Determine how many channels are specified
commaPos = strfind(channelOrderStr,',');
if app.SplitandAlignMoviesCheckBox.Value == 1 && ~isempty(commaPos)
    defaults = {'1', ...
        '0', ...
        '0', ...
        '0'};
    prompt = {'First frame to use',...
        'Last frame to use (0 = use all)',...
        'Channel 2 skip frames',...
        'Channel 3 skip frames'};
    dlgtitle = 'Parameters for the Batch splitting';
    BatchParam = inputdlg(prompt,dlgtitle, 1, defaults);
    if isempty(BatchParam)
        return
    end
    frame1 = str2double(BatchParam{1});
    lastIm = str2double(BatchParam{2});
    Chan2skip = str2double(BatchParam{3});
    Chan3skip = str2double(BatchParam{4});
end

if length(commaPos) == 1
    nChan = 2;
    wl1_num = str2double(channelOrderStr(1:commaPos(1)-1));
    wl1_str = num2str(wl1_num);

    wl2_num = str2double(channelOrderStr(commaPos(1)+1:end));
    wl2_str = num2str(wl2_num);


    wluse = [wl1_num;wl2_num];

    if strcmp(trackChanStr,wl1_str)
        trackChanInd = 1;

    else
        trackChanInd = 2;

    end
    if strcmp(RefChanStr,wl1_str)
        RefChanInd = 1;

    elseif strcmp(RefChanStr,wl2_str)
        RefChanInd = 2;
    else
        RefChanInd = [];
    end


elseif length(commaPos) == 2
    nChan = 3;
    wl1_num = str2double(channelOrderStr(1:commaPos(1)-1));
    wl1_str = num2str(wl1_num);

    wl2_num = str2double(channelOrderStr(commaPos(1)+1:commaPos(2)-1));
    wl2_str = num2str(wl2_num);

    wl3_num = str2double(channelOrderStr(commaPos(2)+1:end));
    wl3_str = num2str(wl3_num);


    wluse = [wl1_num;wl2_num;wl3_num];

    if strcmp(trackChanStr,wl1_str)
        trackChanInd = 1;

    elseif strcmp(trackChanStr,wl2_str)
        trackChanInd = 2;
    else
        trackChanInd = 3;
    end

    if strcmp(RefChanStr,wl1_str)
        RefChanInd = 1;

    elseif strcmp(RefChanStr,wl2_str)
        RefChanInd = 2;
    else
        RefChanInd = 3;
    end

elseif isempty(commaPos)
    wluse = [];
    app.imFilesRef = [];
elseif length(commaPos) > 2
    errordlg('Splitting can currently be done for a maximum of 3 wavelengths ','Too many input channels');
    return
end


%Go through all of the files
d1 = uiprogressdlg(app.QuantiTrackBatchTrackingUIFigure,'Title','Batch Processing',...
    'Message',['Processing ', num2str(length(app.imFilesRaw)), ' Movies'],'Value',0);
for ImIx = 1:length(app.imFilesRaw)
    d1.Value = (ImIx - 1)./length(app.imFilesRaw);

    tmpTrackName = [app.imFilesRaw{ImIx}(1:end-4), '_' trackChanStr];
    if trackChanInd ~= 1
        tmpTrackName = [tmpTrackName, '_aligned'];
    end
    tmpTrackName = [tmpTrackName, '.tif'];

    tmpRefName = [app.imFilesRaw{ImIx}(1:end-4), '_' RefChanStr];
    if RefChanInd ~= 1
        tmpRefName = [tmpRefName, '_aligned'];
    end

    tmpRefName = [tmpRefName, '.tif'];

    app.imFilesTrack{ImIx} = tmpTrackName;
    app.imFilesRef{ImIx} = tmpRefName;

    %Read in the file
    d2 = uiprogressdlg(app.QuantiTrackBatchTrackingUIFigure,'Title',['Processing File ', num2str(ImIx), ' of ', num2str(length(app.imFilesRaw))],...
        'Message',['Importing File: ',IMfiles{ImIx,:}],'Indeterminate','on');

    [imageStack,nImages] = TIFread([IMpaths{ImIx,:},filesep,IMfiles{ImIx,:}]);


    %%%%%%%Split And Align%

    if app.SplitandAlignMoviesCheckBox.Value == 1 && ~isempty(commaPos)
        %Initialize image files

        counter = ones(nChan,1);
        matlabpath = path;
        sc_pos = strfind(matlabpath,pathsep);

        TempSaveDir = [matlabpath(1:sc_pos(1)-1), filesep, 'tmp',filesep]; %temporary save directory to avoid the error when saving to a folder that is open in Windows explorer
        TempDirExists = dir(TempSaveDir);
        if isempty(TempDirExists)
            mkdir(TempSaveDir);
        end
        clear ImAll;
        clear ImAlign;
        counter = ones(nChan,1);
        

        drawnow
        fname2 = cell(3,1);
        if length(commaPos) == 1

            fname2{1,:} = [IMfiles{ImIx,:}(1:end-4),'_',wl1_str,'.tif'];

            fname2{2,:} = [IMfiles{ImIx,:}(1:end-4),'_',wl2_str,'.tif'];

        elseif length(commaPos) == 2

            fname2{1,:} = [IMfiles{ImIx,:}(1:end-4),'_',wl1_str,'.tif'];

            fname2{2,:} = [IMfiles{ImIx,:}(1:end-4),'_',wl2_str,'.tif'];

            fname2{3,:} = [IMfiles{ImIx,:}(1:end-4),'_',wl3_str,'.tif'];


        end
        % app.StatusText.Text = ['Splitting Image ', num2str(ImIx), ' of ', num2str(size(IMfiles,1)),'...'];
        drawnow
        d2.Message = 'Splitting Channels';
        d2.Indeterminate = 'off';
        d2.Value = 0;

        Chan2Ind = 2:Chan2skip+2:nImages;
        Chan3Ind = 3:Chan3skip+3:nImages;

        for i = 1:nImages
            d2.Value = (i-1)/nImages;

            im_tmp = imageStack(i).data;
            if ~isempty(find(Chan2Ind == i,1))
                ImAll{2}(:,:,counter(2)) = im_tmp;
                if trackChanInd == 2
                    imStackTrack(counter(2)) = imageStack(i);
                end
                if RefChanInd == 2
                    imStackRef(counter(2)) = imageStack(i);
                end
                counter(2) = counter(2) + 1;
                fnum = 2;
            else
                if nChan == 3
                    if ~isempty(find(Chan3Ind == i,1))
                        ImAll{3}(:,:,counter(3)) = im_tmp;
                        if trackChanInd == 3
                            imStackTrack(counter(3)) = imageStack(i);
                        end
                        if RefChanInd == 3
                            imStackRef(counter(3)) = imageStack(i);
                        end
                        counter(3) = counter(3) + 1;
                        fnum = 3;
                    else
                        ImAll{1}(:,:,counter(1)) = im_tmp;
                        if trackChanInd == 1
                            imStackTrack(counter(1)) = imageStack(i);
                        end
                        if RefChanInd == 1
                            imStackRef(counter(1)) = imageStack(i);
                        end
                        counter(1) = counter(1) + 1;
                        fnum = 1;
                    end
                else
                    ImAll{1}(:,:,counter(1)) = im_tmp;
                    if trackChanInd == 1
                        imStackTrack(counter(1)) = imageStack(i);
                    end
                    if RefChanInd == 1
                        imStackRef(counter(1)) = imageStack(i);
                    end
                    counter(1) = counter(1) + 1;
                    fnum = 1;
                end
            end
            % if rem(i,nChan) == 1
            % 
            %     ImAll{1}(:,:,counter(1)) = im_tmp;
            %     if trackChanInd == 1
            %         imStackTrack(counter(1)) = imageStack(i);
            %     end
            %     if RefChanInd == 1
            %         imStackRef(counter(1)) = imageStack(i);
            %     end
            % 
            %     counter(1) = counter(1) + 1;
            %     fnum = 1;
            % elseif rem(i,nChan) == 2
            % 
            %     ImAll{2}(:,:,counter(2)) = im_tmp;
            %     if trackChanInd == 2
            %         imStackTrack(counter(2)) = imageStack(i);
            %     end
            %     if RefChanInd == 2
            %         imStackRef(counter(2)) = imageStack(i);
            %     end
            % 
            %     counter(2) = counter(2) + 1;
            %     fnum = 2;
            % elseif rem(i,nChan) == 0 && nChan == 2
            % 
            %     ImAll{2}(:,:,counter(2)) = im_tmp;
            %     if trackChanInd == 2
            %         imStackTrack(counter(2)) = imageStack(i);
            %     end
            %     if RefChanInd == 2
            %         imStackRef(counter(2)) = imageStack(i);
            %     end
            % 
            %     counter(2) = counter(2) + 1;
            %     fnum = 2;
            % elseif rem(i,nChan) == 0 && nChan == 3
            % 
            %     ImAll{3}(:,:,counter(3)) = im_tmp;
            %     if trackChanInd == 3
            %         imStackTrack(counter(3)) = imageStack(i);
            %     end
            %     if RefChanInd == 3
            %         imStackRef(counter(3)) = imageStack(i);
            %     end
            % 
            %     counter(3) = counter(3) + 1;
            %     fnum = 3;
            % end


        end

        d2.Message = 'Writing Split Channel movies to Disk';

        for i = 1:nChan
            if lastIm > 0
                lastIm = min(lastIm,counter(i)-1);
            else
                lastIm = counter(i)-1;
            end
            for j = frame1:lastIm
                im_tmp2 = ImAll{i}(:,:,j);
                if j == frame1
                    imwrite(im_tmp2,[TempSaveDir, fname2{i,:}],'WriteMode','overwrite');
                else
                    imwrite(im_tmp2,[TempSaveDir, fname2{i,:}],'WriteMode','append');
                end
            end
            

            movefile([TempSaveDir, filesep, fname2{i,:}],[IMpaths{ImIx,:}, filesep, fname2{i,:}]);
        end



        Im2Align = ImAll;
        % app.StatusText.Text = ['Aligning Image ', num2str(ImIx), ' of ', num2str(size(IMfiles,1)),'...'];
        drawnow

        d2.Message = 'Aligning Channels';
        d2.Value = 0;

        for i = 1:size(wluse,1)
            if wluse(i) ~= Reg_wls(1)
                Reg_ind = find(Reg_wls(:,1) == wl(1) & Reg_wls(:,2) == wluse(i));
                RegMat_use = RegMat{Reg_ind,:};
                Roriginal = imref2d([size(Im2Align{1},1),size(Im2Align{1},2)]);
                for j = 1:size(Im2Align{i},3)
                    d2.Value = sub2ind([size(wluse,1),size(Im2Align{i},3)],i,j)./(size(wluse,1).*size(Im2Align{i},3));
                    ImAlign{i}(:,:,j) = imwarp(Im2Align{i}(:,:,j),RegMat_use,'OutputView',Roriginal);
                    imwrite(ImAlign{i}(:,:,j),[TempSaveDir,IMfiles{ImIx,:}(1:end-4),'_',num2str(wluse(i)),'_aligned.tif'],'WriteMode','append');
                end
                movefile([TempSaveDir, IMfiles{ImIx,:}(1:end-4),'_',num2str(wluse(i)),'_aligned.tif'],...
                    [IMpaths{ImIx,:}, filesep, IMfiles{ImIx,:}(1:end-4),'_',num2str(wluse(i)),'_aligned.tif']);

            end
        end

    elseif app.SplitandAlignMoviesCheckBox.Value == 0 && isempty(commaPos)
        imStackTrack = imageStack;
        imStackRef = imageStack;
    elseif app.SplitandAlignMoviesCheckBox.Value == 0 && ~isempty(commaPos)
        imStackTrack = TIFread([IMpaths{ImIx,:},filesep,app.imFilesTrack{ImIx}]);
        imStackRef = TIFread([IMpaths{ImIx,:},filesep,app.imFilesRef{ImIx}]);
    end

    %%Set up the Results structure
    clear Results;
    Results.Data.fileName = app.imFilesTrack{ImIx,:};
    Results.Data.pathName = IMpaths{ImIx,:};
    Results.Data.imageStack = imStackTrack;
    Results.Data.nImages = length(imStackTrack);
    Results.Data.clims = [min(min(Results.Data.imageStack(1).data))...
        max(max(Results.Data.imageStack(1).data))];

    % %filter the movie
    BPorLoG = app.FilterTypeDropDown.Value;
    NNorLAP = app.MethodDropDown.Value;
    lpass = app.LowerLimitSpinner.Value;
    hpass = app.UpperLimitSpinner.Value;

    d2.Message = ['Filtering frame 1 of ',num2str(Results.Data.nImages)];
    d2.Value = 0;
    if app.useParallel == 1
        d2.Message = 'Filtering framed in Parallel';
        d2.Indeterminate = 'on';
        parfor j =  1:Results.Data.nImages
            
            if strcmp(BPorLoG,'Bandpass')
                filterStack(j).data = ...
                    bpass(Results.Data.imageStack(j).data, lpass, hpass);
            elseif strcmp(BPorLoG,'LoG') %LoG filtering

                filt_log = fspecialCP3D_MT('2D LoG',hpass,lpass);
                filterStack(j).data = ...
                    imfilter(double(Results.Data.imageStack(j).data), filt_log,'symmetric') *(-1);
               filterStack(j).data(Results.Process.filterStack(j).data < 0) = 0;
            else
                filterStack(j) = Results.Data.imageStack(j);
            end
        end
        Results.Process.filterStack = filterStack;
    else

        for j =  1:Results.Data.nImages
            d2.Message = ['Filtering frame ', num2str(j), ' of ' ,num2str(Results.Data.nImages)];
            d2.Value = (j-1)./Results.Data.nImages;
            if strcmp(BPorLoG,'Bandpass')
                Results.Process.filterStack(j).data = ...
                    bpass(Results.Data.imageStack(j).data, lpass, hpass);
            elseif strcmp(BPorLoG,'LoG') %LoG filtering
    
                filt_log = fspecialCP3D_MT('2D LoG',hpass,lpass);
                Results.Process.filterStack(j).data = ...
                    imfilter(double(Results.Data.imageStack(j).data), filt_log,'symmetric') *(-1);
                Results.Process.filterStack(j).data(Results.Process.filterStack(j).data < 0) = 0;
            else
                Results.Process.filterStack(j) = Results.Data.imageStack(j);
            end
        end
    end


    Results.Process.clims = [min(min(Results.Process.filterStack(1).data))...
        max(max(Results.Process.filterStack(1).data))];

    %Specify ROIs
    if isempty(commaPos)
        x = [1;...
            1;...
            Results.Data.imageStack(1).width;...
            Results.Data.imageStack(1).width;...
            1];
        y = [1;...
            Results.Data.imageStack(1).height;...
            Results.Data.imageStack(1).height;...
            1;...
            1];
        Results.Process.ROIpos{1} = [x,y];
        Results.Process.ROIimage{1} = ones(size(Results.Data.imageStack(1).data));
        Results.Process.ROIlabel{1} = 'ROI 1';
        Results.Process.ROIClass{1} = app.ROIClassEditField.Value;
    else
        d2.Message = 'Finding ROIs';
        d2.Indeterminate = 'on';

        [ROIpos, ROIimage,th1_used] =autoROIs3(imStackRef,length(imStackRef),0,0,0,app.ROIminIntensity0autoEditField.Value);
        Results.Process.ROIpos = ROIpos;
        Results.Process.ROIimage = ROIimage;
        for j = 1:length(ROIpos)
            Results.Process.ROIlabel{j,:} = ['ROI ',num2str(j)];
            Results.Process.ROIClass{j,:} = app.ROIClassEditField.Value;
        end


    end

    %Find Particles
    d2.Message = 'Finding Particles';

    TrackROIsepAns = 'Yes';

    emWl = app.EmissionWavelengthnmEditField.Value;
    objNA = app.ObjectiveNAEditField.Value;
    pxSize = app.PixelSizenmEditField.Value;
    frameInterval = app.TimelapseIntervalsEditField.Value;

    if strcmp(BPorLoG,'Local BG, no filtering (SLIMfast)')
        % maybe add ROI if too slow
        locOptions.locParallel = 0;
        locOptions.rLive = 0;
        locOptions.spatialCorrection = 0;

        locOptions.maxOptimIter = 50;
        locOptions.termTol = -2;
        locOptions.isRadiusTol = 0;
        locOptions.radiusTol = 50;
        locOptions.posTol = 1.5;

        locOptions.w2d = app.WindowSizeSpinner.Value;
        % prompt = {'NA',...
        %     'Em Wavelength (nm)','Max. Iterations','Error Rate (10^{value})',...
        %     'Deflation Loops','Min. Intensity'};
        %
        % dlgtitle = 'Particle Detection Parameters';
        % definputs = {'1.49','670','50','-6','1','0'};
        % opts.Interpreter = 'tex';
        % locInputs = inputdlg(prompt,dlgtitle,1,definputs,opts);
        % if isempty(locInputs)
        %     return
        % end



        psfStd = 1.35*...
            0.55*(0.001*emWl)/...
            str2double(objNA)/1.17/...
            pxSize/2;
        locOptions.psfStd = psfStd; %PSF width (could be calculated)
        locOptions.errorRate = -6;
        locOptions.dfltnLoops = 1;
        locOptions.minInt = 0;

    end
    threshold = app.IntensityThresholdSpinner.Value;
    windowSz = app.WindowSizeSpinner.Value;
    maxJump = app.MaxJumppxSpinner.Value;
    shTrack = app.ShortestTrackframesSpinner.Value;
    closeGaps = app.LengthofGapsframesSpinner.Value;
    isFitPSF = 1;
    if ~strcmp(BPorLoG,'Local BG, no filtering (SLIMfast)')

        if threshold > 0 && windowSz > 0
            Results.Tracking.Centroids = findParticles(Results.Process.filterStack, threshold, hpass,windowSz,app.useParallel);

            if isFitPSF
                CentroidInRoi = InsideROIcheck2(Results.Tracking.Centroids, Results.Process.ROIimage);

                Centroid = CentroidInRoi;
                if ~isempty(Centroid)
                    Particles = peak_fit_psf(Results.Data.imageStack,...
                        Centroid,windowSz,windowSz,app.useParallel);
                    Particles2 = InsideROIcheck2(Particles,Results.Process.ROIimage);
                    Results.Tracking.Particles = Particles2;
                else
                    Results.Tracking.Particles = zeros(1,13);
                end
            end

        end
    else
        locOptions.roi = [1, 1, Results.Data.imageStack(1).width,Results.Data.imageStack(1).height];
        Results.Tracking.Centroids = SLIMfast_loc_wrapper(Results.Data.imageStack,locOptions);
        CentroidInRoi = InsideROIcheck2(Results.Tracking.Centroids, Results.Process.ROIimage);
        Centroid = CentroidInRoi;
        Results.Tracking.Centroids = Centroid;
        if ~isempty(Centroid)
            Results.Tracking.Particles = Centroid;
        else
            Results.Tracking.Particles = zeros(1,13);
        end
    end


    %Tracking
    d2.Message = 'Tracking Particles';

    if strcmp(NNorLAP,'MTT (SLIMfast)') && strcmp(BPorLoG,'Local BG, no filtering (SLIMfast)')
        % prompt = {'Max. Diffusion Coefficient(\mum^2/s)',...
        %     'Averaging Time Window','Counts/photon'};
        %
        % dlgtitle = 'Tracking Parameters';
        %
        % definputs = {num2str(maxD_def),'10','20.2'};
        % opts.Interpreter = 'tex';
        % trkInputs = inputdlg(prompt,dlgtitle,1,definputs,opts);
        % if isempty(trkInputs)
        %     return
        % end
        maxD_def = calcDfromJump(maxJump, pxSize, frameInterval, 4);

        options.pxSize = pxSize;
        options.frameSize = frameInterval*1000;
        options.windowSz = windowSz;
        options.goodTr = shTrack;
        options.maxD = maxD_def;
        options.errorRate = -6;
        options.deflateLoops = 1;
        options.statWin = 10;
        options.minIntensity = 0;
        options.countsPerPhoton = 20.2;



        %     psfStd = 1.35*...
        %             0.55*(0.001*str2double(locInputs{4}))/...
        %             str2double(locInputs{3})/1.17/...
        %             str2double(locInputs{1})/2;
        options.psfStd = locOptions.psfStd;
        options.T_off = -1*(closeGaps);

        options.searchExpFac = 1.2;
        options.maxComp = 3;
        options.intLawWeight = 0.9;
        options.diffLawWeight = 0.5;

        options.trackStart = 1;
        options.trackEnd = inf;

        options.isThreshDensity = 0;
        options.isThreshSNR = 0;
        options.isThreshLocPrec = 0;
        options.hROI = [];

        options.minLoc = 0;
        options.maxLoc = inf;
        options.minSNR = 0;
        options.maxSNR = inf;
    end

    Trackparam.mem = closeGaps;
    Trackparam.good = shTrack;
    Trackparam.dim         =  2;
    Trackparam.quiet       =  0;
    if isFitPSF % if particle position has been evaluated via PSF fitting
        if strcmp(NNorLAP,'Nearest Neighbor')
            Particles = Results.Tracking.Particles(:,[10 11 6 13]);
        elseif strcmp(NNorLAP,'LAP')
            Particles = Results.Tracking.Particles(:,[10, 17, 11, 18, 7, 14, 6, 13]);
        else
            noise_shot = sqrt(max(parts(:, 9), 0));
            Particles = [Results.Tracking.Particles(:,1), ...
                Results.Tracking.Particles(:,2), ...
                Results.Tracking.Particles(:,3), ...
                noise_shot,...
                Results.Tracking.Particles(:,9), ...
                Results.Tracking.Particles(:,8), ...
                Results.Tracking.Particles(:,6)];

            Particles(:,1:2) = Particles(:,1:2) - 1;
        end
    else
        if strcmp(NNorLAP,'Nearest Neighbor')
            Particles = handles.Tracking.Centroids(:,[1 2 6 7]);
        elseif strcmp(NNorLAP,'LAP')
            warndlg('Particles must be fit to a 2D Gaussian in order to perform LAP tracking');
            return
        else
            noise_shot = sqrt(max(parts(:, 9), 0));
                Particles = [Results.Tracking.Particles(:,1), ...
                    Results.Tracking.Particles(:,2), ...
                    Results.Tracking.Particles(:,3), ...
                    noise_shot,...
                    Results.Tracking.Particles(:,9), ...
                    Results.Tracking.Particles(:,8), ...
                    Results.Tracking.Particles(:,6)];

            Particles(:,1:2) = Particles(:,1:2) - 1;
            isFitPSF = 1;
        end
    end

    if ~isempty(Particles) && max(max(abs(Particles))) > 0
        if strcmp(NNorLAP,'Nearest Neighbor')

            Particles(Particles(:,1) == 0,:) = [];

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


            [Tracks, TrkPtsAdded, errorcode] = trackfunctIG(Particles(:,1:3),maxJump,Trackparam);

        elseif strcmp(NNorLAP, 'LAP (uTrack)')
            params.uTrack = struct('maxJump',maxJump,'good', Trackparam.good, 'mem',Trackparam.mem);
            Tracks = uTrackWrapper(Particles,params.uTrack);
        else
            options.roi = [0 0 Results.Data.imageStack(1).width...
                Results.Data.imageStack(1).height];

            Tracks = SLIMfast_trk_wrapper(Particles,Results.Data.imageStack,options);
        end
    end

    if (strcmp(NNorLAP,'Nearest Neighbor') && min(errorcode) == 0) || (strcmp(NNorLAP,'LAP') && ~isempty(Tracks))|| (strcmp(NNorLAP,'MTT') && ~isempty(Tracks))
        Tracks = InsideROIcheck2(Tracks,Results.Process.ROIimage);
        Results.Tracking.Tracks = Tracks;
        if isFitPSF
            ParticlesNew = Results.Tracking.Particles;

            x_ind = 10;
            y_ind = 11;
        else
            ParticlesNew = Results.Tracking.Centroids;
            x_ind = 1;
            y_ind = 2;
        end
        Particles = ParticlesNew;
        % if ~isempty(varargin)
        %     Part_tmp1 = Particles(Particles(:,6) >= varargin{1}(1),:);
        %     Part_tmp2 = Part_tmp1(Part_tmp1(:,6) <= varargin{1}(2),:);
        %     Particles = Part_tmp2;
        %     Particles(:,6) = Particles(:,6) - varargin{1}(1) + 1;
        %     nImages = varargin{1}(2) - varargin{1}(1) + 1;
        % else
        nImages = Results.Data.nImages;
        % end
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
                if isFitPSF
                    ParticleAdd(:,10:11) = ParticleAdd(:,1:2);
                    ParticleAdd(:,12) = 0;
                    if isfield(Results.Process,'ROIpos')
                        ParticleAdd(:,13) = 0;
                    end
                    ParticleAdd(:,14:18) = zeros(1,5);
                else
                    if isfield(Results.Process,'ROIpos')
                        ParticleAdd(:,7) = 0;
                    end
                end
                ParticlesNew = [ParticlesNew; ParticleAdd];
            end


        end
        ParticlesNew = InsideROIcheck2(ParticlesNew,Results.Process.ROIimage);
        if isFitPSF
            ParticlesNew = sortrows(ParticlesNew,[6,13]);
            Results.Tracking.Particles = ParticlesNew;
        else
            ParticlesNew = sortrows(ParticlesNew,[6,7]);
            Results.Tracking.Centroids = ParticlesNew;
        end


        %PreAnalysis
        Tracks = Results.Tracking.Tracks;
        %             if isFitPSF
        %                 Particles = Results.Tracking.Particles;
        %             else
        %                 Particles = Results.Tracking.Centroids;
        %             end
        if ~isempty(Tracks)
            params.lambda = emWl;
            params.NA = objNA;
            [Results.PreAnalysis.Tracks_um, Results.PreAnalysis.NParticles, Results.PreAnalysis.IntensityHist] = preProcess_noGUI(Tracks,Results.Data.imageStack,...
                Particles, pxSize, nImages, Results.Data.fileName,Results.Process.ROIpos,params);

            Results.isFitPSF = isFitPSF;
            Results.Analysis = [];
            Results.Parameters.Used.Tracking = [lpass, hpass, threshold,windowSz, maxJump,closeGaps,shTrack];
            Results.Parameters.Tracking = [lpass, hpass, threshold,windowSz, maxJump,closeGaps,shTrack];
            if exist('locOptions','var')
                Results.Parameters.Used.SLIMfast = locOptions;
            end
            if exist('options','var')
                Results.Parameters.Used.MTT_Tracking = options;
            end
            Results.Parameters.Used.Acquisition.pixelSize = pxSize;
            Results.Parameters.Used.Acquisition.frameTime = frameInterval;
            Results.Parameters.Used.Acquisition.NA = objNA;
            Results.Parameters.Used.Acquisition.EmWavelength = emWl;

            Results.Parameters.Acquisition = Results.Parameters.Used.Acquisition;
            Version = 1.0;
            PathNameOut = fullfile(app.db_path,app.CellProteinDropDown.Value, ...
                app.ConditionDropDown.Value, app.SessionDropDown.Value);
            save([PathNameOut, filesep,Results.Data.fileName(1:end-4),'_preprocess.mat'],'Results','Version');



            profile.lastCellProtein = app.CellProteinDropDown.Value;
            profile.lastCondition = app.ConditionDropDown.Value;
            profile.lastSession = app.SessionDropDown.Value;

            profile.lastName = [Results.Data.fileName(1:end-4),'_preprocess.mat'];
            profile.pixelSize = pxSize;
            profile.exposureTime = app.ExposureTimesEditField.Value;
            profile.frameTime = frameInterval;

            trackTable = generateTrackTable(Results,profile);
            tt_saveLoc = fullfile(app.db_path,profile.lastCellProtein);

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


    end
    close(d2);


end
close(d1);







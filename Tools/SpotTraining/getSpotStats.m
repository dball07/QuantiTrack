function outStats = getSpotStats(Particles,response,responseVal,imageStack,pixelSize)

%Calculates means & standard deviations on spots to be used when generating
%simulated images. The parameters that are output are: intensity,
%background level, background noise, spot size, and spot sub-pixel offset

outStats = struct('mn_intensity',0, 'S_intensity',0,'mn_background',0,...
    'S_background',0,'mn_bgstd',0,'S_bgstd',0,'mn_spotSigma',0,'S_spotSigma',0,...
    'mn_posOffset',zeros(1,2),'S_posOffset',zeros(1,2));

%remove particles that have position = 0
Parts = Particles(Particles(:,1) > 0,:);

%make sure number of particles matches the number of response values
if size(Parts,1) ~= size(response,1)
    error('size of Particles and response do not match');
    
end

part0 = Parts(response == responseVal,:);

%get the spot size stats
outStats.mn_spotSigma = mean(part0(:,8));
outStats.S_spotSigma = std(part0(:,8));

%get the sub-pixel offset stats
posOffsets = part0(:,10:11) - round(part0(:,10:11));

outStats.mn_posOffset = mean(posOffsets);
outStats.S_posOffset = std(posOffsets);


%make a dummy tracking array so we can use AddAiryIntensity
tracks0 = [part0(:,10:11), part0(:,6), (1:length(part0))'];

[~,tracks0_out] = AddAiryIntensity(tracks0, pixelSize, imageStack);

%extract the intensity and background stats
outStats.mn_intensity = mean(tracks0_out(:,5) - tracks0_out(:,6));
outStats.S_intensity = std(double(tracks0_out(:,5) - tracks0_out(:,6)));
outStats.mn_background = mean(tracks0_out(:,6));
outStats.S_background = std(tracks0_out(:,6));
outStats.mn_bgstd = mean(tracks0_out(:,7));
outStats.S_bgstd = std(tracks0_out(:,7));






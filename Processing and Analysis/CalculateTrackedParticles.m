function Nparticles = CalculateTrackedParticles(tracks,NFrames,varargin)


if ~isempty(varargin)
    nROIs = varargin{1};
else

    nROIs = length(unique(tracks(:,5)));

end
FrameList = 1:NFrames;

% preallocate Nparticles
Nparticles =  zeros(NFrames,nROIs);
for iFrame = FrameList
    idx = find(tracks(:,3)==iFrame);
    if ~isempty(idx)
        if nROIs > 1
            for iROI = 1:nROIs
                Particles_tmp = tracks(idx,:);
                idx2 = find(Particles_tmp(:,5) == iROI);


                if isempty(idx2) || sum(Particles_tmp(idx2,1))== 0
                    % if no particles have been found at that frame

                    Nparticles(iFrame,iROI) = 0;
                else
                    idx2(Particles_tmp(idx2,1) == 0,:) = [];
                    Nparticles(iFrame,iROI) = length(idx2);
                    % Otherwise count the number of particles at that frame
                end
            end
        else
            if sum(tracks(idx,1)) == 0
                Nparticles(iFrame,1) = 0;
            else
                idx(tracks(idx,1) == 0,:) =[];
                Nparticles(iFrame,1) = length(idx);
            end
        end
    else
        for j = 1:nROIs
            Nparticles(iFrame,j) = 0;
        end
    end
end

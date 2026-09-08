function classified_tracks = RL_classifyTracks(tracks,P1norm,lagtime, minTrackLength)


% now sort tracks based on P(M)
jdx=islocalmin(P1norm(:,2)); % find all local minima in the P(M) function. these will serve as classification boundaries
idum = find(jdx);
nminima = length(idum);
classified_tracks=zeros(length(tracks),1);
if nminima > 0  
    for i=1:length(tracks)
        if size(tracks{i},1) >= minTrackLength
            x=tracks{i}(:,1);
            y=tracks{i}(:,2);
            rsq = ((x(lagtime+1:end)-x(1:end-lagtime)).^2+(y(lagtime+1:end)-y(1:end-lagtime)).^2);
            mrsq=mean(rsq);
            
            if mrsq < P1norm(idum(1),1)
                classified_tracks(i,:) = 1; % accumulate all tracks in this range
            end
            if nminima>1
                for im=1:nminima-1
                    if mrsq >= P1norm(idum(im),1) && mrsq < P1norm(idum(im+1),1)
                        classified_tracks(i,:) = im+1; % accumulate all tracks in this range  
                    end
                end
            end
            
            if mrsq >= P1norm(idum(nminima),1)
                classified_tracks(i,:) = nminima + 1; % accumulate all tracks in this range
            end
        end  
    end
end

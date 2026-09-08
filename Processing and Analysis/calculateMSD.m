function R_sq = calculateMSD(tracks,frames2avg)

maxTracks = max(tracks(:,4));
r_sq = [];
for i = 1:maxTracks
   curTrack = tracks(tracks(:,4) == i,:);
   
   if size(curTrack,1) >= frames2avg+1
       for j = 1:frames2avg:size(curTrack)-frames2avg
           pos_x = curTrack(j:j+frames2avg,1);
           pos_y = curTrack(j:j+frames2avg,2);
           
           jd_temp_x = diff(pos_x');
           jd_temp_y = diff(pos_y');
           jd1_temp_sq = jd_temp_x.^2 + jd_temp_y.^2;
           r_sq = [r_sq; jd1_temp_sq];
       end
   end
end
R_sq = mean(r_sq,2);

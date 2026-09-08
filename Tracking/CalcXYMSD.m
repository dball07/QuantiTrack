function [msd,Dtot] = CalcXYMSD(varargin)
if isempty(varargin)
    [files path] = uigetfile('*.mat','Select files to open','MultiSelect','on');
end

if ~iscell(files)
    files = {files};
end
if files{1} ~= 0
    msd = [];
    Dtot = [];
    for i = 1:length(files)
        filename = fullfile(path,files{i});
        load(filename);
        trks = Results.PreAnalysis.Tracks_um;
        for j = 1:max(trks(:,4))
            cur_trk = trks(trks(:,4) == j,:);
            
            if size(cur_trk,1) > 1
                dx = diff(cur_trk(:,1));
                dy = diff(cur_trk(:,2));
                dx2 = dx.^2;
                dy2 = dy.^2;
                dr2 = dx2 + dy2;
                msd = [msd;mean(dr2)];
                
                dx_tot = cur_trk(end,1) - cur_trk(1,1);
                dy_tot = cur_trk(end,2) - cur_trk(1,2);
                dr = sqrt(dx_tot.^2 + dy_tot.^2);
                df = cur_trk(end,3) - cur_trk(1,3);
                Dtot = [Dtot; [dr, df]];
            end
                
                
            end
            
        end
    end
end
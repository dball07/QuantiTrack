function angles = calcAngles3(tracks,varargin)

%Calculates all angles from one step to the next for different time-lags
%and different step sizes. Optional second input determines the minimum
%track length in points (Default is 2 points). Optional third input 
% specifies whether to use parallel processing (1-use, 0- do not use,
% Default = 0).

%extract minimum track lengths
if ~isempty(varargin)
    if ~isempty(varargin{1})
        minTrkLength = varargin{1};
    else
        minTrkLength = 2;
    end

    

else
    minTrkLength = 2;
    loc_prec = 0;
end




angles = [];

trkIDs = unique(tracks(:,4));

if min(tracks(:,3)) > 0 && (length(varargin) < 2 || isempty(varargin{2}))
    %If the data is from HILO, ask for a time-step
    defaults = {'0.01'};
    prompt = {'Time-step (seconds)'};
    dlgtitle = 'Set time resolution';
    tStep_str = inputdlg(prompt,dlgtitle, 1, defaults);
    tStep = str2double(tStep_str{1});
    tracks(:,3) = (tracks(:,3) - 1)*tStep;
elseif min(tracks(:,3)) > 0 && length(varargin) > 2 && ~isempty(varargin{2})
    tStep = varargin{2};
    tracks(:,3) = (tracks(:,3) - 1)*tStep;

end
if length(varargin) > 2 && ~isempty(varargin{3})
    loc_prec = varargin{3};
else
    loc_prec = 0;
end

if length(varargin) > 3
    parallelFlag = varargin{4};
else
    parallelFlag = 0;
end

if parallelFlag == 0
    for i = 1:length(trkIDs)
        
        curTrk = tracks(tracks(:,4) == trkIDs(i),:);
        if size(curTrk,1) >= minTrkLength
            x = curTrk(:,1);
            y = curTrk(:,2);
            t = curTrk(:,3) - curTrk(1,3);
           
            nPts = size(t,1);
            % steps = 1:floor((nPts)/2);
            for step = 1:floor((nPts)/2)
                x1 = x(1:nPts - 2*step,:);
                x2 = x(step+1:nPts - step,:);
                x3 = x(step+step+1:nPts,:);
    
                y1 = y(1:nPts - 2*step,:);
                y2 = y(step+1:nPts - step,:);
                y3 = y(step+step+1:nPts,:);
    
                t1 = t(1:nPts - 2*step,:);
                t2 = t(step+1:nPts - step,:);
                t3 = t(step+step+1:nPts,:);
                
                minLength = min(length(x1),length(x2));
                minLength = min(minLength,length(x3));
    
                x1 = x1(1:minLength);
                x2 = x2(1:minLength);
                x3 = x3(1:minLength);
    
                y1 = y1(1:minLength);
                y2 = y2(1:minLength);
                y3 = y3(1:minLength);
                
                t1 = t1(1:minLength);
                t2 = t2(1:minLength);
                t3 = t3(1:minLength);
                
                dx1 = (x2 - x1);
                dx2 = (x3 - x2);
    
                dx1_sq = dx1.^2;
                dx2_sq = dx2.^2;
                
                dy1 = (y2 - y1);
                dy2 = (y3 - y2);
    
                dy1_sq = dy1.^2;
                dy2_sq = dy2.^2;
                
                r1 = sqrt(dx1_sq + dy1_sq);
                r2 = sqrt(dx2_sq + dy2_sq);
                ind1 = find(r1 >= loc_prec);
                ind2 = find(r2 >= loc_prec);
                IND = intersect(ind1,ind2);
                

                % if r1 >= loc_prec && r2 >= loc_prec
                dr_mean = (r1 + r2)./2;

                dt1 = t2 - t1;
                dt2 = t3 - t2;
                
                dt_mean = (dt1 + dt2)./2;

                %calculate determinate for each move and the dot product of the
                %2 vectors

                detStep = (dx1.*dy2 - dx2.*dy1);
                dotStep = (dx1.*dx2 + dy1.*dy2);

                angle1 = zeros(length(detStep),2);
                angle1(:,1) = abs(atan2(detStep,dotStep));
                angle1(:,2) = 2*pi - angle1(:,1);

                angles = vertcat(angles, [angle1(IND,1),dt_mean(IND,:),dr_mean(IND,:); angle1(IND,2), dt_mean(IND,:), dr_mean(IND,:)]);
                
            end
        end
    end
else
    % %determine how many workers we have
    % p = gcp('nocreate');
    % if isempty(p)
    %     p = gcp('nocreate');
    % end
    % poolsize = p.NumWorkers;
    % 
    % tracks_par = cell(poolsize,1);
    % angles_par = cell(poolsize,1);

    %split the tracks variable
    tracks_par = cell(length(trkIDs),1);
    angles_par = cell(length(trkIDs),1);

    for i = 1:length(trkIDs)
        tracks_par{i,:} = tracks(tracks(:,4) == trkIDs(i),:);
    end

    parfor i = 1:length(trkIDs)
        
        curTrk = tracks_par{i}
        if size(curTrk,1) >= minTrkLength
            x = curTrk(:,1);
            y = curTrk(:,2);
            t = curTrk(:,3) - curTrk(1,3);
           
            nPts = size(t,1);
            % steps = 1:floor((nPts)/2);
            for step = 1:floor((nPts)/2)
                x1 = x(1:nPts - 2*step,:);
                x2 = x(step+1:nPts - step,:);
                x3 = x(step+step+1:nPts,:);
    
                y1 = y(1:nPts - 2*step,:);
                y2 = y(step+1:nPts - step,:);
                y3 = y(step+step+1:nPts,:);
    
                t1 = t(1:nPts - 2*step,:);
                t2 = t(step+1:nPts - step,:);
                t3 = t(step+step+1:nPts,:);
                
                minLength = min(length(x1),length(x2));
                minLength = min(minLength,length(x3));
    
                x1 = x1(1:minLength);
                x2 = x2(1:minLength);
                x3 = x3(1:minLength);
    
                y1 = y1(1:minLength);
                y2 = y2(1:minLength);
                y3 = y3(1:minLength);
                
                t1 = t1(1:minLength);
                t2 = t2(1:minLength);
                t3 = t3(1:minLength);
                
                dx1 = (x2 - x1);
                dx2 = (x3 - x2);
    
                dx1_sq = dx1.^2;
                dx2_sq = dx2.^2;
                
                dy1 = (y2 - y1);
                dy2 = (y3 - y2);
    
                dy1_sq = dy1.^2;
                dy2_sq = dy2.^2;
                
                r1 = sqrt(dx1_sq + dy1_sq);
                r2 = sqrt(dx2_sq + dy2_sq);
                ind1 = find(r1 >= loc_prec);
                ind2 = find(r2 >= loc_prec);
                IND = intersect(ind1,ind2);

                dr_mean = (r1 + r2)./2;
    
                dt1 = t2 - t1;
                dt2 = t3 - t2;
                
    
                dt_mean = (dt1 + dt2)./2;
    
                %calculate determinate for each move and the dot product of the
                %2 vectors
                
                detStep = (dx1.*dy2 - dx2.*dy1);
                dotStep = (dx1.*dx2 + dy1.*dy2);
                
                angle1 = zeros(length(detStep),2);
                angle1(:,1) = abs(atan2(detStep,dotStep));
                angle1(:,2) = 2*pi - angle1(:,1);
    
                angles_par{i} = vertcat(angles_par{i}, [angle1(IND,1),dt_mean(IND,:),dr_mean(IND,:); angle1(IND,2), dt_mean(IND,:), dr_mean(IND,:)]);
            end
        end
    end

    %recapitulate the data into a single array
    angles = [];
    for i = 1:length(trkIDs)
        angles = [angles; angles_par{i}];
    end
end

if ~isempty(angles)
    
    angles(:,2) = round(angles(:,2),3);
    angles(angles(:,1) == 0,:) = [];
end

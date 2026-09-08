function [ROIcov_px, ROIim_sum, ROIcentroid_pos] = measureROImotion(Results,splitLength)
%extracts properties of ROI movement in the tracking results input
%variable Results.
%The outputs are:
%
%ROIcov_px: area covered by the entire ROI over the course of the movie
%ROIim_sum: sum projection of the ROI over time
%ROIcentroid_pos: X,Y coordinates of the center of the ROI over time. third
%column is the frame number. columns 4 and 5 are the displacement from the
%mean position.

ROIim = Results.Process.ROIimage;
ROIim_sum = cell(size(ROIim,1),1);
ROIcov_px = zeros(size(ROIim,1),1);
ROIcentroid_pos = cell(size(ROIim,1),1);
if nargin < 2
    splitLength = 0;
end
ind0 = 1;
for i = 1:size(ROIim,1)
    %Get the mask for the current ROI
    if splitLength > 0
        for k = 1:splitLength:size(ROIim,2)-splitLength
            ROIim_cur = ROIim(i,k:k+splitLength-1);
            ROIim_sum{ind0,:} = ROIim_cur{1,1};
            for j = 2:size(ROIim_cur,2)
                ROIim_sum{ind0,:} = ROIim_sum{ind0,:} + ROIim_cur{1,j};
            end
            %Locate pixels > 0
            posPts = find(ROIim_sum{ind0,:} > 0);
            %get the number of pixels
            ROIcov_px(ind0,:) = length(posPts);

            %compile the centroid positions which are stored in a cell array
            ROIpos_cur = Results.Process.ROICentroid(i,k:k+splitLength-1);

            ind = 1;

            for j = 1:size(ROIpos_cur,2)
                if ~isempty(ROIpos_cur{:,j})
                    ROIcentroid_pos{ind0,:}(ind,:) = [ROIpos_cur{:,j}, j];
                    ind = ind + 1;
                end
            end
            %Also subtract the mean position
            if i == 3 && k == 586
                bela = 1;
            end
            if size(ROIcentroid_pos,1) < ind0
                ROIcentroid_pos{ind0,:} = [];
            end
            if ~isempty(ROIcentroid_pos{ind0,:})
                X_cent = mean(ROIcentroid_pos{ind0,:}(:,1:2));
                ROIcentroid_pos{ind0,:}(:,4:5) = ROIcentroid_pos{ind0,:}(:,1:2) - X_cent;
            end
            ind0 = ind0 + 1;
        end
    else

        ROIim_cur = ROIim(i,:);
        %Start the summed mask fromr the mask in frame 1
        
        ROIim_sum{i,:} = ROIim_cur{1,1};
        
    
        %add subsequent masks to the summed image
        for j = 2:size(ROIim_cur,2)
            ROIim_sum{i,:} = ROIim_sum{i,:} + ROIim_cur{1,j};
        end
        %Locate pixels > 0
        posPts = find(ROIim_sum{i,:} > 0);
        %get the number of pixels
        ROIcov_px(i,:) = length(posPts);
    
        %compile the centroid positions which are stored in a cell array
        ROIpos_cur = Results.Process.ROICentroid(i,:);
        ind = 1;
        
        for j = 1:size(ROIpos_cur,2)
            if ~isempty(ROIpos_cur{:,j})
                ROIcentroid_pos{i,:}(ind,:) = [ROIpos_cur{:,j}, j];
                ind = ind + 1;
            end
        end
        %Also subtract the mean position 
        X_cent = mean(ROIcentroid_pos{i,:}(:,1:2));
        ROIcentroid_pos{i,:}(:,4:5) = ROIcentroid_pos{i,:}(:,1:2) - X_cent;
    end
end
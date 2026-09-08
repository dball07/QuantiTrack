function [ROIcov_px, ROIim_sum, ROIcentroid_pos] = measureROImotion_Batch(splitLength,filenames)

%Allows user to select a group of files that will then be analyzed to 
%extract properties of ROI movement in the tracking results input
%variable Results.
%The outputs are:
%
%ROIcov_px: area covered by the entire ROI over the course of the movie
%ROIim_sum: sum projection of the ROI over time
%ROIcentroid_pos: X,Y coordinates of the center of the ROI over time. third
%column is the frame number. columns 4 and 5 are the displacement from the
%mean position.

if nargin < 2
    [files,path] = uigetfile('*.mat','Select Tracking Files to Analyze ROI motion','MultiSelect','on');
    if ~iscell(files)
        files_tmp{1,:} = files;
        files = files_tmp;
    end
    if files{1} ~= 0
        for i = 1:length(files)
            filenames{i,:} = fullfile(path,files{:,i});
        end
    else
        filenames = [];
    end
end
if nargin < 1
    splitLength = 0;
end

if isempty(filenames)
    ROIcov_px = [];
    ROIim_sum = [];
    ROIcentroid_pos = [];
    return;
else
    for i = 1:length(filenames)
        
        IN = load(filenames{i,:});
        if i == 1
            [ROIcov_px, ROIim_sum, ROIcentroid_pos] = measureROImotion(IN.Results,splitLength);
        else
            [ROIcov_px_tmp, ROIim_sum_tmp, ROIcentroid_pos_tmp] = measureROImotion(IN.Results,splitLength);
            
            ROIcov_px = [ROIcov_px; ROIcov_px_tmp];
            ROIim_sum = [ROIim_sum; ROIim_sum_tmp];
            ROIcentroid_pos = [ROIcentroid_pos; ROIcentroid_pos_tmp];
        end
    end
end

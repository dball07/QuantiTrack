function MSD = averageMSDfromFiles

[files, path] = uigetfile('*.mat','Select MSD files to merge','','MultiSelect','on');

if ~iscell(files)
    files_tmp{1} = files;
    files = files_tmp;
end

if files{1} == 0
    return;
end

[outfile, outpath] = uiputfile('*.mat','Specify the save name','');

MSD_all = cell(length(files),1);
all_delays = cell(length(files),1);
for i = 1:length(files)
    IN = load(fullfile(path,files{i}));
    MSD_all{i} = IN.MSD;
    all_delays{i} = MSD_all{i}(:,1);
end
delays = unique(vertcat(all_delays{:}));

n_delays = length(delays);

% Collect
sum_weight          = zeros(n_delays, 1);
sum_weighted_mean   = zeros(n_delays, 1);

for i = 1:length(files)
    t = MSD_all{i}(:,1);
    m = MSD_all{i}(:,2);
    n = MSD_all{i}(:,4);
    
    valid = ~isnan(m);
    t = t(valid);
    m = m(valid);
    if size(MSD_all{i},2)>4
        n = MSD_all{i}(:,5);
    else
        n = MSD_all{i}(:,4);
    end
    
    % Find common indices
    [~, index_in_all_delays, ~] = intersect(delays, t);
    
    % Accumulate
    sum_weight(index_in_all_delays)           = sum_weight(index_in_all_delays)         + n;
    sum_weighted_mean(index_in_all_delays)    = sum_weighted_mean(index_in_all_delays)  + m .* n;
end

% Compute weighted mean
mmean = sum_weighted_mean ./ sum_weight;

% 2nd pass: unbiased variance estimator
sum_weighted_variance = zeros(n_delays, 1);
sum_square_weight     = zeros(n_delays, 1);

for i = 1:length(files)
    t = MSD_all{i}(:,1);
    m = MSD_all{i}(:,2);
    if size(MSD_all{i},2)>4
        n = MSD_all{i}(:,5);
    else
        n = MSD_all{i}(:,4);
    end
    
    % Do not tak NaNs
    valid = ~isnan(m);
    t = t(valid);
    m = m(valid);
    n = n(valid);
    
    % Find common indices
    [~, index_in_all_delays, ~] = intersect(delays, t);
    
    % Accumulate
    sum_weighted_variance(index_in_all_delays)    = sum_weighted_variance(index_in_all_delays)  + n .* (m - mmean(index_in_all_delays)).^2 ;
    sum_square_weight(index_in_all_delays)        = sum_square_weight(index_in_all_delays)      + n.^2;
end
% Standard deviation
mstd = sqrt( sum_weight ./ (sum_weight.^2 - sum_square_weight) .* sum_weighted_variance );

% Output [ T mean std Nfreedom ]
MSD = [ delays mmean mstd (sum_weight.^2 ./ sum_square_weight) sum_weight];

save(fullfile(outpath,outfile),'MSD');

function MSD = compileDisplacements_v1(tracks,varargin)

if isempty(varargin)
    prec = 5;
else
    prec = varargin{1};
end
% t_vec_all = [];
% r_sq_all = [];
%convert track positions to microns
tracks(:,1:2) = tracks(:,1:2).*1e6;


%get all delays
tic;
parfor i = 1:max(tracks(:,4))
    curTrk = tracks(tracks(:,4) == i,:);
    t = curTrk(:,3);
    
    [T1, T2] = meshgrid(t, t);
    dT = round(abs(T1(:)-T2(:)),prec);
    all_delays{i} = unique(dT);
end
t1 = toc;
disp(['Calculation of all delays: ', num2str(round(t1,3)),' s']);

delays = unique(vertcat(all_delays{:}));
n_delays = numel(delays);
%get MSDs
tic
parfor i = 1:max(tracks(:,4))
    mean_msd = zeros(n_delays,1);
    M2_msd2  = zeros(n_delays,1);
    n_msd    = zeros(n_delays,1);
    
    curTrk = tracks(tracks(:,4) == i,:);
    tvec = round(curTrk(:,3),prec);
    xvec = interp1(curTrk(:,3),curTrk(:,1),tvec,'linear');
    yvec = interp1(curTrk(:,3),curTrk(:,2),tvec,'linear');
    
    curTrk(:,1) = xvec;
    curTrk(:,2) = yvec;
    curTrk(:,3) = tvec;
    for j = 1:size(curTrk,1)-1
        
        tmp = curTrk(j+1:end,:);
        t_vec = round((tmp(:,3) - curTrk(j,3)),prec);
        n_dt = numel(t_vec);
        index_in_all_delays = NaN(n_dt,1);
        for k = 1:n_dt
            [~,l] = min(abs(t_vec(k) - delays));
            index_in_all_delays(k) = l;
        end
        
        
        
        dX = tmp(:,1:2) - repmat(curTrk(j,1:2), [size(curTrk,1)-j 1]);
        dr2 = sum(dX.*dX,2);
        
        n_msd(index_in_all_delays) = n_msd(index_in_all_delays) + 1;
        delta = dr2 - mean_msd(index_in_all_delays);
        mean_msd(index_in_all_delays) = mean_msd(index_in_all_delays) + delta./ n_msd(index_in_all_delays);
        M2_msd2(index_in_all_delays)  = M2_msd2(index_in_all_delays) + delta .* (dr2 - mean_msd(index_in_all_delays));
        
    end
    n_msd(1) = size(curTrk,1);
    std_msd = sqrt(M2_msd2 ./ n_msd);
    
    delay_not_present = n_msd == 0;
    mean_msd(delay_not_present) = NaN;
    
    msd{i} = [delays mean_msd std_msd n_msd];
    
end
t2 = toc;
disp(['Calculation of all MSDs: ', num2str(round(t2,3)),' s']);

% Collect
sum_weight          = zeros(n_delays, 1);
sum_weighted_mean   = zeros(n_delays, 1);
%1st pass
tic
for i = 1:max(tracks(:,4))
    t = msd{i}(:,1);
    m = msd{i}(:,2);
    
    n = msd{i}(:,4);
    
    valid = ~isnan(m);
    t = t(valid);
    m = m(valid);
    n = n(valid);
    
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

for i = 1:max(tracks(:,4))
    t = msd{i}(:,1);
    m = msd{i}(:,2);
    n = msd{i}(:,4);
    
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
t3 = toc;
disp(['Calculation of mean MSDs: ', num2str(round(t3,3)),' s']);

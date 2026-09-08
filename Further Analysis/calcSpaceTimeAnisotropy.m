function [AC_t, AC_d] = calcSpaceTimeAnisotropy(angles,binCents_t,binCents_d, bootIter,parallelFlag)

if nargin < 2 || isempty(binCents_t)
    binCents_t = min(angles(:,2)):min(angles(:,2)):max(angles(:,2));
    binWidth_t = min(angles(:,2));
else
    binWidth_t = binCents_t(2) - binCents_t(1);
end

if nargin < 3 || isempty(binCents_d)
    binCents_d = min(angles(:,3)):1.5e-2:max(angles(:,3));
    binWidth_d = 1.5e-2;
else
    binWidth_d = binCents_d(2) - binCents_d(1);
end

if nargin < 4 || isempty(bootIter)
    bootIter = 0;
end
if nargin < 5
    parallelFlag = 0;
end

if ~isempty(angles)
%     binCents_t = min(angles(:,2)):binWidth_t:max(angles(:,2));
    binHalfWidth_t = binWidth_t/2;
    binEdges_t = binCents_t(1)-binHalfWidth_t:binWidth_t:binCents_t(end)+binHalfWidth_t;
    [~,~,bin_t] = histcounts(angles(:,2),binEdges_t);
    AC_t = zeros(length(binCents_t),1);
    ci_t = zeros(length(binCents_t),2);
    

    if parallelFlag == 1
        angles_par = cell(length(binCents_t),1);
        for i = 1:length(binCents_t)
            angles_par{i,:} = angles(bin_t == i,1);
        end
        parfor i = 1:length(binCents_t)
            %         ind = find(bin_t == i);
            % angles_i = angles(bin_t == i,1);
            angles_i = angles_par{i,:};

            if isempty(angles_i)
                AC_t(i,1) = nan;
                ci_tmp = [nan, nan];
                
            else
                AC_t(i,1) = anisCoeff_Calc(angles_i);
                if bootIter > 0
                    if isinf(AC_t(i,1)) || isnan(AC_t(i,1))
                        ci_tmp = [nan, nan];
                    else
                        %bootstrap to get 95%CI
                        ci_tmp = bootci(bootIter,{@anisCoeff_Calc,angles_i},'Type','cper','Options',statset('UseParallel',false));
                    end
                else
                    ci_tmp = [nan, nan];
                end
    
            end
            ci_t(i,:) = ci_tmp;
        end
    else
        for i = 1:length(binCents_t)
            %         ind = find(bin_t == i);
            angles_i = angles(bin_t == i,1);
    
            if isempty(angles_i)
                AC_t(i,1) = nan;
                ci_tmp = [nan, nan];
                
            else
                AC_t(i,1) = anisCoeff_Calc(angles_i);
                if bootIter > 0
                    if isinf(AC_t(i,1)) || isnan(AC_t(i,1))
                        ci_tmp = [nan, nan];
                    else
                        %bootstrap to get 95%CI
                        ci_tmp = bootci(bootIter,{@anisCoeff_Calc,angles_i},'Type','cper','Options',statset('UseParallel',false));
                    end
                else
                    ci_tmp = [nan, nan];
                end
    
            end
            ci_t(i,:) = ci_tmp;
        end
    end
    if bootIter > 0
        AC_t = [binCents_t(:), AC_t, ci_t];
    else
        AC_t = [binCents_t(:), AC_t];
    end

%     binCents_d = 0:binWidth_d:max(angles(:,3));
    binHalfWidth_d = binWidth_d/2;
    binEdges_d = binCents_d(1)-binHalfWidth_d:binWidth_d:binCents_d(end)+binHalfWidth_d;
    [~,~,bin_d] = histcounts(angles(:,3),binEdges_d);
    AC_d = zeros(length(binCents_d),1);
    ci_d = zeros(length(binCents_d),2);

    if parallelFlag == 1
        angles_par = cell(length(binCents_d),1);
        for i = 1:length(binCents_d)
            angles_par{i,:} = angles(bin_d == i,1);
        end
        parfor i = 1:length(binCents_d)
            %         ind = find(bin_d == i);
            % angles_i = angles(bin_d == i,1);
            angles_i = angles_par{i,:};
            if isempty(angles_i)
                AC_d(i,1) = nan;
                ci_tmp = [nan, nan];
                
            else
                AC_d(i,1) = anisCoeff_Calc(angles_i);
                if bootIter > 0
                    if isinf(AC_d(i,1)) || isnan(AC_d(i,1))
                        ci_tmp = [nan, nan];
                    else
                        %bootstrap to get 95%CI
                        ci_tmp = bootci(bootIter,{@anisCoeff_Calc,angles_i},'Type','cper','Options',statset('UseParallel',false));
                    end
                else
                    ci_tmp = [nan, nan];
                end
    
            end
            ci_d(i,:) = ci_tmp;
        end
    else
        for i = 1:length(binCents_d)
            %         ind = find(bin_d == i);
            angles_i = angles(bin_d == i,1);
            if isempty(angles_i)
                AC_d(i,1) = nan;
                ci_tmp = [nan, nan];
                
            else
                AC_d(i,1) = anisCoeff_Calc(angles_i);
                if bootIter > 0
                    if isinf(AC_d(i,1)) || isnan(AC_d(i,1))
                        ci_tmp = [nan, nan];
                    else
                        %bootstrap to get 95%CI
                        ci_tmp = bootci(bootIter,{@anisCoeff_Calc,angles_i},'Type','cper','Options',statset('UseParallel',false));
                    end
                else
                    ci_tmp = [nan, nan];
                end
    
            end
            ci_d(i,:) = ci_tmp;
        end
    end
    if bootIter > 0
        AC_d = [binCents_d(:), AC_d, ci_d];
    else
        AC_d = [binCents_d(:), AC_d];
    end



else
    AC_t = [];
    AC_d = [];
end
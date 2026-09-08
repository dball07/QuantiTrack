function msd = CalculateMSD(x,numLags)
%--------------------------------------------------------------------------
% This function calculates the MSD of a particle trajectory
%
% Code written by: 
%       Peter Koo
%       Yale University, Department of Physis, New Haven, CT, 06511  
%--------------------------------------------------------------------------

dim = size(x,2);

msd = zeros(1,numLags);
for i = 1:numLags
    rho = [];
    for j = 1:i
        for k = 1:dim
            rho = [rho; diff(x(j:i:end,k)).^2];
        end
    end
    msd(i) = mean(rho);
end


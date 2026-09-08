function [P1norm,Gs,psf] = RL_fitVanHove(vanHove,Niter,MSDmin,MSDmax,MSDnBins)

% Richardson-Lucy algorithm to extract P(D) from G(r,t)
% see Ashwin et al. PNAS
% Given a van Hove correlation function, this routine uses the RL algorithm
% to calculate the underlying distribution of MSDs that gave rise to the vH
% function, with the assumption of Gaussian distributed jumps for a given M
% $G(r,t) = \int dM P(M) A exp(-r^2/M)$
% Required Input: 
%       vanHove: vanHove distribution. 2-columns, where first column is the
%       bins, and second column is the Correlation values
% Optional Inputs:
%       Niter : number of iterations for RL algorithm (default: 50,000)
%       MSDmin: minumum for the grid of MSDs (default: 1e-4)
%       MSDmax: maximum for the grid of MSDs (default: 0.25)
%       MSDnBins: number of points in the grid of MSDs (default: 400)
%
% Output:
%       M: values over which empirical MSDs are estimated
%       Gs: estimated van Hove correlation
%       P1norm: P(M), probability distribution of MSDs
% A test case is the empirical distribution of 2 Gaussians 
% Memp=logspace(log10(1e-3),log10(2e-1),200);
% PM=30*exp(-(M-5e-3).^2/(2*1e-6))+10*exp(-(M-5e-2).^2/(2*1e-4));
% which can be used to forward calculate G(r,t) using the point-spread
% function below. Then RL can applied to recover this "unknown" G(r,t) as
% below.

%parse inputs and set missing parameters to the default
if nargin < 2 || isempty(Niter)
    Niter = 50000;
end
if nargin < 3 || isempty(MSDmin)
    MSDmin = 1e-4;
end
if nargin < 4 || isempty(MSDmax)
    MSDmax = 0.25;
end
if nargin < 5 || isempty(MSDnBins)
    MSDnBins = 400;
end

% allocate the grid for MSD calculation
M = logspace(log10(MSDmin),log10(MSDmax),MSDnBins); % allocate the grid for MSD calculation
lM = length(M);

x = vanHove(:,1);
lx = length(vanHove);

%replicate the van Hove bins and the MSD bins to get the "PSF"
M_mat = repmat(M,lx,1);
x_mat = repmat(vanHove(:,1),1,lM);


psf = (1./(pi.*M_mat)).*exp(-(x_mat).^2./(M_mat)); %Gaussian "PSF"

P1=exp(-(M)/1e-3); % initial guess. changing the denominator by 2 OoM doesn't make a difference
P1norm=P1/trapz(M,P1); %normalize P(M) so that integral of P1norm is 1



for iterations=1:Niter
    Gs = trapz(M,P1norm(ones(lx,1),:).*psf,2); %RL first step
    Gsest = vanHove(:,2)./Gs; %ratio of empirical vH to estimated vH
    convest = trapz(x,2*pi*x(:,ones(lM,1)).*Gsest(:,ones(lM,1)).*psf,1); % blur again with PSF
    P1norm = P1norm.*convest; % compute new estimate of P(M)
    P1norm = P1norm/trapz(M,P1norm); %normalize P(M)
    residual=sum((Gs-trapz(M,P1norm.*psf,2)).^2);
    if(residual<1e-12)
        fprintf('number of iterations = %d\n',iterations)
        break 
    end
end

Gs = trapz(M,P1norm(ones(lx,1),:).*psf,2); % estimated van Hove correlation
P1norm = [M(:), P1norm(:)];
Gs = [x,Gs(:)];
fprintf('residual %0.5g\n',residual)
fprintf('integrated squared error %f\n',trapz(x,2*pi*x'.*((Gs(1:end,2)-vanHove(:,2)).^2)))


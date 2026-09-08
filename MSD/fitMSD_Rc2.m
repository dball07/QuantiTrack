function [D, Rc,D_CI, Rc_CI, D_fit, Rc_fit] = fitMSD_Rc2(lags,msd,varargin)

%fits the initial points of the MSD to a line to obtain the diffusion
%coefficient, and the uses this value to fit the entire MSD to the equation
%MSD(t) = Rc^2*(1 - exp(-4Dt/(Rc^2));
%The optional third input specifies the points in the MSD to fit to find D.
% If it is not specified, then the default value of 4 is used. 
% From Wieser & Shutz 2008
%
%D. Ball 2022


%specify the data for fitting D
dataD = [lags(:), msd(:)];
dataR = [lags(:), msd(:)];
if isempty(varargin)
    dataD = dataD(1:4,:);
else
    Dfitlims = varargin{1};
    dataD = dataD(Dfitlims(1):Dfitlims(2),:);
end

% dataR(:,2) = dataR(:,2)./max(dataR(:,2));
%fit the MSD points to a line
[line_coeff, line_sigma, D_fit] = Line_fit(dataD,1);

D = line_coeff(1);
D_CI = line_sigma(1);
D = D./4;
D_CI = D_CI./4;
%fit the whole MSD to the confinement

% define initial values for the parameters
COEF0 = [sqrt(max(msd)), D];

% define lower boundaries for the fitted parameters
COEF_LB = [0, 0];
% define upper boundaries for the fitted parameters
COEF_UB = [Inf, Inf];

% Define anonymous function for the fitting
fitfun = @(COEF) (Confine_fun(COEF, dataR(:,1)) -  dataR(:,2));

% Select Options for the fitting
options = optimset('FunValCheck','off','Display','off');

% run fitting routine
[Rc, resNorm, residuals,exitflag,output,lambda,jacobian] = lsqnonlin(fitfun,COEF0,COEF_LB,COEF_UB,options);
ci = nlparci(Rc,residuals,'jacobian',jacobian);
Rc_CI = (ci(:,2) - ci(:,1))/2;
Rc_CI = Rc_CI';

% Compute output
Rc_fit(:,1) = dataR(:,1);
Rc_fit(:,2)= Confine_fun(Rc,Rc_fit(:,1));

function MSD = Confine_fun(COEF,t)

Rc = COEF(1);
D = COEF(2);

MSD = (Rc.^2)*(1 - exp(-4*D*t/(Rc.^2)));
% MSD = (1 - exp(-4*D*t/(Rc.^2)));

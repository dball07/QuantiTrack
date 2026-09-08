function [Pwr_Coef, Pwr_Sigma, Pwr_Fit] = PwrLawDecay_nlinfit(data, k0s)

% Calculate best two compoonent exponential fit with a the lsqnonlin non 
%linear least square fitting routine.


% Read input data

tlist =data(:,1);
Y = data(:,2);
tlist = tlist(Y > 0);
Y = Y(Y > 0);

k01 = k0s(1);
A0 = max(Y);


% define initial values for the parameters
COEF0 = [k01, A0];


% define lower boundaries for the fitted parameters
% COEF_LB = [0, 0, 0 , 0];
COEF_LB = [0,0];
% 
% % define upper boundaries for the fitted parameters
COEF_UB = [Inf, Inf];

% Define anonymous function for the fitting
% fitfun = @(COEF) (ExpDecay_2Cmp_fun(COEF, tlist)) - (Y);
% fitfun = @(COEF,tlist)PwrLawDecay_fun(COEF, tlist);
fitfun = @(COEF)(PwrLawDecay_log_fun(COEF, tlist)-log10(Y));
% Select Options for the fitting
options = optimset('FunValCheck','off', 'MaxIter', 1000, 'MaxFunEvals', 1000, 'TolFun',10e-30);
% opts = statset('nlinfit');
% opts.RobustWgtFun = 'bisquare';
% opts.TolFun = 10e-30;
% opts.MaxIter = 1000;
% [Pwr_Coef, residuals,jacobian] = nlinfit(data(:,1),data(:,2),fitfun,COEF0,opts);
[Pwr_Coef, resNorm, residuals,exitflag,output,lambda,jacobian] = lsqnonlin(fitfun,COEF0,COEF_LB,COEF_UB,options);
% run fitting routibe
% [Esp_Coef, resNorm, residuals,exitflag,output,lambda,jacobian] = lsqnonlin(fitfun,COEF0,COEF_LB,COEF_UB,options);
% [Esp_Coef, resNorm, residuals,exitflag,output,lambda,jacobian] = lsqnonlin(fitfun,COEF0,options);

ci = nlparci(Pwr_Coef,residuals,'jacobian',jacobian);
Pwr_Sigma = (ci(:,2) - ci(:,1))/2;
Pwr_Sigma = Pwr_Sigma';



% Compute output
Pwr_Fit(:,1) = data(:,1);
Pwr_Fit(:,2) = PwrLawDecay_fun(Pwr_Coef, data(:,1));


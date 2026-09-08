function [h,pval,zscore] = comparePopFractions(f1,f2, n1, n2,varargin)

% Z-test for population fractions, with the Null hypothesis that the 
% fractions are equal. Inputs are the individual fractions (f1,f2) and the 
% number of total cells in each population (n1,n2). Optionally, the
% significance level can be defined (default value is 0.05). Output is the
% result of the hypothesis test, 0 meaning the Null hypothesis can not be
% rejected, and 1 being a significant difference. Optionally, returns the
% p-value, and z-score.
%
%D. Ball 4/2021

if isempty(varargin)
    sig = 0.05;
else
    sig = varargin{1};
end

f_total = ((f1.*n1) + (f2.*n2))./(n1 + n2);

n_total = n1 + n2;

zscore = (f1 - f2)./sqrt(f_total.*(1 - f_total).*((1/n1) + (1/n2)));
zscore = abs(zscore);

%Generate the normal cdf
x = 0:0.0001:100;
CDF = normcdf(x);
CDF = CDF- 0.5;

%Calculate the area under the PDF up to zscore
lastInd = find(x <= zscore,1,'last');

Area = CDF(lastInd);

pval = 0.5 - Area;

if pval < sig
    h = 1;
else
    h = 0;
end
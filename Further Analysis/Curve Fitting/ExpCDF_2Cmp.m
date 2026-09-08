function y = ExpCDF_2Cmp(x,mu1,mu2,f1)

y1 = expcdf(x,mu1);
y2 = expcdf(x,mu2);

y = (f1*y1)+((1-f1)*y2);

% xdiff = diff(x);
% normFac = y(end).*xdiff(end);
% 
% y = y./normFac;



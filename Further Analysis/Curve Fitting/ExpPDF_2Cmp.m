function y = ExpPDF_2Cmp(x,mu1,mu2,f1)

y1 = exppdf(x,mu1);
y2 = exppdf(x,mu2);

y = (f1*y1)+((1-f1)*y2);

% xdiff = diff(x);
% normFac = sum(y(1:end-1).*xdiff);
% 
% y = y./normFac;



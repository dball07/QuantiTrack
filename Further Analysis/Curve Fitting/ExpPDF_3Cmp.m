function y = ExpPDF_3Cmp(x,mu1,mu2,mu3,f1,f2)

y1 = exppdf(x,mu1);
y2 = exppdf(x,mu2);
y3 = exppdf(x,mu3);

y = (f1*y1)+(f2*y2)+((1-f1-f2).*y3);

% xdiff = diff(x);
% normFac = sum(y(1:end-1).*xdiff);
% 
% y = y./normFac;



function pwr = PwrLawGrowth_fun(coeff, x)


alpha = coeff(1);
D = coeff(2);
if length(coeff) < 3
    sigma = 0;
else
    sigma = coeff(3);
end

% c = 4*(sigma^2);
c = sigma;
pwr = D.*x.^(alpha) + c;%*(1 - (k < 0| a<0));

% if (k < 0) || (a < 0)
%     pwr = 100000.*ones(size(x));
% end
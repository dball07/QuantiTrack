function pwr = PwrLawDecay_log_fun(coeff, x)


k = coeff(1);
a = coeff(2);


pwr = a.*x.^(-k);%*(1 - (k < 0| a<0));
pwr = log10(pwr);

% if (k < 0) || (a < 0)
%     pwr = 100000.*ones(size(x));
% end
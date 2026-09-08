function pwr = PwrLawDecay_fun(coeff, x)


k = coeff(1);
a = coeff(2);


pwr = a.*x.^(-k);%*(1 - (k < 0| a<0));

% if (k < 0) || (a < 0)
%     pwr = 100000.*ones(size(x));
% end
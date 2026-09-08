function esp = ExpDecay_2Cmp_log_fun(coeff, x)


k1 = coeff(1);
k2 = coeff(2);
f = coeff(3);
a = coeff(4);


esp = a*(f*(exp(-k1*x)) + (1-f)*exp(-k2*x))*(1 - (k1 < 0|k2 < 0|f < 0|f > 1| a<0));
esp = log10(esp);
% esp = f*(exp(-k1*x)) + a*exp(-k2*x);
% if (k1 < 0) || (k2 < 0) || (f < 0) || (f > 1) || (a < 0)
%     esp = 100000.*ones(size(x));
% end

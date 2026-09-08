function esp = ExpDecay_3Cmp_log_fun(coeff, x)


k1 = coeff(1);
k2 = coeff(2);
k3 = coeff(3);
f1 = coeff(4);
f2 = coeff(5);
a = coeff(6);



esp = a*(f1*(exp(-k1*x)) + f2*exp(-k2*x) + (1 - f1 - f2)*exp(-k3*x));%.*(1 - (k1 < 0|k2 < 0|k3 < 0|f1 < 0|f1 > 1|f2 < 0| f2 > 1| a<0));
esp = log10(esp);
% if (k1 < 0) || (k2 < 0) || (k3 < 0) || (f1 < 0) || (f1 > 1) || (f2 < 0) || (f2 > 1) ||(a < 0)
%     esp = 100000.*ones(size(x));
% end
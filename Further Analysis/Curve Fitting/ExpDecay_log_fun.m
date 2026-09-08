function esp = ExpDecay_log_fun(coeff, x)


k = coeff(1);
a= coeff(2);



esp = a*(exp(-k*x));
esp = log10(esp);


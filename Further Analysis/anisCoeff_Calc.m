function AC_i = anisCoeff_Calc(angles_i)


Ntotal = length(angles_i);
ind180 = find(angles_i >= pi-(3*pi/18) & angles_i <= pi+(3*pi/18));
N180 = length(ind180);
f180 = N180./Ntotal;
ind0 = find(angles_i <= 3*pi/18 | angles_i >= 2*pi - (3*pi/18));
N0 = length(ind0);
f0 = N0./Ntotal;
if N0 > 0
    AC_i = log2(f0/f180);
else
    AC_i = NaN;
end
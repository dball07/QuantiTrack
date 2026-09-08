function pVal_vector = bootstrapKStest2(dist1,dist2,nSamples,nRuns)

pVal_vector = zeros(nRuns,1);

for i = 1:nRuns
    d1_sub = datasample(dist1,nSamples);
    d2_sub = datasample(dist2,nSamples);

    [~, pVal_vector(i)] = kstest2(d1_sub,d2_sub);
    
end
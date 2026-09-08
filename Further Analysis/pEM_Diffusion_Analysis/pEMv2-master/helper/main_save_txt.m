

hmmFile = 0;  % change to 1 if ran HMM
[filename,dirpath] = uigetfile('*.mat','Select pEMv2 results.mat file');


results = load(fullfile(dirpath,filename),'results');
dlmwrite(fullfile(dirpath, 'OptimalVacf.txt'), results.optimalVacf, 'delimiter', '\t','newline','pc');
dlmwrite(fullfile(dirpath, 'OptimalP.txt'), results.optimalP, 'delimiter', '\t','newline','pc');
dlmwrite(fullfile(dirpath, 'OptimalL.txt'), results.optimalL, 'delimiter', '\t','newline','pc');
dlmwrite(fullfile(dirpath, 'PosteriorProb.txt'), results.posteriorProb, 'delimiter', '\t','newline','pc');
dlmwrite(fullfile(dirpath, 'BIC.txt'), results.BIC, 'delimiter', '\t','newline','pc');

if hmmFile == 1
    dlmwrite(fullfile(dirpath, 'HMM_pvector.txt'), results.hmm.p, 'delimiter', '\t','newline','pc');
    dlmwrite(fullfile(dirpath, 'HMM_transition.txt'), results.hmm.a, 'delimiter', '\t','newline','pc');
    dlmwrite(fullfile(dirpath, 'HMM_emission.txt'), results.hmm.b, 'delimiter', '\t','newline','pc');
    dlmwrite(fullfile(dirpath, 'HMM_VACF.txt'), results.hmm.sigma, 'delimiter', '\t','newline','pc');
    dlmwrite(fullfile(dirpath, 'HMM_PosteriorProb.txt'), results.hmm.gammank, 'delimiter', '\t','newline','pc');    
    dlmwrite(fullfile(dirpath, 'HMM_logL.txt'), results.hmm.logL, 'delimiter', '\t','newline','pc');   
end
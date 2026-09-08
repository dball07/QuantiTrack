function [logD, FJH] = resampleFJH(fullJumpHist,varargin)

FJH = fullJumpHist(1:2,2:end);

dT = fullJumpHist(2,1) - fullJumpHist(1,1);

if isempty(varargin)
    nSamples = 100000;
else
    nSamples = varargin{1};
end

%change the probability of a jump to number based on #samples
FJH_N(1,:) = FJH(1,:);
FJH_N(2,:) = round(nSamples*FJH(2,:)./sum(FJH(2,:)));

%create an array of jumps based on the centers of the bins. For best
%results, its best to make the bins as small as possible when creating the 
%fullJumpHist20 nm should be adequate.

jumps = zeros(nSamples,1);
nOld = 1;

for i = 1:size(FJH,2)
    nCur = FJH_N(2,i);
    jumps(nOld:(nOld + nCur - 1),:) = FJH_N(1,i).*ones(nCur,1);
    nOld = nOld + nCur;
end

% remove indices that weren't used
jumps(jumps == 0) = [];

%convert displacement into Diffusion coeffient. 
D  = (jumps.^2)./(4.*dT);
%take log10
logD = log10(D);




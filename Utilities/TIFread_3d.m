function [imStack,nFrames] = TIFread_3d(fileName)

imStack = [];

info = imfinfo(fileName);
nFrames = length(info);

for iImg = 1:nFrames
    imStack(:,:,iImg) = imread(fileName,iImg);
    
end




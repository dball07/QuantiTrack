for i = 1:length(folds)
    cd(folds(i).name);
    Ref_file = dir('*488.tif');
    Mol_file = dir('*647_aligned.tif');
    [RefIm, nImRef] = TIFread(Ref_file(1).name);
    [ROIpos, ROIimage,Cent] =autoROIs2(RefIm,nImRef);
    Results.Process.ROIpos = ROIpos;
    Results.Process.ROIimage = ROIimage;
    Results.Process.ROICentroid = Cent;
    for j = 1:size(ROIpos,1)
        d = num2str(j);
        Results.Process.ROIlabel{j,:} = ['ROI', d];
    end
    Results.Data.fileName = Mol_file(1).name;
    Results.Data.pathName = pwd;
    [Results.Data.imageStack,nFrames] = TIFread(Mol_file(1).name);
    for j = 1:nFrames
        Results.Process.filterStack(j).data = ...
            bpass(Results.Data.imageStack(j).data, 1, 5);
    end
    Results.Data.fileName = Mol_file(1).name;
    Results.Data.pathName = pwd;
    Results.isFitPSF = 1;
    cd ..
    Version = 2;
    Results.Data.nImages = length(Results.Data.imageStack);
    save([Mol_file(1).name(1:end-3),'mat'],'Results','Version','-v7.3');
    clear Results ROIimage ROIpos Cent RefIm
end
im1_suff = '561_Cam1';
im2_suff = '647_Cam1';
im3_suff = '561_Cam2';
im4_suff = '647_Cam2';


for i = 1:length(folders)
    cd(folders(i).name);
    imfile1 = dir('*561_aligned.tif');
    [imStack,nImages] = TIFread(imfile1(1).name);
    im_fileOut1 = [imfile1(1).name(1:end-4),'_', im1_suff, '.tif'];
    im_fileOut2 = [imfile1(1).name(1:end-4),'_', im2_suff, '.tif'];
    for j = 1:2:nImages
        imwrite(imStack(j).data,im_fileOut1,'WriteMode','append');
    end
    for j = 2:2:nImages
        imwrite(imStack(j).data,im_fileOut2,'WriteMode','append');
    end
    imfile2 = dir('*647.tif');
    [imStack,nImages] = TIFread(imfile2(1).name);
    im_fileOut1 = [imfile2(1).name(1:end-4),'_', im3_suff, '.tif'];
    im_fileOut2 = [imfile2(1).name(1:end-4),'_', im4_suff, '.tif'];
    
    for j = 1:2:nImages
        imwrite(imStack(j).data,im_fileOut1,'WriteMode','append');
    end
    for j = 2:2:nImages
        imwrite(imStack(j).data,im_fileOut2,'WriteMode','append');
    end
    cd ..
end
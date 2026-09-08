prefix = '15-';
midpart = 'GR_JF549_JF669_561_647_alt_2CamsSim_100msExp_100msInt_15mW561_MMStack_Pos0.ome_';

matfile1 = [prefix,midpart,'561_aligned_561_Cam1.mat'];
matfile2 = [prefix,midpart,'647_647_Cam2.mat'];
imfile1 = [prefix,midpart,'561_aligned_647_Cam1.tif'];
imfile2 = [prefix,midpart,'647_647_Cam2.tif'];
imfile3 = [prefix,midpart,'647_561_Cam2.tif'];
imfile4 = [prefix,midpart,'561_aligned_647_Cam1.tif'];
imfile5 = [prefix,midpart,'647_561_Cam2.tif'];
imfile6 = [prefix,midpart,'561_aligned_561_Cam1.tif'];

load(matfile1);
[imStack,nImages] = TIFread(imfile1);
trk_cov_532_647_short = Track_FRETCovariance(Results,imStack);
[imStack,nImages] = TIFread(imfile2);
trk_cov_532_short_647_long = Track_FRETCovariance(Results,imStack);
[imStack,nImages] = TIFread(imfile3);
trk_cov_532_short_long = Track_FRETCovariance(Results,imStack);
load(matfile2)
[imStack,nImages] = TIFread(imfile4);
trk_cov_647_long_short = Track_FRETCovariance(Results,imStack);
[imStack,nImages] = TIFread(imfile5);
trk_cov_647_532_long = Track_FRETCovariance(Results,imStack);
[imStack,nImages] = TIFread(imfile6);
trk_cov_647_long_532_short = Track_FRETCovariance(Results,imStack);
save('Tracking_Cov.mat','trk_cov*')
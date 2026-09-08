folders = dir;
folders(1) = [];
folders(end) = [];
folders(1) = [];
folders(end) = [];
JF533_trk_cov_532_647_short = [];
JF533_trk_cov_532_short_647_long = [];
JF533_trk_cov_532_short_long = [];
JF533_trk_cov_647_532_long = [];
JF533_trk_cov_647_long_532_short = [];
JF533_trk_cov_647_long_short = [];
for i = 1:5
%     if i ~= 3
        load([folders(i).name,filesep,'Tracking_Cov.mat']);
        trk_cov_532_647_short = [trk_cov_532_647_short, i*ones(size(trk_cov_532_647_short,1),1)];
        JF533_trk_cov_532_647_short = [JF533_trk_cov_532_647_short;trk_cov_532_647_short];
        
        trk_cov_532_short_647_long = [trk_cov_532_short_647_long, i*ones(size(trk_cov_532_short_647_long,1),1)];
        JF533_trk_cov_532_short_647_long = [JF533_trk_cov_532_short_647_long; trk_cov_532_short_647_long];
        
        trk_cov_532_short_long = [trk_cov_532_short_long, i*ones(size(trk_cov_532_short_long,1),1)];
        JF533_trk_cov_532_short_long = [JF533_trk_cov_532_short_long; trk_cov_532_short_long];
        
        trk_cov_647_532_long = [trk_cov_647_532_long, ones(size(trk_cov_647_532_long,1),1)];
        JF533_trk_cov_647_532_long = [JF533_trk_cov_647_532_long; trk_cov_647_532_long];
        
        trk_cov_647_long_532_short = [trk_cov_647_long_532_short, i*ones(size(trk_cov_647_long_532_short,1),1)];
        JF533_trk_cov_647_long_532_short = [JF533_trk_cov_647_long_532_short; trk_cov_647_long_532_short];
        
        trk_cov_647_long_short = [trk_cov_647_long_short, i*ones(size(trk_cov_647_long_short,1),1)];
        JF533_trk_cov_647_long_short = [JF533_trk_cov_647_long_short; trk_cov_647_long_short];
%     end
end
save('JF533_track_covariances.mat','JF533_trk*');
JF635_trk_cov_532_647_short = [];
JF635_trk_cov_532_short_647_long = [];
JF635_trk_cov_532_short_long = [];
JF635_trk_cov_647_532_long = [];
JF635_trk_cov_647_long_532_short = [];
JF635_trk_cov_647_long_short = [];
for i = 6:10
    load([folders(i).name,filesep,'Tracking_Cov.mat']);
    trk_cov_532_647_short = [trk_cov_532_647_short,i*ones(size(trk_cov_532_647_short,1),1)];
    JF635_trk_cov_532_647_short = [JF635_trk_cov_532_647_short;trk_cov_532_647_short];
    
    trk_cov_532_short_647_long = [trk_cov_532_short_647_long, i*ones(size(trk_cov_532_short_647_long,1),1)];
    JF635_trk_cov_532_short_647_long = [JF635_trk_cov_532_short_647_long; trk_cov_532_short_647_long];
    
    trk_cov_532_short_long = [trk_cov_532_short_long, i*ones(size(trk_cov_532_short_long,1),1)];
    JF635_trk_cov_532_short_long = [JF635_trk_cov_532_short_long; trk_cov_532_short_long];
    
    trk_cov_647_532_long = [trk_cov_647_532_long,i*ones(size(trk_cov_647_532_long,1),1)];
    JF635_trk_cov_647_532_long = [JF635_trk_cov_647_532_long; trk_cov_647_532_long];
    
    trk_cov_647_long_532_short = [trk_cov_647_long_532_short, ones(size(trk_cov_647_long_532_short,1),1)];
    JF635_trk_cov_647_long_532_short = [JF635_trk_cov_647_long_532_short; trk_cov_647_long_532_short];
    
    trk_cov_647_long_short = [trk_cov_647_long_short, i*ones(size(trk_cov_647_long_short,1),1)];
    JF635_trk_cov_647_long_short = [JF635_trk_cov_647_long_short; trk_cov_647_long_short];
end
save('JF635_track_covariances.mat','JF635_trk*');
JF533_JF635_trk_cov_532_647_short = [];
JF533_JF635_trk_cov_532_short_647_long = [];
JF533_JF635_trk_cov_532_short_long = [];
JF533_JF635_trk_cov_647_532_long = [];
JF533_JF635_trk_cov_647_long_532_short = [];
JF533_JF635_trk_cov_647_long_short = [];
for i = 11:15
    load([folders(i).name,filesep,'Tracking_Cov.mat']);
    trk_cov_532_647_short = [trk_cov_532_647_short,i*ones(size(trk_cov_532_647_short,1),1)];
    JF533_JF635_trk_cov_532_647_short = [JF533_JF635_trk_cov_532_647_short;trk_cov_532_647_short];
    
    trk_cov_532_short_647_long = [trk_cov_532_short_647_long, i*ones(size(trk_cov_532_short_647_long,1),1)];
    JF533_JF635_trk_cov_532_short_647_long = [JF533_JF635_trk_cov_532_short_647_long; trk_cov_532_short_647_long];
    
    trk_cov_532_short_long = [trk_cov_532_short_long, i*ones(size(trk_cov_532_short_long,1),1)];
    JF533_JF635_trk_cov_532_short_long = [JF533_JF635_trk_cov_532_short_long; trk_cov_532_short_long];
    
    trk_cov_647_532_long = [trk_cov_647_532_long, i*ones(size(trk_cov_647_532_long,1),1)];
    JF533_JF635_trk_cov_647_532_long = [JF533_JF635_trk_cov_647_532_long; trk_cov_647_532_long];
    
    trk_cov_647_long_532_short = [trk_cov_647_long_532_short, i*ones(size(trk_cov_647_long_532_short,1),1)];
    JF533_JF635_trk_cov_647_long_532_short = [JF533_JF635_trk_cov_647_long_532_short; trk_cov_647_long_532_short];
    
    trk_cov_647_long_short = [trk_cov_647_long_short,i*ones(size(trk_cov_647_long_short,1),1)];
    JF533_JF635_trk_cov_647_long_short = [JF533_JF635_trk_cov_647_long_short; trk_cov_647_long_short];
end
save('JF533_JF635_track_covariances.mat','JF533_JF635_trk*');
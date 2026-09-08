%%
train_ind = 1:10;


im_stats_train = [];
resp_train = [];
for i = 1:length(train_ind)
    imStack = TIFread_3d(im_files(train_ind(i)).name);
    im_stats_train_tmp = imageStats2(imStack);
    im_stats_train = [im_stats_train;im_stats_train_tmp];
    
    S = load(['mask-',im_files(train_ind(i)).name(1:end-4),'.mat']);
    resp_train = [resp_train; S.ROIimage{1}(:)];
    
end
%% Training
InBagFraction = 0.95;
MinLeafSize = 1;
NumPred = 'all';
NumTrees = 10;
options = struct('UseParallel',true,'UseSubstreams',false,'Streams',[]);

BagOtrees = TreeBagger(NumTrees,im_stats_train,resp_train,"InBagFraction",InBagFraction,...
"MinLeafSize",MinLeafSize,"NumPredictorsToSample",NumPred,"OOBPrediction","on","Options",options);

oob_err = oobError(BagOtrees,'Mode','ensemble');
%% Validation
valid_ind = 1:20;
im_stats_valid = [];
for i = 1:length(valid_ind)
    imStack = TIFread_3d(im_files(valid_ind(i)).name);
    im_stats_valid_tmp = imageStats2(imStack);
    
    pred_out = predict(BagOtrees,im_stats_valid_tmp);
    for j = 1:length(pred_out)
        test_pred_arr(j,:) = str2double(pred_out{j});
    end
    resp_pred(:,:,i) = reshape(test_pred_arr,256,256);
    
    
    
    S = load(['mask-',im_files(valid_ind(i)).name(1:end-4),'.mat']);
    resp_act(:,:,i) = S.ROIimage{1};
    
end
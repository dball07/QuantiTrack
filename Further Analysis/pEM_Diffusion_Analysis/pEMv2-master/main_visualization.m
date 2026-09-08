%--------------------------------------------------------------------------
% This script generates some examples of analytics and visualizations that 
% can be obtained from pEMv2 analysis.  Here, it is a direct comparison of 
% its performance on simulated data.  (This script will only run if the
% default file name conventions and directory structure is kept.) This
% script generates numerous plots. Note that while the plots here are generated
% for comparisons between pEMv2 and simulations, extensions to experimental
% data can also be made by reusing the functions used to generate the
% plots, albeit this will take some reverse engineering.  
% 
% Code written by: 
%       Peter Koo
%       Yale University, Department of Physis, New Haven, CT, 06511  
%--------------------------------------------------------------------------

clear all;
clc; 
close all;
addpath('visualization');

%% user parameters

savepath = 'results';   % file where results are stored
saveall = 1;            % save all plots generated

%% load data 

% load simulation data (i.e. ground truth)
[filename,dirpath] = uigetfile('*.mat','Select simulation file');
data = load(fullfile(dirpath,filename));
[tmp,name] = fileparts(filename);
X = data.X;
true_stateSeq = data.markovStateSeq;
simParams = data.simParams;
true_numStates = simParams.numStates;
true_state = simParams.state;
true_A = simParams.A;

% load pEMv2 results
try
    data = load(fullfile(savepath,name,[name '_results.mat']));
    status = 1;
    savepath = fullfile(savepath,name);
    mkdir(savepath);
catch
    disp(['Results file does not exist:' fullfile('Results',[name '_results.mat'])]);
    status = 0;
end

if status == 1

    results = data.results;
    splitX = results.X;
    trackInfo = results.trackInfo;
    splitIndex = results.trackInfo.splitIndex;
    splitLength = trackInfo.splitLength;
    numFeatures = trackInfo.numFeatures;
    vacf_exp = trackInfo.vacf_exp;
    BIC = results.BIC;
    state = results.state;


    %% Print summary of results

    disp('-------------------------------------------------------');
    disp(['Summary of Results']);
    disp(['True number of states: ' num2str(simParams.numStates) ]);
    disp(['Est number of states: ' num2str(results.optimalSize) ]);
    if results.optimalSize == simParams.numStates
        disp('Correct number of states found');
    else
        disp('Wrong number of states found...');
        disp('WARNING: remaining analysis assumes correct number of states');
    end    
    numStates = simParams.numStates;
    numTracks = length(true_stateSeq);
    posteriorProb = state(simParams.numStates).posteriorProb;

    
    % plot BIC
    figure; hold on; box on;
    stateRange = find(BIC ~=0);
    plot(stateRange,BIC(stateRange),'b','linewidth',1.5);
    plot([numStates numStates],[min(BIC(stateRange)) max(BIC(stateRange))],'--k');
    set(gca,'fontsize',20,'linewidth',2);
    xlabel('Model size (states)','fontsize',20);
    ylabel('BIC','fontsize',20);
    if saveall == 1
        print('-depsc',fullfile(savepath,['BIC_comparison']));
    end

    % store results in analytics structure
    analytics = struct;
    analytics.true_numStates = simParams.numStates;
    analytics.est_numStates = results.optimalSize;
    analytics.BIC = BIC;


    %% Fraction correct (Ground truth state matches estimated state)

    % true state sequence (mode within a bin)
    true_stateIndex = zeros(length(splitX),1);
    k = 1;
    for i = 1:length(true_stateSeq)
        N = length(true_stateSeq{i});
        for j = 1:floor(N/splitLength)
            range = j*splitLength-splitLength+1:j*splitLength;
            true_stateIndex(k) = mode(true_stateSeq{i}(range));
            k = k + 1;
        end
    end

    % estimated state sequence
    [MAX,est_stateIndex] = max(posteriorProb,[],2);

    % figure out maximum matches by permuting state indices
    permIndex = perms(1:numStates);
    match = zeros(size(permIndex,1),1);
    for j = 1:size(permIndex,1)
        tmpIndex = [];
        for i = 1:numStates
            index = find(est_stateIndex == permIndex(j,i));
            tmpIndex(index,1) = i;
        end
        match(j) = sum(true_stateIndex == tmpIndex)/length(true_stateIndex);
    end
    [MAX,index] = max(match);
    fractionCorrect = MAX;

    % reconstruct indices based on highest match
    tmpIndex = zeros(length(true_stateIndex),1);
    for i = 1:numStates
        tmpIndex(est_stateIndex == permIndex(index,i),1) = i;
    end
    est_stateIndex = tmpIndex;
    match_Index = permIndex(index,:);


    % print and store results
    disp(['Fraction correct: ' num2str(fractionCorrect)]);
    analytics.fractionCorrect = fractionCorrect;
    analytics.true_stateIndex = true_stateIndex;
    analytics.est_stateIndex = est_stateIndex;
    
    %% Compare population fraction
    
    true_popFraction = zeros(1,numStates);
    est_popFraction = zeros(1,numStates);
    for i = 1:numStates
        true_popFraction(i) = sum(true_stateIndex == i)/length(true_stateIndex);
        est_popFraction(i) = sum(est_stateIndex == i)/length(est_stateIndex);
    end
    
    disp(['True population fraction: ' num2str(true_popFraction)]);
    disp(['Est population fraction: ' num2str(est_popFraction)]);
    analytics.true_popFraction = true_popFraction;
    analytics.est_popFraction = est_popFraction;
    
    
    %% Compare ground truth and estimated MSD for each state

    numLags = size(splitX{1},1)-1;
    [true_stateMSD,true_stateMSDerror,true_stateN] = AverageMSD(splitX,true_stateIndex,numLags);
    [est_stateMSD,est_stateMSDerror,est_stateN] = AverageMSD(splitX,est_stateIndex,numLags);

    % plot MSD
    figure; hold on; box on;
    colorSet = hsv(numStates);
    timeLags = 1:numLags;
    legendname = 'h = legend(';
    for i = 1:numStates
        stderror = est_stateMSDerror(i,:)./sqrt(est_stateN(i));
        errorbar(timeLags,est_stateMSD(i,:),stderror,'color',colorSet(i,:),'linewidth',1.5);
        legendname = [legendname '''State ' num2str(i) ''','];
    end
    for i = 1:numStates
        stderror = true_stateMSDerror(i,:)./sqrt(true_stateN(i));
        errorbar(timeLags,true_stateMSD(i,:),stderror,'--','color',colorSet(i,:),'linewidth',1.5);
    end
    set(gca,'fontsize',20,'linewidth',2);
    eval([legendname(1:end-1) ');']);
    set(h,'box','off','location','northwest','fontsize',20);
    xlabel('Time lags (steps)','fontsize',20);
    ylabel('MSD (\mum^2)','fontsize',20);
    if saveall == 1
        print('-depsc',fullfile(savepath,['MSD_comparison']));
    end

    % store results
    analytics.true_stateMSD = true_stateMSD;
    analytics.est_stateMSD = est_stateMSD;
    analytics.true_stateMSDerror = true_stateMSDerror;
    analytics.est_stateMSDerror = est_stateMSDerror;


    %% Compare ground truth and estimated covariance structure

    [true_stateVACF,true_stateVACFerror,true_stateN] = AverageVACF(splitX,true_stateIndex);
    [est_stateVACF,est_stateVACFerror,est_stateN] = AverageVACF(splitX,est_stateIndex);

    % plot VACF
    figure; hold on; box on;
    colorSet = hsv(numStates);
    timeLags = 1:numLags;
    legendname = 'h = legend(';
    for i = 1:numStates
        stderror = est_stateVACFerror(i,:)./sqrt(est_stateN(i));
        errorbar(timeLags,est_stateVACF(i,:),stderror,'color',colorSet(i,:),'linewidth',1.5);
        legendname = [legendname '''State ' num2str(i) ''','];
    end
    for i = 1:numStates
        stderror = true_stateVACFerror(i,:)./sqrt(true_stateN(i));
        errorbar(timeLags,true_stateVACF(i,:),stderror,'--','color',colorSet(i,:),'linewidth',1.5);
    end
    set(gca,'fontsize',20,'linewidth',2,'xscale','log');
    eval([legendname(1:end-1) ');']);
    set(h,'box','off','location','northeast','fontsize',20);
    xlabel('Time lags (steps)','fontsize',20);
    ylabel('Covariance (\mum^2)','fontsize',20);
    axis tight;
    if saveall == 1
        print('-depsc',fullfile(savepath,['Covariance_comparison']));
    end

    % store results
    analytics.true_stateVACF = true_stateVACF;
    analytics.est_stateVACF = est_stateVACF;
    analytics.true_stateVACFerror = true_stateVACFerror;
    analytics.est_stateVACFerror = est_stateVACFerror;
    analytics.true_stateN = true_stateN;
    analytics.est_stateN = est_stateN;


    %% Compare ground truth and estimated transition matrix 

    % transition probability (true empirical)
    A = zeros(numStates,numStates);
    for i = 1:numTracks
        seq = true_stateSeq{i};    
        for n = 1:length(seq)-1
            A(seq(n),seq(n+1)) = A(seq(n),seq(n+1)) + 1;
        end
    end
    norm = sum(A,2);
    true_transitionMatrix = A./repmat(norm,1,numStates);

    % transition probability (classified)
    est_stateSeq = cell(numTracks,1);
    for i = 1:numTracks
        index = find(splitIndex == i);
        tmp_states = [];
        for j = 1:length(index)
            tmp_states = [tmp_states; ones(splitLength,1)*est_stateIndex(index(j))];
        end
        est_stateSeq{i} = tmp_states;
    end

    A = zeros(numStates,numStates);
    for i = 1:length(est_stateSeq)
        seq = est_stateSeq{i};    
        for n = 1:length(seq)-1
            A(seq(n),seq(n+1)) = A(seq(n),seq(n+1)) + 1;
        end
    end
    norm = sum(A,2);
    est_transitionMatrix = A./repmat(norm,1,numStates);

    disp('true transition matrix:');
    disp(num2str(true_transitionMatrix));
    disp('est transition matrix:');
    disp(num2str(est_transitionMatrix));

    % store results
    analytics.true_transitionMatrix = true_transitionMatrix;
    analytics.est_transitionMatrix = est_transitionMatrix;
    analytics.est_stateSeq = est_stateSeq;
    analytics.true_stateSeq = true_stateSeq;

    % save analytics results
    disp(['saving analytics structure: ' fullfile(savepath,['analytics.mat'])]);
    save(fullfile(savepath,['analytics.mat']));

        
    %%  Distribution of fraction correct per track
    
    fraction_match = zeros(numTracks,1);
    for i = 1:numTracks

        % classified states
        estSeq = est_stateSeq{i};
        N = length(estSeq);

        % true states
        trueSeq = true_stateSeq{i};
        trueSeq = trueSeq(1:N);

        fraction_match(i) = sum(estSeq == trueSeq)/N;
    end
    
    bin = 15;
    MIN = min(fraction_match);
    MAX = max(fraction_match);
    edges = MIN:(MAX-MIN)/bin:MAX;
    DN = histc(fraction_match,edges);
    figure; hold on; box on; 
    plot(edges,DN/sum(DN),'b','linewidth',1.5);
    set(gca,'fontsize',20,'linewidth',2);
    xlabel('Fraction correct','fontsize',20);
    ylabel('Probability','fontsize',20);
    if saveall == 1
        print('-depsc',fullfile(savepath,['Fraction_correct']));
    end
    
    %% plot each track (ground truth - left: estimated - right)

     % setup path where files are to be saved
    if saveall == 1
        trackpath = fullfile(savepath,'tracks');
        if ~isdir(trackpath)
            mkdir(trackpath);
        end
    end

    colors = 'bgrcmyk';  
            % state 1 = blue
            % state 2 = green
            % state 3 = red
            % state 4 = cyan
            % state 5 = magenta
            % state 6 = yellow
            % state 7 = black
    offset = .05;   % size of window about starting position
    error_bar = .2;  % size of error bar (um)
    threshold = .7;  % percent of matched states to display and print
    for i = 1:numTracks

        % classified states
        estSeq = est_stateSeq{i};
        N = length(estSeq);

        % true states
        trueSeq = true_stateSeq{i};
        trueSeq = trueSeq(1:N);

        if sum(estSeq == trueSeq)/N > threshold
            x = X{i}(1:N,:);
            minx = min(x);
            maxx = max(x);

            figure(1); clf; 
            subplot(1,2,1); box on; hold on; axis equal;
            for j = 1:N-1
                plot(x(j:j+1,1),x(j:j+1,2),'color',colors(trueSeq(j)));
            end
            axis([minx(1)-offset maxx(1)+offset minx(2)-offset maxx(2)+offset]);
            set(gca,'linewidth',1.5,'xticklabel',[],'yticklabel',[]);
            title('Ground truth','fontsize',20);

            subplot(1,2,2); box on; hold on; axis equal;
            for j = 1:N-1
                plot(x(j:j+1,1),x(j:j+1,2),'color',colors(estSeq(j)));
            end    
            axis([minx(1)-offset maxx(1)+offset minx(2)-offset maxx(2)+offset]);
            set(gca,'linewidth',1.5,'xticklabel',[],'yticklabel',[]);

            % error bar is 200 nm
            rectangle('position',[minx(1) minx(2) error_bar .02],'facecolor','k','edgecolor','k');
            title('Classified','fontsize',20);

            if saveall == 1
                print('-depsc',fullfile(savepath,'tracks',['track_' num2str(i)]));
            else
                disp(['track_' num2str(i) ': press a button to continue'])
                pause;
            end
        end
    end

end






        
function summary_table = check_pEM_runs_fun(varargin)

% This script checks multiple pEM runs (run with identical parameters) 
% clc; clear; close all;
% Choose base directory where all the files are stored
if isempty(varargin)

    base_dir = uigetdir('', 'Please select the base directory'); 
else
    base_dir = varargin{1};
end
curD = pwd;
cd(base_dir);
% Create a list of locations with trackTables 
% dir_list = dir(fullfile('**', 'trackTable*.mat'));
pEM_list = dir(fullfile(base_dir, '**','pEM_results*.mat'));
summary_table = table;
idx = 1;

% for i=1:length(dir_list)
     
   % List of locations with pEM_results 
%    pEM_list =   dir(fullfile(dir_list(i).folder, '**','pEM_results*.mat'));
   
   cdfFig   =   figure('Position', [1 1 0.5 1].*get(0, 'Screensize')); 
   hold on;
   fig_legend = {};
   for j=1:length(pEM_list)
      % Load pEM_results 
      load(fullfile(pEM_list(j).folder, pEM_list(j).name), 'pEMTable');
      [~, foldername] = fileparts(pEM_list(j).folder);
      timestamp         = foldername(find(foldername=='T')-11:end-4);
      
      timestamp(timestamp == '_') = ' ';
      
      fig_legend        = [fig_legend timestamp];  
      
      cell_protein{idx,:}   =   pEMTable.cell_protein{1};
      splitLength(idx,:)    =   pEMTable.trackInfo{1}.splitLength;
      numFeatures(idx,:)    =   pEMTable.trackInfo{1}.numFeatures;
      condition{idx,:}     =   pEMTable.conditions{1};
      run(idx,:)            =   j;
      runID{idx,:}          =   timestamp;
      numRawTracks(idx,:)   =   pEMTable.numRawTracks(1);
      numSplitTracks(idx,:) =   pEMTable.numSplitTracks(1);
      numStates(idx,:)      =   pEMTable.optimalSize(1);
      logL(idx,:)           =   pEMTable.optimalL(1);
      BIC(idx,:)            =   pEMTable.BIC{1}(pEMTable.optimalSize(1));
      medianMPP(idx,:)      =   median(pEMTable.maxPosteriorProb{1});
      
      cdfplot(pEMTable.maxPosteriorProb{1});
      
      idx = idx + 1;
      if j == 1
          str = sprintf('%d/%d COMPLETE', j, length(pEM_list));
          fprintf(str);
          strLen = length(str);
      else
          str2_1 = sprintf(repmat('\b',1,strLen));
          str2_2 = sprintf('%d/%d COMPLETE', j, length(pEM_list));
          str = strcat(str2_1,str2_2);
          strLen = length(str2_2);
%           str = sprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b\b%d/%d COMPLETE\n', j, length(pEM_list));
          fprintf(str);
      end
   end
   fprintf('\n');

   fig_title = pEMTable.cell_protein{1};
   fig_title(fig_title == '_') = ' ';
   
   xlabel('Max posterior probability');
   ylabel('CDF');
   title(sprintf('MPP CDF %s', fig_title));
   set(gca,'linewidth',2,'fontweight','bold','fontsize',24);

   axis square;
   box off;
   legend(fig_legend, 'location', 'northeast');
   grid on;
   savename = sprintf('MPP_CDF_%s', pEMTable.cell_protein{1});
   
   savefig(cdfFig, fullfile(base_dir, savename), 'compact');
   close(cdfFig);
   
    
% end
summary_table = table(cell_protein, splitLength, numFeatures, condition,...
       run, runID, numRawTracks, numSplitTracks, numStates,logL,BIC, medianMPP);

%remove duplicate runs
[~, ia] = unique(summary_table.run);
summary_table = summary_table(ia,:);


summary_table_temp = removevars(summary_table, 'condition');  % Conditions  can  be  a cell array that cannot  be  written to Excel
writetable(summary_table_temp, fullfile(base_dir, sprintf('pEM_run_check_%s.xlsx',datestr(now, 'yyyy-mm-dd_THHMM'))));
save(fullfile(base_dir, sprintf('summary_table_pEM_runs_%s.mat', datestr(now, 'yyyy-mm-dd_THHMM'))), ...
    'summary_table');

cd(curD);
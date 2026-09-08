function output_flag = genSMTfoldstruct(varargin)

%generates the folder structure required for pEM analysis. output_flag
%reports the status of folder creation. 

rootfolder = uigetdir(pwd,'Select the root folder to store all files');

if rootfolder == 0
    output_flag = -1; %User canceled operation
    return
end

%Determine the number of Conditions
defaults = {'1'};
prompt = {'Enter the number of Cell types/Proteins'};
dlgtitle = 'Number of Cell types';
nProt_in = inputdlg(prompt,dlgtitle, [1 55], defaults);
if isempty(nProt_in)
    output_flag = -1;
    return;
end
nProt = str2double(nProt_in);

%Specify the condition names
defaultsProt = cell(1,nProt);
promptProt = cell(1,nProt);
for i = 1:nProt
    defaultsProt{:,i} = ['Cell type/Protein ', num2str(i)];
    promptProt{:,i} = 'Enter Cell Type/Protein Name';
end
dlgtitleProt = 'Cell type Names';

ProtNames = inputdlg(promptProt,dlgtitleProt, [1 55], defaultsProt);
if isempty(ProtNames)
    output_flag = -1;
    return;
end
moveFiles_flag = questdlg('Move files into folders after they are created?','Copy files','Yes','No','Yes');
%create the folders
for i = 1:length(ProtNames)
    mkdir([rootfolder, filesep, ProtNames{i}]);

    %Determine the number of Conditions
    defaultsCond = {'1'};
    promptCond = {'Enter the Number of Conditions'};
    dlgtitleCond = ['Number of Conditions for ', ProtNames{i}];
    nCond_in = inputdlg(promptCond,dlgtitleCond, [1 55], defaultsCond);
    if isempty(nCond_in)
        output_flag = -1;
        return;
    end
    nCond = str2double(nCond_in);
    
    %Specify the condition names
    defaultsCond2 = cell(1,nCond);
    promptCond2 = cell(1,nCond);
    for j = 1:nCond
        defaultsCond2{:,j} = ['Condition ', num2str(j)];
        promptCond2{:,j} = 'Enter Condition name';
    end
    dlgtitleCond2 = ['Condition Names for ', ProtNames{i}];

    CondNames = inputdlg(promptCond2,dlgtitleCond2, [1 55], defaultsCond2);
    if isempty(CondNames)
        output_flag = -1;
        return;
    end
    %create the folders
    for j = 1:length(CondNames)
        mkdir([rootfolder, filesep, ProtNames{i}, filesep, CondNames{j}]);
        %Determine the number of Dataesets (dates)
        defaultsDate = {'1'};
        promptDate = {'Enter the Number of Datasets'};
        dlgtitleDate = ['Number of Dates for ', CondNames{j}];
        nDate_in = inputdlg(promptDate,dlgtitleDate, [1 55], defaultsDate);
        if isempty(nDate_in)
            output_flag = -1;
            return;
        end
        nDate = str2double(nDate_in);

        %Specify the condition names
        defaultsDate2 = cell(1,nDate);
        promptDate2 = cell(1,nDate);
        for k = 1:nDate
            defaultsDate2{:,k} = ['Date ', num2str(k)];
            promptDate2{:,k} = 'Enter Dataset name';
        end
        dlgtitleDate2 = ['Dataset Names for ', CondNames{j}];

        DateNames = inputdlg(promptDate2,dlgtitleDate2, [1 55], defaultsDate2);
        if isempty(DateNames)
            output_flag = -1;
            return;
        end
        %create the folders
        for k = 1:length(DateNames)
            mkdir([rootfolder, filesep, ProtNames{i}, filesep, CondNames{j}, filesep, DateNames{k}]);
            if strcmp(moveFiles_flag,'Yes')
                [files,path] = uigetfile('*.mat',['Select the files to move into ', CondNames{j},'/',DateNames{k}],'MultiSelect','on');
                if ~iscell(files)
                    files_tmp{1} = files;
                    files = files_tmp;
                end
                if files{1} ~= 0
                    for m = 1:length(files)
                        inFile = fullfile(path,files{m});
                        outFile = fullfile([rootfolder, filesep, ProtNames{i}, filesep, CondNames{j}, filesep, DateNames{k}],files{m});
                        copyfile(inFile,outFile);
                    end
                end


            end
        end
    end

end

%Cycle throug the proteins and ask for the number of conditions

output_flag = 1;
function [IMfiles, IMpaths] = extractMovieFileNames(FileRootPath,figH)

Dcur = pwd;
Folds2Search = {FileRootPath};
InternalFolds = {FileRootPath};
%Recursively search for possible images to load
d = uiprogressdlg(figH,'Title','Searching for Movies', ...
    'Message','Recursively searching within folders','Indeterminate','on');
while ~isempty(InternalFolds)
    InternalFolds_new = {};

    for i = 1:length(InternalFolds)
        cd(InternalFolds{i,:});

        FoldCont = dir;
        FoldCont(~[FoldCont.isdir]) = [];
        tf = ismember({FoldCont.name},{'.','..'});
        FoldCont(tf) = [];
        if ~isempty(FoldCont)
            for j = 1:size(FoldCont,1)
                InternalFolds_new = [InternalFolds_new; [InternalFolds{i,:}, filesep, FoldCont(j).name]];
            end
        end
    end
    InternalFolds = InternalFolds_new;
    Folds2Search = [Folds2Search; InternalFolds];
    IMpaths = {};
    IMfiles = {};
    for i = 1:size(Folds2Search,1)

        cd(Folds2Search{i,:})
        imsPresent = dir('*.tif');
        if ~isempty(imsPresent)
            for j = 1:size(imsPresent,1)
                IMpaths = [IMpaths; Folds2Search(i)];
                IMfiles = [IMfiles; imsPresent(j).name];
            end
        end
    end
end
cd(Dcur);

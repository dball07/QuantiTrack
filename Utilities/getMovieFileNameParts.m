function [IMfiles_base, IMfiles_ends, IMfiles_endsAll] = getMovieFileNameParts(IMpaths,IMfiles,Paths_present)

IMfiles_base = cell(size(Paths_present));
IMfiles_ends = cell(size(Paths_present));
IMfiles_endsAll = [];

for i = 1:length(Paths_present)
    %find all of the movie files that are in each
    %folder
    curPath = Paths_present{i};
    ind = [];
    for j = 1:length(IMpaths)
        if strcmp(IMpaths{j}, curPath)
            ind = [ind; j];
        end
    end
    strLen = 1e4;
    for j = 1:length(ind)
        if length(IMfiles{ind(j)}) < strLen
            strLen = length(IMfiles{ind(j)});
            curFile = IMfiles{ind(j)};
        end
    end
    IMfiles_base{i} = curFile;
    
    curEnds = cell(length(ind),1);
    for j = 1:length(ind)
        if strcmp(curFile,IMfiles{ind(j)})
            curEnds{j} = 'raw';
        else
            curEnds{j} = IMfiles{ind(j)}(length(curFile)-2:end-4);
        end
    end
    IMfiles_endsAll = unique([IMfiles_endsAll; curEnds],'stable');

    IMfiles_ends{i} = curEnds;


end
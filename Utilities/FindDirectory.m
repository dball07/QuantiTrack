function dirpath = FindDirectory(parentpath)

dirName = dir(parentpath);
dirpath = {};
k = 1;
for i = 3:length(dirName)
    if dirName(i).isdir == 1 && isempty(strfind(dirName(i).name,'results')) 
        dirpath{k} = fullfile(parentpath,dirName(i).name);
        k = k + 1;
    end
end
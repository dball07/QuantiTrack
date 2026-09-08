function increaseFontSizesIfReq(handles)
% make all fonts smaller on a non-mac-osx computer

fontSizeFactor = 2.0;
VER = ver;
matlabInd = 0;
for i = 1:length(VER)
    if strcmp(VER(i).Name,'MATLAB')
        matlabInd = i;
        break
    end
end
R2025 = strfind(VER(matlabInd).Release,'2025');

persistent fontSizeIncreased
fontSizeIncreased = [];
if ismac() && isempty(R2025)
    % No MAC OSX detected; decrease font sizes
    if isempty(fontSizeIncreased)
        for afield = fieldnames(handles)'
            afield = afield{1}; %#ok<FXSET>
            try %#ok<TRYNC>
                set(handles.(afield),'FontSize',get(handles.(afield),'FontSize')*fontSizeFactor); % decrease font size
            end
        end
        fontSizeIncreased=1; % do not perform this step again.
    end
end
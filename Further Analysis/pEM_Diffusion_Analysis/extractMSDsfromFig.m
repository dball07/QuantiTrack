function state_msds = extractMSDsfromFig()

curves = get(gca,'Children');
nStates = length(curves);
state_msds = cell(nStates,1);
for i = 1:nStates
    state_msds{i}(:,1) = curves(nStates-i+1).XData(:);
    state_msds{i}(:,2) = curves(nStates-i+1).YData(:);
end

% clear curves nStates i

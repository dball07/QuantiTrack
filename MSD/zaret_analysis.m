function [Lc, avg_step] = zaret_analysis(track_table,varargin)

%Calculates the radius of confinement (Lc) and the average step size
%(avg_step) for each track in the input table (track_table), which should
%have a column called X which contains a cell array of all tracks.
%Optionally, the condition label can be specified to perform analysis on a
%specific condition independently.

%Determine if a specific condition is specified, otherwise the entire table
%is used
if ~isempty(varargin)
    cond_str = varargin{1};
    cond_ind = strcmp(track_table.condition,cond_str);
    track_table = track_table(cond_ind,:);
end

k=1;
%cycle through the cells
for i = 1:height(track_table)
    tracks = track_table.X{i};

    for ii=1:length(tracks)
        if(length(tracks{ii})>=50)
            x=tracks{ii}(:,1);
            y=tracks{ii}(:,2);
            r = sqrt(diff(x).^2 + diff(y).^2);
            x_av = mean(x);
            y_av = mean(y);
            Lc(k)=sqrt(mean((x-x_av).^2+(y-y_av).^2));
            avg_step(k) = mean(r);
            k=k+1;
        end
    end
end
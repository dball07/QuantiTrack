function createSpotImages(Particles,imStack,response,varargin)

if isempty(varargin)
    savepath = uigetdir(pwd,'Select Folder to save Particle images');
    if savepath ~= 0
        savePath = savepath;
    else
        return;
    end
    dTpoints = 0;
    wndo = 15;
    saveName = 'A';
elseif length(varargin) == 1
    savepath = uigetdir(pwd,'Select Folder to save Particle images');
    if savepath ~= 0
        savePath = savepath;
    else
        return;
    end
    dTpoints = varargin{1};
    wndo = 15;
    saveName = 'A';
elseif length(varargin) == 2
    savepath = uigetdir(pwd,'Select Folder to save Particle images');
    if savepath ~= 0
        savePath = savepath;
    else
        return;
    end
    dTpoints = varargin{1};
    wndo = varargin{2};
    saveName = 'A';
elseif length(varargin) == 3
    dTpoints = varargin{1};
    wndo = varargin{2};
    savePath = varargin{3};
    saveName = 'A';
else
    dTpoints = varargin{1};
    wndo = varargin{2};
    savePath = varargin{3};
    saveName = varargin{4};
end
%see if we need to create the savePath
cur_d = pwd;

ex = dir(savePath);

if isempty(ex)
    mkdir(savePath);
end



%Make sure that the Particle array doesn't include any positions of 0

Particles = Particles(Particles(:,1) > 0,:);
Particles = Particles(Particles(:,1) > 0,:);

%get the image dimensions
width = imStack(1).width;
height = imStack(1).height;

for i = 1:size(Particles)
    d = num2str(i);
    if i < 10
        d = ['0', d];
    end
    if i < 100
        d = ['0', d];
    end
    curPart = Particles(i,:);
    t_cur = curPart(:,6);
    
    for j = 1:2*dTpoints+1
        curT = (t_cur - dTpoints - 1) + j;
        if curT < 1 || curT > length(imStack)
            spotIm(:,:,j) = uint16(zeros(2*wndo + 1));
        else
            
            x_cur = curPart(:,10);
            y_cur = curPart(:,11);
            
            imCur = imStack(curT).data;
%             make sure we aren't near an edge
            xlim(1) = max(1,round(x_cur) - wndo);
            xlim(2) = min(height,round(x_cur) + wndo);
            ylim(1) = max(1,round(y_cur) - wndo);
            ylim(2) = min(width,round(y_cur) + wndo);
            spotIm_tmp = imCur(ylim(1):ylim(2),xlim(1):xlim(2));
            
            if xlim(1) == 1
                missingpxX = 1 - (round(x_cur) - wndo);
                spotIm_tmp = [zeros(size(spotIm_tmp,1),missingpxX),spotIm_tmp];
            end
            if xlim(2) == height
                missingpxX = (round(x_cur) + wndo) - height;
                spotIm_tmp = [spotIm_tmp,zeros(size(spotIm_tmp,1),missingpxX)];
            end
            if ylim(1) == 1
                missingpxY = 1 - (round(y_cur) - wndo);
                spotIm_tmp = [zeros(missingpxY,size(spotIm_tmp,2));spotIm_tmp];
            end
            
            if ylim(2) == width
                missingpxY = (round(y_cur) + wndo) - width;
                spotIm_tmp = [spotIm_tmp;zeros(missingpxY,size(spotIm_tmp,2))];
            end
            
            spotIm(:,:,j) = spotIm_tmp;
        end
        if j == 1
            if isempty(response)
                imwrite(spotIm(:,:,j),[savePath,filesep,saveName,'_',d,'.tif']);
            else
                curCat = num2str(response(i));
                cd(savePath);
                D_exists = dir(curCat);
                if isempty(D_exists)
                   mkdir(curCat);
                end
                imwrite(spotIm(:,:,j),[savePath,filesep,curCat,filesep,saveName,'_',d,'.tif']);
            end
        else
            if isempty(response)
                imwrite(spotIm(:,:,j),[savePath,filesep,saveName,'_',d,'.tif'],'WriteMode','append');
            else
                curCat = num2str(response(i));
                cd(savePath);
                D_exists = dir(curCat);
                if isempty(D_exists)
                   mkdir(curCat);
                end
                imwrite(spotIm(:,:,j),[savePath,filesep,curCat,filesep,saveName,'_',d,'.tif'],'WriteMode','append');
            end
        end
    end
end
cd(cur_d);      
            
            
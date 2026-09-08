function varargout = ROI_GUI(varargin)
% ROI_GUI MATLAB code for ROI_GUI.fig
%      ROI_GUI, by itself, creates a new ROI_GUI or raises the existing
%      singleton*.
%
%      H = ROI_GUI returns the handle to a new ROI_GUI or the handle to
%      the existing singleton*.
%
%      ROI_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ROI_GUI.M with the given input arguments.
%
%      ROI_GUI('Property','Value',...) creates a new ROI_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ROI_GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ROI_GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ROI_GUI

% Last Modified by GUIDE v2.5 05-Mar-2020 10:50:03

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ROI_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @ROI_GUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before ROI_GUI is made visible.
function ROI_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ROI_GUI (see VARARGIN)

% Choose default command line output for ROI_GUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ROI_GUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = ROI_GUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in LoadImage.
function LoadImage_Callback(hObject, eventdata, handles)
% hObject    handle to LoadImage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Choose file
[fname, pname] = uigetfile('*.tif','Select an Image file');

if fname ~= 0
    answer = questdlg('What type of projection do you want to use for the Reference Image',...
        'Projection Type','Sum','Maximum','Entire Stack','Sum');
    im = TIFread_3d(fullfile(pname,fname));
    set(handles.BlackValSlider,'Min',0);
    set(handles.WhiteValSlider,'Min',0);
    handles.data.fname = fname;
    handles.data.pname = pname;
    handles.data.image = im;
    if strcmp(answer,'Sum')
        im_sum = double(im(:,:,1));
        for i = 2:size(im,3)
            im_sum = im_sum + double(im(:,:,i));
        end
        nFrames = 1;

        %set max slider values, and slider steps
        set(handles.BlackValSlider,'Max',65535*size(im,3));
        set(handles.WhiteValSlider,'Max',65535*size(im,3));
        set(handles.BlackValSlider,'SliderStep',[1/(65535),10/(65535)]);
        set(handles.WhiteValSlider,'SliderStep',[1/(65535),10/(65535)]);
        set(handles.frameSlider,'Enable','off');
        set(handles.nFrameText,'Visible','off','String','0/0');
        set(handles.text7,'Visible','off'); %"Frame"
        
    elseif strcmp(answer,'Maximum')
        im_sum = max(im,[],3);
        nFrames = 1;
        %set max slider values, and slider steps
        set(handles.BlackValSlider,'Max',65535);
        set(handles.WhiteValSlider,'Max',65535);
        set(handles.BlackValSlider,'SliderStep',[1/65535,10/65535]);
        set(handles.WhiteValSlider,'SliderStep',[1/65535,10/65535]);
        set(handles.frameSlider,'Enable','off');
        set(handles.nFrameText,'Visible','off','String','0/0');
        set(handles.text7,'Visible','off'); %"Frame"
    else
        im_sum = im(:,:,1);
        nFrames = size(im,3);
        set(handles.BlackValSlider,'Max',65535);
        set(handles.WhiteValSlider,'Max',65535);
        set(handles.BlackValSlider,'SliderStep',[1/65535,10/65535]);
        set(handles.WhiteValSlider,'SliderStep',[1/65535,10/65535]);
        set(handles.frameSlider,'Enable','on','Min',1,'Max',nFrames,...
            'SliderStep',[1/(nFrames - 1), 10/(nFrames-1)],'Value',1);
        set(handles.nFrameText,'Visible','on','String',['1/',num2str(nFrames)]);
        set(handles.text7,'Visible','on'); %"Frame"
    end
    handles.data.SumImage = im_sum;
    handles.data.nFrames = nFrames;
    handles.Current.Ix = 1;
    handles.Current.clims = [min(im_sum(:)),max(im_sum(:))];
    set(handles.BlackValEdit,'String',num2str(handles.Current.clims(1)));
    set(handles.WhiteValEdit,'String',num2str(handles.Current.clims(2)));
    set(handles.BlackValSlider,'Value',handles.Current.clims(1));
    set(handles.WhiteValSlider,'Value',handles.Current.clims(2));
    axes(handles.axes1);
    imagesc(im_sum);
    colormap(gray);
    axis image;
    handles.Process = [];
    handles.Process.ROIClass = [];
    handles.Process.ROILabel = [];
    set(handles.ROIList,'String',[]);
    
end
guidata(hObject,handles);


% --- Executes on button press in ROIbutton.
function ROIbutton_Callback(hObject, eventdata, handles)
% hObject    handle to ROIbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%draw the ROI
if isfield(handles.Process,'ROIpos')
    nROIs = size(handles.Process.ROIpos,1);
    if size(handles.Process.ROIpos,2) > 1
        ROI = handles.Process.ROIpos(:,handles.Current.Ix);
    else
        ROI = handles.Process.ROIpos(:,1);
    end
    plotROI(ROI);
    
else
    nROIs = 0;
end
hPoly = impoly;

ROI_label_def = {['ROI ' num2str(nROIs+1)]};
ROI_label = inputdlg('Create a label for the new ROI:','ROI label',1,ROI_label_def);

if ~isempty(ROI_label)
    ROI_list = get(handles.ROIList,'String');
    if isempty(ROI_list)
        ROI_list = cell(1);
        ROI_list{1,:} = ROI_label{1,:};
    else
        ROI_list{nROIs+1,:} = ROI_label{1,:};
    end
    set(handles.ROIList,'String',ROI_list);
    set(handles.ROIList,'Value',nROIs+1);
    if isfield(handles.Process,'ROIpos')
        for j = 1:size(handles.Process.ROIpos,2)
            handles.Process.ROIpos{nROIs+1,j} = getPosition(hPoly);
            handles.Process.ROIimage{nROIs+1,j} = createMask(hPoly);
        end
    else
        handles.Process.ROIpos{nROIs+1,1} = getPosition(hPoly);
        handles.Process.ROIimage{nROIs+1,1} = createMask(hPoly);
    end
    handles.Process.ROIlabel = get(handles.ROIList,'String');
    delete(hPoly);
    set(handles.axes1,'NextPlot','replacechildren');
    imagesc(handles.data.SumImage, handles.Current.clims);
    %     axis image;
    if isfield(handles.Process,'ROIpos')
        if size(handles.Process.ROIpos,2) > 1
            ROI = handles.Process.ROIpos(:,handles.Current.Ix);
        else
            ROI = handles.Process.ROIpos(:,1);
        end
    else
        ROI = handles.Process.ROIpos(:,1);
    end
    plotROI(ROI);
    %Add classes if desired
    if isempty(handles.Process.ROIClass)
        
        AddClassAns = questdlg('Do you want to separate the ROIs into 2 or more classifications?', 'Classify ROIs','Yes','No','Cancel','No');
        if strcmp(AddClassAns,'Cancel')
            delete(hPoly);
            set(handles.roiButton, 'Enable', 'on');
            set(handles.roiRemovePush,'Enable',ROIrem_enable);
            set(handles.roiNamePush,'Enable',ROIname_enable);
        elseif strcmp(AddClassAns,'No')
            handles.Process.ROIClass = {0};
        else
            ClassName = inputdlg('Specify the name of the new class:','New Classification',1,{'Nucleus'});
            handles.Process.ROIClass = cell(size(handles.Process.ROIpos));
            handles.Process.ROIClass{end,:} = ClassName(1);
            handles.Process.AllROIClasses = ClassName(1);
            set(handles.ROIClassCur_text,'String',ClassName{1});
            set(handles.ChangeROIClass,'Enable','on');
        end
    elseif iscell(handles.Process.ROIClass{1,:})
        ROIstring = handles.Process.AllROIClasses;
        ROIstring{end+1,1} = 'New...';
        ROIidx = ROIClassChooseDlg(ROIstring);
        if ROIidx < size(ROIstring,1)
            handles.Process.ROIClass{end+1,:} = ROIstring{ROIidx,:};
        else
            ClassName = inputdlg('Specify the name of the new class:','New Classification',1,{'Nucleus'});
            %Need to verify that it is really new
            isnew = 1;
            for i = 1:size(handles.Process.AllROIClasses,1)
                if strcmpi(ClassName{1},handles.Process.AllROIClasses{i,:})
                    isnew = 0;
                    break;
                end
            end
            if isnew == 1
                handles.Process.AllROIClasses{end+1,:} = ClassName{1};
                handles.Process.ROIClass{end+1,:} = ClassName{1};
            else
                handles.Process.ROIClass{end+1,:} = handles.Process.AllROIClasses{i,:};
            end
            
            
        end
        set(handles.ROIClassCur_text,'String',handles.Process.ROIClass{end,:});
        set(handles.ChangeROIClass,'Enable','on');
    else
        set(handles.ROIClassCur_text,'String','Not defined');
        set(handles.ChangeROIClass,'Enable','on');
    end
else
    delete(hPoly);
    set(handles.roiButton, 'Enable', 'on');
    set(handles.roiRemovePush,'Enable',ROIrem_enable);
    set(handles.roiNamePush,'Enable',ROIname_enable);
    set(handles.axes1,'NextPlot','replacechildren');
    imagesc(handles.data.SumImage, handles.Current.clims);
    
       
    if isfield(handles.Process,'ROIpos')
        if size(handles.Process.ROIpos,2) > 1
            ROI = handles.Process.ROIpos(:,handles.Current.Ix);
        else
            ROI = handles.Process.ROIpos(:,1);
        end
        plotROI(ROI);
        
    end
    
    
end
guidata(hObject,handles);

% --- Executes on button press in Savebutton.
function Savebutton_Callback(hObject, eventdata, handles)
% hObject    handle to Savebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isfield(handles,'data') && isfield(handles.data,'pname')
    defPath = handles.data.pname;
else
    defPath = pwd;
end

ROIsaveName = ['mask-',handles.data.fname(1:end-3),'mat'];
% [save_file,save_path] = uiputfile('*.mat','Choose Save location',fullfile(defPath,ROIsaveName));
save_path = defPath;
save_file = ROIsaveName;
if save_file ~= 0
    ROIpos = handles.Process.ROIpos;
    ROIimage = handles.Process.ROIimage;
    if handles.data.nFrames > 1
        dim = size(handles.data.image);
        for i = 1:size(ROIimage,1)
            for j = 1:size(ROIimage,2)
                if isempty(ROIimage{i,j})
                    
                    ROIimage{i,j} = false(dim(1),dim(2));
                end
            end
        end
        
        if size(ROIimage,1) < handles.data.nFrames
            for j = size(ROIimage,2)+1:handles.data.nFrames
                for i = 1:size(ROIimage,1)
                    ROIimage{i,j} = false(dim(1),dim(2));
                end
            end
        end
    end
    ROIlabel = handles.Process.ROIlabel;
    ROIClass = handles.Process.ROIClass;
    save(fullfile(save_path,save_file),'ROIpos','ROIimage','ROIlabel','ROIClass');
end


% --- Executes on button press in CircleROIbutton.
function CircleROIbutton_Callback(hObject, eventdata, handles)
% hObject    handle to CircleROIbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isfield(handles.Process,'ROIpos')
    nROIs = size(handles.Process.ROIpos,1);
    if handles.data.nFrames > 1 
        curFrame = round(get(handles.frameSlider,'Value'));
        if size(handles.Process.ROIpos,2) >= curFrame
            ROI = handles.Process.ROIpos(:,handles.Current.Ix);
        else
            ROI = [];
        end
    else
        ROI = handles.Process.ROIpos(:,1);
    end
    plotROI(ROI);
    
else
    nROIs = 0;
end

diam = str2double(get(handles.CircDiamText,'String'));

hPoint = impoint(handles.axes1);

newPos = getPosition(hPoint);
delete(hPoint);

x1 = -diam/2:0.1:diam/2;
x2 = -1*x1;

y1 = sqrt((diam/2)^2 - x1.^2);
y2 = -1*y1;
x = [x1'; x2'];

y = [y1';y2'];
x(end) = [];
y(end) = [];
x = x + newPos(1);
y = y + newPos(2);
x = [x;x(1)];
y = [y;y(1)];
if min(x) < 1 || min(y) < 1 || max(x) > size(handles.data.image,1) || max(y) > size(handles.data.image,2)
    errordlg('New ROI is too close to the image edge','Invalid ROI placement');
    return
else
    newROIim = false(size(handles.data.image(:,:,1)));
    for i = round(min(x)):round(max(x))
        for j = round(min(y)):round(max(y))
            if sqrt((i - newPos(1)).^2 + (j - newPos(2)).^2) <= diam/2
                newROIim(j,i) = 1;
            end
        end
    end
    handles.out.ROI = newROIim;
    
    
    
    axes(handles.axes1)
%     hold on
%     plot(x,y,'r');
%     hold off;
end
if nROIs > 0 && handles.data.nFrames > 1
    newOrCurrent = questdlg('Do you want to add to the current ROI or create a new one?','Append or Create','Current','New','Current');
else
    newOrCurrent = 'New';
end
if strcmp(newOrCurrent,'New')
    ROI_label_def = {['ROI ' num2str(nROIs+1)]};
    ROI_label = inputdlg('Create a label for the new ROI:','ROI label',1,ROI_label_def);
    addROI = nROIs+1;
else
    addROI = nROIs;
    ROI_label = '';
end

if ~isempty(ROI_label) || strcmp(newOrCurrent,'Current')
    ROI_list = get(handles.ROIList,'String');
    if isempty(ROI_list)
        ROI_list = cell(1);
        ROI_list{1,:} = ROI_label{1,:};
    else
        if strcmp(newOrCurrent,'New')
            ROI_list{nROIs+1,:} = ROI_label{1,:};
        end
    end
    set(handles.ROIList,'String',ROI_list);
    set(handles.ROIList,'Value',addROI);
    if isfield(handles.Process,'ROIpos')
        if handles.data.nFrames == 1
            for j = 1:size(handles.Process.ROIpos,2)
            
                handles.Process.ROIpos{nROIs+1,j} = [x,y];
                handles.Process.ROIimage{nROIs+1,j} = newROIim;
            end
        else
            curFrame = get(handles.frameSlider,'Value');
            handles.Process.ROIpos{addROI,curFrame} = [x,y];
            handles.Process.ROIimage{addROI,curFrame} = newROIim;
                
        end
    else
        handles.Process.ROIpos{nROIs+1,1} = [x,y];
        handles.Process.ROIimage{nROIs+1,1} = newROIim;
    end
    handles.Process.ROIlabel = get(handles.ROIList,'String');
%     delete(hPoly);
    set(handles.axes1,'NextPlot','replacechildren');
    imagesc(handles.data.SumImage, handles.Current.clims);
    %     axis image;
    if isfield(handles.Process,'ROIpos')
        if size(handles.Process.ROIpos,2) > 1
            ROI = handles.Process.ROIpos(:,handles.Current.Ix);
        else
            ROI = handles.Process.ROIpos(:,1);
        end
    else
        ROI = handles.Process.ROIpos(:,1);
    end
    plotROI(ROI);
    %Add classes if desired
    if isempty(handles.Process.ROIClass)
        
        AddClassAns = questdlg('Do you want to separate the ROIs into 2 or more classifications?', 'Classify ROIs','Yes','No','Cancel','No');
        if strcmp(AddClassAns,'Cancel')
            delete(hPoly);
            set(handles.roiButton, 'Enable', 'on');
            set(handles.roiRemovePush,'Enable',ROIrem_enable);
            set(handles.roiNamePush,'Enable',ROIname_enable);
        elseif strcmp(AddClassAns,'No')
            handles.Process.ROIClass = {0};
        else
            ClassName = inputdlg('Specify the name of the new class:','New Classification',1,{'Nucleus'});
            handles.Process.ROIClass = cell(size(handles.Process.ROIpos));
            handles.Process.ROIClass{end,:} = ClassName(1);
            handles.Process.AllROIClasses = ClassName(1);
            set(handles.ROIClassCur_text,'String',ClassName{1});
            set(handles.ChangeROIClass,'Enable','on');
        end
    elseif iscell(handles.Process.ROIClass{1,:})
        ROIstring = handles.Process.AllROIClasses;
        ROIstring{end+1,1} = 'New...';
        ROIidx = ROIClassChooseDlg(ROIstring);
        if ROIidx < size(ROIstring,1)
            handles.Process.ROIClass{end+1,:} = ROIstring{ROIidx,:};
        else
            ClassName = inputdlg('Specify the name of the new class:','New Classification',1,{'Nucleus'});
            %Need to verify that it is really new
            isnew = 1;
            for i = 1:size(handles.Process.AllROIClasses,1)
                if strcmpi(ClassName{1},handles.Process.AllROIClasses{i,:})
                    isnew = 0;
                    break;
                end
            end
            if isnew == 1
                handles.Process.AllROIClasses{end+1,:} = ClassName{1};
                handles.Process.ROIClass{end+1,:} = ClassName{1};
            else
                handles.Process.ROIClass{end+1,:} = handles.Process.AllROIClasses{i,:};
            end
            
            
        end
        set(handles.ROIClassCur_text,'String',handles.Process.ROIClass{end,:});
        set(handles.ChangeROIClass,'Enable','on');
    else
        set(handles.ROIClassCur_text,'String','Not defined');
        set(handles.ChangeROIClass,'Enable','on');
    end
else
    delete(hPoly);
    set(handles.roiButton, 'Enable', 'on');
    set(handles.roiRemovePush,'Enable',ROIrem_enable);
    set(handles.roiNamePush,'Enable',ROIname_enable);
    set(handles.axes1,'NextPlot','replacechildren');
    imagesc(handles.data.SumImage, handles.Current.clims);
    
       
    if isfield(handles.Process,'ROIpos')
        if size(handles.Process.ROIpos,2) > 1
            ROI = handles.Process.ROIpos(:,handles.Current.Ix);
        else
            ROI = handles.Process.ROIpos(:,1);
        end
        plotROI(ROI);
        
    end
    
    
end
guidata(hObject,handles);


function CircDiamText_Callback(hObject, eventdata, handles)
% hObject    handle to CircDiamText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of CircDiamText as text
%        str2double(get(hObject,'String')) returns contents of CircDiamText as a double


% --- Executes during object creation, after setting all properties.
function CircDiamText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to CircDiamText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




% --- Executes on button press in AdjCntr.
function AdjCntr_Callback(hObject, eventdata, handles)
% hObject    handle to AdjCntr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.BlackValSlider,'Val',min(handles.data.SumImage(:)));
set(handles.WhiteValSlider,'Val',max(handles.data.SumImage(:)));

set(handles.BlackValEdit,'String',num2str(round(double(min(handles.data.SumImage(:)))*100)/100));
set(handles.WhiteValEdit,'String',num2str(round(double(max(handles.data.SumImage(:)))*100)/100));
handles.Current.clims = [min(handles.data.SumImage(:)), max(handles.data.SumImage(:))];
set(handles.axes1,'NextPlot','replacechildren');
imagesc(handles.data.SumImage, handles.Current.clims);       % plot image
% axis image;

if isfield(handles.Process,'ROIpos')
    if size(handles.Process.ROIpos,2) > 1
        ROI = handles.Process.ROIpos(:,handles.Current.Ix);
    else
        ROI = handles.Process.ROIpos(:,1);
    end
    plotROI(ROI);
    
end
guidata(hObject,handles);

% --- Executes on slider movement.
function WhiteValSlider_Callback(hObject, eventdata, handles)
% hObject    handle to WhiteValSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
BlackLevel = get(handles.BlackValSlider,'Val');
WhiteLevel = get(hObject,'Val');
if WhiteLevel == 0
    WhiteLevel = 0.1;
end

if WhiteLevel <= BlackLevel
    BlackLevel = WhiteLevel-0.1;
    set(handles.BlackValSlider,'Val',BlackLevel);
end

set(handles.BlackValEdit,'String',num2str(round(double(BlackLevel)*100)/100));
set(handles.WhiteValEdit,'String',num2str(round(double(WhiteLevel)*100)/100));
handles.Current.clims = [BlackLevel WhiteLevel];

set(handles.axes1,'NextPlot','replacechildren');
imagesc(handles.data.SumImage, handles.Current.clims);       % plot image
% axis image;
%Plot ROI

if isfield(handles.Process,'ROIpos')
    if size(handles.Process.ROIpos,2) > 1
        ROI = handles.Process.ROIpos(:,handles.Current.Ix);
    else
        ROI = handles.Process.ROIpos(:,1);
    end
    plotROI(ROI);
    
end
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function WhiteValSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to WhiteValSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function BlackValSlider_Callback(hObject, eventdata, handles)
% hObject    handle to BlackValSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

MaxBrightnessStack = get(handles.BlackValSlider,'Max');

BlackLevel = get(hObject,'Val');
WhiteLevel = get(handles.WhiteValSlider,'Val');

if BlackLevel == MaxBrightnessStack
    BlackLevel = MaxBrightnessStack -0.1;
end
if BlackLevel >= WhiteLevel
    WhiteLevel = BlackLevel+0.1;
    set(handles.WhiteValSlider,'Val',WhiteLevel);
end

set(handles.BlackValEdit,'String',num2str(round(double(BlackLevel)*100)/100));
set(handles.WhiteValEdit,'String',num2str(round(double(WhiteLevel)*100)/100));
handles.Current.clims = [BlackLevel WhiteLevel];


set(handles.axes1,'NextPlot','replacechildren');
imagesc(handles.data.SumImage, handles.Current.clims);       % plot image
% axis image;


if isfield(handles.Process,'ROIpos')
    if size(handles.Process.ROIpos,2) > 1
        ROI = handles.Process.ROIpos(:,handles.Current.Ix);
    else
        ROI = handles.Process.ROIpos(:,1);
    end
    plotROI(ROI);
    
end
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function BlackValSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BlackValSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function BlackValEdit_Callback(hObject, eventdata, handles)
% hObject    handle to BlackValEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of BlackValEdit as text
%        str2double(get(hObject,'String')) returns contents of BlackValEdit as a double

MaxBrightnessStack = get(handles.BlackValSlider,'Max');

BlackLevel = str2double(get(hObject,'String'));
%Make sure we don't try to set the brightness outside of the slider limits
if BlackLevel < 0
    BlackLevel = 0;
elseif BlackLevel > MaxBrightnessStack
    BlackLevel = MaxBrightnessStack-0.1;
end

set(hObject,'String',num2str(round(double(BlackLevel)*100)/100));
WhiteLevel = str2double(get(handles.WhiteValEdit,'String'));

if BlackLevel >= WhiteLevel
    WhiteLevel = BlackLevel+0.1;
    set(handles.WhiteValEdit,'String',num2str(round(double(WhiteLevel)*100)/100));
end

set(handles.BlackValSlider,'Val',BlackLevel);
set(handles.WhiteValSlider,'Val',WhiteLevel);
handles.Current.clims = [BlackLevel WhiteLevel];


set(handles.axes1,'NextPlot','replacechildren');
imagesc(handles.data.SumImage, handles.Current.clims);       % plot image
% axis image;
%Plot ROI

if isfield(handles.Process,'ROIpos')
    if size(handles.Process.ROIpos,2) > 1
        ROI = handles.Process.ROIpos(:,handles.Current.Ix);
    else
        ROI = handles.Process.ROIpos(:,1);
    end
    plotROI(ROI);
    
end
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function BlackValEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BlackValEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function WhiteValEdit_Callback(hObject, eventdata, handles)
% hObject    handle to WhiteValEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of WhiteValEdit as text
%        str2double(get(hObject,'String')) returns contents of WhiteValEdit as a double
MaxBrightnessStack = get(handles.BlackValSlider,'Max');

WhiteLevel = str2double(get(hObject,'String'));
%Make sure we don't try to set the brightness outside of the slider limits
if WhiteLevel < 0
    WhiteLevel = 0.1;
elseif WhiteLevel > MaxBrightnessStack
    WhiteLevel = MaxBrightnessStack;
end

set(hObject,'String',num2str(round(double(WhiteLevel)*100)/100));
BlackLevel = str2double(get(handles.BlackValEdit,'String'));

if WhiteLevel <= BlackLevel
    BlackLevel = WhiteLevel-0.1;
    set(handles.BlackValEdit,'String',num2str(round(double(BlackLevel)*100)/100));
end

set(handles.BlackValSlider,'Val',BlackLevel);
set(handles.WhiteValSlider,'Val',WhiteLevel);
handles.Current.clims = [BlackLevel WhiteLevel];

set(handles.axes1,'NextPlot','replacechildren');
imagesc(handles.data.SumImage, handles.Current.clims);       % plot image
% axis image;


if isfield(handles.Process,'ROIpos')
    if size(handles.Process.ROIpos,2) > 1
        ROI = handles.Process.ROIpos(:,handles.Current.Ix);
    else
        ROI = handles.Process.ROIpos(:,1);
    end
    plotROI(ROI);
    
end
guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function WhiteValEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to WhiteValEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in ROIList.
function ROIList_Callback(hObject, eventdata, handles)
% hObject    handle to ROIList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ROIList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ROIList
curSel = get(hObject,'Value');
if size(handles.Process.ROIpos,2) > 1
    ROI = handles.Process.ROIpos(:,handles.Current.Ix);
else
    ROI = handles.Process.ROIpos(:,1);
end
plotROI(ROI,handles.axes1,curSel);
if ~isempty(handles.Process.ROIClass) && ~isempty(handles.Process.ROIClass{1,:}) ...
        && length(handles.Process.ROIClass)>= curSel && ~isempty(handles.Process.ROIClass{curSel,:})
    if iscell(handles.Process.ROIClass{1,:})
        set(handles.ROIClassCur_text,'String',handles.Process.ROIClass{curSel,:});
    else
        set(handles.ROIClassCur_text,'String','Not Defined');
    end
else
    set(handles.ROIClassCur_text,'String','Not Defined');
end

% --- Executes during object creation, after setting all properties.
function ROIList_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ROIList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in ChangeROIClass.
function ChangeROIClass_Callback(hObject, eventdata, handles)
% hObject    handle to ChangeROIClass (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isempty(handles.Process.ROIClass) || (~isempty(handles.Process.ROIClass{1,:}) && handles.Process.ROIClass{1,:}{1}(1) == 0)
    ReallyAdd = questdlg('No classifications exist for current dataset, Do you want to add them?','Add Classifications','OK', 'Cancel','Cancel');
    
else
    ReallyAdd = 'OK';
end

if strcmp(ReallyAdd,'OK')
    
    
    
    curSel = get(handles.ROIList,'Value');
    if isempty(handles.Process.ROIClass) || (~isempty(handles.Process.ROIClass{1,:}) && handles.Process.ROIClass{1,:}{1}(1) == 0)
        handles.Process.ROIClass = cell(size(handles.Process.ROIimage));
        ClassName = inputdlg('Specify the name of the new class:','New Classification',1,{'Nucleus'});
        handles.Process.ROIClass{curSel,:} = ClassName(1);
        handles.Process.AllROIClasses = ClassName(1);
        set(handles.ROIClassCur_text,'String',ClassName{1});
    else
        ROIstring = handles.Process.AllROIClasses;
        ROIstring{end+1,1} = 'New...';
        ButPos = get(hObject,'Position');
        figPos = get(gcf,'Position');
        XYPos(1) = (figPos(1) + ButPos(1)*figPos(3));
        XYPos(2) = (figPos(2) + ButPos(2)*figPos(4));
        ROIidx = ROIClassChooseDlg(ROIstring,XYPos);
        if ROIidx < size(ROIstring,1)
            handles.Process.ROIClass{curSel,:} = ROIstring{ROIidx,:};
        else
            ClassName = inputdlg('Specify the name of the new class:','New Classification',1,{'Nucleus'});
            handles.Process.ROIClass{curSel,:} = ClassName{1};
            %Need to verify that it is actually new
            isnew = 1;
            for i = 1:size(handles.Process.AllROIClasses,1)
                if strcmpi(ClassName{1},handles.Process.AllROIClasses{i,:})
                    isnew = 0;
                    break;
                end
            end
            if isnew == 1
                handles.Process.AllROIClasses{end+1,:} = ClassName{1};
            else
                handles.Process.ROIClass{curSel,:} = handles.Process.AllROIClasses{i,:};
            end
        end
    end
    set(handles.ROIClassCur_text,'String',handles.Process.ROIClass{curSel,:});
    guidata(hObject,handles);
end


% --- Executes on slider movement.
function frameSlider_Callback(hObject, eventdata, handles)
% hObject    handle to frameSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

curFrame = round(get(hObject,'Value'));
set(handles.nFrameText,'String',[num2str(curFrame),'/',num2str(handles.data.nFrames)]);
handles.Current.Ix = curFrame;
axes(handles.axes1);
imagesc(handles.data.image(:,:,curFrame),handles.Current.clims);
colormap(gray);
axis image;

if isfield(handles.Process,'ROIpos') && size(handles.Process.ROIpos,2) >= curFrame
    if size(handles.Process.ROIpos,2) > 1
        ROI = handles.Process.ROIpos(:,handles.Current.Ix);
    else
        ROI = handles.Process.ROIpos(:,1);
    end
else
    ROI = [];
end
plotROI(ROI);

guidata(hObject,handles);

% --- Executes during object creation, after setting all properties.
function frameSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to frameSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in DeleteROIbutton.
function DeleteROIbutton_Callback(hObject, eventdata, handles)
% hObject    handle to DeleteROIbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
curSel = get(handles.ROIList,'Value');

handles.Process.ROIpos(curSel) = [];
handles.Process.ROIimage(curSel) = [];
handles.Process.ROIlabel(curSel) = [];

ROIlist = get(handles.ROIList,'String');
lastInd = length(ROIlist);
if curSel == lastInd
    set(handles.ROIList,'Value',curSel - 1);
end
ROIlist(curSel) = [];

set(handles.ROIList,'String',ROIlist);
plotROI(handles.Process.ROIpos,handles.axes1,curSel);
guidata(hObject,handles);


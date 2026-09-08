function varargout = ROIViewer(varargin)
% ROIVIEWER MATLAB code for ROIViewer.fig
%      ROIVIEWER, by itself, creates a new ROIVIEWER or raises the existing
%      singleton*.
%
%      H = ROIVIEWER returns the handle to a new ROIVIEWER or the handle to
%      the existing singleton*.
%
%      ROIVIEWER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ROIVIEWER.M with the given input arguments.
%
%      ROIVIEWER('Property','Value',...) creates a new ROIVIEWER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ROIViewer_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ROIViewer_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ROIViewer

% Last Modified by GUIDE v2.5 29-Aug-2018 10:49:03

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ROIViewer_OpeningFcn, ...
                   'gui_OutputFcn',  @ROIViewer_OutputFcn, ...
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


% --- Executes just before ROIViewer is made visible.
function ROIViewer_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ROIViewer (see VARARGIN)

% Choose default command line output for ROIViewer
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ROIViewer wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = ROIViewer_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on slider movement.
function imageSlider_Callback(hObject, eventdata, handles)
% hObject    handle to imageSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
% whatToDraw = get(handles.imagePopup, 'Value');
% % Image the selected image
handles.Current.Ix = round(get(hObject,'Value'));
% switch whatToDraw
%     case 1
        handles.Current.Image = ...
            handles.Data.imageStack(handles.Current.Ix).data;
        %         handles.Current.clims = handles.Data.clims;
%     case 2
%         handles.Current.Image = ...
%             handles.Process.filterStack(handles.Current.Ix).data;
%         %         handles.Current.clims = handles.Process.clims;
%         %         handles.Current.clims = [0 500];
%         
% end;
set(handles.axes1,'NextPlot','replacechildren');
imagesc(handles.Current.Image, handles.Current.clims);
% imagesc(handles.Current.Image);
%         axis image;
% if get(handles.showParticles, 'Value')
%     if handles.isFitPSF
%         plotParticle(handles.Tracking.Particles, ...
%             handles.Current.Ix, handles.isFitPSF);
%     else
%         plotParticle(handles.Tracking.Centroids, ...
%             handles.Current.Ix, handles.isFitPSF);
%     end
% end
% 
% if get(handles.showTracks, 'Value')
%     plotTracks(handles.Current.Tracks, handles.Current.Ix);
% end

if isfield(handles.Process,'ROIpos')
    ROI = handles.Process.ROIpos(:,handles.Current.Ix);
    plotROI(ROI);
    
end

% Update the image indicator in the panel
set(handles.imageCounter, 'String', ['Image ', num2str(handles.Current.Ix),'/',num2str(handles.Data.nImages)]);

impixelinfo;
% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function imageSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to imageSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in LoadImageButton.
function LoadImageButton_Callback(hObject, eventdata, handles)
% hObject    handle to LoadImageButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[fileName,pathName]  = uigetfile('*.tif','Select stack for read out');
if fileName ~= 0
    set(handles.StatusText,'String','Reading Image...');
    drawnow;
    [imageStack, nImages] = TIFread([pathName, fileName]);
    set(handles.StatusText,'String','Reading Image...Done');
    drawnow;
    % Reset Data fields;
    handles.Data = [];
    
    % Update Handles
    handles.Data.fileName = fileName;
    handles.Data.pathName = pathName;
    handles.Data.imageStack = imageStack;
    handles.Data.nImages = nImages;
    
    % Reset all the fields (opening a new file you will lose the unsaved
    % changes to the current file).
    
    handles.Process = [];
    handles.Process.ROIClass = [];
    handles.Parameters.Used = [];
%     handles.Tracking = [];
%     handles.Analysis = [];
%     handles.PreAnalysis = [];
    handles.Current = [];
    handles.Current.Ix = 1;
    % Select current image and set colormap limits.
    handles.Current.Image = handles.Data.imageStack(handles.Current.Ix).data;
    handles.Data.clims = [min(min(handles.Current.Image))...
        max(max(handles.Current.Image))];
    handles.Current.clims = handles.Data.clims;
    MaxBrightness = zeros(handles.Data.nImages,1);
    for i = 1:handles.Data.nImages
        MaxBrightness(i) = max(handles.Data.imageStack(i).data(:));
    end
    handles.Data.MaxBrightnessStack = 2*max(MaxBrightness); %give a 100% buffer above the maximum
    set(handles.BlackValSlider,'Min',0,'Max',handles.Data.MaxBrightnessStack,'SliderStep',[1/(handles.Data.MaxBrightnessStack-1),10/(handles.Data.MaxBrightnessStack-1)]);
    set(handles.WhiteValSlider,'Min',0,'Max',handles.Data.MaxBrightnessStack,'SliderStep',[1/(handles.Data.MaxBrightnessStack-1),10/(handles.Data.MaxBrightnessStack-1)]);
    
    set(handles.BlackValEdit,'String',num2str(handles.Current.clims(1)));
    set(handles.BlackValSlider,'Value',handles.Current.clims(1));
    set(handles.WhiteValEdit,'String',num2str(handles.Current.clims(2)));
    set(handles.WhiteValSlider,'Value',handles.Current.clims(2));
    
    %Reset the ROI list
    set(handles.ROIList,'Value',1);
    set(handles.ROIList,'String','');
    
    
    % Enable the image slider
    if handles.Data.nImages > 1
        % Set Minimum of image slider
        set(handles.imageSlider,'Min', handles.Current.Ix);
        % Set Maximum of image slider
        set(handles.imageSlider,'Max', handles.Data.nImages);
        % Set Value of image slider
        set(handles.imageSlider,'Value', handles.Current.Ix);
        % Set Step of image slider
        set(handles.imageSlider, 'SliderStep', [1/(handles.Data.nImages-1)...
            1/(handles.Data.nImages-1)]);
        % Set Image counter
        set(handles.imageCounter, 'String', ['Image ', ...
            num2str(handles.Current.Ix),'/',num2str(handles.Data.nImages)]);
    end
    
    % Disable the options to visualize filtered images
%     set(handles.imagePopup, 'Value',1);
%     set(handles.imagePopup, 'Enable', 'off');
    
    % Disable the otpions to visualize hand checked tracks
%     set(handles.TrackPopUp, 'Value',1);
%     set(handles.TrackPopUp, 'Enable', 'off');
    
    % Disable the options to visualize localized particles
%     set(handles.showParticles, 'Value', 0);
%     set(handles.showParticles, 'Enable', 'off');
%     
    % Disable the options to visualize the tracks
%     set(handles.showTracks, 'Value', 0);
%     set(handles.showTracks, 'Enable', 'off');
    
    %Enable the roi button
%     set(handles.roiButton,'Enable','on');
%     set(handles.LoadROIfromFile,'Enable','on');
%     set(handles.StandardROIbutton,'Enable','on');
%     set(handles.RemRefImage,'Enable','off');
    
    %Diable the ROI delete & ROI rename buttons
%     set(handles.roiRemovePush,'Enable','off');
%     set(handles.roiNamePush,'Enable','off');
    
    %Reset the Classification display
%     set(handles.ROIClassCur_text,'String','');
    
    
    %Enable the filter button
%     set(handles.filterButton,'Enable','on');
%     set(handles.lpEdit,'Enable','on');
%     set(handles.hpEdit,'Enable','on');
    
    
    % Display current Image
    
    colormap(gray);
    set(handles.axes1,'NextPlot','replace');
    imagesc(handles.Current.Image, handles.Current.clims);
    axis image;
    impixelinfo;
    
end
% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in LoadROIButton.
function LoadROIButton_Callback(hObject, eventdata, handles)
% hObject    handle to LoadROIButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[fileName,pathName]  = uigetfile('*.mat','Select mat file containing ROI data');
if fileName ~= 0
    set(handles.StatusText,'String','Loading ROI data...');
    drawnow;
    IN = load(fullfile(pathName,fileName));
    handles.Process.ROIpos = IN.ROIpos;
    handles.Process.ROIimage = IN.ROIimage;
    
    tpoint = get(handles.imageSlider,'Value');
    ax_h = handles.axes1;
    ROI = handles.Process.ROIpos(:,tpoint);
    plotROI(ROI,ax_h,0);
    set(handles.StatusText,'String','Loading ROI data...Done');
    drawnow;
end
guidata(hObject,handles);

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
imagesc(handles.Current.Image, handles.Current.clims);       % plot image
% axis image;
% if get(handles.showParticles, 'Value')
%     if handles.isFitPSF
%         plotParticle(handles.Tracking.Particles, ...
%             handles.Current.Ix, handles.isFitPSF);
%     else
%         plotParticle(handles.Tracking.Centroids, ...
%             handles.Current.Ix, handles.isFitPSF);
%     end
% end
% 
% if get(handles.showTracks, 'Value')
%     plotTracks(handles.Current.Tracks, handles.Current.Ix);
% end

if isfield(handles.Process,'ROIpos')
    ROI = handles.Process.ROIpos(:,handles.Current.Ix);     
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
imagesc(handles.Current.Image, handles.Current.clims);       % plot image
% axis image;
%Plot ROI

% if get(handles.showParticles, 'Value')
%     if handles.isFitPSF
%         plotParticle(handles.Tracking.Particles, ...
%             handles.Current.Ix, handles.isFitPSF);
%     else
%         plotParticle(handles.Tracking.Centroids, ...
%             handles.Current.Ix, handles.isFitPSF);
%     end
% end
% 
% if get(handles.showTracks, 'Value')
%     plotTracks(handles.Current.Tracks, handles.Current.Ix);
% end

if isfield(handles.Process,'ROIpos')
    ROI = handles.Process.ROIpos(:,handles.Current.Ix);
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
imagesc(handles.Current.Image, handles.Current.clims);       % plot image
% axis image;
%Plot ROI

% if get(handles.showParticles, 'Value')
%     if handles.isFitPSF
%         plotParticle(handles.Tracking.Particles, ...
%             handles.Current.Ix, handles.isFitPSF);
%     else
%         plotParticle(handles.Tracking.Centroids, ...
%             handles.Current.Ix, handles.isFitPSF);
%     end
% end
% 
% if get(handles.showTracks, 'Value')
%     plotTracks(handles.Current.Tracks, handles.Current.Ix);
% end

if isfield(handles.Process,'ROIpos')
    ROI = handles.Process.ROIpos(:,handles.Current.Ix);     
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
imagesc(handles.Current.Image, handles.Current.clims);       % plot image
% axis image;
% if get(handles.showParticles, 'Value')
%     if handles.isFitPSF
%         plotParticle(handles.Tracking.Particles, ...
%             handles.Current.Ix, handles.isFitPSF);
%     else
%         plotParticle(handles.Tracking.Centroids, ...
%             handles.Current.Ix, handles.isFitPSF);
%     end
% end
% 
% if get(handles.showTracks, 'Value')
%     plotTracks(handles.Current.Tracks, handles.Current.Ix);
% end

if isfield(handles.Process,'ROIpos')
    ROI = handles.Process.ROIpos(:,handles.Current.Ix);     
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

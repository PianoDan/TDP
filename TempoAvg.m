function varargout = TempoAvg(varargin)
% TEMPOAVG MATLAB code for TempoAvg.fig
%      TEMPOAVG, by itself, creates a new TEMPOAVG or raises the existing
%      singleton*.
%
%      H = TEMPOAVG returns the handle to a new TEMPOAVG or the handle to
%      the existing singleton*.
%
%      TEMPOAVG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TEMPOAVG.M with the given input arguments.
%
%      TEMPOAVG('Property','Value',...) creates a new TEMPOAVG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before TempoAvg_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to TempoAvg_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help TempoAvg

% Last Modified by GUIDE v2.5 14-Feb-2018 20:15:39

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @TempoAvg_OpeningFcn, ...
                   'gui_OutputFcn',  @TempoAvg_OutputFcn, ...
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


% --- Executes just before TempoAvg is made visible.
function TempoAvg_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to TempoAvg (see VARARGIN)

% Choose default command line output for TempoAvg
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes TempoAvg wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = TempoAvg_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in ActiveDirectoryButton.
function ActiveDirectoryButton_Callback(hObject, eventdata, handles)
% hObject    handle to ActiveDirectoryButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.dir = uigetdir('','Set Active Directory');
if ~handles.dir
    return;
end
handles.ActiveDirectoryBox.String = handles.dir;
subjectlist = dir([handles.dir,filesep,'*_analysis.mat']);

for i = length(subjectlist):-1:1
    handles.subject(i) = load([handles.dir,filesep,subjectlist(i).name]);  
    melodies = cellfun(@str2num,handles.subject(i).subject.data(:,1));
    [melodies, indices] = sort(melodies);
    handles.subject(i).subject.data = handles.subject(i).subject.data(indices,:);
end

handles.MelodyBox.String = handles.subject(1).subject.data(:,1);
set(handles.SaveAveragesButton,'enable','on');

guidata(hObject,handles);


% --- Executes on selection change in MelodyBox.
function MelodyBox_Callback(hObject, eventdata, handles)
% hObject    handle to MelodyBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns MelodyBox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from MelodyBox

selection = get(hObject,'Value');

subjectid = {};
for i = length(handles.subject):-1:1
    interplength(i) = length(handles.subject(i).subject.data{selection,3}) -1;
    subjectid(i) = {handles.subject(i).subject.id;};
end
[maxlength,maxindex] = max(interplength);
allinterpy = nan(maxlength,length(handles.subject));

for i = length(handles.subject):-1:1
    x = cell2mat(handles.subject(i).subject.data{selection,4}(2:end,11));
    y = cell2mat(handles.subject(i).subject.data{selection,4}(2:end,9));
    interpy = cell2mat(handles.subject(i).subject.data{selection,3}(2:end,9));
    allinterpy(:,i) = [interpy;nan(maxlength-length(interpy),1)];
    plot(x,y,'Parent',handles.Ax);
    hold on
end
interpx = cell2mat(handles.subject(maxindex).subject.data{selection,3}(2:end,11));
plot(interpx,nanmean(allinterpy,2),'k','Parent',handles.Ax);

subjectid = flip(subjectid);
subjectid(end+1) = {'Average'};
legend(subjectid);

xlabel('Total Beats');
ylabel('Beat Duration (ms)');

hold off


% --- Executes during object creation, after setting all properties.
function MelodyBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MelodyBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in SaveAveragesButton.
function SaveAveragesButton_Callback(hObject, eventdata, handles)
% hObject    handle to SaveAveragesButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

nmelodies = length(handles.MelodyBox.String);
header = {'Melody'};
outputfile = [handles.dir,filesep,'MelodyAverages.xlsx'];

for j = 1:nmelodies
    header = [header; {handles.MelodyBox.String{j}}];
    header = [header; {' '}];
    subjectid = {};
    for i = length(handles.subject):-1:1
        interplength(i) = length(handles.subject(i).subject.data{j,3}) -1;
        subjectid(i) = {handles.subject(i).subject.id;};
    end
    [maxlength,maxindex] = max(interplength);
    allinterpy = nan(maxlength,length(handles.subject));

    for i = length(handles.subject):-1:1
        interpy = cell2mat(handles.subject(i).subject.data{j,3}(2:end,9));
        allinterpy(:,i) = [interpy;nan(maxlength-length(interpy),1)];
    end
    interpx = cell2mat(handles.subject(maxindex).subject.data{j,3}(2:end,11));
    meany = nanmean(allinterpy,2);
    
    xlswrite(outputfile,interpx',1,['B' num2str(j*2)]);
    xlswrite(outputfile,meany',1,['B' num2str(j*2 + 1)]);
    
end

xlswrite(outputfile,header,1,'A1');


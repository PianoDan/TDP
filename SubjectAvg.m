function varargout = SubjectAvg(varargin)
% SubjectAvg MATLAB code for SubjectAvg.fig
%      SubjectAvg, by itself, creates a new SubjectAvg or raises the existing
%      singleton*.
%
%      H = SubjectAvg returns the handle to a new SubjectAvg or the handle to
%      the existing singleton*.
%
%      SubjectAvg('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SubjectAvg.M with the given input arguments.
%
%      SubjectAvg('Property','Value',...) creates a new SubjectAvg or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SubjectAvg_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SubjectAvg_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SubjectAvg

% Last Modified by GUIDE v2.5 21-May-2018 18:10:44

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SubjectAvg_OpeningFcn, ...
                   'gui_OutputFcn',  @SubjectAvg_OutputFcn, ...
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


% --- Executes just before SubjectAvg is made visible.
function SubjectAvg_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SubjectAvg (see VARARGIN)

% Choose default command line output for SubjectAvg
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes SubjectAvg wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = SubjectAvg_OutputFcn(hObject, eventdata, handles) 
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
ids = [];

for i = length(subjectlist):-1:1
    handles.subject(i) = load([handles.dir,filesep,subjectlist(i).name]);  
    melodies = cellfun(@str2num,handles.subject(i).subject.data(:,1));
    ids = [str2double(handles.subject(i).subject.id) ids];
    [melodies, indices] = sort(melodies);
    handles.subject(i).subject.data = handles.subject(i).subject.data(indices,:);
end

[ids, idindices] = sort(ids);
handles.subject = handles.subject(:,idindices);


handles.idindices = idindices;
handles.MelodyBox.String = ids;
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

nstimuli = length(handles.subject(selection).subject.data);

for i = nstimuli:-1:1
    interplength(i) = length(handles.subject(selection).subject.data{i,3}) -1;
    stimulusid(i) = {handles.subject(selection).subject.data{i,1};};
end

[maxlength,maxindex] = max(interplength);
allinterpy = nan(maxlength,nstimuli);

for i = 1:nstimuli
    x = cell2mat(handles.subject(selection).subject.data{i,4}(2:end,11));
    y = cell2mat(handles.subject(selection).subject.data{i,4}(2:end,9));
    interpy = cell2mat(handles.subject(selection).subject.data{i,3}(2:end,9));
    allinterpy(:,i) = [interpy;nan(maxlength-length(interpy),1)];
    plot(x,y,'Parent',handles.Ax);
    hold on
end

interpx = cell2mat(handles.subject(selection).subject.data{maxindex,3}(2:end,11));
plot(interpx,nanmean(allinterpy,2),'k','Parent',handles.Ax);

%stimulusid = flip(stimulusid);
stimulusid(end+1) = {'Average'};
legend(stimulusid);

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

nsubjects = length(handles.MelodyBox.String(:,1));
header = {'Subject'};
outputfile = [handles.dir,filesep,'SubjectAverages.xlsx'];

for j = 1:nsubjects
    header = [header; {handles.MelodyBox.String(j,:)}];
    header = [header; {' '}];
    subjectid = {};
    nstimuli = length(handles.subject(j).subject.data);
    for i = nstimuli:-1:1
        interplength(i) = length(handles.subject(j).subject.data{i,3}) -1;
        subjectid(i) = {handles.subject(j).subject.id;};
    end
    [maxlength,maxindex] = max(interplength);
    allinterpy = nan(maxlength,length(handles.subject));

    for i = nstimuli:-1:1
        interpy = cell2mat(handles.subject(j).subject.data{i,3}(2:end,9));
        allinterpy(:,i) = [interpy;nan(maxlength-length(interpy),1)];
    end
    interpx = cell2mat(handles.subject(j).subject.data{maxindex,3}(2:end,11));
    meany = nanmean(allinterpy,2);
    
    xlswrite(outputfile,handles.MelodyBox.String(j,:),1,['A',num2str(j*2)]);
    xlswrite(outputfile,interpx',1,['B' num2str(j*2)]);
    xlswrite(outputfile,meany',1,['B' num2str(j*2 + 1)]);
    
end

xlswrite(outputfile,header,1,'A1');

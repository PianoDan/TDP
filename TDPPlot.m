function varargout = TDPPlot(varargin)
% TDPPLOT MATLAB code for TDPPlot.fig
%      TDPPLOT, by itself, creates a new TDPPLOT or raises the existing
%      singleton*.
%
%      H = TDPPLOT returns the handle to a new TDPPLOT or the handle to
%      the existing singleton*.
%
%      TDPPLOT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TDPPLOT.M with the given input arguments.
%
%      TDPPLOT('Property','Value',...) creates a new TDPPLOT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before TDPPlot_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to TDPPlot_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help TDPPlot

% Last Modified by GUIDE v2.5 18-Oct-2017 20:45:27

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @TDPPlot_OpeningFcn, ...
                   'gui_OutputFcn',  @TDPPlot_OutputFcn, ...
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


% --- Executes just before TDPPlot is made visible.
function TDPPlot_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to TDPPlot (see VARARGIN)

subjectlist = dir('*_analysis.mat');
set(handles.SubjectBox,'String',{subjectlist.name});

% Choose default command line output for TDPPlot
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes TDPPlot wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = TDPPlot_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in SubjectBox.
function SubjectBox_Callback(hObject, ~, handles)
% hObject    handle to SubjectBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns SubjectBox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from SubjectBox

contents = cellstr(get(hObject,'String'));
subjectfile = contents{get(hObject,'Value')};
load(subjectfile);
handles.subject = subject;
set(handles.startstopaction,'Enable','on');
[~, idx] = sort(str2double({subject.data{:,1}}));
subject.data = subject.data(idx,:);
set(handles.StimulusBox,'String',{subject.data{:,1}});

guidata(hObject,handles);


% --- Executes during object creation, after setting all properties.
function SubjectBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SubjectBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in StimulusBox.
function StimulusBox_Callback(hObject, eventdata, handles)
% hObject    handle to StimulusBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns StimulusBox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from StimulusBox
contents = cellstr(get(hObject,'String'));
stimulus = contents{get(hObject,'Value')};

index = strcmp(handles.subject.data,stimulus);
data = handles.subject.data{index,2};

graphtype = get(handles.GraphTypeMenu,'Value');

timems = cell2mat(data(2:end,7));
answerms = cell2mat(data(2:end,9));
totalbeats = cell2mat(data(2:end,11));

if graphtype == 1
    x = totalbeats;
    y = answerms;
elseif graphtype == 2
    x = timems;
    y = answerms;
end

plot(handles.GraphAxes,x,y);
ylabel('Answer (ms)')

if graphtype == 1
    xlabel('Total Beats');
elseif graphtype == 2
    xlabel('Time (ms)');
end

set(handles.startbox,'String',strcat(num2str(y(1)),' ms'));
set(handles.endbox,'String',strcat(num2str(y(end)),' ms'));



% --- Executes during object creation, after setting all properties.
function StimulusBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to StimulusBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in GraphTypeMenu.
function GraphTypeMenu_Callback(hObject, eventdata, handles)
% hObject    handle to GraphTypeMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns GraphTypeMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from GraphTypeMenu
contents = cellstr(get(handles.StimulusBox,'String'));
if isempty(contents{1})
    return
end
stimulus = contents{get(handles.StimulusBox,'Value')};

index = strcmp(handles.subject.data,stimulus);
data = handles.subject.data{index,2};

graphtype = get(handles.GraphTypeMenu,'Value');

timems = cell2mat(data(2:end,7));
answerms = cell2mat(data(2:end,9));
totalbeats = cell2mat(data(2:end,11));

if graphtype == 1
    x = totalbeats;
    y = answerms;
elseif graphtype == 2
    x = timems;
    y = answerms;
end

plot(handles.GraphAxes,x,y);
ylabel('Answer (ms)')

if graphtype == 1
    xlabel('Total Beats');
elseif graphtype == 2
    xlabel('Time (ms)');
end


% --- Executes during object creation, after setting all properties.
function GraphTypeMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to GraphTypeMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function toolsmenu_Callback(hObject, eventdata, handles)
% hObject    handle to toolsmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function startstopaction_Callback(hObject, eventdata, handles)
% hObject    handle to startstopaction (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

nsubjects = length(handles.subject.data);
stimuli = strings(1,nsubjects);
starts = zeros(1,nsubjects);
ends = zeros(1,nsubjects);
for idx = 1:nsubjects
    stimuli(idx) = handles.subject.data{idx,1};
    starts(idx) = handles.subject.data{idx,2}{2,9};
    ends(idx) = handles.subject.data{idx,2}{end,9};
end

[~,i]=sort(str2double(stimuli));

f=figure;
set(f,'Name',['Intitial/Final Answers for Subject ' handles.subject.id]);
output = [stimuli(i);starts(i);ends(i)]';
t=uitable(f,'Data',cellstr(output));
t.ColumnName = {'Stimulus','Start(ms)','End(ms)'};



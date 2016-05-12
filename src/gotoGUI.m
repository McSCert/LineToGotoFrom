function varargout = gotoGUI(varargin)
% GOTOGUI MATLAB code for gotoGUI.fig
%      GOTOGUI, by itself, creates a new GOTOGUI or raises the existing
%      singleton*.
%
%      H = GOTOGUI returns the handle to a new GOTOGUI or the handle to
%      the existing singleton*.
%
%      GOTOGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GOTOGUI.M with the given input arguments.
%
%      GOTOGUI('Property','Value',...) creates a new GOTOGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before gotoGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to gotoGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help gotoGUI

% Last Modified by GUIDE v2.5 25-Apr-2016 15:15:20

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @gotoGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @gotoGUI_OutputFcn, ...
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


% --- Executes just before gotoGUI is made visible.
function gotoGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to gotoGUI (see VARARGIN)

% Center GUI window on screen
set(handles.figure1, 'Units', 'pixels');
screenSize = get(0, 'ScreenSize');
position = get(handles.figure1, 'Position');
position(1) = (screenSize(3) - position(3))/2;
position(2) = (screenSize(4) - position(4))/2;
set(handles.figure1, 'Position', position);

% Choose default command line output for gotoGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes gotoGUI wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = gotoGUI_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
%varargout{1} = handles.output;

% Get the value from the textbox
newName = get(handles.textboxTagName, 'String');

% If name provided is invalid, don't provide it
if ~isvarname(newName)
    newName = '';
end
varargout{1} = newName;

% Close window
delete(handles.figure1);


function textboxTagName_Callback(hObject, eventdata, handles)
% hObject    handle to textboxTagName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of textboxTagName as text
%        str2double(get(hObject,'String')) returns contents of textboxTagName 
%        as a double


% --- Executes during object creation, after setting all properties.
function textboxTagName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to textboxTagName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
    
    
end


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Check that name provided is valid
newName = get(handles.textboxTagName, 'String');
if isvarname(newName)
	close(handles.figure1);
else
    disp(['Error using line2Goto:' char(10) ...
          ' Invalid goto/from tag name provided. Valid ' ...
          'identifiers start with a letter, contain no spaces or ' ...
          'special characters and are at most 63 characters long'])
end

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

hFig = ancestor(hObject,'Figure');
if isequal(get(hFig, 'waitstatus'), 'waiting')
    uiresume(hFig);
else
    % Close the figure
    delete(hFig);
end


% --- Executes on key press with focus on figure1 and none of its controls.
function figure1_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

key = get(gcf,'CurrentKey');
if (strcmp(key, 'return'))
        pushbutton1_Callback(hObject, eventdata, handles)
end

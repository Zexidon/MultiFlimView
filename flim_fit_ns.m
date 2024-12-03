function varargout = flim_fit_ns(varargin)
% FLIM_FIT_NS M-file for flim_fit_ns.fig
%      FLIM_FIT_NS, by itself, creates a new FLIM_FIT_NS or raises the existing
%      singleton*.
%
%      H = FLIM_FIT_NS returns the handle to a new FLIM_FIT_NS or the handle to
%      the existing singleton*.
%
%      FLIM_FIT_NS('Property','Value',...) creates a new FLIM_FIT_NS using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to flim_fit_ns_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      FLIM_FIT_NS('CALLBACK') and FLIM_FIT_NS('CALLBACK',hObject,...) call the
%      local function named CALLBACK in FLIM_FIT_NS.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help flim_fit_ns

% Last Modified by GUIDE v2.5 04-Dec-2018 15:30:55

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @flim_fit_ns_OpeningFcn, ...
    'gui_OutputFcn',  @flim_fit_ns_OutputFcn, ...
    'gui_LayoutFcn',  [], ...
    'gui_Callback',   []);
if nargin & isstr(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before flim_fit_ns is made visible.
function flim_fit_ns_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)

% Choose default command line output for flim_fit_ns
global HEADER_LENGTH;
global IMG_MIN;
global MAX_NUM_TAU;
global MAX_AMP MAX_TAU;
global lineColor stringColor;

HEADER_LENGTH = 1280;
IMG_MIN = 0.1;
MAX_NUM_TAU=3;
lineColor={'bx' 'kx' 'rx' 'gx'};
stringColor={'blue' 'black' 'red' 'green'};
MAX_TAU = 1e5;
MAX_AMP = 1e7;

handles.output = hObject;
guidata(hObject, handles);
    if size(varargin,2)>=3
    set(handles.pathString, 'String',varargin{2});
    set(handles.fileString, 'String',varargin{3});
    LoadDataButton_Callback(hObject, eventdata, handles)
    ViewImage_Callback(hObject, eventdata, handles)
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Outputs from this function are returned to the command line.
function varargout = flim_fit_ns_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on selection change in Colormap.
function Colormap_Callback(hObject, eventdata, handles)
% hObject    handle to Colormap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns Colormap contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Colormap
ValueCM = get(hObject,'Value');
StringCM = get(hObject,'String');
CMap = StringCM{ValueCM};
colormap(CMap);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in PrintButton.
function PrintButton_Callback(hObject, eventdata, handles)
% hObject    handle to PrintButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global IMG_Main;

[PrintFilename, PrintPathname, flag]= uiputfile({'*.jpg';'*.tiff'}, 'save image');
viewOption=get(handles.viewOpt,'Value');
if flag==0    
else
    Filename=[PrintPathname PrintFilename];
    comment=get(handles.textComment,'String');
    print_figure(IMG_Main,Filename,viewOption,comment);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function print_figure(W,NamePrint,viewOption,comment)
if isempty(W)
    return
end

switch viewOption
    case 1  % intensity
        ClMap=get(gcf,'Colormap');
        PrintFigureHn=figure;
        colormap(ClMap);
        imagesc(W), axis image;
        Limiti=get(gca,'Clim');
        MxLabel=sprintf(' Max\n%.0f',Limiti(2));
        MnLabel=sprintf(' Min\n%.0f',Limiti(1));
        text(+1.02,0.8,MxLabel,'Units','Normalized','FontSize',12,'FontWeight','Bold');
        text(+1.02,0.2,MnLabel,'Units','Normalized','FontSize',12,'FontWeight','Bold');
        
        print(PrintFigureHn,'-djpeg100', [NamePrint]);
        
    case 2  % gray level
        img=((W))/2^(14);
        imwrite(img,NamePrint);
end


% close(PrintFigureHn);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in RescaleButton.
function RescaleButton_Callback(hObject, eventdata, handles)
% hObject    handle to RescaleButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global IMG_Main;


image=IMG_Main;
rescaleOption=get(handles.rescaleSelection,'Value');
if rescaleOption==1
    [ClLow,ClHigh]=rescale_figure(image);
else
    ClLow=str2num(get(handles.rescaleMin,'String'));
    ClHigh=str2num(get(handles.rescaleMax,'String'));
end
ClipValues = [ClLow ClHigh];
set(gca,'Clim',ClipValues);
colorbar;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [Cl_Low,Cl_High]=rescale_figure(W)
% Rescale the colormap of an image based on a rectangle

if isempty(W)
    return
end

sw=1;
while sw
    [x,y]=ginput(2);
    x=round(x);
    y=round(y);
    if (x>0)&(y>0)&(x<=size(W,2))&(y<=size(W,1))
        sw=0;
    end
end
Max=max(max(W(min(y):max(y),min(x):max(x))));
Min=min(min(W(min(y):max(y),min(x):max(x))));
Cl_High=Max;
Cl_Low=Min;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on button press in AverageButton.
function AverageButton_Callback(hObject, eventdata, handles)
% hObject    handle to AverageButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global handleRect;
global IMG_Main;


image=IMG_Main;
numRect=str2num(get(handles.numSelection,'String'));
optAverAoi=get(handles.FitAoiSelection,'Value');
if optAverAoi==2
    firstCol=str2num(get(handles.fitAoiFirstCol,'String'));
    lastCol=str2num(get(handles.fitAoiLastCol,'String'));
    firstRow=str2num(get(handles.fitAoiFirstRow,'String'));
    lastRow=str2num(get(handles.fitAoiLastRow,'String'));
    NumPoint = (lastCol-firstCol+1) * (lastRow-firstRow+1);
    handleRect=rectangle('Position', [firstCol firstRow lastCol-firstCol lastRow-firstRow]);
    [average,stdDeviation]=average_figure(image,numRect,optAverAoi,firstCol,lastCol,firstRow,lastRow);
else
    [average,stdDeviation]=average_figure(image,numRect,optAverAoi);
end
for (i=1:numRect)
    Buffer{i}=sprintf('%11.2f  +/- %8.2f (%6.2f%%)',average(i),stdDeviation(i),(stdDeviation(i)/average(i))*100);
end
msgbox(Buffer);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [Avg,Std]=average_figure(W,AverageNum,opt,firstCol,lastCol,firstRow,lastRow)
% Rescale the colormap of an image based on a rectangle
% Check the figure
if isempty(W)
    return
end
if opt==2
    for i = 1:AverageNum
        [Avg(i),Std(i)]=avfunction(W,opt,firstCol,lastCol,firstRow,lastRow);
    end
else
    for i = 1:AverageNum
        [Avg(i),Std(i)]=avfunction(W,opt);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [AvM,Std]=avfunction(H,opt,firstCol,lastCol,firstRow,lastRow)
% Calculate average in selected rectangle
if opt==2
    x(1)=firstCol;
    x(2)=lastCol;
    y(1)=firstRow;
    y(2)=lastRow;
else
    sw=1;
    while sw
        [x,y,handlePlot]=select_rect(1);
        x=round(x);
        y=round(y);
        if (x>0)&&(y>0)&&(x<=size(H,2))&&(y<=size(H,1))
            sw=0;
        end
    end
    delete(handlePlot);
end
n_pixel=(max(x)-min(x)+1)*(max(y)-min(y)+1);
Area=H(min(y):max(y),min(x):max(x));
Area=reshape(Area,1,n_pixel);
Area(isnan(Area))=0;
AvM=mean(Area);
Std=std(Area);
fprintf('Average = %11.2f  StdDev = %6.2f Ratio=%5.2f%% NumPixel= %d\n',AvM,Std,(Std/AvM)*100,n_pixel);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function output_text(newBuffer)
% Print text on the Output Window of a GUI

handle=findobj(gcbf,'Tag','outputText');
set(handle,'String',newBuffer);
drawnow;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in ClearButton.
function ClearButton_Callback(hObject, eventdata, handles)
% hObject    handle to ClearButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global handleRect;

clear global handleRect;
axes(handles.mainAxes);
cla;
delete(findobj(gcbf,'Tag','TMW_COLORBAR'));
set(handles.textGain,'String','');
set(handles.textDelay,'String','');
axes(handles.plotAxes), cla;
axes(handles.residAxes), cla;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on slider movement.
function Brightness_Callback(hObject, eventdata, handles)
% hObject    handle to Brightness (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

Beta=get(hObject,'Value');
ValueCM = get(handles.Colormap,'Value');
StringCM = get(handles.Colormap,'String');
CMap = StringCM{ValueCM};
colormap(brighten(eval(CMap),Beta));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on button press in HistButton.
function HistButton_Callback(hObject, eventdata, handles)
% hObject    handle to HistButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global IMG_Main;

image=IMG_Main;
[x,y,handleRect]=select_rect(1);
delete(handleRect);
x=round(x);
y=round(y);
Aoi=image(min(y):max(y),min(x):max(x));
[average,stdDev]=hist_figure(Aoi);
Buffer=sprintf('Average=%11.2f +/- %8.2f (%6.2f %%)',average,stdDev,stdDev/average*100);
h=text(1,1,Buffer);
set(h,'Units','Normalized');
set(h,'Position',[0.2 0.95]);
% output_text(Buffer);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  [avW,stdW]=hist_figure(W)
% Calculate the image histogram
% Check the figure
if isempty(W)
    return
end
figure;
VECTOR=reshape(W,1,size(W,1)*size(W,2));
%VECTOR=VECTOR(find(not(VECTOR==0)));
VECTOR=VECTOR(not(isnan(VECTOR)));
%M=min(VECTOR)+(0:255).*((max(VECTOR)-min(VECTOR))/255);
M=2^14-1;
[n,xout]=hist(VECTOR,M);
bar(xout,n);
avW=mean(VECTOR);
stdW=std(VECTOR);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [x,y,handle]=select_rect(Option)
% Select a rectange (to be used instead of ginput(2))
[x y]=ginput(2);

if Option==1
    xplot = [x(1) x(2) x(2) x(1) x(1)];
    yplot = [y(1) y(1) y(2) y(2) y(1)];
    hold on
    axis manual
    handle=plot(xplot,yplot,'w');
    hold off
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on button press in ZoomButton.
function ZoomButton_Callback(hObject, eventdata, handles)
% hObject    handle to ZoomButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

ZoomOn = get(hObject, 'Value');
if ZoomOn
    zoom on
else
    zoom off
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on button press in ProfileButton.
function ProfileButton_Callback(hObject, eventdata, handles)
% hObject    handle to ProfileButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
axes(handles.mainAxes);
[CX,CY,profilo,x,y]=improfile;
clear CX CY;
figure;
if (x(2)-x(1))>(y(2)-y(1))
    asse=round(x(1)):1:(round(x(1))+length(profilo)-1);
    textLabel=sprintf('Asse x');
else
    asse=round(y(1)):1:(round(y(1))+length(profilo)-1);
    textLabel=sprintf('Asse x');
end
handle=plot(asse,profilo','k-*');
set(handle,'MarkerSize',3);
xlabel(textLabel);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on button press in ViewLstButton.
function ViewLstButton_Callback(hObject, eventdata, handles)
% hObject    handle to ViewLstButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global DelayCellArray gain X TimeExp;
for i=1:length(gain)
    fprintf('%s\t%5d\t%5d\t%6.3f\n',(DelayCellArray{i}),X(i),gain(i),TimeExp(i));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in LinLogButton.
function LinLogButton_Callback(hObject, eventdata, handles)
% hObject    handle to LinLogButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of LinLogButton
axes(handles.plotAxes);

if (get(hObject,'Value')==1)
    set(gca,'YScale','linear');
    set(hObject,'String','Log');
else
    set(gca,'YScale','log');
    set(hObject,'String','Linear');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on button press in NormRestoreButton.
function NormRestoreButton_Callback(hObject, eventdata, handles)
% hObject    handle to NormRestoreButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of NormRestoreButton
global X Y_Single Y_Single_std selectionNum;

errorbarOn=get(handles.errorbarOn,'Value');
if (get(hObject,'Value')==1)
    for i=1:selectionNum
        Y_SingleNormalized(i,:)=Y_Single(i,:)/max(Y_Single(i,:));
        Y_Single_stdNormalized(i,:)=Y_Single_std(i,:)/max(Y_Single(i,:));
    end
    axes(handles.plotAxes),cla;
    plotData(X,Y_SingleNormalized,Y_Single_stdNormalized,selectionNum,errorbarOn);    
    set(hObject,'String','Restore');
else
    axes(handles.plotAxes),cla;
    plotData(X,Y_Single,Y_Single_std,selectionNum,errorbarOn);
    set(hObject,'String','Normalize');
end
x1=str2num(get(handles.plot_XMin,'String'));
x2=str2num(get(handles.plot_XMax,'String'));
set(gca,'Xlim',[x1 x2]);

y1=str2num(get(handles.plot_YMin,'String'));
y2=str2num(get(handles.plot_YMax,'String'));
set(gca,'Ylim',[y1 y2]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on button press in SavePlotButton.
function SavePlotButton_Callback(hObject, eventdata, handles)
% hObject    handle to SavePlotButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global X Y_Single selectionNum;
FileName=get(handles.fileString,'String');
SaveMatrix = [X' (Y_Single(1:selectionNum,:))'];
SaveData = ['save ' tempdir FileName '.dat' ' SaveMatrix -ascii']
eval(SaveData);
SaveMatData = ['save ' tempdir FileName '.mat' ' X Y_Single']
eval(SaveMatData);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on button press in SelectButton.
function SelectButton_Callback(hObject, eventdata, handles)
% hObject    handle to SelectButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global iml_or_lst;
global EXTENSION;

FileType=get(handles.FileType,'Value');
switch FileType
    case 1 %IMH (Hamamatsu)
        EXTENSION='.imh';
    case 2 %IMR (Photek)
        EXTENSION='.imq';
end

currentDir=get(handles.pathString,'String');
if isempty(currentDir)
    currentDir=pwd;
end

iml_or_lst=get(handles.iml_or_lst,'Value');
if iml_or_lst==0
    [filename, pathname, output]=uigetfile('*.lst','Load image name', currentDir);
else
    [filename, pathname, output]=uigetfile(EXTENSION,'Load image name', currentDir);
end
if output==0
    return;
end
% set pathname
set(handles.pathString, 'String',pathname);
% set filename
filename=filename(1:end-4);
set(handles.fileString, 'String',filename);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on button press in SelectBkgFile.
function SelectBkgFile_Callback(hObject, eventdata, handles)
% hObject    handle to SelectBkgFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

currentDir=get(handles.pathString,'String');
if isempty(currentDir)
    currentDir=pwd;
end
[bkgFilename, bkgPathname, output]=uigetfile('*.lst','Load BKG image name');
if output==0
    return;
end
% set pathname
set(handles.bkgPathString, 'String',bkgPathname);
% set filename
bkgFilename=bkgFilename(1:end-4);
set(handles.bkgFileString, 'String',bkgFilename);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% --- Executes on button press in LoadDataButton.
function LoadDataButton_Callback(hObject, eventdata, handles)
% hObject    handle to LoadDataButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global EXTENSION;
global HEADER_LENGTH;

clear global X Y gain gain_n;
clear global RowLength ColLength gate xbin ybin;
clear global DelayCellArray;
clear global TimeExp;

global X Y gain gain_n;
global RowLength ColLength gate xbin ybin;
global DelayCellArray;
global TimeExp;
global BkgFromFileON;
global XZero;


G = [599 600 620 640 660 680 700 720 740 760 780 800 820 840 860 880 900 920 940 960 980 999];
H = [1 1.00 1.34 1.88 2.55 3.49 4.78 6.42 8.65 11.56 15.60 20.72 27.16 35.43 46.73 60.41 78.18 100.61 128.61 162.51 209.73 258.58]/258.58;



G_Photek = [1 1.5 2 2.5 3 3.5 4 4.5 5 5.5 6 6.5 7 8 9 10];
H_Photek = [1.00E+00 6.41E+00 3.33E+01 1.42E+02 5.63E+02 1.96E+03 6.35E+03 1.89E+04 5.69E+04 1.32E+05 2.49E+05 3.60E+05 4.57E+05 7.33E+05 8.40E+05 8.40E+05]/8.40E+05;

set(handles.BkgOn,'Value',0);

h=findobj(gcbf,'Tag','PanelMain');
set(h,'Pointer','Watch');

h=findobj(gcbf,'Tag','PanelMain');
set(h,'Pointer','Watch');
FileType=get(handles.FileType,'Value');
switch FileType
    case 1 %IMH (Hamamatsu)
        EXTENSION='.imh';
    case 2 %IMR (Photek)
        EXTENSION='.imq';
end


pathName=get(handles.pathString,'String');
fileName=get(handles.fileString,'String');
iml_or_lst=get(handles.iml_or_lst,'Value');
if  iml_or_lst==0
    [DelayCellArray, DelayNum, status]=LoadLst(pathName,fileName);
    if (status < 0)
        h=findobj(gcbf,'Tag','PanelMain');
        set(h,'Pointer','Arrow');
        return;
    end
    if (EXTENSION=='.imh')
        for i=1:DelayNum
            FileNameCellArray{i}=[pathName fileName DelayCellArray{i} EXTENSION];
        end
    elseif (EXTENSION=='.imq')
        for i=1:DelayNum
            FileNameCellArray{i}=[pathName fileName(1:end-1) DelayCellArray{i} fileName(end) EXTENSION];
        end
    end
else
    DelayNum=1;
    FileNameCellArray{1}=[pathName fileName EXTENSION];
end

% Check for file existence
FileExist = 1;
for i=1:(size(FileNameCellArray,2))
    ExistTest = exist(FileNameCellArray{i});
    if ~ExistTest
        Buffer = sprintf('File %s not found',FileNameCellArray{i});
        warndlg(Buffer);
        %       output_text(Buffer);
        h=findobj(gcbf,'Tag','PanelMain');
        set(h,'Pointer','Arrow');
        return;
    end
end

%Read header
if (EXTENSION=='.imh')
    fid = fopen(FileNameCellArray{1},'r','ieee-le');
    fscanf(fid,'%12f',1);
    gate = fscanf(fid,'%12f',1);
    fscanf(fid,'%12f',1);
    xbin = fscanf(fid,'%4d',1);
    ybin = fscanf(fid,'%4d',1);
    RowLength = fscanf(fid,'%8d',1);
    ColLength = fscanf(fid,'%8d',1);
    SizeUtil = (RowLength*ColLength);
    TimeExp =  fscanf(fid,'%12f',1)/1000;
    fscanf(fid,'%f',1);
    fscanf(fid,'%f',1);
    CcdType=fscanf(fid,'%1d',1);
    Timescale=fscanf(fid,'%1d',1);
    fseek(fid,29,0);
    Comment = fscanf(fid,';%s',1);
    fclose(fid);
elseif (EXTENSION=='.imq')
    fid = fopen(FileNameCellArray{1},'r');
    fscanf(fid,'%6f',1);
    gate=5;
    fscanf(fid,'%6f',1);
    xbin=1;
    ybin=1;
    RowLength=192;
    ColLength=144;
    SizeUtil = (RowLength*ColLength);
    TimeExp=0.02*32;
    CcdType=1;
    Comment=fscanf(fid,'; %[^;]',1);
    fclose(fid);
end

set(handles.textGate,'String',num2str(gate));
set(handles.textBinX,'String',num2str(xbin));
set(handles.textBinY,'String',num2str(ybin));
set(handles.textTimeExp,'String',num2str(TimeExp));
set(handles.textComment,'String',Comment);
set(handles.textDelay,'String','');
set(handles.textGain,'String','');

if BkgFromFileON
    
    bkgPathName=get(handles.bkgPathString,'String');
    bkgFileName=get(handles.bkgFileString,'String');
    
    if  iml_or_lst==0
        [BkgDelayCellArray, BkgDelayNum, status]=LoadLst(bkgPathName,bkgFileName);
        if (status < 0)
            h=findobj(gcbf,'Tag','PanelMain');
            set(h,'Pointer','Arrow');
            return;
        end
        if (EXTENSION=='.imh')
            for i=1:BkgDelayNum
                BkgFileNameCellArray{i}=[bkgPathName bkgFileName BkgDelayCellArray{i} EXTENSION];
            end
        elseif (EXTENSION=='.imq')
            for i=1:BkgDelayNum
                BkgFileNameCellArray{i}=[bkgPathName bkgFileName(1:end-1) BkgDelayCellArray{i} bkgFileName(end) EXTENSION];
            end
        end
    else
        BkgDelayNum=1;
        BkgFileNameCellArray{1}=[bkgPathName bkgFileName EXTENSION];
    end
    
    % Check for file existence
    FileExist = 1;
    for i=1:(size(BkgFileNameCellArray,2))
        ExistTest = exist(BkgFileNameCellArray{i});
        if ~ExistTest
            Buffer = sprintf('File %s not found',BkgFileNameCellArray{i});
            warndlg(Buffer);
            %       output_text(Buffer);
            h=findobj(gcbf,'Tag','PanelMain');
            set(h,'Pointer','Arrow');
            return;
        end
    end
end


RotImageOn=get(handles.RotImageOn,'Value');


%Read all the images

for f=1:DelayNum
    fid = fopen(FileNameCellArray{f},'r','ieee-le');
    X(f) = fscanf(fid,'%12f',1);
    fscanf(fid,'%12f',1);
    gain(f) = fscanf(fid,'%12f',1);
    gain_n(f) = 1./exp(interp1(G,log(H),gain(f)));
    fscanf(fid,'%4d',1);
    fscanf(fid,'%4d',1);
    fscanf(fid,'%8d',1);
    fscanf(fid,'%8d',1);
    TimeExp(f) =  fscanf(fid,'%12f',1)/1000;
    fseek(fid,HEADER_LENGTH,-1);
    [C(:,f), count] = fread(fid,SizeUtil,'uint16');
    C(:,f)=C(:,f)+1;%counts from 1 to 2^12
    fclose(fid);
end


if BkgFromFileON
    for f=1:BkgDelayNum
        fid = fopen(BkgFileNameCellArray{f},'r','ieee-le');
        Bkg_X(f) = fscanf(fid,'%12f',1);
        fscanf(fid,'%12f',1);
        Bkg_gain(f) = fscanf(fid,'%12f',1);
        Bkg_gain_n(f) = 1./exp(interp1(G,log(H),Bkg_gain(f)));
        fscanf(fid,'%4d',1);
        fscanf(fid,'%4d',1);
        fscanf(fid,'%8d',1);
        fscanf(fid,'%8d',1);
        Bkg_TimeExp(f) =  fscanf(fid,'%12f',1)/1000;
        fseek(fid,HEADER_LENGTH,-1);
        [Bkg_C(:,f), count] = fread(fid,SizeUtil,'uint16');
        Bkg_C(:,f)=Bkg_C(:,f)+1;%counts from 1 to 2^12
        fclose(fid);
    end    
end

if BkgFromFileON
    if (or(or(not(X==Bkg_X),not(gain_n==Bkg_gain_n)),not(TimeExp==Bkg_TimeExp)))
        Buffer = sprintf('Data and bkd data not consistent !\n Bkg subtraction was not performed');
        warndlg(Buffer);
    else
        C=max(C-Bkg_C,1);
    end
end
%
% if  not(iml_or_lst==0)
%     gain_n=ones(DelayNum,1);
% end

for f=1:DelayNum
    image=reshape(gain_n(f)*C(:,f)/TimeExp(f),RowLength,ColLength)';
    Y(:,:,f)=image(:,:);
end

% sort temporal vector in ascending order
if not(issorted(X))
    [X iX]=sort(X);
    temp=Y;
    for f=1:DelayNum
        Y(:,:,f)=temp(:,:,iX(f));
    end
    clear temp;
end

meanIntensityTimeBehav=squeeze(sum(sum(Y,1),2))/SizeUtil;
[massimo indexZero]=max(meanIntensityTimeBehav);

XZero=X(indexZero);

if  iml_or_lst==0
    X=X-XZero;
end

switch Timescale
    case 1 % nanosecond
        set(handles.TimescaleTEXT,'String','Nanosecond');
    case 3 % microsecond
        gate=gate/1000;
        set(handles.TimescaleTEXT,'String','Microsecond');        
    case 2 % picosecond
        gate=gate*1000;
        set(handles.TimescaleTEXT,'String','Picosecond');        
end


set(handles.ClearDataButton,'Visible','On');
set(handles.ViewLstButton,'Visible','On');
h=findobj(gcbf,'Tag','PanelMain');
set(h,'Pointer','Arrow');

set(handles.plot_XMin,'string',num2str(X(1)));
set(handles.plot_XMax,'string',num2str(X(end)));

% if  iml_or_lst==0
%     axes(handles.plotAxes);
%     set(gca,'XLim',[X(1) X(end)]);
%     axes(handles.residAxes);
%     set(gca,'XLim',[X(1) X(end)]);
% end



if RotImageOn
    RotationAngleIndex=get(handles.RotationAngle,'Value');
    switch RotationAngleIndex
        case 1 %90 degree clockwise
            Y=rot90(Y);
        case 2 %180 degree clockwise
            Y=rot90(Y);
            Y=rot90(Y);            
        case 3 %270 degree clockwise
            Y=rot90(Y);
            Y=rot90(Y);
            Y=rot90(Y);
    end
    RowLength=size(Y,2);
    ColLength=size(Y,1);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [delay, numDelay, status]=LoadLst(path,file)

global EXTENSION;
FileDelayList = [path file '.lst'];
if exist(FileDelayList,'file')
    fidDelayList = fopen(FileDelayList,'r');
    numDelay=0;
    while ~feof(fidDelayList)
        if EXTENSION=='.imh'
            DelayValue = fscanf(fidDelayList,'%5d',1);
            DelayTimescale = fscanf(fidDelayList,'%c',1);
            if size(DelayValue,2) < 1
                break;
            else
                %DelayStr=str2num(DelayStr);
                numDelay = numDelay+1;
                if DelayValue>=0
                    delay{numDelay} = sprintf('%05d',DelayValue);               
                else
                    delay{numDelay} = sprintf('%04d%c',abs(DelayValue),'u');
                end
                if not(isempty(DelayTimescale))
                     delay{numDelay} = strcat(delay{numDelay},DelayTimescale);
                end
            end
        
        elseif EXTENSION=='.imq'
            lineStr=fgets(fidDelayList);
            if isempty(lineStr)
                break;
            end
            stringa = sscanf(lineStr,'%[^ ]%d');
            DelayStr = stringa(end);
            numDelay = numDelay+1;
            if DelayStr<0
                delay{numDelay} = 'XX';
            elseif  DelayStr==999
                delay{numDelay} = 'BK';
            else
                delay{numDelay} = sprintf('%02d',DelayStr);
            end
        end
    end
    fclose(fidDelayList);
    status=1;
else
    Buffer = sprintf('File %s not found',FileDelayList);
    warndlg(Buffer);
    status=-1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in ClearDataButton.
function ClearDataButton_Callback(hObject, eventdata, handles)
% hObject    handle to ClearDataButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global X Y;
clear global X;
clear global Y;
clear global gain gain_n;
clear global RowLength ColLength gate xbin ybin;
set(handles.textGate,'String','');
set(handles.textBinX,'String','');
set(handles.textBinY,'String','');
set(handles.textTimeExp,'String','');
set(handles.textComment,'String','');
set(handles.ClearDataButton,'Visible','Off');
set(handles.ViewLstButton,'Visible','Off');
% output_text('');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in ViewImage.
function ViewImage_Callback(hObject, eventdata, handles)
% hObject    handle to ViewImage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global X Y gain gain_n;
global IMG_Main;
global index_Zero;
global TimeExp;
global ThresholdON ThMask;
global firstAOIRow lastAOIRow firstAOICol lastAOICol;


axes(handles.mainAxes), cla;
iml_or_lst=get(handles.iml_or_lst,'Value');
if iml_or_lst==0
    DisplayX=str2double(get(handles.displayDelay,'String'));
    if isempty(DisplayX)
        return;
    end
    index_Zero=findIndex(DisplayX,X);
else
    index_Zero=1;
end

set(handles.textDelay,'String',num2str(X(index_Zero)));
set(handles.textGain,'String',num2str(gain(index_Zero)));

if exist('IMG_Main','var')
    clear global IMG_Main;
    global IMG_Main;
end
IMG_Main=Y(:,:,index_Zero);

viewOption=get(handles.viewOpt,'Value');
switch viewOption
    case 1  % intensity
    case 2  % gray level
        IMG_Main=IMG_Main/gain_n(index_Zero)*TimeExp(index_Zero);
end

dim1=size(IMG_Main,1);
dim2=size(IMG_Main,2);

optAoi=get(handles.FitAoiSelection,'Value');
if optAoi==1
    [firstAOICol,lastAOICol,firstAOIRow,lastAOIRow]=getSingleData;
elseif optAoi==2
    firstAOICol=str2num(get(handles.fitAoiFirstCol,'String'));
    lastAOICol=str2num(get(handles.fitAoiLastCol,'String'));
    firstAOIRow=str2num(get(handles.fitAoiFirstRow,'String'));
    lastAOIRow=str2num(get(handles.fitAoiLastRow,'String'));
elseif optAoi==3
    firstAOICol=1;
    lastAOICol=dim2;
    firstAOIRow=1;
    lastAOIRow=dim1;
end
IMG_Main=IMG_Main(firstAOIRow:lastAOIRow,firstAOICol:lastAOICol);
% 
% v=get(handles.numBinning,'value');
% s=get(handles.numBinning,'String');
% numBinning=str2num(s{v});
% 
% numBinning=str2double(s{v});
% dim1_New=fix(dim1/numBinning);
% dim2_New=fix(dim2/numBinning);

% 
% if numBinning==1
% else
%     [x y]=meshgrid(1:dim1,1:dim2);
%     [xbin ybin]=meshgrid(1:numBinning:dim1,1:numBinning:dim2);
%     IMG_Binned=zeros(round(dim2/numBinning),round(dim1/numBinning));
% 
%     IMG_Binned=interp2(IMG_Main,ybin,xbin,'bicubic');
%     IMG_Main=permute(IMG_Binned,[2 1]);
% end

if ThresholdON
    threshold=str2num(get(handles.ThresholdValue,'String'));
    ThMask=(IMG_Main>=threshold);
    figure, imagesc(ThMask); axis image;
else
    ThMask=ones(size(IMG_Main));
end

temp=NaN(size(ThMask));
temp(ThMask==1)=ThMask(ThMask==1);
ThMask=temp;
IMG_Main=IMG_Main.*ThMask;


FilterSize=str2double(get(handles.FilterSize,'String'));
if FilterSize>0
    IMG_Main=imfilter(IMG_Main,fspecial('gaussian',[FilterSize FilterSize],0.5));
end
axes(handles.mainAxes);
imagesc(IMG_Main);
colormap(jet);
colorbar;
axis image;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [i]=findIndex(value,vector)
temp1=find(vector <= value);
temp2=find(vector > value);
if ~isempty(temp1)
    if ~isempty(temp2)
        if ((value-vector(temp1(end))) < (vector(temp2(1))-value))
            i=temp1(end);
        else
            i=temp2(1);
        end
    else
        i=temp1(end);
    end
else
    i=temp2(1);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in PlotSingle.
function PlotSingle_Callback(hObject, eventdata, handles)
% hObject    handle to PlotSingle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global X Y Y_Single Y_Single_std;
global selectionNum;
global TimeExp gain_n;
global ThresholdON ThMask;
global firstAOIRow lastAOIRow firstAOICol lastAOICol;



if exist('Y_Single')
    clear global Y_Single;
    global Y_Single;
end

axes(handles.mainAxes);

selectionNum=str2num(get(handles.numSelection,'String'));
datacursormode on;
for i=1:selectionNum
        rect=getrect;
        rect=round(rect);
        hRect(i)=rectangle('Position',rect);
        xmin=rect(1);
        ymin=rect(2);
        width=rect(3); 
        height=rect(4);
        firstRow(i)=ymin;
        lastRow(i)=ymin+height;
        firstCol(i)=xmin;
        lastCol(i)=xmin+width;
        % x,y]=ginput(2);
        % x=round(x);
        % y=round(y);
        % temp=data(min(y):max(y),min(x):max(x),:);
end
datacursormode off;

% firstCol=zeros(1,selectionNum);
% lastCol=firstCol;
% firstRow=firstCol;
% lastRow=firstCol;
% NumPoint=firstCol;
% for i=1:selectionNum,
%     [firstCol(i),lastCol(i),firstRow(i),lastRow(i)]=getSingleData;
% end;

Y_Single = zeros(selectionNum,size(Y,3));
Y_Single_std=zeros(selectionNum,size(Y,3));

if ThresholdON  
    dim3=size(Y,3);
    for i=1:dim3
        Y_THR(:,:,i)=squeeze(Y(firstAOIRow:lastAOIRow,firstAOICol:lastAOICol,i)).*ThMask;
    end
else
    Y_THR=Y;
end

for i=1:selectionNum
    NumPoint(i) = (lastCol(i)-firstCol(i)+1) * (lastRow(i)-firstRow(i)+1);
    temp=Y_THR(firstRow(i):lastRow(i),firstCol(i):lastCol(i),:);
    vettore_m=squeeze(nanmean(reshape(temp,[1 size(temp,1)*size(temp,2) size(temp,3)])));
    Y_Single(i,:)=vettore_m;

    vettore_s=squeeze(nanstd(reshape(temp,[1 size(temp,1)*size(temp,2) size(temp,3)])));
    Y_Single_std(i,:)=vettore_s;
end
axes(handles.plotAxes);
cla;
errorbarOn=get(handles.errorbarOn,'Value');
plotData(X,Y_Single,Y_Single_std,selectionNum,errorbarOn);

Y_SingleNormalized=zeros(size(Y_Single));
Y_Single_stdNormalized=zeros(size(Y_Single));

for i=1:selectionNum
    Y_SingleNormalized(i,:)=Y_Single(i,:)/max(Y_Single(i,:));
    Y_Single_stdNormalized(i,:)=Y_Single_std(i,:)/max(Y_Single(i,:));
end

figure,
subplot(2,1,1)
plotData(X,Y_Single,Y_Single_std,selectionNum,errorbarOn);
set(gca,'Yscale','log');


subplot(2,1,2)
plotData(X,Y_SingleNormalized,Y_Single_stdNormalized,selectionNum,errorbarOn);   
set(gca,'Yscale','log');


% x1=str2num(get(handles.plot_XMin,'String'));
% x2=str2num(get(handles.plot_XMax,'String'));
% set(gca,'Xlim',[x1 x2]);
% 
% y1=str2num(get(handles.plot_YMin,'String'));
% y2=str2num(get(handles.plot_YMax,'String'));
% set(gca,'Ylim',[y1 y2]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [c1,c2,r1,r2]=getSingleData
global ColLength RowLength;
sw=1;
while sw
    [x,y,handle]=select_rect(1);
    delete(handle);
    x=round(x);
    y=round(y);
    if (x>0)&(y>0)&(x<RowLength)&(y<ColLength)
        sw=0;
    end
end
c1=min(x);
c2=max(x);
r1=min(y);
r2=max(y);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function plotData(asse,data,dataStd,num,errorbarOn)

MarkerColor(1,:)=[1 0 0];
MarkerColor(2,:)=[0 1 0];
MarkerColor(3,:)=[0 0 1];
MarkerColor(4,:)=[0 0 0];
MarkerColor(5,:)=[0 1 1];
MarkerColor(6,:)=[1 0 1];
MarkerColor(6,:)=[1 1 0];

% Plot the time behaviour(s)
Massimo=max(max(data));
Minimo=min(min(data));
for i=1:num
    if errorbarOn
        errorbar(asse,data(i,:),dataStd(i,:),'LineStyle','none','Marker','o','MarkerSize', 2,'Color',MarkerColor(i,:),'MarkerFaceColor',MarkerColor(i,:));
    else
        semilogy(asse,data(i,:),'LineStyle','none','Marker','o','MarkerSize', 2,'MarkerEdgeColor',MarkerColor(i,:),'MarkerFaceColor',MarkerColor(i,:));
    end
    hold on;
end

% set(gca,'YLim',[Minimo Massimo]);
%     axis([asse(1) asse(length(asse)) Minimo Massimo])
%set(gca,'DefaulttextUnits','Normalized');
xlabel('Delay (timescale unit)');
ylabel('Intensity (a.u.)');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on button press in MovieButton.
function MovieButton_Callback(hObject, eventdata, handles)
% hObject    handle to MovieButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global X Y gain_n TimeExp gate;


colors={'r' 'g' 'b' 'k'};
style={'.-r' '.-g' '.-b' '.-k'};

saveOpt=get(handles.saveMovie,'Value');
%scaleFree=get(handles.scaleFree,'Value');
fixOn=get(handles.Fix_max_color_range,'value');

value=get(handles.rescaleSelection,'value');
string=get(handles.rescaleSelection,'string');
fixOpt = string{value};

viewOption=get(handles.viewOpt,'Value');

if saveOpt
    fileAvi=[get(handles.fileString,'String') '.avi'];
    aviobj = VideoWriter(fileAvi,'Motion JPEG AVI');
    aviobj.FrameRate=1;
    open(aviobj);
%     aviobj=avifile(fileAvi,'fps',2,'compression','None');
end


if fixOn
    if strcmp(fixOpt,'manual')
        if viewOption==2
            minimo_image=0;
            massimo_image=2^12;
        else
            for f=1:size(Y,3)
                massimo(f)=max(max(Y(:,:,f)));
                minimo(f)=min(min(Y(:,:,f)));
            end
            massimo_image=max(massimo)*1.1;
            minimo_image=min(minimo)*0.9;
            clear minimo;
            clear massimo;
        end
    else if strcmp(fixOpt,'input')
            minimo_image=str2num(get(handles.rescaleMin,'String'));
            massimo_image=str2num(get(handles.rescaleMax,'String'));
        end
    end
end
% 
% selectionNum=str2num(get(handles.numSelection,'String'));
% data_Single=zeros(selectionNum,size(Y,3));
% for i=1:selectionNum
%     Buffer = sprintf(('Select aoi %d'),i);
%     output_text(Buffer);
%     datacursormode on;
%     point = ginput(2);    % button down detected
%     datacursormode off;
%     x=point(:,1);
%     y=point(:,2);
%     temp=Y(round(y(1)):round(y(2)),round(x(1)):round(x(2)),:);
%     data_Single(i,:)=mean(mean(temp));
% end
% 
% if viewOption==2
%     for(f=1:size(data_Single,2))
%         data_Single(:,f)=data_Single(:,f)/gain_n(f)*TimeExp(f);
%     end
% end

% if fixOn
%     for i=1:selectionNum,
%         minimo(i)=min(data_Single(i,:));
%         massimo(i)=max(data_Single(i,:));
%     end
%     massimo_plot=max(massimo)*1.1;
%     minimo_plot=min(minimo)*0.9;
%     clear minimo;
%     clear massimo;
% end

ValueCM = get(handles.Colormap,'Value');
StringCM = get(handles.Colormap,'String');
CMap = StringCM{ValueCM};

x1=str2num(get(handles.plot_XMin,'String'));
x2=str2num(get(handles.plot_XMax,'String'));

y1=str2num(get(handles.plot_YMin,'String'));
y2=str2num(get(handles.plot_YMax,'String'));


handleF=figure;
set(gcf,'Menubar','none');
for f=1:size(Y,3)
    %     subplot('position',[0.05 0.4 0.9,0.55]);
   
    if viewOption==1
        imagesc(Y(:,:,f));
    else
        imagesc(Y(:,:,f)/gain_n(f)*TimeExp(f));
    end
    if fixOn
        set(gca,'clim',[minimo_image massimo_image]);
    end
    colormap(CMap);
    colorbar;
    axis image;    
    set(gca,'XTick',[]);
    set(gca,'YTick',[]);
%     titolo=sprintf('PL image(counts) @Delay = %d mus \n(acquisition gate window = %d mus)',round(X(f)/1000),round(gate/1000));
        titolo=sprintf('PL image(counts) @Delay = %d ns \n(acquisition gate window = %d ns)',round(X(f)),round(gate));
title(titolo);

%     subplot('position',[0.10 0.12 0.8,0.2]);
%     for(i=1:selectionNum)
%         semilogy(X(1:f),data_Single(i,1:f),style{i},'LineWidth',3);
%         hold on;
%     end
%     hold off;
%     set(gca,'XLim',[x1 x2]);
%     set(gca,'YLim',[y1 y2]);
%     if fixOn
%         set(gca,'YLim',[minimo_plot massimo_plot]);
%     end
%     xlabel('Time (timescale unit)');
%     ylabel('Fluorescence counts - log scale ');
%     hold off;
    if saveOpt
        frame=getframe(handleF);
        writeVideo(aviobj,frame);
%         aviobj=addframe(aviobj,frame);
    end
    pause(0.5);
end
if saveOpt
    close(aviobj);
    Buffer = sprintf('movie saved in %s file',fileAvi)
    output_text(Buffer);
end;

clear tempMatrix;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in FitSingle.
function FitSingle_Callback(hObject, eventdata, handles)
% hObject    handle to FitSingle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of FitSingle
global X Y Y_Single;
global SingleFit SingleFitStop;

if exist('Y_Single')
    clear global Y_Single;
    global Y_Single;
end

Y_Single=zeros(1,size(Y,3));
SingleFit=get(hObject,'Value');
if SingleFit
    SingleFitStop=0;
    selectionNum=1;
    [firstCol,lastCol,firstRow,lastRow]=getSingleData;
    NumPoint = (lastCol-firstCol+1) * (lastRow-firstRow+1);
    temp=sum(sum(Y(firstRow:lastRow,firstCol:lastCol,:),1),2)/NumPoint;
    for (i=1:size(temp,3))
        Y_Single(i)=temp(1,1,i);
    end
    axes(handles.plotAxes),cla;
    plotData(X,Y_Single,0,selectionNum,0);
    x1=str2num(get(handles.plot_XMin,'String'));
    x2=str2num(get(handles.plot_XMax,'String'));
    set(gca,'Xlim',[x1 x2]);

    y1=str2num(get(handles.plot_YMin,'String'));
    y2=str2num(get(handles.plot_YMax,'String'));
    set(gca,'Ylim',[y1 y2]);
else
    SingleFitStop=1;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in FitImage.
function FitImage_Callback(hObject, eventdata, handles)
% hObject    handle to FitImage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of FitImage
global Y Y_Image;
global RowLength ColLength;
global index_Zero gain_n TimeExp;
global ImageFit ImageFitStop;
global ThMask;
global IMG;
global aoi1 aoi2;
global ThresholdON;


if exist('Y_Image')
    clear global Y_Image;
    global Y_Image;
end

ImageFit=get(hObject,'Value');
if ImageFit
    ImageFitStop=0;
    
    optAoi=get(handles.FitAoiSelection,'Value');
    if optAoi==1
        [firstCol,lastCol,firstRow,lastRow]=getSingleData;
    elseif optAoi==2
        firstCol=str2num(get(handles.fitAoiFirstCol,'String'));
        lastCol=str2num(get(handles.fitAoiLastCol,'String'));
        firstRow=str2num(get(handles.fitAoiFirstRow,'String'));
        lastRow=str2num(get(handles.fitAoiLastRow,'String'));
    elseif optAoi==3
        firstCol=1;
        lastCol=RowLength;
        firstRow=1;
        lastRow=ColLength;
    end
    NumPoint = (lastCol-firstCol+1) * (lastRow-firstRow+1);
    Y_Image=Y(firstRow:lastRow,firstCol:lastCol,:);
    %     v=get(handles.numBinning,'value');
    %     s=get(handles.numBinning,'String');
    %     numBinning=str2num(s{v});
    dim1=size(Y_Image,1);
    dim2=size(Y_Image,2);
    dim3=size(Y_Image,3);
    %     numBinning=str2double(s{v});
    %     dim1_New=fix(dim1/numBinning);
    %     dim2_New=fix(dim2/numBinning);
    
    %     if numBinning==1
    %     else
    %         [x y]=meshgrid(1:dim1,1:dim2);
    %         [xbin ybin]=meshgrid(1:numBinning:dim1,1:numBinning:dim2);
    %         Y_Binned=zeros(round(dim2/numBinning),round(dim1/numBinning),dim3);
    %         for(i=1:dim3)
    %             temp=interp2(Y_Image(:,:,i),ybin,xbin,'bicubic');
    %             Y_Binned(:,:,i)=temp;
    %         end
    %         Y_Image=permute(Y_Binned,[2 1 3]);
    %     end
    IMG=Y_Image(:,:,index_Zero);
    
    viewOption=get(handles.viewOpt,'Value');
    switch viewOption
        case 1  % intensity
        case 2  % gray level
            IMG=IMG/gain_n(index_Zero)*TimeExp(index_Zero);
    end
    
    if ThresholdON
        threshold=str2num(get(handles.ThresholdValue,'String'));
        ThMask=(IMG>=threshold);
    else
        ThMask=ones(size(IMG));
    end
    axes(handles.mainAxes);
    imagesc(IMG.*ThMask);
    colorbar;
    
    FilterSize=str2double(get(handles.FilterSize,'String'));
    if FilterSize>0
        for i=1:size(Y_Image,3)
            Y_Image(:,:,i)=imfilter(Y_Image(:,:,i),fspecial('gaussian',[FilterSize FilterSize],0.5));
        end
    end


    aoi1=size(Y_Image,1);
    aoi2=size(Y_Image,2);
    SizeUtil=aoi1*aoi2;
    Y_Image=reshape(Y_Image,SizeUtil,size(Y_Image,3))';
    ThMask_Vector=reshape(ThMask,SizeUtil,1);

else
    ImageFitStop=1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on button press in FitImgMonoExp.
function FitImgMonoExp_Callback(hObject, eventdata, handles)
% hObject    handle to FitImgMonoExp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of FitImgMonoExp
global X Y Y_Image;
global gate;
global RowLength ColLength;
global index_Zero gain_n TimeExp;
global aoi1 aoi2;
global ThMaskNaN;
global IMG;
global ThresholdON;

clear global Amp_Image Tau_Image Image_HSV Image_RGB beta_Image;
global Amp_Image Tau_Image Image_HSV Image_RGB beta_Image;

if exist('Y_Image')
    clear global Y_Image;
    global Y_Image;
end

optAoi=get(handles.FitAoiSelection,'Value');
if optAoi==1
    [firstCol,lastCol,firstRow,lastRow]=getSingleData;
elseif optAoi==2
    firstCol=str2num(get(handles.fitAoiFirstCol,'String'));
    lastCol=str2num(get(handles.fitAoiLastCol,'String'));
    firstRow=str2num(get(handles.fitAoiFirstRow,'String'));
    lastRow=str2num(get(handles.fitAoiLastRow,'String'));
elseif optAoi==3
    firstCol=1;
    lastCol=RowLength;
    firstRow=1;
    lastRow=ColLength;
end

DisplayX=str2double(get(handles.displayDelay,'String'));
index_Zero=findIndex(DisplayX,X);

SingleExpFit_Type=get(handles.SingleExpFitType,'Value');

low=str2num(get(handles.fitSingle_r1,'String'));
high=str2num(get(handles.fitSingle_r2,'String'));
indexFirst=findIndex(low,X);
indexLast=findIndex(high,X);
XStripped=X(indexFirst:indexLast);
NumPoint = (lastCol-firstCol+1) * (lastRow-firstRow+1);
Y_Image=Y(firstRow:lastRow,firstCol:lastCol,indexFirst:indexLast);

% v=get(handles.numBinning,'value');
% s=get(handles.numBinning,'String');
% numBinning=str2num(s{v});
dim1=size(Y_Image,1);
dim2=size(Y_Image,2);
dim3=size(Y_Image,3);
% dim1_New=fix(dim1/numBinning);
% dim2_New=fix(dim2/numBinning);

% 
% if numBinning==1
% else
%     [x y]=meshgrid(1:dim1,1:dim2);
%     [xbin ybin]=meshgrid(1:numBinning:dim1,1:numBinning:dim2);
%     Y_Binned=zeros(round(dim2/numBinning),round(dim1/numBinning),dim3);
%     for(i=1:dim3)
%         temp=interp2(Y_Image(:,:,i),ybin,xbin,'bicubic');
%         Y_Binned(:,:,i)=temp;
%     end
%     Y_Image=permute(Y_Binned,[2 1 3]);
% end

% index_Zero=index_Zero-indexFirst+1;
% IMG=Y_Image(:,:,index_Zero);
IMG=Y(:,:,index_Zero);
viewOption=get(handles.viewOpt,'Value');
switch viewOption
    case 1  % intensity
    case 2  % gray level
        IMG=IMG/gain_n(index_Zero)*TimeExp(index_Zero);
end

if ThresholdON
    threshold=str2num(get(handles.ThresholdValue,'String'));
    ThMask=(IMG>=threshold);
else
    ThMask=ones(size(IMG));
end

ThMaskNaN=ones(size(ThMask));
ThMaskNaN(ThMask==0)=NaN;
axes(handles.mainAxes);
imagesc(IMG.*ThMask), axis image;
colorbar;

FilterSize=str2double(get(handles.FilterSize,'String'));
if FilterSize>0
    for i=1:size(Y_Image,3)        
        Y_Image(:,:,i)=imfilter(Y_Image(:,:,i),fspecial('gaussian',[FilterSize FilterSize],0.5));        
    end
end



aoi1=size(Y_Image,1);
aoi2=size(Y_Image,2);
SizeUtil=aoi1*aoi2;
Y_Image=reshape(Y_Image,SizeUtil,size(Y_Image,3))';
ThMask_Vector=reshape(ThMaskNaN,SizeUtil,1);

if exist('Amp_Image')
    Amp_Image=zeros(aoi1,aoi2);
    Tau_Image=zeros(aoi1,aoi2);
    beta_Image=zeros(aoi1,aoi2);
end

%% fit
h=findobj(gcbf,'Tag','PanelMain');
set(h,'Pointer','Watch');

if (SingleExpFit_Type==1) % MonoExp fit
    YStripped_Image=Y_Image;
    [Amp_v,Tau_v]=Stripping_Image(XStripped,YStripped_Image);
    for(i=1:length(X))
        Y_temp(i,:)=Amp_v.*Tau_v.*(1-exp(-gate./Tau_v)).*exp(-X(i)./Tau_v);
    end
    Amp_Image=reshape(Amp_v,aoi1,aoi2);
    Tau_Image=reshape(Tau_v,aoi1,aoi2);
    Amp_Image=real(Amp_Image.*ThMaskNaN);
    Tau_Image=real(Tau_Image.*ThMaskNaN);
    beta_Image=ones(size(Amp_Image));
elseif (SingleExpFit_Type==3) % Effective Lifetime
    Tau_v=zeros(size(Y_Image,2),1);
    Amp_v=Tau_v;
    XStripped_i=XStripped(1):1:XStripped(end);
    %     Y_Image_i=zeros(size(Y_Image,1),length(XStripped_i));
    for i=1:size(Y_Image,2)
        %         Y_Image_i(:,i)=interp1(XStripped,Y_Image(:,i),XStripped_i);
        DecayData=interp1(XStripped,Y_Image(:,i),XStripped_i);
        index=find(DecayData<=(DecayData(1)./exp(1)),1);
        if isempty(index)
            Tau_v(i)=XStripped_i(end);
        else
            Tau_v(i)=XStripped_i(index);
        end
        Amp_v(i)=DecayData(1)/Tau_v(i)/(1-exp(-gate/Tau_v(i)));        
        
    end
    Amp_Image=reshape(Amp_v,aoi1,aoi2);
    Tau_Image=reshape(Tau_v,aoi1,aoi2);
    Amp_Image=real(Amp_Image.*ThMaskNaN);
    Tau_Image=real(Tau_Image.*ThMaskNaN);
    beta_Image=ones(size(Amp_Image));    
elseif (SingleExpFit_Type==2) % Stretched Exp fit
    Y_mean=sum(Y_Image,2)/SizeUtil;
    [A_mean,TAU_mean]=Stripping(XStripped,Y_mean');

    low=str2num(get(handles.fitSingle_r1,'String'));
    high=str2num(get(handles.fitSingle_r2,'String'));
    indexFirst=findIndex(low,X);
    indexLast=findIndex(high,X);
    XStretched=X(indexFirst:indexLast);
    YStretched=Y_Image;

    XNonLin=XStretched(1):1:XStretched(end);
    gain_nNonLin=interp1(XStretched,gain_n(indexFirst:indexLast),XNonLin);

    for q=1:SizeUtil
        if ThMaskNaN(q)
            YNonLin=interp1(XStretched,YStretched(:,q),XNonLin);
            [beta(q), Tau_v(q)]=stretchExpImage(XNonLin,YNonLin,TAU_mean,1./gain_nNonLin);
        else
            Tau_v(q)=0.0;
            beta(q)=0.0;
        end
        if (mod(q,round(SizeUtil/10))==0)
            fprintf(' Calculating stretched exp... %d %%\n',q*100/(SizeUtil));
        end
    end
    Amp_v=Y_Image(index_Zero,:)./Tau_v./(1-exp(-gate./Tau_v));

    Amp_Image=reshape(Amp_v,aoi1,aoi2);
    Tau_Image=reshape(Tau_v,aoi1,aoi2);
    beta_Image=reshape(beta,aoi1,aoi2);
    Amp_Image=real(Amp_Image.*ThMaskNaN);
    Tau_Image=real(Tau_Image.*ThMaskNaN);
    beta_Image=real(beta_Image.*ThMaskNaN);
end

% if (numBinning~=1)
%     [x y]=meshgrid(1:1/numBinning:floor(dim1/numBinning),1:1/numBinning:floor(dim2/numBinning));
%     Amp_Image=interp2(Amp_Image,y,x,'nearest')';
%     Tau_Image=interp2(Tau_Image,y,x,'nearest')';
%     beta_Image=interp2(beta_Image,y,x,'nearest')';
% end;
%% end fit

filename=get(handles.fileString,'String');
h=findobj(gcbf,'Tag','PanelMain');
set(h,'Pointer','Arrow');

MonoExpFitFigureHn=findobj('Tag','MonoExpFitImage');
if isempty(MonoExpFitFigureHn)
    MonoExpFitFigureHn=figure(monoExpFit_image);
else
    figure(MonoExpFitFigureHn);
end
h=guihandles(MonoExpFitFigureHn);
set(h.FileName,'String',filename);

FittingLimitsString=sprintf('MonoExp fit from %d to %d ns',X(indexFirst),X(indexLast));
set(h.Title,'String',FittingLimitsString);

axes(h.TauPlot), cla;
imagesc(Tau_Image);
colorbar;
set(gca,'Xlim',[1 size(Tau_Image,2)]);
set(gca,'Ylim',[1 size(Tau_Image,1)]);
axis image;

axes(h.AmpPlot), cla;
imagesc(Amp_Image);
colorbar;
set(gca,'Xlim',[1 size(Amp_Image,2)]);
set(gca,'Ylim',[1 size(Amp_Image,1)]);
axis image;

if (SingleExpFit_Type==2) % Stretched Exp fit
    axes(h.BetaPlot), cla;
    imagesc(beta_Image);
    set(gca,'Xlim',[1 size(beta_Image,2)]);
    set(gca,'Ylim',[1 size(beta_Image,1)]);
    colorbar;
    axis image;
end

temp=reshape(Tau_Image,1,size(Tau_Image,1)*size(Tau_Image,2));
tau_av=nanmean(temp);
ClTAUHigh = nanmin(nanmax(nanmax(Tau_Image)),tau_av*2.5);
ClTAULow = nanmax(nanmin(nanmin(Tau_Image)),tau_av*0.5);

temp=reshape(Amp_Image,1,size(Amp_Image,1)*size(Amp_Image,2));
amp_av=nanmean(temp);
ClAHigh = nanmin(nanmax(nanmax(Amp_Image)),amp_av*2.5);
ClALow = nanmax(nanmin(nanmin(Amp_Image)),amp_av*0.1);


% HSV image
% set the Saturation to 1
Image_HSV(:,:,2)=ones(size(Amp_Image));
% Clip the Amp map for the HSV image
HH=nanmin(ClAHigh.*ones(size(Amp_Image)),Amp_Image);
KK=nanmax(ClALow.*ones(size(Amp_Image)),HH);
% set the Value to the normalized amplitude
AMax=nanmax(nanmax(KK));
AMin=nanmin(nanmin(KK));
Image_HSV(:,:,3)=(KK-AMin)/(AMax-AMin).*ThMaskNaN;
% Clip the Tau map for the HSV image
HH=nanmin(ClTAUHigh.*ones(size(Tau_Image)),Tau_Image);
KK=nanmax(ClTAULow.*ones(size(Tau_Image)),HH);
% set the Hue to the normalized TAU
TAUMax=nanmax(max(KK));
TAUMin=nanmin(min(KK));
Image_HSV(:,:,1)=(ones(size(KK))-(KK-TAUMin)/(TAUMax-TAUMin))*0.7.*ThMaskNaN;  % factor 0.667 simulate JET colormap
Image_RGB=hsv2rgb(Image_HSV);

axes(h.HSVPlot), cla;
imagesc(Image_RGB), axis image;
set(gca,'Xlim',[1 size(Image_RGB,2)]);
set(gca,'Ylim',[1 size(Image_RGB,1)]);

figure, 
plot(reshape(Tau_Image,1,size(Tau_Image,1)*size(Tau_Image,2)),reshape(Amp_Image,1,size(Amp_Image,1)*size(Amp_Image,2)));
xlabel('Lifetime (ns)');
ylabel('Amplitude (a.u.)');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on selection change in GuessChoice.
function GuessChoice_Callback(hObject, eventdata, handles)
% hObject    handle to GuessChoice (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns GuessChoice contents as cell array
%        contents{get(hObject,'Value')} returns selected item from GuessChoice
guessChoice=get(hObject,'Value');
switch guessChoice
    case 1  % Stripping
        set(handles.Tau1Fix,'Visible','Off');
        set(handles.Tau2Fix,'Visible','Off');
        set(handles.Tau3Fix,'Visible','Off');
        set(handles.TauFix_On,'Visible','Off');
        set(handles.Strip1_L,'Visible','On');
        set(handles.Strip1_H,'Visible','On');
        set(handles.Strip2_L,'Visible','On');
        set(handles.Strip2_H,'Visible','On');
        set(handles.Strip3_L,'Visible','On');
        set(handles.Strip3_H,'Visible','On');
        set(handles.Strip1_On,'Visible','On');
        set(handles.Strip2_On,'Visible','On');
        set(handles.Strip3_On,'Visible','On');
        set(handles.CompleteStrip,'Visible','On');
    case 2  % Tau Fix
        set(handles.Tau1Fix,'Visible','On');
        set(handles.Tau2Fix,'Visible','On');
        set(handles.Tau3Fix,'Visible','On');
        set(handles.TauFix_On,'Visible','On');
        set(handles.Strip1_L,'Visible','Off');
        set(handles.Strip1_H,'Visible','Off');
        set(handles.Strip2_L,'Visible','Off');
        set(handles.Strip2_H,'Visible','Off');
        set(handles.Strip3_L,'Visible','Off');
        set(handles.Strip3_H,'Visible','Off');
        set(handles.Strip1_On,'Visible','Off');
        set(handles.Strip2_On,'Visible','Off');
        set(handles.Strip3_On,'Visible','Off');
        set(handles.CompleteStrip,'Visible','Off');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on button press in Strip1_On.
function Strip1_On_Callback(hObject, eventdata, handles)
% hObject    handle to Strip1_On (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Strip1_On
global X Y_Single Y_Single_NoStrip1;
global Y_Image Y_Image_NoStrip1;
global SingleFit ImageFit;
global Amp Tau;
global gate;
global SingleFitStop;
global aoi1 aoi2;
global ImageFigureHn;
global Amp_Image Tau1_Image;
global ThMask;
global aoi1 aoi2;


global Amp1_Image Tau1_Image;

strip1On=get(hObject,'Value');
if strip1On
    stripPercOn=get(handles.stripPercOn,'Value');
    if stripPercOn
        lowPerc=str2num(get(handles.Strip1_L_perc,'String'));
        highPerc=str2num(get(handles.Strip1_H_perc,'String'));
    else
        low=str2num(get(handles.Strip1_L,'String'));
        high=str2num(get(handles.Strip1_H,'String'));
        indexFirst=findIndex(low,X);
        indexLast=findIndex(high,X);
        XStripped=X(indexFirst:indexLast);
    end
    if SingleFit
        if stripPercOn
            indexZero=findIndex(0,X);
            zeroIntensity=Y_Single(indexZero);
            temp=find(Y_Single(indexZero:end)<=Y_Single(indexZero)*lowPerc/100);
            indexFirst=temp(1)+indexZero-1;
            temp=find(Y_Single(indexZero:end)<=Y_Single(indexZero)*highPerc/100);
            indexLast=temp(1)+indexZero-1;
            XStripped=X(indexFirst:indexLast);
        end
        PlotFigureHn=findobj('Tag','FigurePlot');
        if isempty(PlotFigureHn)
            PlotFigureHn=figure(plot_figure_ns);
        else
            figure(PlotFigureHn);
        end
        h=guihandles(PlotFigureHn);
        set(h.Tau1Init,'String','0');
        set(h.A1Init,'String','0');
        set(h.Tau2Init,'String','0');
        set(h.A2Init,'String','0');
        set(h.Tau3Init,'String','0');
        set(h.A3Init,'String','0');
        set(h.ChiInit,'String','0');
        if exist('Amp')
            Amp=zeros(1,3);
            Tau=zeros(1,3);
        end
        YStripped=Y_Single(indexFirst:indexLast);
        [Amp(1),Tau(1)]=Stripping(XStripped,YStripped);
        yFit=Amp(1)*Tau(1)*exp(-X/Tau(1))*(1-exp(-gate/Tau(1)));
        Resid=(Y_Single-yFit)./Y_Single;
        ChiSquared= (norm((Y_Single(indexFirst:indexLast)-yFit(indexFirst:indexLast))./Y_Single(indexFirst:indexLast)));
        Y_Single_NoStrip1=Y_Single;
        Y_Single=Y_Single-yFit;
        axes(handles.plotAxes), cla;
        plotFittedData(X,Y_Single_NoStrip1,yFit,indexFirst,indexLast,Y_Single);
        axes(handles.residAxes), cla;
        plotResidual(X,Resid,indexFirst,indexLast,1);
        AString=sprintf('%6.1f',Amp(1));
        TauString=sprintf('%6.2f',Tau(1));
        ChiString=sprintf('%5.3f',ChiSquared);
        PlotFigureHn=findobj('Tag','FigurePlot');
        if isempty(PlotFigureHn)
            PlotFigureHn=figure(plot_figure_ns);
        else
            figure(PlotFigureHn);
        end
        h=guihandles(PlotFigureHn);
        set(h.Tau1Init,'String',TauString);
        set(h.A1Init,'String',AString);
        set(h.ChiInit,'String',ChiString);
    elseif ImageFit
        ImageFigureHn=findobj('Tag','FigureFitLinImage');
        if isempty(ImageFigureHn)
            ImageFigureHn=figure(fit_image_ns);
        else
            figure(ImageFigureHn);
        end
        axes(findobj(ImageFigureHn,'Tag','axes1'));
        imagesc(zeros(aoi1,aoi2));
        axes(findobj(ImageFigureHn,'Tag','axes2'));
        imagesc(zeros(aoi1,aoi2));
        axes(findobj(ImageFigureHn,'Tag','axes3'));
        imagesc(zeros(aoi1,aoi2));
        axes(findobj(ImageFigureHn,'Tag','axes4'));
        imagesc(zeros(aoi1,aoi2));
        axes(findobj(ImageFigureHn,'Tag','axes5'));
        imagesc(zeros(aoi1,aoi2));
        axes(findobj(ImageFigureHn,'Tag','axes6'));
        imagesc(zeros(aoi1,aoi2));

        if exist('Amp_Image')
            Amp_Image=zeros(aoi1,aoi2);
            Tau_Image=zeros(aoi1,aoi2);
        end
        YStripped_Image=Y_Image(indexFirst:indexLast,:);
        [Amp_v,Tau_v]=Stripping_Image(XStripped,YStripped_Image);
        for(i=1:length(X))
            Y_temp(i,:)=Amp_v.*Tau_v.*(1-exp(-gate./Tau_v)).*exp(-X(i)./Tau_v);
        end
        yFit=Y_temp;
        Y_Image_NoStrip1=Y_Image;
        Y_Image=Y_Image-yFit;
        Amp1_Image=reshape(Amp_v,aoi1,aoi2);
        Tau1_Image=reshape(Tau_v,aoi1,aoi2);
        Amp1_Image=real(Amp1_Image.*ThMask);
        Tau1_Image=real(Tau1_Image.*ThMask);
% 
%         ImageFigureHn=findobj('Tag','FigureFitImage');
%         if isempty(ImageFigureHn),
%             ImageFigureHn=figure(fit_image_ns);
%         else
%             figure(ImageFigureHn);
%         end
%         axes(findobj(ImageFigureHn,'Tag','axes1'));
        figure;
        imagesc(Tau1_Image.*ThMask), title('Tau1');
        colorbar;

%         axes(findobj(ImageFigureHn,'Tag','axes2'));
        figure;
        imagesc(Amp1_Image), title('Amp1');
        colorbar;
    end
else
    if SingleFitStop==1
        Y_Image=Y_Image_NoStrip1;
        ImageFigureHn=findobj('Tag','FigureFitImage');
        if isempty(ImageFigureHn)
            ImageFigureHn=figure(fit_image_ns);
        else
            figure(ImageFigureHn);
        end
        axes(findobj(ImageFigureHn,'Tag','axes1'));
        imagesc(zeros(aoi1,aoi2));
        axes(findobj(ImageFigureHn,'Tag','axes2'));
        imagesc(zeros(aoi1,aoi2));
    elseif SingleFitStop==0
        Y_Single=Y_Single_NoStrip1;
        axes(handles.plotAxes),cla;
        plotData(X,Y_Single,0,1,0);
        axes(handles.residAxes),cla;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on button press in Strip2_On.
function Strip2_On_Callback(hObject, eventdata, handles)
% hObject    handle to Strip2_On (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Strip2_On
global X Y_Single Y_Single_NoStrip2;
global Y_Image Y_Image_NoStrip2;
global SingleFit ImageFit;
global Amp Tau;
global gate;
global SingleFitStop;
global aoi1 aoi2;
global ImageFigureHn;
global Amp2_Image Tau2_Image;
global ThMask;
global aoi1 aoi2;

strip2On=get(hObject,'Value');
if strip2On
    low=str2num(get(handles.Strip2_L,'String'));
    high=str2num(get(handles.Strip2_H,'String'));
    indexFirst=findIndex(low,X);
    indexLast=findIndex(high,X);
    XStripped=X(indexFirst:indexLast);
    if SingleFit
        YStripped=Y_Single(indexFirst:indexLast);
        [Amp(2),Tau(2)]=Stripping(XStripped,YStripped);
        yFit=Amp(2)*Tau(2)*exp(-X/Tau(2))*(1-exp(-gate/Tau(2)));
        ChiSquared= (norm((Y_Single(indexFirst:indexLast)-yFit(indexFirst:indexLast))./Y_Single(indexFirst:indexLast)));
        Resid=(Y_Single-yFit)./Y_Single;
        Y_Single_NoStrip2=Y_Single;
        Y_Single=Y_Single-yFit;
        axes(handles.plotAxes),cla;
        plotFittedData(X,Y_Single_NoStrip2,yFit,indexFirst,indexLast,Y_Single);
        axes(handles.residAxes),cla;
        plotResidual(X,Resid,indexFirst,indexLast,1);
        PlotFigureHn=findobj('Tag','FigurePlot');
        if isempty(PlotFigureHn)
            PlotFigureHn=figure(plot_figure_ns);
        else
            figure(PlotFigureHn);
        end
        h=guihandles(PlotFigureHn);
        TauString=sprintf('%6.2f',Tau(2));
        AString=sprintf('%6.1f',Amp(2));
        ChiString=sprintf('%5.3f',ChiSquared);
        set(h.Tau2Init,'String',TauString);
        set(h.A2Init,'String',AString);
        set(h.ChiInit,'String',ChiString);
    elseif ImageFit
        YStripped_Image=Y_Image(indexFirst:indexLast,:);
        [Amp_v,Tau_v]=Stripping_Image(XStripped,YStripped_Image);
        for(i=1:length(X))
            Y_temp(i,:)=Amp_v.*Tau_v.*(1-exp(-gate./Tau_v)).*exp(-X(i)./Tau_v);
        end
        yFit=Y_temp;
        Y_Image_NoStrip2=Y_Image;
        Y_Image=Y_Image-yFit;
        Amp2_Image=reshape(Amp_v,aoi1,aoi2);
        Tau2_Image=reshape(Tau_v,aoi1,aoi2);
        Amp2_Image=real(Amp2_Image.*ThMask);
        Tau2_Image=real(Tau2_Image.*ThMask);
        %         ImageFigureHn=findobj('Tag','FigureFitImage');
        %         if isempty(ImageFigureHn),
        %             ImageFigureHn=figure(fit_image_ns);
        %         else
        %             figure(ImageFigureHn);
        %         end
        %         axes(findobj(ImageFigureHn,'Tag','axes4'));
        figure;
        imagesc(Tau2_Image), title('Tau2');
        colorbar;
        %         axes(findobj(ImageFigureHn,'Tag','axes5'));
        figure;
        imagesc(Amp2_Image), title('Amp2');
        colorbar;
    end
else
    if SingleFitStop==1
        Y_Image=Y_Image_NoStrip2;
        ImageFigureHn=findobj('Tag','FigureFitImage');
        if isempty(ImageFigureHn)
            ImageFigureHn=figure(fit_image_ns);
        else
            figure(ImageFigureHn);
        end
        axes(findobj(ImageFigureHn,'Tag','axes4'));
        imagesc(zeros(aoi1,aoi2));
        axes(findobj(ImageFigureHn,'Tag','axes5'));
        imagesc(zeros(aoi1,aoi2));
    elseif SingleFitStop==0
        Y_Single=Y_Single_NoStrip2;
        axes(handles.plotAxes),cla;
        plotData(X,Y_Single,0,1,0);
        axes(handles.residAxes),cla;
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on button press in Strip3_On.
function Strip3_On_Callback(hObject, eventdata, handles)
% hObject    handle to Strip3_On (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Strip3_On
global X Y_Single Y_Single_NoStrip3;
global Y_Image Y_Image_NoStrip3;
global SingleFit ImageFit;
global Amp Tau;
global gate;
global SingleFitStop;
global aoi1 aoi2;
global ImageFigureHn;
global Amp3_Image Tau3_Image;
global ThMask;
global aoi1 aoi2;



strip3On=get(hObject,'Value');
if strip3On
    low=str2num(get(handles.Strip3_L,'String'));
    high=str2num(get(handles.Strip3_H,'String'));
    indexFirst=findIndex(low,X);
    indexLast=findIndex(high,X);
    XStripped=X(indexFirst:indexLast);
    if SingleFit
        YStripped=Y_Single(indexFirst:indexLast);
        [Amp(3),Tau(3)]=Stripping(XStripped,YStripped);
        yFit=Amp(3)*Tau(3)*exp(-X/Tau(3))*(1-exp(-gate/Tau(3)));
        ChiSquared= (norm((Y_Single(indexFirst:indexLast)-yFit(indexFirst:indexLast))./Y_Single(indexFirst:indexLast)));
        Resid=(Y_Single-yFit)./Y_Single;
        Y_Single_NoStrip3=Y_Single;
        Y_Single=Y_Single-yFit;
        axes(handles.plotAxes),cla;
        plotFittedData(X,Y_Single_NoStrip3,yFit,indexFirst,indexLast,Y_Single);
        axes(handles.residAxes),cla;
        plotResidual(X,Resid,indexFirst,indexLast,1);
        PlotFigureHn=findobj('Tag','FigurePlot');
        if isempty(PlotFigureHn)
            PlotFigureHn=figure(plot_figure_ns);
        else
            figure(PlotFigureHn);
        end
        h=guihandles(PlotFigureHn);
        TauString=sprintf('%6.2f',Tau(3));
        AString=sprintf('%6.1f',Amp(3));
        ChiString=sprintf('%5.3f',ChiSquared);
        PlotFigureHn=findobj('Tag','FigurePlot');
        set(h.Tau3Init,'String',TauString);
        set(h.A3Init,'String',AString);
        set(h.ChiInit,'String',ChiString);
    elseif ImageFit
        YStripped_Image=Y_Image(indexFirst:indexLast,:);
        [Amp_v,Tau_v]=Stripping_Image(XStripped,YStripped_Image);
        for(i=1:length(X))
            Y_temp(i,:)=Amp_v.*Tau_v.*(1-exp(-gate./Tau_v)).*exp(-X(i)./Tau_v);
        end
        yFit=Y_temp;
        Y_Image_NoStrip3=Y_Image;
        Y_Image=Y_Image-yFit;
        Amp3_Image=reshape(Amp_v,aoi1,aoi2);
        Tau3_Image=reshape(Tau_v,aoi1,aoi2);
        Amp3_Image=real(Amp3_Image.*ThMask);
        Tau3_Image=real(Tau3_Image.*ThMask);
        figure
%         ImageFigureHn=findobj('Tag','FigureFitImage');
%         if isempty(ImageFigureHn),
%             ImageFigureHn=figure(fit_image_ns);
%         else
%             figure(ImageFigureHn);
%         end
%         axes(findobj(ImageFigureHn,'Tag','axes7'));
        imagesc(Tau3_Image), title('Tau3');
        colorbar;
%         axes(findobj(ImageFigureHn,'Tag','axes8'));
        figure
        imagesc(Amp3_Image), title('Amp3');
        colorbar;
    end
else
    if SingleFitStop==1
        Y_Image=Y_Image_NoStrip3;
        ImageFigureHn=findobj('Tag','FigureFitImage');
        if isempty(ImageFigureHn)
            ImageFigureHn=figure(fit_image_ns);
        else
            figure(ImageFigureHn);
        end
        axes(findobj(ImageFigureHn,'Tag','axes7'));
        imagesc(zeros(aoi1,aoi2));
        axes(findobj(ImageFigureHn,'Tag','axes8'));
        imagesc(zeros(aoi1,aoi2));
    elseif SingleFitStop==0
        Y_Single=Y_Single_NoStrip3;
        axes(handles.plotAxes),cla;
        plotData(X,Y_Single,0,1,0);
        axes(handles.residAxes),cla;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on button press in CompleteStrip.
function CompleteStrip_Callback(hObject, eventdata, handles)
% hObject    handle to CompleteStrip (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global X Y_Single Y_Single_NoStrip1;
global Y_Image Y_Image_NoStrip1;
global Amp Tau AmpRel;
global Amp1_Image Amp2_Image Amp3_Image;
global Tau1_Image Tau2_Image Tau3_Image;
global gate;
global SingleFit ImageFit;
global Amp1Rel_Image Amp2Rel_Image Amp3Rel_Image;
global ThMask;
global aoi1 aoi2;


stripPercOn=get(handles.stripPercOn,'Value');
if stripPercOn
    highPerc=str2num(get(handles.Strip1_H_perc,'String'));
    lowPerc=str2num(get(handles.Strip1_L_perc,'String'));
else
    high=str2num(get(handles.Strip1_H,'String'));
    indexLast=findIndex(high,X);
    if (get(handles.Strip3_On,'Value')==0)
        if (get(handles.Strip2_On,'Value')==0)
            low=str2num(get(handles.Strip1_L,'String'));
            numTau=1;
        else
            low=str2num(get(handles.Strip2_L,'String'));
            numTau=2;
        end
    else
        low=str2num(get(handles.Strip3_L,'String'));
        numTau=3;
    end
    indexFirst=findIndex(low,X);
end
if SingleFit
    Y_Single=Y_Single_NoStrip1;
    if stripPercOn
        indexZero=findIndex(0,X);
        zeroIntensity=Y_Single(indexZero);
        temp=find(Y_Single(indexZero:end)<=Y_Single(indexZero)*lowPerc/100);
        indexFirst=temp(1)+indexZero-1;
        temp=find(Y_Single(indexZero:end)<=Y_Single(indexZero)*highPerc/100);
        indexLast=temp(1)+indexZero-1;
        XStripped=X(indexFirst:indexLast);
        numTau=1;
    end
    yFit=zeros(1,indexLast-indexFirst+1);
    for(i=1:numTau)
        yFit=yFit+Amp(i)*Tau(i)*exp(-X(indexFirst:indexLast)/Tau(i))*(1-exp(-gate/Tau(i)));
    end
    ChiSquared=(norm((Y_Single(indexFirst:indexLast)-yFit)./Y_Single(indexFirst:indexLast)));
    Resid=(Y_Single(indexFirst:indexLast)-yFit)./Y_Single(indexFirst:indexLast);
    axes(handles.plotAxes),cla;
    plotFittedData(X,Y_Single,yFit,indexFirst,indexLast);
    axes(handles.residAxes),cla;
    plotResidual(X,Resid,indexFirst,indexLast,2);
    AmpRel=Amp./sum(Amp)*100;
    PlotFigureHn=findobj('Tag','FigurePlot');
    if isempty(PlotFigureHn)
        PlotFigureHn=figure(plot_figure_ns);
    else
        figure(PlotFigureHn);
    end
    h=guihandles(PlotFigureHn);
    ARelString=sprintf('%5.2f',AmpRel(1));
    set(h.A1RelInit,'String',ARelString);
    ARelString=sprintf('%5.2f',AmpRel(2));
    set(h.A2RelInit,'String',ARelString);
    ARelString=sprintf('%5.2f',AmpRel(3));
    set(h.A3RelInit,'String',ARelString);
    ChiString=sprintf('%5.3f',ChiSquared);
    set(h.ChiInit,'String',ChiString);

    TauMean=sum(Amp.*Tau)/sum(Amp)

elseif ImageFit
    Y_Image=Y_Image_NoStrip1;
    if numTau >=2
        global Amp2_Image;
        if numTau >=3
            global Amp3_Image;
        else
            Tau3_Image=zeros(size(Amp1_Image));
            Amp3_Image=zeros(size(Amp1_Image));
        end
    else
        Tau2_Image=zeros(size(Amp1_Image));
        Tau3_Image=zeros(size(Amp1_Image));
        Amp2_Image=zeros(size(Amp1_Image));
        Amp3_Image=zeros(size(Amp1_Image));
    end
    warning off MATLAB:divideByZero
    Amp1Rel_Image=Amp1_Image./(Amp1_Image+Amp2_Image+Amp3_Image)*100;
    Amp2Rel_Image=Amp2_Image./(Amp1_Image+Amp2_Image+Amp3_Image)*100;
    Amp3Rel_Image=Amp3_Image./(Amp1_Image+Amp2_Image+Amp3_Image)*100;
    warning on MATLAB:divideByZero
    
    %     ImageFigureHn=findobj('Tag','FigureFitImage');
    %     if isempty(ImageFigureHn),
    %         ImageFigureHn=figure(fit_image_ns);
    %     else
    %         figure(ImageFigureHn);
    %     end
    %     axes(findobj(ImageFigureHn,'Tag','axes3'));
    figure
    imagesc(Amp1Rel_Image.*ThMask), title('Amp1Rel');
    set(gca,'Clim',[0 100]);
    colorbar;
    if numTau >=2
        %         axes(findobj(ImageFigureHn,'Tag','axes6'));
        figure
        imagesc(Amp2Rel_Image.*ThMask), title('Amp2Rel');
        set(gca,'Clim',[0 100]);
        colorbar;
    end

    if numTau >=3
        %         axes(findobj(ImageFigureHn,'Tag','axes9'));
        figure
        imagesc(Amp3Rel_Image.*ThMask),title('Amp3Rel');
        set(gca,'Clim',[0 100]);
        colorbar;
    end
end
set(handles.Strip1_On,'Value',0);
set(handles.Strip2_On,'Value',0);
set(handles.Strip3_On,'Value',0);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [A,TAU]=Stripping(X,Y)
global gate

DelayNum=length(X);
den=DelayNum*sum(X.^2)-sum(X).^2;
TAU=(DelayNum*sum(X.*log(Y))-sum(X)*sum(log(Y)))/den;
TAU=-1./TAU;
% Calculate the Amplitude taking the average of the solutions of all the linear equations
A= zeros(size(TAU));
for f=1:DelayNum
    A = A+Y(f).*(exp(X(f)/TAU))/(TAU*(1-exp(-gate/TAU)));
end
A = A./DelayNum;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [A,TAU]=Stripping_Image(X,Y)
global gate

DelayNum=length(X);
den=DelayNum*sum(X.^2)-sum(X).^2;
TAU=(DelayNum*sum(diag(X)*log(Y))-sum(X)*sum(log(Y)))/den;
TAU=-1./TAU;
% Calculate the Amplitude taking the average of the solutions of all the linear equations
A= zeros(size(TAU));
for f=1:DelayNum
    A = A+Y(f,:).*(exp(X(f)./TAU))./(TAU.*(1-exp(-gate./TAU)));
end
A = A./DelayNum;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function plotFittedData(asse,data,dataFit,i1,i2,resto)

Massimo=max(max(data));
Minimo=min(min(data));
if nargin==6
    semilogy(asse,data,'bx',asse,dataFit,'r-',asse,resto,'kx'), hold on;
else
    semilogy(asse,data,'bx',asse(i1:i2),dataFit,'r-'), hold on;
end
axis([asse(1) asse(length(asse)) Minimo Massimo]);
Yline=Minimo:(Massimo-Minimo)/1000:Massimo;
asseStart=asse(i1)*ones(1,length(Yline));
asseEnd=asse(i2)*ones(1,length(Yline));
handleStart=line(asseStart,Yline);
set(handleStart,'LineWidth',[2]);
set(handleStart,'Color','g');
handleEnd=line(asseEnd,Yline);
set(handleEnd,'LineWidth',[2]);
set(handleEnd,'Color','g');
xlabel('Delay (ps)');
ylabel('Intensity (a.u.)');


YMax=str2num(get(findobj('Tag','plot_YMax'),'String'));
YMin=str2num(get(findobj('Tag','plot_YMin'),'String'));
XMax=str2num(get(findobj('Tag','plot_XMax'),'String'));
XMin=str2num(get(findobj('Tag','plot_XMin'),'String'));

if ((not(isempty(XMin))) & (not(isempty(XMax))))
    set(gca,'XLim',[XMin XMax]);
end
if ((not(isempty(YMax))) & (not(isempty(YMax))))
    set(gca,'YLim',[YMin YMax]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function plotResidual(asse,residual,i1,i2,flag)

hold on;
if flag==1
    plot(asse,0,'k',asse(i1:i2),residual(i1:i2),'-b');
    Massimo=max(max(residual(i1:i2)))+0.1;
    Minimo=min(min(residual(i1:i2)))-0.1;
else
    plot(asse,0,'k',asse(i1:i2),residual,'-b');
    Massimo=max(max(residual))+0.1;
    Minimo=min(min(residual))-0.1;
end

set(gca,'YLim',[Minimo Massimo]);

XMax=str2num(get(findobj('Tag','plot_XMax'),'String'));
XMin=str2num(get(findobj('Tag','plot_XMin'),'String'));

if ((not(isempty(XMin))) & (not(isempty(XMax))))
    set(gca,'XLim',[XMin XMax]);
end

Yline=Minimo:(Massimo-Minimo)/1000:Massimo;
asseStart=asse(i1)*ones(1,length(Yline));
asseEnd=asse(i2)*ones(1,length(Yline));
handleStart=line(asseStart,Yline);
set(handleStart,'LineWidth',[2]);
set(handleStart,'Color','g');
handleEnd=line(asseEnd,Yline);
set(handleEnd,'LineWidth',[2]);
set(handleEnd,'Color','g');
hold off;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes on button press in TauFix_On.
function TauFix_On_Callback(hObject, eventdata, handles)
% hObject    handle to TauFix_On (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global MAX_NUM_TAU;
global X Y_Single;
global SingleFit;
global Amp Tau;
global gate;

if exist('Amp')
    Amp=zeros(1,3);
    Tau=zeros(1,3);
end
tauInput(1)=str2num(get(handles.Tau1Fix,'String'));
temp=str2num(get(handles.Tau2Fix,'String'));
if isempty(temp)
    numTau=1;
else
    tauInput(2)=temp;
    clear temp;
    temp=str2num(get(handles.Tau3Fix,'String'));
    if isempty(temp)
        numTau=2;
    else
        numTau=3;
        tauInput(3)=temp;
    end
end
low=str2num(get(handles.fitSingle_r1,'String'));
high=str2num(get(handles.fitSingle_r2,'String'));
indexFirst=findIndex(low,X);
indexLast=findIndex(high,X);
XTauFix=X(indexFirst:indexLast);
if SingleFit
    YTauFix=interp1(XTauFix,Y_Single(indexFirst:indexLast),XTauFix(1):1:XTauFix(end));
    XTauFix=XTauFix(1):1:XTauFix(end);
    [Amp,Tau]=TauFix(XTauFix,YTauFix,tauInput,numTau);
    for (i=(numTau+1):MAX_NUM_TAU)
        Amp(i)=0;
        Tau(i)=0;
    end
    yFit=zeros(1,indexLast-indexFirst+1);
    for(i=1:numTau)
        yFit=yFit+Amp(i)*Tau(i)*exp(-X(indexFirst:indexLast)/Tau(i))*(1-exp(-gate/Tau(i)));
    end
    ChiSquared=(norm((Y_Single(indexFirst:indexLast)-yFit)./Y_Single(indexFirst:indexLast)));
    Resid=(Y_Single(indexFirst:indexLast)-yFit)./Y_Single(indexFirst:indexLast);
    axes(handles.plotAxes),cla;
    plotFittedData(X,Y_Single,yFit,indexFirst,indexLast);
    axes(handles.residAxes),cla;
    plotResidual(X,Resid,indexFirst,indexLast,2);
    PlotFigureHn=findobj('Tag','FigurePlot');
    if isempty(PlotFigureHn)
        PlotFigureHn=figure(plot_figure_ns);
    else
        figure(PlotFigureHn);
    end
    AmpRel=Amp./sum(Amp)*100;
    h=guihandles(PlotFigureHn);
    TauString=sprintf('%6.2f',Tau(1));
    AString=sprintf('%6.1f',Amp(1));
    ARelString=sprintf('%5.2f',AmpRel(1));
    set(h.Tau1Init,'String',TauString);
    set(h.A1Init,'String',AString);
    set(h.A1RelInit,'String',ARelString);
    TauString=sprintf('%6.2f',Tau(2));
    AString=sprintf('%6.1f',Amp(2));
    ARelString=sprintf('%5.2f',AmpRel(2));
    set(h.Tau2Init,'String',TauString);
    set(h.A2Init,'String',AString);
    set(h.A2RelInit,'String',ARelString);
    TauString=sprintf('%6.2f',Tau(3));
    AString=sprintf('%6.1f',Amp(3));
    ARelString=sprintf('%5.2f',AmpRel(3));
    set(h.Tau3Init,'String',TauString);
    set(h.A3Init,'String',AString);
    set(h.A3RelInit,'String',ARelString);
    ChiString=sprintf('%5.3f',ChiSquared);
    set(h.ChiInit,'String',ChiString);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [A,TAU]=TauFix(X,Y,tauIn,numTau)
global gate;

for(i=1:numTau)
    C(i,:)=(tauIn(i).*exp(-X/tauIn(i)).*(1-exp(-gate./tauIn(i)))).*ones(size(X));
end

TolX=10*max(size(C))*norm(C,1)*eps,
options1 = optimset('TolX',TolX);
AInput=max(Y)/gate/numTau*ones(1,numTau);
[A, resnorm, residual1,exitflag,output] = lsqnonneg(C',Y',AInput,options1);
TAU=tauIn;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in NonLin.
function NonLin_Callback(hObject, eventdata, handles)
% hObject    handle to NonLin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global MAX_NUM_TAU;
global fitChoice;
global X Y_Single Y_Image;
global SingleFit ImageFit;
global Amp Tau;
global AmpFitted TauFitted;
global gate;
global Amp1_Image Amp2_Image Amp3_Image Tau1_Image Tau2_Image Tau3_Image;
global Amp1_Fitted_Image Amp2_Fitted_Image Tau1_Fitted_Image Tau2_Fitted_Image;
global Amp1Rel_Fitted_Image Amp2Rel_Fitted_Image Amp3Rel_Fitted_Image;
global ThMask;
global aoi1 aoi2;
global success_Image;
global gain_n TimeExp;

h=findobj(gcbf,'Tag','PanelMain');
set(h,'Pointer','Watch');
low=str2num(get(handles.fitSingle_r1,'String'));
high=str2num(get(handles.fitSingle_r2,'String'));
indexFirst=findIndex(low,X);
indexLast=findIndex(high,X);
XNonLin=X(indexFirst:indexLast);

if SingleFit
    if exist('AmpFitted')
        AmpFitted=zeros(1,3);
        TauFitted=zeros(1,3);
    end
    indexZero=findIndex(0,X);
    zeroIntensity=Y_Single(indexZero);
    %interp at 1 ns step
    YNonLin=interp1(XNonLin,Y_Single(indexFirst:indexLast),XNonLin(1):1:XNonLin(end));
    TimeExpNonLin=interp1(XNonLin,TimeExp(indexFirst:indexLast),XNonLin(1):1:XNonLin(end));
    gain_nNonLin=interp1(XNonLin,gain_n(indexFirst:indexLast),XNonLin(1):1:XNonLin(end));
    XNonLin=XNonLin(1):1:XNonLin(end);

    %     Response=gausswin(200,50);

    %     scalingFactor=gain_nNonLin./TimeExpNonLin;
    scalingFactor=1./gain_nNonLin;

    fitChoice=get(handles.fitChoice,'Value');
    FitDisplayOn=get(handles.FitDisplayOn,'Value');
    switch fitChoice
        case 1
            [AmpFitted, TauFitted, success]=biExp(XNonLin,YNonLin,Amp,Tau,scalingFactor,FitDisplayOn);
            numTau=2;
        case 2
            [AmpFitted, TauFitted, success]=triExp(XNonLin,YNonLin,Amp,Tau,scalingFactor,FitDisplayOn);
            numTau=3;
        case 3
            YNonLin=YNonLin;
            [BetaFitted, TauKWW, success]=stretchExp(XNonLin,YNonLin,scalingFactor,Tau(1),FitDisplayOn);
            numTau=1;
    end
    for (i=(numTau+1):MAX_NUM_TAU)
        AmpFitted(i)=0;
        TauFitted(i)=0;
    end

    yFit=zeros(1,indexLast-indexFirst+1);
    if (fitChoice==3)
        TauKWW=real(TauKWW);
        BetaFitted=(BetaFitted);
        %      yFit=zeroIntensity*(exp(-(X(indexFirst:indexLast)./TauKWW).^BetaFitted));
        yFit=Y_Single(indexFirst)*(exp(-(X(indexFirst:indexLast)./TauKWW).^BetaFitted));
        TauFitted(1)=(TauKWW*gamma(1/BetaFitted))/BetaFitted;
        AmpFitted(1)=1;
    else
        for(i=1:numTau)
            yFit=yFit+AmpFitted(i)*TauFitted(i)*exp(-X(indexFirst:indexLast)/TauFitted(i))*(1-exp(-gate/TauFitted(i)));
        end
    end
    ChiSquared=(norm((Y_Single(indexFirst:indexLast)-yFit)./Y_Single(indexFirst:indexLast)));
    Resid=(Y_Single(indexFirst:indexLast)-yFit)./Y_Single(indexFirst:indexLast);
    axes(handles.plotAxes),cla;
    plotFittedData(X,Y_Single,yFit,indexFirst,indexLast);
    axes(handles.residAxes),cla;
    plotResidual(X,Resid,indexFirst,indexLast,2);
    AmpRelFitted=AmpFitted./sum(AmpFitted)*100;
    h=findobj(gcbf,'Tag','PanelMain');
    set(h,'Pointer','Arrow');
    PlotFigureHn=findobj('Tag','FigurePlot');
    if isempty(PlotFigureHn)
        PlotFigureHn=figure(plot_figure_ns);
    else
        figure(PlotFigureHn);
    end
    h=guihandles(PlotFigureHn);
    TauString=sprintf('%6.2f',TauFitted(1));
    AString=sprintf('%6.1f',AmpFitted(1));
    ARelString=sprintf('%5.2f',AmpRelFitted(1));
    set(h.Tau1,'String',TauString);
    set(h.A1,'String',AString);
    set(h.A1Rel,'String',ARelString);
    if fitChoice==3
        TauString=sprintf('%5.3f',BetaFitted);
    else
        TauString=sprintf('%6.2f',TauFitted(2));
    end
    AString=sprintf('%6.1f',AmpFitted(2));
    ARelString=sprintf('%5.2f',AmpRelFitted(2));
    set(h.Tau2,'String',TauString);
    set(h.A2,'String',AString);
    set(h.A2Rel,'String',ARelString);
    TauString=sprintf('%6.2f',TauFitted(3));
    AString=sprintf('%6.1f',AmpFitted(3));
    ARelString=sprintf('%5.2f',AmpRelFitted(3));
    set(h.Tau3,'String',TauString);
    set(h.A3,'String',AString);
    set(h.A3Rel,'String',ARelString);
    ChiString=sprintf('%5.3f',ChiSquared);
    set(h.Chi,'String',ChiString);
    if success==1
        FitString='Good';
    else
        FitString='Bad';
        beep;
    end
    set(h.FitSuccess,'String',FitString);

elseif ImageFit
    YNonLin_Image=Y_Image(indexFirst:indexLast,:);
    sizeUtil=size(Y_Image,2);
    XNonLin_interp=XNonLin(1):1:XNonLin(end);
    scalingFactor=1./interp1(XNonLin,gain_n(indexFirst:indexLast),XNonLin_interp);
    switch fitChoice
        case 1
            numTau=2;
            clear global Amp1_Fitted_Image Amp2_Fitted_Image Amp3_Fitted_Image Tau1_Fitted_Image Tau2_Fitted_Image Tau3_Fitted_Image ErrMask success_Image;
            global Amp1_Fitted_Image Amp2_Fitted_Image Amp3_Fitted_Image Tau1_Fitted_Image Tau2_Fitted_Image Tau3_Fitted_Image ErrMask success_Image;
            warning off MATLAB:divideByZero;

            for q=1:sizeUtil
                if ThMask(q)
                    YNonLin_interp=interp1(XNonLin,YNonLin_Image(:,q),XNonLin_interp);
                    [Amp1_Fitted_Image(q),Amp2_Fitted_Image(q),Tau1_Fitted_Image(q),Tau2_Fitted_Image(q),success_Image(q)]=biExpImage(XNonLin_interp,YNonLin_interp,Amp1_Image(q),Tau1_Image(q),Amp2_Image(q),Tau2_Image(q),scalingFactor);
                else
                    Amp1_Fitted_Image(q)=0.0;
                    Tau1_Fitted_Image(q)=0.0;
                    Amp2_Fitted_Image(q)=0.0;
                    Tau2_Fitted_Image(q)=0.0;
                    success_Image(q)=0;
                end
                if (mod(q,round(sizeUtil/10))==0)
                    fprintf(' Calculating non lin biexp... %d %%\n',q*100/(sizeUtil));
                end
            end

            Amp1_Fitted_Image=reshape(Amp1_Fitted_Image,aoi1,aoi2);
            Tau1_Fitted_Image=reshape(Tau1_Fitted_Image,aoi1,aoi2);
            Amp2_Fitted_Image=reshape(Amp2_Fitted_Image,aoi1,aoi2);
            Tau2_Fitted_Image=reshape(Tau2_Fitted_Image,aoi1,aoi2);
            Amp3_Fitted_Image=zeros(size(Tau1_Fitted_Image));
            Tau3_Fitted_Image=zeros(size(Tau1_Fitted_Image));
            Amp1Rel_Fitted_Image=Amp1_Fitted_Image./(Amp1_Fitted_Image+Amp2_Fitted_Image+Amp3_Fitted_Image)*100;
            Amp2Rel_Fitted_Image=Amp2_Fitted_Image./(Amp1_Fitted_Image+Amp2_Fitted_Image+Amp3_Fitted_Image)*100;
            Amp3Rel_Fitted_Image=Amp3_Fitted_Image./(Amp1_Fitted_Image+Amp2_Fitted_Image+Amp3_Fitted_Image)*100;
            warning on MATLAB:divideByZero;
            success_Image=reshape(success_Image,aoi1,aoi2);
            
        case 2
            numTau=3;
            clear global Amp1_Fitted_Image Amp2_Fitted_Image Amp3_Fitted_Image Tau1_Fitted_Image Tau2_Fitted_Image Tau3_Fitted_Image ErrMask success_Image;
            global Amp1_Fitted_Image Amp2_Fitted_Image Amp3_Fitted_Image Tau1_Fitted_Image Tau2_Fitted_Image Tau3_Fitted_Image ErrMask success_Image;
            warning off MATLAB:divideByZero;

            for q=1:sizeUtil
                if ThMask(q)
                    YNonLin_interp=interp1(XNonLin,YNonLin_Image(:,q),XNonLin_interp);
                    [Amp1_Fitted_Image(q),Amp2_Fitted_Image(q),Amp3_Fitted_Image(q),Tau1_Fitted_Image(q),Tau2_Fitted_Image(q),Tau3_Fitted_Image(q),success_Image(q)]=triExpImage(XNonLin_interp,YNonLin_interp,Amp1_Image(q),Tau1_Image(q),Amp2_Image(q),Tau2_Image(q),Amp3_Image(q),Tau3_Image(q),scalingFactor);
                else
                    Amp1_Fitted_Image(q)=0.0;
                    Tau1_Fitted_Image(q)=0.0;
                    Amp2_Fitted_Image(q)=0.0;
                    Tau2_Fitted_Image(q)=0.0;
                    Amp3_Fitted_Image(q)=0.0;
                    Tau3_Fitted_Image(q)=0.0;
                    success_Image(q)=0;
                end
                if (mod(q,round(sizeUtil/10))==0)
                    fprintf(' Calculating non lin triexp... %d %%\n',q*100/(sizeUtil));
                end
            end
            Amp1_Fitted_Image=reshape(Amp1_Fitted_Image,aoi1,aoi2);
            Tau1_Fitted_Image=reshape(Tau1_Fitted_Image,aoi1,aoi2);
            Amp2_Fitted_Image=reshape(Amp2_Fitted_Image,aoi1,aoi2);
            Tau2_Fitted_Image=reshape(Tau2_Fitted_Image,aoi1,aoi2);
            Amp3_Fitted_Image=reshape(Amp3_Fitted_Image,aoi1,aoi2);
            Tau3_Fitted_Image=reshape(Tau3_Fitted_Image,aoi1,aoi2);
            Amp1Rel_Fitted_Image=Amp1_Fitted_Image./(Amp1_Fitted_Image+Amp2_Fitted_Image+Amp3_Fitted_Image)*100;
            Amp2Rel_Fitted_Image=Amp2_Fitted_Image./(Amp1_Fitted_Image+Amp2_Fitted_Image+Amp3_Fitted_Image)*100;
            Amp3Rel_Fitted_Image=Amp3_Fitted_Image./(Amp1_Fitted_Image+Amp2_Fitted_Image+Amp3_Fitted_Image)*100;
            warning on MATLAB:divideByZero;
            success_Image=reshape(success_Image,aoi1,aoi2);
    end
    h=findobj(gcbf,'Tag','PanelMain');
    set(h,'Pointer','Arrow');
    %     NonLinImageFigureHn=findobj('Tag','FigureFitNonLinImage');
    %     if isempty(NonLinImageFigureHn),
    %         NonLinImageFigureHn=figure(fitNonLin_image_ns);
    %     else
    %         figure(NonLinImageFigureHn);
    %     end
    %     axes(findobj(NonLinImageFigureHn,'Tag','axes1'));
    figure, imagesc(Tau1_Fitted_Image), title('Tau1 nonlin');
    colorbar;
%     figure;
% %     axes(findobj(NonLinImageFigureHn,'Tag','axes2'));
%     imagesc(Amp1_Fitted_Image), title('Amp1 nonlin');
%     colorbar;
    if numTau>1
        %         axes(findobj(NonLinImageFigureHn,'Tag','axes4'));
        figure, imagesc(Tau2_Fitted_Image), title('Tau2 nonlin');
        colorbar;
%         axes(findobj(NonLinImageFigureHn,'Tag','axes5'));
%         figure;
%         imagesc(Amp2_Fitted_Image), title('Amp2 nonlin');
%         colorbar;
        %         axes(findobj(NonLinImageFigureHn,'Tag','axes3'));
        figure, imagesc(Amp1Rel_Fitted_Image), title('Amp1Rel nonlin');
        set(gca,'Clim',[0 100]);
        colorbar;
        %         axes(findobj(NonLinImageFigureHn,'Tag','axes6'));
        figure, imagesc(Amp2Rel_Fitted_Image), title('Amp2Rel nonlin');
        set(gca,'Clim',[0 100]);
        colorbar;
%         axes(findobj(NonLinImageFigureHn,'Tag','axes7'));
%         imagesc(ThMask);
%         colorbar;
%         axes(findobj(NonLinImageFigureHn,'Tag','axes8'));
%         imagesc(success_Image);
%         colorbar;
        if numTau>2
%             axes(findobj(NonLinImageFigureHn,'Tag','axes7'));
            figure, imagesc(Tau3_Fitted_Image), title('Tau3 nonlin');
            colorbar;
%             axes(findobj(NonLinImageFigureHn,'Tag','axes8'));
%             imagesc(Amp3_Fitted_Image);
%             colorbar;
%             axes(findobj(NonLinImageFigureHn,'Tag','axes9'));
            figure, imagesc(Amp3Rel_Fitted_Image), title('Amp3Rel nonlin');
            set(gca,'Clim',[0 100]);
            colorbar;
%             figure;
%             imagesc(ThMask);
%             colorbar;
%             figure;
%             imagesc(success_Image);
%             colorbar;
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [A, TAU, exitflag]=biExp(X,Y,AmpIn,TauIn,scalingFactor,FitDisplayOn)
global gate;

if AmpIn(2)==0
    AmpIn(2)=AmpIn(1);
end
lb=[0 0 0 0];
ub=[2*AmpIn(1) 2*TauIn(1) 2*AmpIn(2) 2*TauIn(2)];


options = optimset('lsqnonlin');
options = optimset(options,'MaxIter',25);
options = optimset(options,'Display','iter');


if FitDisplayOn
    figure, semilogy(X,Y,'-o'),hold on;
end

[parm,resnorm,residual,exitflag,output]=lsqnonlin(@(parm) exp21_fun(parm,X,Y,gate,scalingFactor,FitDisplayOn),[AmpIn(1) TauIn(1) AmpIn(2) TauIn(2)],lb,ub,options);

if FitDisplayOn
    Function = (parm(1)*parm(2)*exp(-X/parm(2))*(1-exp(-gate/parm(2)))+parm(3)*parm(4)*exp(-X/parm(4))*(1-exp(-gate/parm(4))));
    semilogy(X,Function,'r');
    F = (Y-Function)./sqrt(Y);
    error=sum(F.^2);

    Message=sprintf('error=%f beta=%f tauKWW=%f%',error,parm(1),parm(2));
    text(50,0.2,Message);

    hold off;
end

if exitflag==1
    Buffer = sprintf('Fit successful NumIterations= %d FitMethod=%s',output.iterations,output.algorithm)
    output_text(Buffer);
else
    Buffer = sprintf('Fit not successful|NumIterations= %d| FitMethod=%s',output.iterations,output.algorithm)
    output_text(Buffer);
end
A(1)=parm(1);
A(2)=parm(3);
TAU(1)=parm(2);
TAU(2)=parm(4);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function F = exp21_fun(parm,time,dataY,gwidth,factor,displayOn)

Function = (parm(1)*parm(2)*exp(-time/parm(2))*(1-exp(-gwidth/parm(2)))+parm(3)*parm(4)*exp(-time/parm(4))*(1-exp(-gwidth/parm(4))));

F = (dataY-Function)./(Function.*(0.3*factor+0.05));
% F = (dataY-Function)./(sqrt((1+dataY).*dataY.*factor));
% F = (dataY-Function)./(sqrt(dataY));

if displayOn
    N=length(F);
    error=sum(F.^2);
    h1=semilogy(time,Function,'r');
    set(gca,'YLim',[min(dataY) max(dataY)]);
    Message=sprintf('errore=%f beta=%f tauKWW=%f%',error,parm(1),parm(2));
    h2=text(50,0.2,Message);
    pause(0.3);
    delete(h1);
    delete(h2);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [A, TAU, exitflag]=triExp(X,Y,AmpIn,TauIn,scalingFactor,FitDisplayOn)
global gate;

lb=[0 0 0 0 0 0];
ub=[2*AmpIn(1) 2*TauIn(1) 2*AmpIn(2) 2*TauIn(2) 2*AmpIn(3) 2*TauIn(3)];

options = optimset('lsqnonlin');
options = optimset(options,'MaxIter',25);
options = optimset(options,'Display','iter');

if FitDisplayOn
    figure, semilogy(X,Y,'-o'),hold on;
end

[parm,resnorm,residual,exitflag,output]=lsqnonlin(@(parm) exp31_fun(parm,X,Y,gate,scalingFactor,FitDisplayOn),[AmpIn(1) TauIn(1) AmpIn(2) TauIn(2) AmpIn(3) TauIn(3)],lb,ub,options);
if FitDisplayOn
    Function = (parm(1)*parm(2)*exp(-X/parm(2))*(1-exp(-gate/parm(2)))+parm(3)*parm(4)*exp(-X/parm(4))*(1-exp(-gate/parm(4)))+parm(5)*parm(6)*exp(-X/parm(6))*(1-exp(-gate/parm(6))));
    semilogy(X,Function,'r');
    F = (Y-Function)./sqrt(Y);
    error=sum(F.^2);

    Message=sprintf('error=%f beta=%f tauKWW=%f%',error,parm(1),parm(2));
    text(50,0.2,Message);

    hold off;
end

if exitflag==1
    Buffer = sprintf('Fit successful NumIterations= %d FitMethod=%s',output.iterations,output.algorithm)
    output_text(Buffer);
else
    Buffer = sprintf('Fit not successful|NumIterations= %d| FitMethod=%s',output.iterations,output.algorithm)
    output_text(Buffer);
end

A(1)=parm(1);
A(2)=parm(3);
A(3)=parm(5);

TAU(1)=parm(2);
TAU(2)=parm(4);
TAU(3)=parm(6);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function F = exp31_fun(parm,time,dataY,gwidth,factor,displayOn)

Function = (parm(1)*parm(2)*exp(-time/parm(2))*(1-exp(-gwidth/parm(2)))+...
    parm(3)*parm(4)*exp(-time/parm(4))*(1-exp(-gwidth/parm(4)))+parm(5)*parm(6)*exp(-time/parm(6))*(1-exp(-gwidth/parm(6))));

F = (dataY-Function)./(Function.*(0.3*factor+0.05));
% F = (dataY-Function)./sqrt((1+dataY./factor).*dataY);
% F = (dataY-Function)./(sqrt((1+dataY).*dataY.*factor));
% F = (dataY-Function)./(sqrt(dataY));

if displayOn
    N=length(F);
    error=sum(F.^2);
    h1=semilogy(time,Function,'r');
    set(gca,'YLim',[min(dataY) max(dataY)]);
    Message=sprintf('errore=%f beta=%f tauKWW=%f%',error,parm(1),parm(2));
    h2=text(50,0.2,Message);
    pause(0.3);
    delete(h1);
    delete(h2);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [beta, TAU, exitflag]=stretchExp(X,Y,scalingFactor,TauIn,FitDisplayOn)

betaIn=1;
Tau_KWW_In=TauIn*betaIn/(gamma(1/betaIn));
lb=[0 0];
ub=[1 5*Tau_KWW_In];

options = optimset('lsqnonlin');
options = optimset(options,'MaxIter',25);
options = optimset(options,'Display','iter');

if FitDisplayOn
    figure, semilogy(X,Y,'-o'),hold on;
end

[parm,resnorm,residual,exitflag,output]=lsqnonlin(@(parm) stretchExp_fun(parm,X,Y,scalingFactor,FitDisplayOn),[betaIn Tau_KWW_In],lb,ub,options);

if FitDisplayOn
    Function=Y(1)*(exp(-(X/parm(2)).^(parm(1))));
    semilogy(X,Function,'r');
    F = (Y-Function)./sqrt(Y);
    error=sum(F.^2);

    Message=sprintf('error=%f beta=%f tauKWW=%f%',error,parm(1),parm(2));
    text(50,0.2,Message);

    hold off;
end

if exitflag==1
    Buffer = sprintf('Fit successful NumIterations= %d FitMethod=%s',output.iterations,output.algorithm)
    output_text(Buffer);
else
    Buffer = sprintf('Fit not successful|NumIterations= %d| FitMethod=%s',output.iterations,output.algorithm)
    output_text(Buffer);
end
beta=parm(1);
TAU=parm(2);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function F = stretchExp_fun(parm,time,dataY,factor,displayOn)


Function=dataY(1)*(exp(-(time/parm(2)).^(parm(1))));

% ConvolutedFunction=conv(Function,Response);
% [massimo i]=max(ConvolutedFunction);
% ConvolutedFunction=ConvolutedFunction(i:i+length(Function)-1)./massimo*dataY(1);
% Function=ConvolutedFunction';

% Function=dataY(1)*(exp(-(time/parm(2)).^(parm(1))));
F = (dataY-Function)./(Function.*(0.3*factor+0.05));
% F = (dataY-Function)./sqrt((1+dataY./factor).*dataY);
% F = (dataY-Function)./(sqrt((1+dataY).*dataY.*factor));
% F = (dataY-Function)./(sqrt(dataY));

if displayOn
    N=length(F);
    error=sum(F.^2);
    h1=semilogy(time,Function,'r');
    set(gca,'YLim',[min(dataY) max(dataY)]);
    Message=sprintf('errore=%f beta=%f tauKWW=%f%',error,parm(1),parm(2));
    h2=text(50,0.2,Message);
    pause(0.3);
    delete(h1);
    delete(h2);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [beta, TAU]=stretchExpImage(X,Y,TauIn,scalingFactor)

betaIn=1;
Tau_KWW_In=TauIn*betaIn/(gamma(1/betaIn));

lb=[0 0];
ub=[1 5*Tau_KWW_In];

options = optimset('lsqnonlin');
options = optimset(options,'MaxIter',25);
options = optimset(options,'Display','off');

FitDisplayOn=0;
[parm,resnorm,residual,exitflag,output]=lsqnonlin(@(parm) stretchExp_fun(parm,X,Y,scalingFactor,FitDisplayOn),[betaIn Tau_KWW_In],lb,ub,options);
beta=parm(1);
Tau_KWW=parm(2);
TAU=(Tau_KWW.*gamma(1./beta))./beta;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% numPixel=size(Y,1);
% beta=zeros(1,numPixel);
% Tau_KWW=zeros(1,numPixel);
%
%
% FitDisplayOn=0;
%
% Xi=X(1):1:X(end);
% Yi=interp1(X,Y',Xi);
% Yi=Yi';
%
% dim3=length(Xi);
%
% for(i=1:numPixel)
%     if(isnan(Yi(i,:)))
%         Mask(i)=0;
%     end
%     if(isinf(Yi(i,:)))
%         Mask(i)=0;
%     end
% end
%
% for(i=1:numPixel)
%     if (Mask(i)==0)
%         parm=[0 0];
%     else
%         [parm]=lsqnonlin(@(parm) stretchExp_fun(parm,Xi,Yi(i,:),scalingFactor,FitDisplayOn),[betaIn Tau_KWW_In],lb,ub,options);
%     end;
%     beta(i)=parm(1);
%     Tau_KWW(i)=parm(2);
%     if (mod(i,round(numPixel/10))==0),
%         fprintf(' Calculating stretched exp... %d %%\n',i*100/(numPixel));
%     end
% end
% TAU=(Tau_KWW.*gamma(1./beta))./beta;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [A1, A2, TAU1, TAU2, exitflag]=biExpImage(X,Y,Amp1_In,Tau1_In,Amp2_In,Tau2_In,scalingFactor)
global gate;

lb=[0 0 0 0];
ub=2*[Amp1_In Tau1_In Amp2_In Tau2_In];

options = optimset('lsqnonlin');
options = optimset(options,'MaxIter',25);
options = optimset(options,'Display','off');

FitDisplayOn=0;
[parm,resnorm,residual,exitflag,output]=lsqnonlin(@(parm) exp21_fun(parm,X,Y,gate,scalingFactor,FitDisplayOn),[Amp1_In Tau1_In Amp2_In Tau2_In],lb,ub,options);
A1=parm(1);
A2=parm(3);
TAU1=parm(2);
TAU2=parm(4);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [A1, A2, A3, TAU1, TAU2, TAU3, exitflag]=triExpImage(X,Y,Amp1_In,Tau1_In,Amp2_In,Tau2_In,Amp3_In,Tau3_In,scalingFactor);
global gate;

lb=[0 0 0 0 0 0];
ub=2*[Amp1_In Tau1_In Amp2_In Tau2_In Amp3_In Tau3_In];

options = optimset('lsqnonlin');
options = optimset(options,'MaxIter',25);
options = optimset(options,'Display','off');

FitDisplayOn=0;
[parm,resnorm,residual,exitflag,output]=lsqnonlin(@(parm) exp21_fun(parm,X,Y,gate,scalingFactor,FitDisplayOn),[Amp1_In Tau1_In Amp2_In Tau2_In Amp3_In Tau3_In],lb,ub,options);
A1=parm(1);
A2=parm(3);
A3=parm(5);

TAU1=parm(2);
TAU2=parm(4);
TAU3=parm(6);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function PanelMain_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to PanelMain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in BkgOn.
function BkgOn_Callback(hObject, eventdata, handles)
% hObject    handle to BkgOn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of BkgOn
global X Y;
global Y_original;

global BkgOPT;
BkgOPT=1;
bOn=get(handles.BkgOn,'Value');
if bOn
    Y_original=Y;
    switch (BkgOPT)
        case 1 % from delayed data
            d1=str2num(get(handles.BkgFirst,'String'));
            d2=str2num(get(handles.BkgLast,'String'));
            
            i1=findIndex(d1,X);
            i2=findIndex(d2,X);
            
            B=sum(Y(:,:,i1:i2),3)/(i2-i1+1);
            for(i=1:length(X))
                Y(:,:,i)=max(1,Y(:,:,i)-B);
            end
            
        case 2 % from file
            
    end    
else
    Y=Y_original;
end
% --- Executes on button press in SetYAxis.
function SetYAxis_Callback(hObject, eventdata, handles)
% hObject    handle to SetYAxis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


y1=str2num(get(handles.plot_YMin,'String'));
y2=str2num(get(handles.plot_YMax,'String'));
axes(handles.plotAxes);
set(gca,'YLim',[y1 y2]);

% --- Executes on button press in SetXAxis.
function SetXAxis_Callback(hObject, eventdata, handles)
% hObject    handle to SetXAxis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

x1=str2num(get(handles.plot_XMin,'String'));
x2=str2num(get(handles.plot_XMax,'String'));
axes(handles.plotAxes);
set(gca,'XLim',[x1 x2]);
axes(handles.residAxes);
set(gca,'XLim',[x1 x2]);



% --- Executes on button press in SetYAxisResid.
function SetYAxisResid_Callback(hObject, eventdata, handles)
% hObject    handle to SetYAxisResid (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

y1=str2num(get(handles.edit52,'String'));
y2=str2num(get(handles.edit53,'String'));
axes(handles.residAxes);
set(gca,'YLim',[y1 y2]);


% --- Executes on selection change in SingleExpFitType.
function SingleExpFitType_Callback(hObject, eventdata, handles)
% hObject    handle to SingleExpFitType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns SingleExpFitType contents as cell array
%        contents{get(hObject,'Value')} returns selected item from SingleExpFitType


% --- Executes during object creation, after setting all properties.
function SingleExpFitType_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SingleExpFitType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in saveMovie.
function saveMovie_Callback(hObject, eventdata, handles)
% hObject    handle to saveMovie (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of saveMovie


% --- Executes on button press in Fix_max_color_range.
function Fix_max_color_range_Callback(hObject, eventdata, handles)
% hObject    handle to Fix_max_color_range (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of Fix_max_color_range


% --- Executes on button press in FitDisplayOn.
function FitDisplayOn_Callback(hObject, eventdata, handles)
% hObject    handle to FitDisplayOn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of FitDisplayOn



function FilterSize_Callback(hObject, eventdata, handles)
% hObject    handle to FilterSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of FilterSize as text
%        str2double(get(hObject,'String')) returns contents of FilterSize as a double


% --- Executes during object creation, after setting all properties.
function FilterSize_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FilterSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in ThresholdON.
function ThresholdON_Callback(hObject, eventdata, handles)
% hObject    handle to ThresholdON (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ThresholdON
global ThresholdON;
ThresholdON=get(hObject,'Value');

function ExportSpectroscopyDataset_Callback(hObject, eventdata, handles)
global X Y index_Zero XZero;
global ThresholdON;


optAoi=get(handles.FitAoiSelection,'Value');
if optAoi==1
    [firstCol,lastCol,firstRow,lastRow]=getSingleData;
elseif optAoi==2
    firstCol=str2num(get(handles.fitAoiFirstCol,'String'));
    lastCol=str2num(get(handles.fitAoiLastCol,'String'));
    firstRow=str2num(get(handles.fitAoiFirstRow,'String'));
    lastRow=str2num(get(handles.fitAoiLastRow,'String'));
elseif optAoi==3
    firstCol=1;
    lastCol=size(Y,2);
    firstRow=1;
    lastRow=size(Y,1);
end
Y_Image=Y(firstRow:lastRow,firstCol:lastCol,:);

FilterSize=str2double(get(handles.FilterSize,'String'));
if FilterSize>0
    for i=1:size(Y_Image,3)        
        Y_Image(:,:,i)=imfilter(Y_Image(:,:,i),fspecial('gaussian',[FilterSize FilterSize],0.5));        
    end
end

IMG=Y_Image(:,:,index_Zero);
if ThresholdON
    threshold=str2num(get(handles.ThresholdValue,'String'));
    ThMask=(IMG>=threshold);
else
    ThMask=ones(size(IMG));
end
ThMaskNaN=ones(size(ThMask));
ThMaskNaN(ThMask==0)=NaN;

for i=1:size(Y_Image,3)        
        Y_Image(:,:,i)=squeeze(Y_Image(:,:,i)).*ThMaskNaN;
end

axes(handles.mainAxes);
imagesc(Y_Image(:,:,index_Zero)), axis image;
colorbar;
SpectralDataset=(squeeze(nanmean(Y_Image)))';

% [massimo index]=max(max(SpectralDataset'))
% X_i=X(1:4),X(5):1:X(end);
% SpectralDataset_i=zeros(length(X_i),size(SpectralDataset,2));
% for i=1:size(SpectralDataset,2)
%     SpectralDataset_i(:,i)=interp1(X,SpectralDataset(:,i),X_i);
% end
figure, imagesc((1:size(SpectralDataset,2)),X+XZero,SpectralDataset), colormap('jet'), colorbar;
xlabel('pixel');
ylabel('delay (timescale unit)');
title('Sum of data along CCD rows');

[filename, pathname, filterIndex]=uiputfile('*.mat','Save spectral dataset');

time=X+XZero;
save([pathname,filename],'time','SpectralDataset');



% --- Executes on button press in BkgFromFileON.
function BkgFromFileON_Callback(hObject, eventdata, handles)
% hObject    handle to BkgFromFileON (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of BkgFromFileON
global BkgFromFileON;
BkgFromFileON=get(hObject,'Value');


% --- Executes on button press in RotImageOn.
function RotImageOn_Callback(hObject, eventdata, handles)
% hObject    handle to RotImageOn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of RotImageOn


% --- Executes on selection change in RotationAngle.
function RotationAngle_Callback(hObject, eventdata, handles)
% hObject    handle to RotationAngle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns RotationAngle contents as cell array
%        contents{get(hObject,'Value')} returns selected item from RotationAngle


% --- Executes during object creation, after setting all properties.
function RotationAngle_CreateFcn(hObject, eventdata, handles)
% hObject    handle to RotationAngle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

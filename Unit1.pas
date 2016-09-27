unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, {xpman,} ExtCtrls, StdCtrls, Series, TeEngine, TeeProcs, Chart,
  ComCtrls,DateUtils, Math, FileCtrl, IniFiles,
  WriteSkoUnit,syncobjs,ConstUnit,WriteGistUnit,WriteLogUnit, Gauges, ExcelWorkUnit;
type
  TForm1 = class(TForm)
    Panel1: TPanel;
    changeFile: TButton;
    StartButton: TButton;
    Chart1: TChart;
    Series1: TBarSeries;
    Chart2: TChart;
    Series2: TLineSeries;
    Label2: TLabel;
    timeLabel: TLabel;
    OpenDialog1: TOpenDialog;
    Timer1: TTimer;
    StopButton: TButton;
    Splitter1: TSplitter;
    Panel2: TPanel;
    TrackBar1: TTrackBar;
    Label3: TLabel;
    Label4: TLabel;
    LabelLat: TLabel;
    LabelLon: TLabel;
    Panel3: TPanel;
    Label7: TLabel;
    Label9: TLabel;
    TrackBar2: TTrackBar;
    Label5: TLabel;
    FileNumTrack: TTrackBar;
    Label6: TLabel;
    Label1: TLabel;
    Button4: TButton;
    Label8: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    Label19: TLabel;
    Label20: TLabel;
    tmr1: TTimer;
    tmr2: TTimer;
    gProgress1: TGauge;
    tmrEnd3: TTimer;
    mmo1: TMemo;
    procedure changeFileClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure StartButtonClick(Sender: TObject);
    procedure StopButtonClick(Sender: TObject);
    procedure Series1Click(Sender: TChartSeries; ValueIndex: Integer;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure FormCreate(Sender: TObject);
    procedure TrackBar1Change(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure TrackBar2Change(Sender: TObject);
    procedure FileNumTrackChange(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure tmr1Timer(Sender: TObject);
    procedure tmr2Timer(Sender: TObject);
    procedure tmrEnd3Timer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }

  end;
  // ��� ��� �������� �������� ���������� � �����-������ �������
  TfileMiniInfo=record
    path:string;
    size:integer;
  end;

  //��� ��� �������� ���������� ��� ���������� ������ � ����
  TrecInfo=record
    fileNumber:integer;
    fileOffset:int64;
  end;

  //��� ���������� ���������
  TFreqRange=record
    beginRange:real;
    endRange:real;
  end;

  //��� ��� �������� ������� ������� � �������� ���������
  TMyArrayOfString=array of TfileMiniInfo;

var
  Form1: TForm1;
  fileSCRUTJT:file;
  stream: TFileStream;
  iGist:integer;
  chanelIndex:integer;
  graphFlag:boolean;
  pocketSCRUTJT: array[1..POCKETSIZE] of byte;//������ - ����� ����
  timeGeosArr :array [1..4] of byte;//---time
  //skT,cT:integer;
  //---latitude
  latArr :array [1..4] of byte;
  cS,skS :integer;
  //---longtitude
  lonArr:array [1..4] of byte;
  cD,skD :integer;
  //������
  heightArr:array [1..2] of byte;
  //��������
  speedArr:array [1..2] of byte;
  //����
  pathArr:array [1..2] of byte;
  //���������� ���. ������� �� 10 �� �������
  numPocketSp:integer;
  //���������� ������� ��� ��������������� ��������
  countTrack:integer;
  trackSizeKoef:integer;//����. ��������������� ��� ��������
  //������ ������
  SCRUTfileArr:TMyArrayOfString;
  fileIndex:integer;
  //������ ����������� ������ � ������
  allRecordSize:Int64;
  changeFileFlag:boolean;
  kkkk:integer;
  deltaInFileForBack:Int64;
  //��� ������ ��� ������ ������� �����. � ����
  recordInfoMas:array of TrecInfo;
  iRecordInfoMas:integer;
  //���������� ��� �������� ������� ��������� � ��������� ����
  beginInterval:string;
  endInterval:string;
  //���������� ��� ������ � ������ ������������
  confIni:TIniFile;
  //������� ����� �� ������� ������� ��� ���������� �������
  //countPointInSpArr:integer;
  //������� ������ ��� ���. �������
  //spArrayIn:TByteArr;
  //�������� ������ �������
  //spArrayOut:TIntArr;
  //������� ������� ������
  fastProcBegLimit:real;
  fastProcEndLimit:real;
  //�������� ��������� �������
  fastInterval:real;
  //������������ ���. ���������
  intervalSize:integer;
  //������� ������ �������
  poolFastFreq:integer;
  poolFastVal:integer;
  //������������ ���. ���������
  kadrSize:integer;
  //������������ ���. ��������� � �����. �����
  poolKadrSize:integer;
  //�������� �������� �������� ��������
  procentD:real;
  //���������� �������������
  countInterval:integer;

  //������ ��������� ���������� ��� �.2 ��  ����
  arrFreqRange:array [1..MAX_FREQ_RANGES] of TFreqRange;
  //���������� ��� ����������� � ������� ������� �������
  dateTimeBeg:TDateTime;
  dateTimeEnd:TDateTime;
  unixTime:Int64;
  strTime:string;
  csk:TCriticalSection;
  //���������� ������. ��������� ����������
  numFreqRange:integer;
  //������� ������������
  cosArrA:array [1..MAX_T_NUM2] of {single}double;
  sinArrA:array [1..MAX_T_NUM2] of {single}double;
  cosArrB:array [1..MAX_T_NUM] of {single}double;
  sinArrB:array [1..MAX_T_NUM] of {single}double;
  //��������� �������� ����� �� �������
  procedure openFileForIndex(ind:integer);
  //function TestTime(time:string):boolean; //���������� ��� ����������� ������� �� ��. �����
implementation

uses TestChUnit;
const
POCKETSIZE=26;//������ ������ ����
//uses Unit3;
{$R *.dfm}
//��������� ��������
//==============================================================================
procedure Wait(value:integer);
var
  i:integer;
begin
  for i:=1 to value do
  begin
    sleep(3);
    application.ProcessMessages;
  end;
end;
//==============================================================================

//==============================================================================
//��������� ���������� �� ����� � ����
//==============================================================================

//��������� ��� ������ � ���� ����� 
procedure SaveResultToFile(var outF:text;str:string);
begin
  Writeln(outF,str);
  //exit
end;
//==============================================================================

//==============================================================================
//������� ����������� ������ ������(������ ����) � ������ ������ ������. ��� �����������.
//==============================================================================
function FillFileArray(var treeDirPath:string;
  var SCRUTfileArr:TMyArrayOfString;var allRecordSize:Int64):boolean;
var
  //������ ���������� � �������� �����
  searchResult : TSearchRec;
  iSCRUTfileArr:integer;

begin
  allRecordSize:=0;
  SCRUTfileArr:=nil;
  iSCRUTfileArr:=0;

  //-----------
  //������� \ � ����� �������� ���� ��� ���
  if treeDirPath[length(treeDirPath)]<>'\' then
  begin
    treeDirPath:=treeDirPath+'\';
  end;
  //-----------

  //������� ������ ���������� ����� ������ �� �������
  if FindFirst(treeDirPath+'IRUT****',faAnyFile,searchResult)=0 then
  begin
    SetLength(SCRUTfileArr,iSCRUTfileArr+1);
    //������ ���� � �����
    SCRUTfileArr[iSCRUTfileArr].path:=treeDirPath+searchResult.Name;
    //������ ����� � ������
    SCRUTfileArr[iSCRUTfileArr].size:=searchResult.Size;
    inc(iSCRUTfileArr);
    allRecordSize:=allRecordSize+searchResult.Size;
    //���� ��������� ���������� ���� �� ������ ���
    while FindNext(searchResult) = 0 do
    begin
      //������ ���� � �����
      //��������� ��� ��� ����. ����
      if searchResult.Name<>'irutConf.ini' then
      begin
        SetLength(SCRUTfileArr,iSCRUTfileArr+1);
        SCRUTfileArr[iSCRUTfileArr].path:=treeDirPath+searchResult.Name;
        //������ ����� � ������
        SCRUTfileArr[iSCRUTfileArr].size:=searchResult.Size;
        inc(iSCRUTfileArr);
        allRecordSize:=allRecordSize+searchResult.Size;
      end;
    end;
    FindClose(searchResult);
    result:=true;
  end
  else
  begin
    //������ � ������ ������
    //����������� ��������� ������
    FindClose(searchResult);
    result:=false;
  end;
end;
//==============================================================================

//==============================================================================
//���������� ������� ��������� ����������. ���������� �����. ������. ��������� ����������
//==============================================================================
function FillFreqRange:integer;
var
  i:integer;
  begFreq:real;
  endFreq:real;
begin
  i:=1;
  //�������� ������ ��������� ���������� ���������
  while (true) do
  begin
    begFreq:=confIni.readFloat('������� ����� ���������',
      '��������� �������� ��������� �'+intToStr(i)+' ��',0.0);
    endFreq:=confIni.readFloat('������� ����� ���������',
      '��������� �������� ��������� �'+intToStr(i)+' ��',0.0);
    if ((begFreq>0.0)and(endFreq>0.0)) then
    begin
      arrFreqRange[i].beginRange:=begFreq;
      arrFreqRange[i].endRange:=endFreq;
      inc(i);
    end
    else
    begin
      //������ ���������� ��������� ���, ������ ��� ��������� ���������
      break;
    end;
  end;
  //���������� ����������� ��������� ����������
  result:=i-1;
end;
//==============================================================================

//==============================================================================
//���������� ������� ������������ �������
//==============================================================================
procedure FillEnabledChanal;
var
  //������� ��� ���������� ������� ������������ �������
  i:integer;
  //������� ��� �������� ��������� ��������
  k:integer;
  m:integer;
  num:integer;

  sl:array[1..6] of string;
begin
  //��������� ������ �������
  for i:=1 to MAX_CH_COUNT_FAST do
  begin
    if confIni.readString('����� '+intToStr(i), '���������','')='���' then
    begin
      arrEnableChanals[i].enabled:=true;
    end
    else
    begin
      arrEnableChanals[i].enabled:=false;
    end;
    arrEnableChanals[i].typeS:='fast';
    //�������� �������� ��������� ������
    getChRange(confIni.ReadFloat('����� '+intToStr(i),'����������������',0.0),i);
  end;

  k:=1;
  while (true) do
  begin
    if confIni.readString('������ �����������\��������� �'+intToStr(k), '���������','')='���' then
    begin
      //������������� �����
      arrEnableChanals[i].enabled:=true;
      arrEnableChanals[i].typeS:='slowTV';
      arrEnableChanals[i].begRange:=confIni.ReadFloat('������ �����������\��������� �'+
          intToStr(k),'�������� ����������� ��',0.0);
      arrEnableChanals[i].endRange:=confIni.ReadFloat('������ �����������\��������� �'+
          intToStr(k),'�������� ����������� ��',0.0);
      arrEnableChanals[i].slowParP:=0;
      arrEnableChanals[i].slowParV:=0;
      arrEnableChanals[i].slowParT:=confIni.readInteger('������ �����������\��������� �'+
          intToStr(k),'����� ������ ����.',0);
      inc(i);
      //����� ����.
      arrEnableChanals[i].enabled:=true;
      arrEnableChanals[i].typeS:='slowTV';
      arrEnableChanals[i].begRange:=confIni.ReadFloat('������ �����������\��������� �'+
          intToStr(k),'�������� ��������� ��',0.0);
      arrEnableChanals[i].endRange:=confIni.ReadFloat('������ �����������\��������� �'+
          intToStr(k),'�������� ��������� ��',0.0);
      arrEnableChanals[i].slowParP:=0;
      arrEnableChanals[i].slowParT:=0;
      arrEnableChanals[i].slowParV:=confIni.readInteger('������ �����������\��������� �'+
          intToStr(k),'����� ������ ����.',0);
      inc(i);
    end
    else if confIni.readString('������ �����������\��������� �'+intToStr(k), '���������','')='����' then
    begin
      arrEnableChanals[i].enabled:=false;
      arrEnableChanals[i].typeS:='slowTV';
      arrEnableChanals[i].begRange:=confIni.ReadFloat('������ �����������\��������� �'+
          intToStr(k),'�������� ����������� ��',0.0);
      arrEnableChanals[i].endRange:=confIni.ReadFloat('������ �����������\��������� �'+
          intToStr(k),'�������� ����������� ��',0.0);
      arrEnableChanals[i].slowParT:=0;
      arrEnableChanals[i].slowParV:=0;
      arrEnableChanals[i].slowParP:=0;
      inc(i);
      arrEnableChanals[i].enabled:=false;
      arrEnableChanals[i].typeS:='slowTV';
       arrEnableChanals[i].begRange:=confIni.ReadFloat('������ �����������\��������� �'+
          intToStr(k),'�������� ��������� ��',0.0);
      arrEnableChanals[i].endRange:=confIni.ReadFloat('������ �����������\��������� �'+
          intToStr(k),'�������� ��������� ��',0.0);
      arrEnableChanals[i].slowParT:=0;
      arrEnableChanals[i].slowParV:=0;
      arrEnableChanals[i].slowParP:=0;
      inc(i);
    end
    else
    begin
      if confIni.readString('������ ��������', '���������','')='���' then
      begin
        arrEnableChanals[i].enabled:=true;
        arrEnableChanals[i].slowParP:=confIni.readInteger('������ ��������','����� ������ ���.',0);
      end
      else
      begin
        arrEnableChanals[i].enabled:=false;
        arrEnableChanals[i].slowParP:=0;
      end;
      arrEnableChanals[i].typeS:='slowP';
      arrEnableChanals[i].begRange:=confIni.ReadFloat('������ ��������','�������� �������� ��',0.0);
      arrEnableChanals[i].endRange:=confIni.ReadFloat('������ ��������','�������� �������� ��',0.0);
      arrEnableChanals[i].slowParT:=0;
      arrEnableChanals[i].slowParV:=0;
      inc(i);
    end;

    inc(k);
    if(k=4) then
    begin
      Break;
    end;
  end;

  //k:=1;

  //������� ��������������� ������ ���������
  for m:=MAX_CH_COUNT_FAST+1 to MAX_CH_COUNT do
  begin
    Form1.mmo1.Lines.Add(IntToStr(m));
    if arrEnableChanals[m].enabled then
    begin
      if  arrEnableChanals[m].typeS='slowTV' then
      begin
        if arrEnableChanals[m].slowParT<>0 then
        begin
          sl[arrEnableChanals[m].slowParT]:='T';
        end
        else
        begin
          sl[arrEnableChanals[m].slowParV]:='V';
        end;
      end
      else
      begin
        if arrEnableChanals[m].slowParP<>0 then
        begin
          sl[arrEnableChanals[m].slowParP]:='P';
        end
      end;
      //inc(k);
    end;
  end;

  i:=1;
  for m:=1 to 6 do
  begin
    if sl[m]<>'' then
    begin
      slowHelpArr[i]:=sl[m];
      Inc(i);
    end;
  end;



end;
//==============================================================================

//==============================================================================
//������ � ������ ������������. �������� ��������� ��� ������ ��
//==============================================================================
procedure WriteConfParam(confPath:string);
begin
  confIni:=TiniFile.Create(confPath);
  //���������� ���������� �� ����. �����
  fastProcBegLimit:=confIni.readFloat('������� ����� ���������', '������� ����������� ��������� ��', 0.0);
  fastProcEndLimit:=confIni.readFloat('������� ����� ���������', '������� ����������� ��������� ��', 0.0);
  fastInterval:=confIni.readFloat('������� ����� ���������', '�������� ����������� ���������',0.0);
  intervalSize:=confIni.readInteger('����� ���������', '������������ ���. ���������',0);
  poolFastFreq:=confIni.readInteger('������� ����� ���������', '������� �������������',0);
  //������� ������������ ���. ��������� � ���������� �����
  poolFastVal:=poolFastFreq*intervalSize;
  //�������� ������ ������ �� ����� ������
  blockSize:=POCKETSIZE*READ_POCKET_NUM{(poolFastVal*10)};
  //������� �������� ������������ ����� ������ � ��������
  kadrSize:=confIni.readInteger('����� ���������','���������� ���. ���������� � �����',0);
  //������� ������������ ����� ������ � ���������� �����  !!!poolFastFreq
  poolKadrSize:=poolFastFreq*intervalSize*kadrSize;
  procentD:=confIni.readFloat('������� ����� ���������', '������� �������� ��������',0.0);
  //��������� �� % � ������������ �����
  procentD:=procentD/100;
  //���������� ��������� ����������
  numFreqRange:=FillFreqRange;
  //�������� ������������ ������ �� �����. ��������
  FillEnabledChanal;
  confIni.Free;
end;
//==============================================================================

//==============================================================================
//���� ��������
//==============================================================================
function CollectCounter(iByteDj:integer):byte;
begin
  result:=pocketSCRUTJT[iByteDj];
end;
//==============================================================================

//==============================================================================
//���� ���������� ���������
//==============================================================================
function CollectSlowParam(iB:integer):word;
begin
  result:=pocketSCRUTJT[iB]+pocketSCRUTJT[iB+1] shl 8;
end;
//==============================================================================


//==============================================================================
//�������� �������� �������
//==============================================================================
procedure CollectTime(iB:integer;count:byte);
var
  timeGEOS_int:Int64;
  dT:TDateTime;
  dtStr:string;
  timeGEOS:cardinal;
begin
  if count=3 then
  begin
    timeGeosArr[4]:=pocketSCRUTJT[iB];
    timeGEOS:=(timeGeosArr[1] shl 24)+(timeGeosArr[2] shl 16)+
      (timeGeosArr[3] shl 8)+timeGeosArr[4];
    //�������� ����� ���� � UnixTime
    timeGEOS_int:=timeGEOS+1199145600{+14400};
    //�������� � ������� dateTime
    dT:=UnixToDateTime(timeGEOS_int);
    //�������� ����� � ������
    DateTimeToString(dtStr,'dd.mm.yyyy hh:mm:ss',dT);
    //����� �������
    form1.timeLabel.Caption:=dtStr;
  end
  else
  begin
    case count of
      0:
      begin
        timeGeosArr[1]:=pocketSCRUTJT[iB];
      end;
      1:
      begin
        timeGeosArr[2]:=pocketSCRUTJT[iB];
      end;
      2:
      begin
        timeGeosArr[3]:=pocketSCRUTJT[iB];
      end;
    end;
  end;
end;
//==============================================================================

//==============================================================================
//�������� �������� ������
//==============================================================================
procedure CollectLatitude(iB:integer;count:byte);
var
  gradLat,minLat,secLat :real;
  lat:double;
  latStr:string;
begin
  if count=7 then
  begin
    latArr[4]:=pocketSCRUTJT[iB];
    lat:=(latArr[1] shl 24)+(latArr[2] shl 16)+(latArr[3] shl 8)+
    latArr[4];
    //�������� �� 25 �� ������������ �� ��������
    lat:=lat/100000000;
    //�������� �������
    lat:=lat*180/3.1415926535;
    gradLat:=trunc(lat);
    //�������� ������
    minLat:=frac(lat)*60;
    //�������
    secLat:=frac(minLat)*60;
    secLat:=round(secLat);
    minLat:=trunc(minLat);
    latStr:=FloatToStr(gradLat)+'� '+FloatToStr(minLat)+''' '+FloatToStr(secLat)+'"';
    form1.LabelLat.Caption:=latStr;
  end
  else
  begin
     case count of
      4:
      begin
        latArr[1]:=pocketSCRUTJT[iB];
      end;
      5:
      begin
        latArr[2]:=pocketSCRUTJT[iB];
      end;
      6:
      begin
        latArr[3]:=pocketSCRUTJT[iB];
      end;
     end;
  end;
end;
//==============================================================================

//==============================================================================
//�������� �������� �������
//==============================================================================
procedure CollectLongtitude(iB:integer;count:byte);
var
  lon :double;
  gradLon,minLon,secLon :real;
  lonStr:string;
begin
  if count=11 then
  begin
    lonArr[4]:=pocketSCRUTJT[iB];
    lon:=(lonArr[1] shl 24)+(lonArr[2] shl 16)+(lonArr[3] shl 8)+
    lonArr[4];
    //�������� �� 25 �� ������������ �� ��������
    lon:=lon/100000000;
    //�������� �������
    lon:=lon*180/3.1415926535;
    gradLon:=trunc(lon);
    //�������� ������
    minLon:=frac(lon)*60;
    //�������
    secLon:=frac(minLon)*60;
    secLon:=round(secLon);
    minLon:=trunc(minLon);
    lonStr:=FloatToStr(gradLon)+'� '+FloatToStr(minLon)+''' '+FloatToStr(secLon)+'"';
    form1.LabelLon.Caption:=lonStr;
  end
  else
  begin
    case count of
      8:
      begin
        lonArr[1]:=pocketSCRUTJT[iB];
      end;
      9:
      begin
        lonArr[2]:=pocketSCRUTJT[iB];
      end;
      10:
      begin
        lonArr[3]:=pocketSCRUTJT[iB];
      end;
    end;
  end;
end;
//==============================================================================


//==============================================================================
//�������� ������
//==============================================================================
procedure CollectHeight(iB:integer;count:byte);
var
  height:word;
begin
  if count=13 then
  begin
    heightArr[2]:=pocketSCRUTJT[iB];
    height:=(heightArr[1] shl 8)+ heightArr[2];
    form1.Label10.Caption:=intToStr(height);
  end
  else
  begin
    case count of
      12:
      begin
        heightArr[1]:=pocketSCRUTJT[iB];
      end;
    end;
  end;
end;
//==============================================================================

//==============================================================================
//�������� ��������
//==============================================================================
procedure CollectSpeed(iB:integer;count:byte);
var
  speed:word;
begin
  if count=15 then
  begin
    speedArr[2]:=pocketSCRUTJT[iB];
    speed:=(speedArr[1] shl 8)+ speedArr[2];
    form1.Label12.Caption:=intToStr(speed);
  end
  else
  begin
    case count of
      14:
      begin
        speedArr[1]:=pocketSCRUTJT[iB];
      end;
    end;
  end;
end;
//==============================================================================

//==============================================================================
//�������� ����
//==============================================================================
procedure CollectPath(iB:integer;count:byte);
var
  path:double;
  gradPath:real;
  minPath:real;
  pathStr:string;
begin
  if count=17 then
  begin
    pathArr[2]:=pocketSCRUTJT[iB];
    path:=(pathArr[1] shl 8)+ pathArr[2];
    //������ �������� ����������� �����.
    path:=path/10000;
    gradPath:=trunc(path);
    //�������� ������
    minPath:=frac(path)*60;
    minPath:=trunc(minPath);
    pathStr:=FloatToStr(gradPath)+'� '+FloatToStr(minPath)+''' ';
    form1.Label14.Caption:=pathStr;
  end
  else
  begin
    case count of
      16:
      begin
        pathArr[1]:=pocketSCRUTJT[iB];
      end;
    end;
  end;
end;
//==============================================================================


//==============================================================================
//�������� ���������� ������� ���������
//==============================================================================
procedure CollectVisSetellites(iB:integer);
begin
  form1.Label16.Caption:=intToStr(pocketSCRUTJT[iB]);
end;
//==============================================================================

//==============================================================================
//�������� ���������� ������� ���������
//==============================================================================
procedure CollectDecisSetellites(iB:integer);
begin
  form1.Label18.Caption:=intToStr(pocketSCRUTJT[iB]);
end;
//==============================================================================

//==============================================================================
//�������� ������� ������� �������� � ������� ������
//==============================================================================
procedure CollectDecision(iB:integer);
begin
  if (pocketSCRUTJT[iB] and 1)=1 then
  begin
    form1.Label20.Caption:='��';
  end
  else
  begin
    form1.Label20.Caption:='���';
  end;
end;
//==============================================================================


//==============================================================================
//�������� ���������� +5V
//==============================================================================
{procedure CollectColibP5(iB:integer);
begin
//colibP5:=

end;}
//==============================================================================

//==============================================================================
//����� �� ��������� � �����������
//==============================================================================
procedure OutToDiaAndGist(var iB:integer);
begin
  form1.Chart1.Series[0].Clear;
  while iB<=POCKETSIZE-1 do
  begin
    //����� ������� �� ���������. c 1 .
    //��������� ��������� �� �����, ���� ��� ������ �������� ������� ����
    if (arrEnableChanals[iB-1].enabled) then
    begin
      form1.Chart1.Series[0].AddXY(iB-1,pocketSCRUTJT[iB]);
    end
    else
    begin
      // ����� �� �������� ������� ����
      form1.Chart1.Series[0].AddXY(iB-1,0);
    end;
    //form1.Memo1.Lines.Add(intToStr(iB-2));

    //����� ���������� �������� ����� �� �����������
    //==
    if (graphFlag) then
    begin
      if iB=chanelIndex+2 then
      begin
        //��������� ��������� �� ��������� �� ����. �����
        //-2 �.� � ������� �����. ������� 1 ����� � 1 ��������. � � ������ �� 3
        if (arrEnableChanals[iB-1].enabled) then
        begin
          form1.Chart2.Series[0].AddXY(iGist,pocketSCRUTJT[iB]);
          inc(iGist);
        end
        else
        begin
          // ����� �� �������� ������� ����
          form1.Chart2.Series[0].AddXY(iGist,0);
        end;
        if iGist>round(form1.Chart2.BottomAxis.Maximum) then
        begin
          iGist:=0;
          form1.Chart2.Series[0].Clear;
        end;
      end;
    end;
    //==
    inc(iB);
  end;
end;
//==============================================================================




//==============================================================================
// ��������� �������� ����� �� �������
//==============================================================================
procedure openFileForIndex(ind:integer);
begin
  stream:=TFileStream.Create(SCRUTfileArr[ind].path,fmShareDenyNone{fmOpenRead});
end;
//==============================================================================

//==============================================================================
//���� ��������� ����������
//==============================================================================
procedure CollectSlowParams(iByte:integer;pockCount:byte);
begin
  //� ����������� �� ������ �������� ������ ��������� ���� ����.
  //� ������� ����� ��������� ����������

  //�����
  if ((pockCount>=0) and (pockCount<=3)) then
  begin
    CollectTime(iByte,pockCount);
  end;

  //������
  if ((pockCount>=4) and (pockCount<=7)) then
  begin
    CollectLatitude(iByte,pockCount);
  end;

  //�������
  if ((pockCount>=8) and (pockCount<=11)) then
  begin
    CollectLongtitude(iByte,pockCount);
  end;

  //������
  if ((pockCount>=12) and (pockCount<=13)) then
  begin
    CollectHeight(iByte,pockCount);
  end;

  //��������
  if ((pockCount>=14) and (pockCount<=15)) then
  begin
    CollectSpeed(iByte,pockCount);
  end;

  //����
  if ((pockCount>=16) and (pockCount<=17)) then
  begin
    CollectPath(iByte,pockCount);
  end;

  //���������� ������� ���������
  if pockCount=18 then
  begin
    CollectVisSetellites(iByte);
  end;

  //���������� ��������� � �������
  if pockCount=19 then
  begin
    CollectDecisSetellites(iByte);
  end;

  //����� ��������� 0-��� �������, 1-���� �������
  if pockCount=20 then
  begin
    CollectDecision(iByte);
  end;

  //���������� +5�
  {if pockCount=22 then
  begin
    CollectColibP5(iByte);
  end;}
end;
//==============================================================================

//==============================================================================
//��������� �� ������� ������ �������. ���������� ���������� �������.
//==============================================================================
procedure ParsePocket(numberOfPocket:word;var bool:boolean);
var
  i:integer;
  iByte:integer;
  //������� �������
  countSCRUTJT:byte;//0..255
  //��������� ��������
  //slowParamSCRUTJ:word;
  //strPocket:string;
begin
  i:=1;
  //��� ������������ ����� �������
  if (bool) then
  begin
    bool:=false;
    form1.TrackBar1.Position:=1;
  end;

  //��������������� ������������ ������
  while i<=numberOfPocket do
  begin
    try
      //������ �� ����� 26 ����, 1 �����
      Stream.Read(pocketSCRUTJT, SizeOf(pocketSCRUTJT));
      //������ ���� ������� ������
      //������� ������(�����).�������� ���.
      iByte:=1;
      countSCRUTJT:=CollectCounter(iByte);
      iByte:=2;
      //����� ������� ���������� �� ��������� � ����� �� ������
      //1-24 ������� �� 1 �����
      OutToDiaAndGist(iByte);
      //�������� ��������� ���������
      CollectSlowParams(iByte,countSCRUTJT);
      if countTrack=trackSizeKoef then
      begin
         form1.TrackBar1.Position:=form1.TrackBar1.Position+form1.TrackBar1.PageSize;
         countTrack:=1;
      end
      else
      begin
        inc(countTrack);
      end;
    finally
      //���������  ����� �� �� ����� �����. ����� ������ ����������� ������ � ������
      if  stream.Position>=stream.Size then
      begin
        form1.Timer1.Enabled:=false;
        //��������� �� ����� �� ������
        if fileIndex<length(SCRUTfileArr)-1 then
        begin
          stream.Free;
          //wait(5);
          inc(fileIndex);
          openFileForIndex(fileIndex);
          //����������� ����� ����� � �������� �������
          form1.FileNumTrack.Position:=form1.FileNumTrack.Position+form1.FileNumTrack.PageSize;
          form1.TrackBar1.Position:=1;
        end
        else
        begin
          //�����
          //��������� ���� �� �����������
          form1.StartButton.Enabled:=false;
          form1.StopButton.Enabled:=false;
          form1.Chart1.Series[0].Clear;
          form1.Chart2.Series[0].Clear;
        end;
      end;
    end;
    inc(i);
  end;
end;

//==============================================================================

//==============================================================================
//
//==============================================================================
procedure FillSinCosTables;
var
  i:integer;
  j:integer;
  k:integer;
  iPrev:integer;
  //����������� ����������� �������.
  arrSize:integer;
  //�������� ������� �������
  arrSizeDiv2:integer;
  koef:double;
  //ff:integer;
begin
  arrSize:=trunc(poolFastVal/KOEF_R);
  arrSizeDiv2:=trunc(arrSize/2);
  k:=1;
  for i:=1 to arrSizeDiv2 do
  begin
    iPrev:=i;
    koef:=iPrev/arrSizeDiv2;
    j:=1;
    while j<=arrSizeDiv2 do
    begin
      cosArrA[k]:=cos(2*PI*(j+1)*koef);
      cosArrA[k+1]:=cos(2*PI*(j+2)*koef);
      cosArrA[k+2]:=cos(2*PI*(j+3)*koef);
      cosArrA[k+3]:=cos(2*PI*(j+4)*koef);

      sinArrA[k]:=sin(2*PI*(j+1)*koef);
      sinArrA[k+1]:=sin(2*PI*(j+2)*koef);
      sinArrA[k+2]:=sin(2*PI*(j+3)*koef);
      sinArrA[k+3]:=sin(2*PI*(j+4)*koef);
      k:=k+4;
      j:=j+4;
    end;
  end;

  for i:=1 to arrSizeDiv2 do
  begin
    iPrev:=i;
    koef:=iPrev/arrSize;
    cosArrB[i]:=cos(2*PI*koef);
    sinArrB[i]:=sin(2*PI*koef);
  end;
end;
//==============================================================================

procedure TForm1.changeFileClick(Sender: TObject);
var
  //������ � ������� ���������� ��������  � ������� ������
  folderStr:string;
begin
  fileIndex:=0;
  //form1.FileNumTrack.Enabled:=true;
  //form1.TrackBar1.Enabled:=true;
  Form1.TrackBar1.Enabled:=False;
  Form1.FileNumTrack.Enabled:=False;
  Form1.TrackBar2.Enabled:=False;
  if SelectDirectory('�������� ������� � ������� ����� �����-������ ����','\',folderStr) then
  begin
    //�������� ������� ������ ��� ���������� ��������
    //��������� ���. ������ � ������� ������ �� ������ ������� �����. �������� �����
    if FillFileArray(folderStr,SCRUTfileArr,allRecordSize) then
    begin
      //���������� �������� ������ �����
      form1.FileNumTrack.Max:=length(SCRUTfileArr);
      form1.FileNumTrack.Min:=1;
      form1.FileNumTrack.Position:=1;
      //��������� � ������ ������ �������
      openFileForIndex(fileIndex);
      //������� ����. ��������������� ������������ �������� ��������� �����
      trackSizeKoef:=trunc(stream.Size/POCKETSIZE/400000)+1;
      //������������ �������
      form1.TrackBar1.Max:=trunc(stream.Size/POCKETSIZE/trackSizeKoef);
      //���.�������� ������
      numPocketSp:=RTPOCKETNUM;
      ShowMessage('�������� ���� ������������!');
      while (true) do
      begin
        //������� ���� ������������
        if form1.OpenDialog1.Execute then
        begin
          //����������� ������ ������ ��� ������ ������
          form1.StartButton.Enabled:=true;
          form1.changeFile.Enabled:=false;
          form1.Button4.Enabled:=true;
          //������ ������� ������� ��������� �� ���������
          form1.OpenDialog1.InitialDir := GetCurrentDir;
          //������ �� ����� ������ ���� ���
          form1.OpenDialog1.Filter :='INI|*.ini';
          //��������� ������������
          WriteConfParam(form1.OpenDialog1.FileName);
          //���������� ������� ������������ ������� � ���������
          FillSinCosTables;
          break;
        end
        else
        begin
          ShowMessage('������! ���� ������������ �� ������!');
          break;
        end;
      end;
    end
    else
    begin
      ShowMessage('������ ���������� ������ ������ ����');
      exit;
    end;
  end
  else
  begin
    ShowMessage('������� �� ������!');
  end;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  //������ ������ ������� ��������� ���������� ����� �������
  ParsePocket(numPocketSp,changeFileFlag);
end;

procedure TForm1.StartButtonClick(Sender: TObject);
begin
  Form1.TrackBar2.Enabled:=true;
  form1.FileNumTrack.Enabled:=true;
  form1.TrackBar1.Enabled:=true;
  Form1.Button4.Enabled:=False;
  form1.StartButton.Enabled:=false;
  form1.StopButton.Enabled:=true;
  form1.Timer1.Enabled:=true;//������ �������
end;

procedure TForm1.StopButtonClick(Sender: TObject);
begin
  Form1.TrackBar2.Enabled:=False;
  form1.FileNumTrack.Enabled:=false;
  form1.TrackBar1.Enabled:=false;
  Form1.Button4.Enabled:=true;
  form1.StartButton.Enabled:=true;
  form1.StopButton.Enabled:=false;
  form1.Timer1.Enabled:=false;
end;

procedure TForm1.Series1Click(Sender: TChartSeries; ValueIndex: Integer;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  iGist:=0;
  if (graphFlag) then
  begin
    form1.Chart2.Series[0].Clear;
    graphFlag:=false;
  end
  else
  begin
    graphFlag:=true;
    chanelIndex:=ValueIndex;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  csk:=TCriticalSection.Create;
  //��������� ������ ������ � ������
  stream:=nil;
  //����������� ������
  form1.changeFile.Enabled:=true;
  form1.StartButton.Enabled:=false;
  form1.StopButton.Enabled:=false;
  form1.Button4.Enabled:=false;
  form1.FileNumTrack.Enabled:=false;
  form1.TrackBar1.Enabled:=false;
  //������������� �������� ��� ��������������� ��������
  countTrack:=1;
  changeFileFlag:=true;
  graphFlag:=false;
  iGist:=0;
  chanelIndex:=0;
  //countPointInSpArr:=1;//������� ��� ���������� ������� �������
  //����������� ����������� ����� � ����������� ����� ����� �����.
  DecimalSeparator := '.';   //!!!
end;

//==============================================================================
//
//==============================================================================
procedure CheckToFileEnd;
begin
  if form1.TrackBar1.Position=form1.TrackBar1.Max-2 then
  begin
    form1.TrackBar1.Enabled:=false;
  end
  else
  begin
    form1.TrackBar1.Enabled:=true;
  end;
  if form1.TrackBar1.Position=form1.TrackBar1.Min+2 then
  begin
    form1.TrackBar1.Enabled:=false;
  end
  else
  begin
    form1.TrackBar1.Enabled:=true;
  end;
end;
//==============================================================================



procedure TForm1.TrackBar1Change(Sender: TObject);
begin
  //������������ ����� �� ������� ����� �����
  CheckToFileEnd;
  //����������� ������ �������� �������. ��� ������ ����� �� ������ �� ����� �����
  form1.StopButton.Enabled:=true;
  form1.Timer1.Enabled:=false;
  //������� ��������� � ������� �������� ����� ��� ���������� ������� �� �����
  stream.Position:=(form1.TrackBar1.Position-1)*POCKETSIZE*trackSizeKoef;
  form1.Timer1.Enabled:=true;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Stream.Free;
  //��������� ������� �� excel
  if (CheckExcelRun) then
  begin
    //�������, ��������
    StopExcel;
  end;

  Application.Terminate;
end;

procedure TForm1.TrackBar2Change(Sender: TObject);
begin
  numPocketSp:=form1.TrackBar2.Position;
end;

procedure TForm1.FileNumTrackChange(Sender: TObject);
begin
  form1.Timer1.Enabled:=false;
  //���������� ���������� ����������� �����
  stream.Free;
  //������� ������� ��� ����� ��������� �������� �� ������.
  form1.Chart1.Series[0].Clear;
  form1.Chart2.Series[0].Clear;
  //���������� ���������� ��� ������������
  countTrack:=1;
  iGist:=0;
  //��������� � ��������� ������
  fileIndex:=form1.FileNumTrack.Position-1;
  openFileForIndex(fileIndex);
  //������� ����. ��������������� ������������ �������� ��������� �����
  trackSizeKoef:=trunc(stream.Size/POCKETSIZE/400000)+1;
  //������������ �������
  form1.TrackBar1.Max:=trunc(stream.Size/POCKETSIZE/trackSizeKoef);
  changeFileFlag:=true;
  form1.Timer1.Enabled:=true;//������ �������
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  //����� ������ ���������� ������ ������
  skoCompl:=false;
  gistCompl:=false;
  logCompl:=False;
  //����� 
  Form1.gProgress1.Progress:=0;
  Form1.StartButton.Enabled:=False;
  Form1.StopButton.Enabled:=False;
  //���������� ������� ���� � �����.
  dateTimeBeg:=Now;
  //������� ����� � ������� ��������
  form2.Show;
end;



procedure TForm1.tmr1Timer(Sender: TObject);
var
  i:Integer;
  bool:Boolean;
begin
  bool:=True;
  for i:=1 to Form1.tmr1.Tag do
    begin
      if not arrEnbChannal[i] then
      begin
        bool:=False;
      end;
    end;
  if (bool) then
  begin
    //��������� ������ ��� ���������� ������� ������
    Form1.tmr1.Enabled:=False;
    //Form1.Memo1.Lines.Add('����� ����� ��� ��������!');

    Form1.StartButton.Enabled:=true;
    Form1.StopButton.Enabled:=true;
    //Form1.gProgress1.Progress:=100;
    //�������� ���������
    //ShowMessage('��������� ���������!');
    //���������� ��� ����� � ������ ��������
    skoCompl:=true;
    thWriteSKO.Free;
    exit;
  end;
end;

procedure TForm1.tmr2Timer(Sender: TObject);
var
  i:Integer;
  bool:Boolean;
begin
  bool:=True;
  for i:=1 to Form1.tmr2.Tag do
  begin
    if not arrEnbChannal[i] then
    begin
      bool:=False;
    end;
  end;
  if (bool) then
  begin
    //��������� ������ ��� ���������� ������� ������
    Form1.tmr2.Enabled:=False;
    //Form1.Memo1.Lines.Add('����� ����� GIST ��������!');
    //������ ������ ����� ���������� �����������
    if form2.chk2.Checked then
    begin
      thWriteSko.Resume;
    end;
    gistCompl:=true;
    thWriteGist.Free;
    exit;
  end;
end;

procedure TForm1.tmrEnd3Timer(Sender: TObject);
begin
  if (skoCompl)and(gistCompl)and(logCompl) then
  begin
    if Form1.gProgress1.Progress<100 then
    begin
      Form1.gProgress1.Progress:=100;
      //�������� ���������
      ShowMessage('��������� ���������!');
      //�����
      Form1.gProgress1.Progress:=0;
    end;
    //���������� �������
    Form1.tmrEnd3.Enabled:=False;
  end;
end;

end.

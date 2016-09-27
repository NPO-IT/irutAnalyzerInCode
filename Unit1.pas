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
  // тип для хранения короткой информации о файле-записи СКРУТЖТ
  TfileMiniInfo=record
    path:string;
    size:integer;
  end;

  //тип для хранения информации для выборочной записи в файл
  TrecInfo=record
    fileNumber:integer;
    fileOffset:int64;
  end;

  //тип частотного диапазона
  TFreqRange=record
    beginRange:real;
    endRange:real;
  end;

  //тип для передаче динамич массива в качестве параметра
  TMyArrayOfString=array of TfileMiniInfo;

var
  Form1: TForm1;
  fileSCRUTJT:file;
  stream: TFileStream;
  iGist:integer;
  chanelIndex:integer;
  graphFlag:boolean;
  pocketSCRUTJT: array[1..POCKETSIZE] of byte;//массив - пакет ИРУТ
  timeGeosArr :array [1..4] of byte;//---time
  //skT,cT:integer;
  //---latitude
  latArr :array [1..4] of byte;
  cS,skS :integer;
  //---longtitude
  lonArr:array [1..4] of byte;
  cD,skD :integer;
  //высота
  heightArr:array [1..2] of byte;
  //скорость
  speedArr:array [1..2] of byte;
  //курс
  pathArr:array [1..2] of byte;
  //количество обр. пакетов за 10 мс таймера
  numPocketSp:integer;
  //внутренний счетчик для масштабирования трекбара
  countTrack:integer;
  trackSizeKoef:integer;//коэф. масштабирования для ТрекБара
  //массив файлов
  SCRUTfileArr:TMyArrayOfString;
  fileIndex:integer;
  //полная размерность записи в байтах
  allRecordSize:Int64;
  changeFileFlag:boolean;
  kkkk:integer;
  deltaInFileForBack:Int64;
  //дин массив для записи быстрых парам. в файл
  recordInfoMas:array of TrecInfo;
  iRecordInfoMas:integer;
  //переменные для хранения пользов интервала с строковом виде
  beginInterval:string;
  endInterval:string;
  //переменная для работы с файлом конфигурации
  confIni:TIniFile;
  //счетчик точек во входном массиве для вычисления спектра
  //countPointInSpArr:integer;
  //входной массив для выч. спектра
  //spArrayIn:TByteArr;
  //выходной массив спектра
  //spArrayOut:TIntArr;
  //граница быстрых начало
  fastProcBegLimit:real;
  fastProcEndLimit:real;
  //интервал обработки быстрых
  fastInterval:real;
  //длительность обр. интервала
  intervalSize:integer;
  //частота опроса быстрых
  poolFastFreq:integer;
  poolFastVal:integer;
  //длительность обр. интервала
  kadrSize:integer;
  //длительность обр. интервала в колич. точек
  poolKadrSize:integer;
  //параметр разности скорости движения
  procentD:real;
  //количество подинтервалов
  countInterval:integer;

  //массив частотных диапазонов для п.2 ТЗ  ИРУТ
  arrFreqRange:array [1..MAX_FREQ_RANGES] of TFreqRange;
  //Переменные для отображения с момента запуска времени
  dateTimeBeg:TDateTime;
  dateTimeEnd:TDateTime;
  unixTime:Int64;
  strTime:string;
  csk:TCriticalSection;
  //количество заполн. частотных диапазонов
  numFreqRange:integer;
  //массивы коэфициентов
  cosArrA:array [1..MAX_T_NUM2] of {single}double;
  sinArrA:array [1..MAX_T_NUM2] of {single}double;
  cosArrB:array [1..MAX_T_NUM] of {single}double;
  sinArrB:array [1..MAX_T_NUM] of {single}double;
  //процедура открытия файла по индексу
  procedure openFileForIndex(ind:integer);
  //function TestTime(time:string):boolean; //объявление для возможности запуска из др. юнита
implementation

uses TestChUnit;
const
POCKETSIZE=26;//размер пакета ИРУТ
//uses Unit3;
{$R *.dfm}
//Процедура задержки
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
//Процедуры отвечающие за вывод в файл
//==============================================================================

//процедура для записи в файл логов 
procedure SaveResultToFile(var outF:text;str:string);
begin
  Writeln(outF,str);
  //exit
end;
//==============================================================================

//==============================================================================
//Функция формирующая список файлов(полные пути) и полный размер записи. Без вложенности.
//==============================================================================
function FillFileArray(var treeDirPath:string;
  var SCRUTfileArr:TMyArrayOfString;var allRecordSize:Int64):boolean;
var
  //запись найденного в каталоге файла
  searchResult : TSearchRec;
  iSCRUTfileArr:integer;

begin
  allRecordSize:=0;
  SCRUTfileArr:=nil;
  iSCRUTfileArr:=0;

  //-----------
  //добавим \ в конец каталога если его нет
  if treeDirPath[length(treeDirPath)]<>'\' then
  begin
    treeDirPath:=treeDirPath+'\';
  end;
  //-----------

  //находим первое совпадение файла исходя из условий
  if FindFirst(treeDirPath+'IRUT****',faAnyFile,searchResult)=0 then
  begin
    SetLength(SCRUTfileArr,iSCRUTfileArr+1);
    //полный путь к файлу
    SCRUTfileArr[iSCRUTfileArr].path:=treeDirPath+searchResult.Name;
    //размер файла в байтах
    SCRUTfileArr[iSCRUTfileArr].size:=searchResult.Size;
    inc(iSCRUTfileArr);
    allRecordSize:=allRecordSize+searchResult.Size;
    //ищем повторные совпадения пока не найдем все
    while FindNext(searchResult) = 0 do
    begin
      //полный путь к файлу
      //проверяем что это конф. файл
      if searchResult.Name<>'irutConf.ini' then
      begin
        SetLength(SCRUTfileArr,iSCRUTfileArr+1);
        SCRUTfileArr[iSCRUTfileArr].path:=treeDirPath+searchResult.Name;
        //размер файла в байтах
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
    //ошибка в поиске файлов
    //освобождаем структуру поиска
    FindClose(searchResult);
    result:=false;
  end;
end;
//==============================================================================

//==============================================================================
//Заполнение массива частотных диапазонов. Возвращает колич. заполн. частотных диапазонов
//==============================================================================
function FillFreqRange:integer;
var
  i:integer;
  begFreq:real;
  endFreq:real;
begin
  i:=1;
  //заполним массив частотных диапазонов обработки
  while (true) do
  begin
    begFreq:=confIni.readFloat('Быстрые общие параметры',
      'Частотный диапазон обработки №'+intToStr(i)+' от',0.0);
    endFreq:=confIni.readFloat('Быстрые общие параметры',
      'Частотный диапазон обработки №'+intToStr(i)+' до',0.0);
    if ((begFreq>0.0)and(endFreq>0.0)) then
    begin
      arrFreqRange[i].beginRange:=begFreq;
      arrFreqRange[i].endRange:=endFreq;
      inc(i);
    end
    else
    begin
      //такого частотного диапазона нет, значит все диапазоны заполнены
      break;
    end;
  end;
  //количество заполненных частотных диапазонов
  result:=i-1;
end;
//==============================================================================

//==============================================================================
//Заполнение массива подключенных каналов
//==============================================================================
procedure FillEnabledChanal;
var
  //счетчик для заполнения массива подключенных каналов
  i:integer;
  //счетчик для перебора медленных датчиков
  k:integer;
  m:integer;
  num:integer;

  sl:array[1..6] of string;
begin
  //заполняем каналы быстрых
  for i:=1 to MAX_CH_COUNT_FAST do
  begin
    if confIni.readString('Канал '+intToStr(i), 'Состояние','')='ВКЛ' then
    begin
      arrEnableChanals[i].enabled:=true;
    end
    else
    begin
      arrEnableChanals[i].enabled:=false;
    end;
    arrEnableChanals[i].typeS:='fast';
    //заполним диапазон измерения канала
    getChRange(confIni.ReadFloat('Канал '+intToStr(i),'Чувствительность',0.0),i);
  end;

  k:=1;
  while (true) do
  begin
    if confIni.readString('Датчик температуры\влажности №'+intToStr(k), 'Состояние','')='ВКЛ' then
    begin
      //температурный канал
      arrEnableChanals[i].enabled:=true;
      arrEnableChanals[i].typeS:='slowTV';
      arrEnableChanals[i].begRange:=confIni.ReadFloat('Датчик температуры\влажности №'+
          intToStr(k),'Диапазон температуры от',0.0);
      arrEnableChanals[i].endRange:=confIni.ReadFloat('Датчик температуры\влажности №'+
          intToStr(k),'Диапазон температуры до',0.0);
      arrEnableChanals[i].slowParP:=0;
      arrEnableChanals[i].slowParV:=0;
      arrEnableChanals[i].slowParT:=confIni.readInteger('Датчик температуры\влажности №'+
          intToStr(k),'Номер канала темп.',0);
      inc(i);
      //канал влаж.
      arrEnableChanals[i].enabled:=true;
      arrEnableChanals[i].typeS:='slowTV';
      arrEnableChanals[i].begRange:=confIni.ReadFloat('Датчик температуры\влажности №'+
          intToStr(k),'Диапазон влажности от',0.0);
      arrEnableChanals[i].endRange:=confIni.ReadFloat('Датчик температуры\влажности №'+
          intToStr(k),'Диапазон влажности до',0.0);
      arrEnableChanals[i].slowParP:=0;
      arrEnableChanals[i].slowParT:=0;
      arrEnableChanals[i].slowParV:=confIni.readInteger('Датчик температуры\влажности №'+
          intToStr(k),'Номер канала влаж.',0);
      inc(i);
    end
    else if confIni.readString('Датчик температуры\влажности №'+intToStr(k), 'Состояние','')='ВЫКЛ' then
    begin
      arrEnableChanals[i].enabled:=false;
      arrEnableChanals[i].typeS:='slowTV';
      arrEnableChanals[i].begRange:=confIni.ReadFloat('Датчик температуры\влажности №'+
          intToStr(k),'Диапазон температуры от',0.0);
      arrEnableChanals[i].endRange:=confIni.ReadFloat('Датчик температуры\влажности №'+
          intToStr(k),'Диапазон температуры до',0.0);
      arrEnableChanals[i].slowParT:=0;
      arrEnableChanals[i].slowParV:=0;
      arrEnableChanals[i].slowParP:=0;
      inc(i);
      arrEnableChanals[i].enabled:=false;
      arrEnableChanals[i].typeS:='slowTV';
       arrEnableChanals[i].begRange:=confIni.ReadFloat('Датчик температуры\влажности №'+
          intToStr(k),'Диапазон влажности от',0.0);
      arrEnableChanals[i].endRange:=confIni.ReadFloat('Датчик температуры\влажности №'+
          intToStr(k),'Диапазон влажности до',0.0);
      arrEnableChanals[i].slowParT:=0;
      arrEnableChanals[i].slowParV:=0;
      arrEnableChanals[i].slowParP:=0;
      inc(i);
    end
    else
    begin
      if confIni.readString('Датчик давления', 'Состояние','')='ВКЛ' then
      begin
        arrEnableChanals[i].enabled:=true;
        arrEnableChanals[i].slowParP:=confIni.readInteger('Датчик давления','Номер канала дав.',0);
      end
      else
      begin
        arrEnableChanals[i].enabled:=false;
        arrEnableChanals[i].slowParP:=0;
      end;
      arrEnableChanals[i].typeS:='slowP';
      arrEnableChanals[i].begRange:=confIni.ReadFloat('Датчик давления','Диапазон давления от',0.0);
      arrEnableChanals[i].endRange:=confIni.ReadFloat('Датчик давления','Диапазон давления до',0.0);
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

  //получим вспомогательный массив медленных
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
//Работа с файлом конфигурации. Вынимаем параметры для работы ПО
//==============================================================================
procedure WriteConfParam(confPath:string);
begin
  confIni:=TiniFile.Create(confPath);
  //заполнение параметров из конф. файла
  fastProcBegLimit:=confIni.readFloat('Быстрые общие параметры', 'Граница гистограммы обработки от', 0.0);
  fastProcEndLimit:=confIni.readFloat('Быстрые общие параметры', 'Граница гистограммы обработки до', 0.0);
  fastInterval:=confIni.readFloat('Быстрые общие параметры', 'Интервал гистограммы обработки',0.0);
  intervalSize:=confIni.readInteger('Общие параметры', 'Длительность обр. интервала',0);
  poolFastFreq:=confIni.readInteger('Быстрые общие параметры', 'Частота дискретизации',0);
  //запишем длительонсть обр. интервала в количестве точек
  poolFastVal:=poolFastFreq*intervalSize;
  //байтовый размер чтения из файла данных
  blockSize:=POCKETSIZE*READ_POCKET_NUM{(poolFastVal*10)};
  //запишем параметр длительности кадра записи в секундах
  kadrSize:=confIni.readInteger('Общие параметры','Количество обр. интервалов в кадре',0);
  //запишем длительность кадра записи в количестве точек  !!!poolFastFreq
  poolKadrSize:=poolFastFreq*intervalSize*kadrSize;
  procentD:=confIni.readFloat('Быстрые общие параметры', 'Разница скорости движения',0.0);
  //переводим из % в вещественное число
  procentD:=procentD/100;
  //заполнение частотных диапазонов
  numFreqRange:=FillFreqRange;
  //заполним подключенные каналы из подкл. датчиков
  FillEnabledChanal;
  confIni.Free;
end;
//==============================================================================

//==============================================================================
//Сбор счетчика
//==============================================================================
function CollectCounter(iByteDj:integer):byte;
begin
  result:=pocketSCRUTJT[iByteDj];
end;
//==============================================================================

//==============================================================================
//Сбор медленного параметра
//==============================================================================
function CollectSlowParam(iB:integer):word;
begin
  result:=pocketSCRUTJT[iB]+pocketSCRUTJT[iB+1] shl 8;
end;
//==============================================================================


//==============================================================================
//Собираем значение времени
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
    //приводим время ГЕОС в UnixTime
    timeGEOS_int:=timeGEOS+1199145600{+14400};
    //приводим к формату dateTime
    dT:=UnixToDateTime(timeGEOS_int);
    //приводим время к строке
    DateTimeToString(dtStr,'dd.mm.yyyy hh:mm:ss',dT);
    //вывод времени
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
//Собираем значение широты
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
    //точность до 25 см расположения по величине
    lat:=lat/100000000;
    //получаем градусы
    lat:=lat*180/3.1415926535;
    gradLat:=trunc(lat);
    //получаем минуты
    minLat:=frac(lat)*60;
    //секунды
    secLat:=frac(minLat)*60;
    secLat:=round(secLat);
    minLat:=trunc(minLat);
    latStr:=FloatToStr(gradLat)+'° '+FloatToStr(minLat)+''' '+FloatToStr(secLat)+'"';
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
//Собираем значение долготы
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
    //точность до 25 см расположения по величине
    lon:=lon/100000000;
    //получаем градусы
    lon:=lon*180/3.1415926535;
    gradLon:=trunc(lon);
    //получаем минуты
    minLon:=frac(lon)*60;
    //секунды
    secLon:=frac(minLon)*60;
    secLon:=round(secLon);
    minLon:=trunc(minLon);
    lonStr:=FloatToStr(gradLon)+'° '+FloatToStr(minLon)+''' '+FloatToStr(secLon)+'"';
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
//Собираем высоту
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
//Собираем скорость
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
//Собираем курс
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
    //задаем точность определения курса.
    path:=path/10000;
    gradPath:=trunc(path);
    //получаем минуты
    minPath:=frac(path)*60;
    minPath:=trunc(minPath);
    pathStr:=FloatToStr(gradPath)+'° '+FloatToStr(minPath)+''' ';
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
//Получаем количество видимых спутников
//==============================================================================
procedure CollectVisSetellites(iB:integer);
begin
  form1.Label16.Caption:=intToStr(pocketSCRUTJT[iB]);
end;
//==============================================================================

//==============================================================================
//Получаем количество видимых спутников
//==============================================================================
procedure CollectDecisSetellites(iB:integer);
begin
  form1.Label18.Caption:=intToStr(pocketSCRUTJT[iB]);
end;
//==============================================================================

//==============================================================================
//Получаем признак наличия спутника в текущий момент
//==============================================================================
procedure CollectDecision(iB:integer);
begin
  if (pocketSCRUTJT[iB] and 1)=1 then
  begin
    form1.Label20.Caption:='Да';
  end
  else
  begin
    form1.Label20.Caption:='Нет';
  end;
end;
//==============================================================================


//==============================================================================
//Получаем колибровку +5V
//==============================================================================
{procedure CollectColibP5(iB:integer);
begin
//colibP5:=

end;}
//==============================================================================

//==============================================================================
//Вывод на диаграмму и гистограмму
//==============================================================================
procedure OutToDiaAndGist(var iB:integer);
begin
  form1.Chart1.Series[0].Clear;
  while iB<=POCKETSIZE-1 do
  begin
    //вывод столбца на диаграмму. c 1 .
    //проверяем подключен ли канал, если нет вместо значений выводим нули
    if (arrEnableChanals[iB-1].enabled) then
    begin
      form1.Chart1.Series[0].AddXY(iB-1,pocketSCRUTJT[iB]);
    end
    else
    begin
      // канал не подлючен выводим нули
      form1.Chart1.Series[0].AddXY(iB-1,0);
    end;
    //form1.Memo1.Lines.Add(intToStr(iB-2));

    //Вывод выбранного значения байта на гистограмму
    //==
    if (graphFlag) then
    begin
      if iB=chanelIndex+2 then
      begin
        //проверяем подключен ли выводимый на гист. канал
        //-2 т.к в массиве подкл. каналов 1 канал в 1 элементе. а в пакете он 3
        if (arrEnableChanals[iB-1].enabled) then
        begin
          form1.Chart2.Series[0].AddXY(iGist,pocketSCRUTJT[iB]);
          inc(iGist);
        end
        else
        begin
          // канал не подлючен выводим нули
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
// Процедура открытия файла по индексу
//==============================================================================
procedure openFileForIndex(ind:integer);
begin
  stream:=TFileStream.Create(SCRUTfileArr[ind].path,fmShareDenyNone{fmOpenRead});
end;
//==============================================================================

//==============================================================================
//Сбор медленных параметров
//==============================================================================
procedure CollectSlowParams(iByte:integer;pockCount:byte);
begin
  //в зависимости от номера счетчика пакета причислим байт медл.
  //к нужному байту медленных параметров

  //время
  if ((pockCount>=0) and (pockCount<=3)) then
  begin
    CollectTime(iByte,pockCount);
  end;

  //широта
  if ((pockCount>=4) and (pockCount<=7)) then
  begin
    CollectLatitude(iByte,pockCount);
  end;

  //долгота
  if ((pockCount>=8) and (pockCount<=11)) then
  begin
    CollectLongtitude(iByte,pockCount);
  end;

  //высота
  if ((pockCount>=12) and (pockCount<=13)) then
  begin
    CollectHeight(iByte,pockCount);
  end;

  //скорость
  if ((pockCount>=14) and (pockCount<=15)) then
  begin
    CollectSpeed(iByte,pockCount);
  end;

  //курс
  if ((pockCount>=16) and (pockCount<=17)) then
  begin
    CollectPath(iByte,pockCount);
  end;

  //количество видимых спутников
  if pockCount=18 then
  begin
    CollectVisSetellites(iByte);
  end;

  //количество спутников в решении
  if pockCount=19 then
  begin
    CollectDecisSetellites(iByte);
  end;

  //слово состояния 0-нет решения, 1-есть решение
  if pockCount=20 then
  begin
    CollectDecision(iByte);
  end;

  //колибровка +5В
  {if pockCount=22 then
  begin
    CollectColibP5(iByte);
  end;}
end;
//==============================================================================

//==============================================================================
//Процедура по разбору пакета СКРУТЖТ. Передается количество пакетов.
//==============================================================================
procedure ParsePocket(numberOfPocket:word;var bool:boolean);
var
  i:integer;
  iByte:integer;
  //счетчик СКРУТЖТ
  countSCRUTJT:byte;//0..255
  //медленный параметр
  //slowParamSCRUTJ:word;
  //strPocket:string;
begin
  i:=1;
  //для переключения между файлами
  if (bool) then
  begin
    bool:=false;
    form1.TrackBar1.Position:=1;
  end;

  //последовательно обрабатываем пакеты
  while i<=numberOfPocket do
  begin
    try
      //читаем из файла 26 байт, 1 пакет
      Stream.Read(pocketSCRUTJT, SizeOf(pocketSCRUTJT));
      //первый байт счетчик пакета
      //счетчик пакета(слово).Собираем его.
      iByte:=1;
      countSCRUTJT:=CollectCounter(iByte);
      iByte:=2;
      //Вывод быстрых параметров на Диаграмму и вывод на график
      //1-24 быстрых по 1 байту
      OutToDiaAndGist(iByte);
      //собираем медленные параметры
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
      //проверяем  дошли ли до конца файла. Дошли значит заканчиваем работу с файлом
      if  stream.Position>=stream.Size then
      begin
        form1.Timer1.Enabled:=false;
        //проверяем не конец ли записи
        if fileIndex<length(SCRUTfileArr)-1 then
        begin
          stream.Free;
          //wait(5);
          inc(fileIndex);
          openFileForIndex(fileIndex);
          //переключаем номер файла в трекбаре номеров
          form1.FileNumTrack.Position:=form1.FileNumTrack.Position+form1.FileNumTrack.PageSize;
          form1.TrackBar1.Position:=1;
        end
        else
        begin
          //конец
          //последний файл не освобождаем
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
  //размерность переданного массива.
  arrSize:integer;
  //половина размера массива
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
  //строка с адресом выбранного каталога  с файлами скрута
  folderStr:string;
begin
  fileIndex:=0;
  //form1.FileNumTrack.Enabled:=true;
  //form1.TrackBar1.Enabled:=true;
  Form1.TrackBar1.Enabled:=False;
  Form1.FileNumTrack.Enabled:=False;
  Form1.TrackBar2.Enabled:=False;
  if SelectDirectory('Выберите каталог в котором лежат файлы-записи ИРУТ','\',folderStr) then
  begin
    //передаем функции полное имя выбранного каталога
    //формируем дин. массив с полными путями до файлов СКРУТЖТ соотв. заданной маске
    if FillFileArray(folderStr,SCRUTfileArr,allRecordSize) then
    begin
      //подготовка трекбара номера файла
      form1.FileNumTrack.Max:=length(SCRUTfileArr);
      form1.FileNumTrack.Min:=1;
      form1.FileNumTrack.Position:=1;
      //связываем с первым файлом массива
      openFileForIndex(fileIndex);
      //считаем коэф. масштабирования относительно текущего открытого файла
      trackSizeKoef:=trunc(stream.Size/POCKETSIZE/400000)+1;
      //масштабируем Трекбар
      form1.TrackBar1.Max:=trunc(stream.Size/POCKETSIZE/trackSizeKoef);
      //нач.скорость работы
      numPocketSp:=RTPOCKETNUM;
      ShowMessage('Выберите файл конфигурации!');
      while (true) do
      begin
        //выбрать файл конфигурации
        if form1.OpenDialog1.Execute then
        begin
          //доступность кнопки старта для работы дальше
          form1.StartButton.Enabled:=true;
          form1.changeFile.Enabled:=false;
          form1.Button4.Enabled:=true;
          //делаем текущий каталог каталогом по умолчанию
          form1.OpenDialog1.InitialDir := GetCurrentDir;
          //фильтр на выбор только типа ини
          form1.OpenDialog1.Filter :='INI|*.ini';
          //параметры конфигурации
          WriteConfParam(form1.OpenDialog1.FileName);
          //заполнение таблицы коэфициентов синусов и косинусов
          FillSinCosTables;
          break;
        end
        else
        begin
          ShowMessage('Ошибка! Файл конфигураций не выбран!');
          break;
        end;
      end;
    end
    else
    begin
      ShowMessage('Ошибка заполнения списка файлов ИРУТ');
      exit;
    end;
  end
  else
  begin
    ShowMessage('Каталог не выбран!');
  end;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  //каждый проход таймера разбираем переданное колич пакетов
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
  form1.Timer1.Enabled:=true;//начало разбора
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
  //обнуление потока работы с файлом
  stream:=nil;
  //доступность кнопок
  form1.changeFile.Enabled:=true;
  form1.StartButton.Enabled:=false;
  form1.StopButton.Enabled:=false;
  form1.Button4.Enabled:=false;
  form1.FileNumTrack.Enabled:=false;
  form1.TrackBar1.Enabled:=false;
  //инициализация счетчика для масштабирования трекбара
  countTrack:=1;
  changeFileFlag:=true;
  graphFlag:=false;
  iGist:=0;
  chanelIndex:=0;
  //countPointInSpArr:=1;//счетчик для заполнения массива спектра
  //присваиваем разделитель целой и вещетвенной части числа точка.
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
  //контролируем выход за пределы конца файла
  CheckToFileEnd;
  //доступность кнопки останова разбора. Для случая когда ПО дойдет до конца файла
  form1.StopButton.Enabled:=true;
  form1.Timer1.Enabled:=false;
  //внесено изменение в позиции трекбара файла для правильонй выборки из файла
  stream.Position:=(form1.TrackBar1.Position-1)*POCKETSIZE*trackSizeKoef;
  form1.Timer1.Enabled:=true;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Stream.Free;
  //проверяем запущен ли excel
  if (CheckExcelRun) then
  begin
    //запущен, вырубаем
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
  //освободили предидущий выполняемый поток
  stream.Free;
  //очищаем графики для более красивого перехода по файлам.
  form1.Chart1.Series[0].Clear;
  form1.Chart2.Series[0].Clear;
  //подготовка переменных для переключения
  countTrack:=1;
  iGist:=0;
  //связываем с выбранным файлом
  fileIndex:=form1.FileNumTrack.Position-1;
  openFileForIndex(fileIndex);
  //считаем коэф. масштабирования относительно текущего открытого файла
  trackSizeKoef:=trunc(stream.Size/POCKETSIZE/400000)+1;
  //масштабируем Трекбар
  form1.TrackBar1.Max:=trunc(stream.Size/POCKETSIZE/trackSizeKoef);
  changeFileFlag:=true;
  form1.Timer1.Enabled:=true;//запуск таймера
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  //сброс флагов завершения работы потока
  skoCompl:=false;
  gistCompl:=false;
  logCompl:=False;
  //сброс 
  Form1.gProgress1.Progress:=0;
  Form1.StartButton.Enabled:=False;
  Form1.StopButton.Enabled:=False;
  //записываем текущую дату и время.
  dateTimeBeg:=Now;
  //покажем форму с выбором проверок
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
    //выключили таймер для завершения нужного потока
    Form1.tmr1.Enabled:=False;
    //Form1.Memo1.Lines.Add('Общий поток СКО завершен!');

    Form1.StartButton.Enabled:=true;
    Form1.StopButton.Enabled:=true;
    //Form1.gProgress1.Progress:=100;
    //проверки завершены
    //ShowMessage('Обработка завершена!');
    //обработали все файлы в рамках проверки
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
    //выключили таймер для завершения нужного потока
    Form1.tmr2.Enabled:=False;
    //Form1.Memo1.Lines.Add('Общий поток GIST завершен!');
    //запуск потока после завершения гистограммы
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
      //проверки завершены
      ShowMessage('Обработка завершена!');
      //сброс
      Form1.gProgress1.Progress:=0;
    end;
    //выключение таймера
    Form1.tmrEnd3.Enabled:=False;
  end;
end;

end.

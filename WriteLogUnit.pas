unit WriteLogUnit;

interface
uses
Classes, SysUtils, Dialogs, DateUtils, Forms,ConstUnit, ExcelWorkUnit;
const
  ExcelApp = 'Excel.Application';
type
//поток для записи
TThreadWriteLog = class(TThread)
  private
    { Private declarations }
  protected
    procedure Execute; override;
end;

//тип потока для обработки одного массива канала в блоке
{TProcess=class(TThread)
private
  //с какого массива начинать обработку
  indBeg:integer;
  //сколько массивов надо обрабатывать
  numArr:integer;
  //номер процесса
  prNum:integer;
  //колич. обр точек в массиве
  numP:integer;
  //writeNBlock:boolean;
  //обработка 1 буфера
  procedure ParseBuf(arrNum:integer;numValInFfileBufer:integer);
  //вывод 1 буфера
  //procedure WriteBuf(arrNum:Integer;endBlockFlag:boolean);
protected
  procedure Execute; override;
public
  property ind: integer read indBeg write indBeg;
  property countArr: integer read numArr write numArr;
  property processNum:integer read prNum write prNum;
  property numPoint:integer read numP write numP;
end;}


TProc=array [1..PROC_VAL_NUM] of {word}{byte}real;

var
  //поток для параллельной работы
  thWriteLog: TThreadWriteLog;
  //счетчик кадра
  kadrCount:integer;
  //текстовый файл вывода
  fileF:text;
  //переменная для хранения текущего времени
  timeCount:int64;
  //счетчик блоков
  blockCount:cardinal;
  //массив процессов
  //thLogArr:array[1..PROC_NUM] of TProcess;
  //максимальное значение за блок
  maxVal:{word}real=0;
  iBlock:integer;
  //массив буферов значений для каждого файла
  procArray:array [1..MAX_CH_COUNT] of TProc;
  //колибровочные массивы
  arrKolibP5V:array [1..MAX_COLIB_P] of Byte;
  iKP5V:Cardinal=1;
  arrKolibM5V:array [1..MAX_COLIB_P] of Byte;
  iKM5V:Cardinal=1;
  arrkolib0V:array [1..MAX_COLIB_P] of Byte;
  iK0V:Cardinal=1;
  arrKolib4mA:array [1..MAX_COLIB_P] of Byte;
  iK4mA:Cardinal=1;
  arrKolib20mA:array [1..MAX_COLIB_P] of Byte;
  iK20mA:Cardinal=1;

   //time
  timeGeosArrTh :array [1..4] of byte;
  //latitude
  latArrTh :array [1..4] of byte;
  //longtitude
  lonArrTh:array [1..4] of byte;
  //speed
  speedArrTh:array [1..2] of byte;

  //колибровки для быстрых
  kolibP5V:byte;
  kolibM5V:byte;
  kolib0V:byte;

  //колибровки для медленных
  kolib20mA:byte;
  kolib4mA:byte;
  //массив флагов завершенности процессов обработки
  arrComplProc:array[1..COMPL_PROC_NUM] of boolean;

  //массив содержимого текущего пакета
  pocket:array[1..POCKETSIZE]  of byte;

  buff:array [1..BUFF_NUM] of byte;

  startFlagFast:boolean;

  flagConq:Boolean;

  //флаг для сбора времени начала блока
  blockFlag:Boolean=true;

  //время блока
  blockTimeTh:string;
  minSpeedTh:integer=-5;
  maxSpeedTh:integer=-5;
  latStrTh:string;
  lonStrTh:string;

  fileName:string;


  //счетчик записанных колон
  colCount:Integer;
  //счетчик записанных рядов
  rowCount:Integer;

implementation
uses
Unit1,WriteGistUnit,TestChUnit;

//==============================================================================
//Функция перевода быстрых в вольты
//==============================================================================
function getColibValF(kodVal:{byte}real;kP:byte;kM:byte):real;
begin
 //10 это размах от -5 до 5
 Result:=((kodVal-kM)/(kP-kM))*10-5;
end;
//==============================================================================

//==============================================================================
//Функция перевода быстрых из вольт в м/c2
//==============================================================================
function getAcs(volt:double;kP:double;kM:double;diap:double):real;
begin
 //abs(diap*2) это размах от -5В до 5В
 Result:=((volt-kM)/(kP-kM))*abs(diap*2)+diap;
end;
//==============================================================================

//==============================================================================
//Функция перевода медленных в мА
//==============================================================================
function getColibValS(kodVal:{byte}real;k20mA:byte;k4mA:byte):real;
begin
  //16 это размах 20-4
  Result:=((kodVal-k4mA)/(k20mA-k4mA))*16+4;
end;
//==============================================================================

//==============================================================================
//Функция перевода медленных с градусы
//==============================================================================
function getT(kodVal:{byte}real;kP:integer;kM:integer):real;
begin
 //150 это размах от -40 до 110
 Result:=((kodVal-kM)/(kP-kM))*{10}150-{5}40;
end;
//==============================================================================

//==============================================================================
//Функция перевода медленных в проценты влажности
//==============================================================================
function getV(kodVal:{byte}real;kP:integer;kM:integer):real;
begin
 //10 это размах от 0 до 100
 Result:=((kodVal-kM)/(kP-kM))*100;
end;
//==============================================================================

//==============================================================================
//Функция перевода медленных в давление
//==============================================================================
function getP(kodVal:{byte}real;kP:integer;kM:integer):real;
begin
 //2496 это размах от 4 до 2496
 Result:=((kodVal-kM)/(kP-kM))*2496+4;
end;
//==============================================================================

//==============================================================================
//
//==============================================================================
procedure WriteFast(iPos:integer);
var
 i:integer;
begin
  i:=1;
  while i<=MAX_CH_COUNT_FAST do
  begin
    //проверяем подключен ли канал, если нет заполняем его значения нулями
    if (arrEnableChanals[i].enabled) then
    begin
      //проверяем нашли калибровки +5 -5 или нет
      //if (startFlagFast)then
      //begin
        //procArray[i][iPos]:=getColibValF(pocket[i+1],kolibP5V,kolibM5V);
      //end
      //else
      //begin
        procArray[i][iPos]:=pocket[i+1{2}];
      //end;
    end
    else
    begin
      //procArray[i][iPos]:=0.0;
    end;
    inc(i);
  end;
end;

//==============================================================================

//==============================================================================
//Функция для сбора счетчика пакета. Передается номер младшего байта. Вернет счетчик
//==============================================================================
function CollectCounterTh(iByteDj:integer):byte;
begin
  result:=pocket[iByteDj];
end;
//==============================================================================

//==============================================================================
//Собираем значение времени
//==============================================================================
function CollectTimeTh(iB:integer;count:byte):string;
var
  timeGEOS_int:Int64;
  dT:TDateTime;
  dtStr:string;
  timeGEOS:cardinal;
begin
  if count=3 then
  begin
    timeGeosArrTh[4]:=pocket[iB];
    timeGEOS:=(timeGeosArrTh[1] shl 24)+(timeGeosArrTh[2] shl 16)+(timeGeosArrTh[3] shl 8)+
    timeGeosArrTh[4];
    //приводим время ГЕОС в UnixTime
    timeGEOS_int:=timeGEOS+1199145600{+14400};
    //приводим к формату dateTime
    dT:=UnixToDateTime(timeGEOS_int);
    //приводим время к строке
    DateTimeToString(dtStr,'dd.mm.yyyy hh:mm:ss',dT);
    //вывод времени
    //form1.timeLabel.Caption:=dtStr;
    result:=dtStr;
  end
  else
  begin
    case count of
      0:
      begin
        timeGeosArrTh[1]:=pocket[iB];
      end;
      1:
      begin
        timeGeosArrTh[2]:=pocket[iB];
      end;
      2:
      begin
        timeGeosArrTh[3]:=pocket[iB];
      end;
    end;
    result:='nil';
  end;
end;
//==============================================================================

//==============================================================================
//Собираем значение широты
//==============================================================================
function CollectLatitudeTh(iB:integer;count:byte):string;
var
  gradLat,minLat,secLat :real;
  lat:double;
  latStr:string;
begin
  if count=7 then
  begin
    latArrTh[4]:=pocket[iB];
    lat:=(latArrTh[1] shl 24)+(latArrTh[2] shl 16)+(latArrTh[3] shl 8)+
    latArrTh[4];
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
    latStr:=floatToStr(gradLat)+'° '+floatToStr(minLat)+''' '+floatToStr(secLat)+'"';
    //form1.LabelLat.Caption:=latStr;
    result:=latStr;
  end
  else
  begin
     case count of
      4:
      begin
        latArrTh[1]:=pocket[iB];
      end;
      5:
      begin
        latArrTh[2]:=pocket[iB];
      end;
      6:
      begin
        latArrTh[3]:=pocket[iB];
      end;
     end;
     result:='nil';
  end;
end;
//==============================================================================

//==============================================================================
//Собираем значение долготы
//==============================================================================
function CollectLongtitudeTh(iB:integer;count:byte):string;
var
  lon :double;
  //pLon :^double;
  gradLon,minLon,secLon :real;
  lonStr:string;
begin
  if count=11 then
  begin
    lonArrTh[4]:=pocket[iB];
    lon:=(lonArrTh[1] shl 24)+(lonArrTh[2] shl 16)+(lonArrTh[3] shl 8)+
    lonArrTh[4];
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
    lonStr:=floatToStr(gradLon)+'° '+floatToStr(minLon)+''' '+floatToStr(secLon)+'"';
    //form1.LabelLon.Caption:=lonStr;
    result:=lonStr;
  end
  else
  begin
    case count of
      8:
      begin
        lonArrTh[1]:=pocket[iB];
      end;
      9:
      begin
        lonArrTh[2]:=pocket[iB];
      end;
      10:
      begin
        lonArrTh[3]:=pocket[iB];
      end;
    end;
    result:='nil';
  end;
end;
//==============================================================================

//==============================================================================
//Собираем скорость
//==============================================================================
function CollectSpeedTh(iB:integer;count:byte):string;
var
  speed:word;
begin
  if count=15 then
  begin
    speedArrTh[2]:=pocket[iB];
    speed:=(speedArrTh[1] shl 8)+ speedArrTh[2];
    result:=intToStr(speed);
    //form1.Label12.Caption:=intToStr(speed);
  end
  else
  begin
    case count of
       14:
       begin
        speedArrTh[1]:=pocket[iB];
       end;
    end;
    result:='nil';
  end;
end;
//==============================================================================

//==============================================================================
//Функция проверяет содержит ли пакет нужный параметр.
//передается номер канала и номер текущего пришедшего пакета
//==============================================================================
function testCh(chNumber:integer;currentPocketNum:integer):boolean;
var
  //шаг разбора
  step:integer;
  //начальный номер счетчика пакета, параметр зависит от номера канала
  begPocketNum:integer;
  //конечный счетчик номера пакета
  endPocketNum:integer;
  i:integer;
  bool:boolean;

begin
  begPocketNum:=0;
  endPocketNum:=0;
  bool:=false;
  step:=8;
  case chNumber of
    1:
    begin
      //1 канал
      begPocketNum:=26;
      endPocketNum:=186;
    end;
    2:
    begin
      begPocketNum:=27;
      endPocketNum:=187;
    end;
    3:
    begin
      begPocketNum:=28;
      endPocketNum:=188;
    end;
    4:
    begin
      begPocketNum:=29;
      endPocketNum:=189;
    end;
    5:
    begin
      begPocketNum:=30;
      endPocketNum:=190;
    end;
    6:
    begin
      //6 канал
      begPocketNum:=31;
      endPocketNum:=191;
    end;
    //калиб. 20мА
    7:
    begin
      begPocketNum:=32;
      endPocketNum:=192;
    end;
    //калиб. 4мА
    8:
    begin
      //6 канал
      begPocketNum:=33;
      endPocketNum:=193;
    end;

    //колибровка +5В
    22:
    begin
      begPocketNum:=22;
      endPocketNum:=22;
    end;
     //колибровка -5В
    23:
    begin
      begPocketNum:=23;
      endPocketNum:=23;
    end;
     //колибровка 0В
    24:
    begin
      begPocketNum:=24;
      endPocketNum:=24;
    end;
  end;
  //устанавливаем номер первого пакета для переданного номера канала
  i:=begPocketNum;
  //перебираем все возможные номера для переданного канала
  while i<=endPocketNum do
  begin
    //ищем текущий пакет среди всех возможных
    if i=currentPocketNum then
    begin
      //нашли и вышли
      bool:=true;
      break;
    end;
    i:=i+step;
  end;
  result:=bool;
end;
//==============================================================================

//==============================================================================
//Разбор пакета ИРУТ по буферам файлов-каналов
//==============================================================================
procedure ParsePocketToSignalBlocks(iPosInBuf:integer);
var
  i:integer;
  j:integer;
  //iWrite:integer;
  //номер текущего пакета
  counter:byte;

  time:string;
  lat:string;
  lon:string;
  speed:string;
  speedI:integer;
begin
  //получим номер пакета
  counter:=CollectCounterTh(1);

  //время
  if ((counter>=0) and (counter<=3)) then
  begin
    time:=CollectTimeTh(length(pocket),counter);
    if time<>'nil' then
    begin
      if (blockFlag) then
      begin
        blockTimeTh:=time;
        blockFlag:=False;
      end;
    end;
  end;

  //широта
  if ((counter>=4) and (counter<=7)) then
  begin
    lat:=CollectLatitudeTh(length(pocket),counter);
    if lat<>'nil' then
    begin
      latStrTh:=lat;
    end;
  end;

  //долгота
  if ((counter>=8) and (counter<=11)) then
  begin
    lon:=CollectLongtitudeTh(length(pocket),counter);
    if lon<>'nil' then
    begin
      lonStrTh:=lon;
    end;
  end;

  //скорость
  if ((counter>=14) and (counter<=15)) then
  begin
    speed:=CollectSpeedTh(length(pocket),counter);
    if speed<>'nil' then
    begin
      speedI:=StrToInt(speed);
      if ((minSpeedTh=-5) and (maxSpeedTh=-5)) then
      begin
        //первый сбор скорости за блок
        minSpeedTh:=speedI;
        maxSpeedTh:=speedI;
      end
      else
      begin
        //max
        if maxSpeedTh<=speedI then
        begin
          maxSpeedTh:=speedI;
        end;
        //min
        if minSpeedTh>=speedI then
        begin
          minSpeedTh:=speedI;
        end;
      end;
    end;
  end;


  //проверяем что пришел пакет с калибровкой +5В
  if (testCh(NUM_P_P5V,counter)) then
  begin
    //+5В
    kolibP5V:=pocket[length(pocket)];
    arrKolibP5V[iKP5V]:=kolibP5V;
    Inc(iKP5V);
  end;

  //проверяем что пришел пакет с калибровкой -5В
  if (testCh(NUM_P_M5V,counter)) then
  begin
    //-5В
    kolibM5V:=pocket[length(pocket)];
    arrkolibM5V[iKM5V]:=kolibM5V;
    Inc(iKM5V);
  end;

  //проверяем что пришел пакет с калибровкой 0В
  if (testCh(NUM_P_0V,counter)) then
  begin
    //0 В
    kolib0V:=pocket[length(pocket)];
    arrkolib0V[iK0V]:=kolib0V;
    Inc(iK0V);
  end;

  //=====
  //заполнение медленных параметров
  //канал1
  if (testCh(1,counter)) then
  begin
    slowArray[1][iSlowArray]:=pocket[length(pocket)];
  end;
  //канал2
  if (testCh(2,counter)) then
  begin
    slowArray[2][iSlowArray]:=pocket[length(pocket)];
  end;
  //канал3
  if (testCh(3,counter)) then
  begin
    slowArray[3][iSlowArray]:=pocket[length(pocket)];
  end;
  //канал4
  if (testCh(4,counter)) then
  begin
    slowArray[4][iSlowArray]:=pocket[length(pocket)];
  end;
  //канал5
  if (testCh(5,counter)) then
  begin
    slowArray[5][iSlowArray]:=pocket[length(pocket)];
  end;
  //канал6
  if (testCh(6,counter)) then
  begin
    slowArray[6][iSlowArray]:=pocket[length(pocket)];
    inc(iSlowArray);
  end;
  //проверяем,что пришел пакет с калиб. 20мА
  if (testCh(7,counter)) then
  begin
    kolib20mA:=pocket[length(pocket)];
  end;
  //проверяем что пришел пакет с калиб. 4мА
  if (testCh(8,counter)) then
  begin
    kolib4mA:=pocket[length(pocket)];
    //переводим медленные в мА
    for i:=1 to 6 do
    begin
      for j:=iSlowArrayOld to iSlowArray-1 do
      begin
        slowArray[i][j]:=getColibValS(slowArray[i][j],kolib20mA,kolib4mA);
        //проверяем какой это параметр Т,V,P
        {if slowHelpArr[i]='T' then
        begin
          //град
          slowArray[i][j]:=getT(slowArray[i][j],110,-40);
        end;
        if slowHelpArr[i]='V' then
        begin
          //%
          slowArray[i][j]:=getV(slowArray[i][j],100,0);
        end;
        if slowHelpArr[i]='P' then
        begin
          //кПа
          slowArray[i][j]:=getP(slowArray[i][j],2500,4);
        end;}

      end;
    end;
    iSlowArrayOld:=iSlowArray;
    //startFlagSlow:=true;
  end;
  //======

  //запись быстрых
  WriteFast(iPosInBuf);

  //запись медленных
  //WriteSlow(25,iPosInBuf,counter);
end;
//==============================================================================

//==============================================================================
//Формирование пакета данных ИРУТ для дальнейшего разбора
//==============================================================================
procedure SetDateToPocket(iPock:integer);
var
  i:integer;
  j:integer;
begin
  //перепишем данные в пакет
  i:=1;
  j:=iPock;
  while i<=POCKETSIZE do
  begin
    pocket[i]:=buff[j];
    inc(i);
    inc(j);
  end;
end;
//==============================================================================

//==============================================================================
//Процедура разбора одного канала-блока
//==============================================================================
{procedure TProcess.ParseBuf(arrNum:integer;numValInFfileBufer:integer);
var
  fileBufCount:integer;
  //сформированная записываемая строка
  writeStr:string;
  maxValNum:Integer;
begin
  //arrNum-количество каналов
  //g
  if arrNum<=FILE_NUM_LOG then
  begin
    //проверяем подключен ли канал, если нет то и не проверяем его, там нули
    if (arrEnableChanals[arrNum].enabled) then
    begin
      //разбор файла поэлементно
      fileBufCount:=1;
      while fileBufCount<=numValInFfileBufer do
      begin
        if fileBufCount=1 then
        begin
          maxVal:=procArray[arrNum][fileBufCount];
        end
        else
        begin
          if maxVal<procArray[arrNum][fileBufCount] then
          begin
            maxVal:=procArray[arrNum][fileBufCount];
            maxValNum:=fileBufCount;
          end;
        end;
        inc(fileBufCount);
      end;

      //получили максимальное значение в кодах
      //перед выводом преобраз его к физ величине
      if (arrNum>=1)and(arrNum<=24) then
      begin
        //Form1.mmo1.Lines.Add('ddddd');
        //быстрый параметр
        maxVal:=getColibValF(maxVal,arrKolibP5V[trunc(maxValNum/224)+1],
          arrkolibM5V[trunc(maxValNum/224)+1]);

        maxVal:=getAcs(maxVal,5,-5,arrEnableChanals[arrNum].begRange);
      end;
      //формируем строку для вывода
      writeStr:=#9+floatToStrF(maxVal,ffFixed,3,3);
      //выведем содержимое максимума текущего проверяемого канала
      write(fileF,writeStr);
    end;
  end;
  arrComplProc[arrNum]:=true;
end; }
//==============================================================================

//==============================================================================
//
//==============================================================================
{procedure TProcess.Execute;
var
  i:integer;
begin
  i:=indBeg;
  while (i<=(numArr+(indBeg-1))) do
  begin
    ParseBuf(i,numP);
    inc(i);
  end
end; }
//==============================================================================

//==============================================================================
//Предварительное заполнение файла до разбора
//==============================================================================
procedure PreWriteLogFile;
var
  i:integer;

  slowN:integer;


begin
  colCount:=1;
  rowCount:=1;
  slowN:=1;
  //формируем имя файла
  fileName:=ExtractFileDir(ParamStr(0))+'\Report'+'\log\'+'Log'+'.xls'; // xlsx

  //подготовка к работе с excel запуск
  RunExcel(True,false);
  //добавление рабочей книги
  AddWorkBook(True);
  //активация листа рабочей книги
  //1 это первая рабочая книга, а Лист1 это ее название
  //ActivateSheet(1,'Лист1');

  SetCellValue(MyExcel,'№кадра',rowCount,colCount);
  Inc(colCount);
  SetCellValue(MyExcel,'Дата и время начала блока',rowCount,colCount);
  Inc(colCount);
  SetCellValue(MyExcel,'Средняя скорость',rowCount,colCount);
  Inc(colCount);
  SetCellValue(MyExcel,'Мин. скорость',rowCount,colCount);
  Inc(colCount);
  SetCellValue(MyExcel,'Макс. скорость',rowCount,colCount);
  Inc(colCount);
  SetCellValue(MyExcel,'Широта',rowCount,colCount);
  Inc(colCount);
  SetCellValue(MyExcel,'Долгота',rowCount,colCount);
  Inc(colCount);
  //связали дял записи
  {AssignFile(fileF,fileName);
  Rewrite(fileF);
  write(fileF,'№кадра':20);
  write(fileF,#9+'Дата и время начала блока':40);
  write(fileF,#9+'Средняя скорость':40);
  write(fileF,#9+'Мин. скорость':40);
  write(fileF,#9+'Макс. скорость':40);
  write(fileF,#9+'Широта':40);
  write(fileF,#9+'Долгота':40);}


  //для быстрых и медленных
  for i:=1 to MAX_CH_COUNT do
  begin
    // включен ли канал
    if  (arrEnableChanals[i].enabled) then
    begin
      //быстрый?
      if arrEnableChanals[i].typeS='fast' then
      begin
        SetCellValue(MyExcel,'БП'+intToStr(i)+',м/c2',rowCount,colCount);
        //write(fileF,#9+'БП'+intToStr(i)+',м/c2':10);

        //form1.Memo1.Lines.Add('+ '+'fast '+intToStr(i));
      end;
       //медленный?
      if ((arrEnableChanals[i].typeS='slowTV')or
          (arrEnableChanals[i].typeS='slowP')) then
      begin
        if slowHelpArr[slowN]='T' then
        begin
          //температурный параметр
          SetCellValue(MyExcel,'МП'+intToStr(slowN)+',°',rowCount,colCount);
          //write(fileF,#9+'МП'+intToStr(slowN)+',°':10);
        end;

        if slowHelpArr[slowN]='V' then
        begin
          //влажностный параметр
          SetCellValue(MyExcel,'МП'+intToStr(slowN)+',%',rowCount,colCount);
          //write(fileF,#9+'МП'+intToStr(slowN)+',%':10);
        end;

        if slowHelpArr[slowN]='P' then
        begin
          //параметр давления
          SetCellValue(MyExcel,'МП'+intToStr(slowN)+',кПа',rowCount,colCount);
          //write(fileF,#9+'МП'+intToStr(slowN)+',кПа':10);
        end;



        {if arrEnableChanals[i].slowParT<>0 then
        begin
          //температурный параметр
          write(fileF,#9+'МП'+intToStr(slowN)+',°':10);
        end;
        if arrEnableChanals[i].slowParV<>0 then
        begin
          //влажностный параметр
          write(fileF,#9+'МП'+intToStr(slowN)+',%':10);
        end;
        if arrEnableChanals[i].slowParP<>0 then
        begin
          //параметр давления
          write(fileF,#9+'МП'+intToStr(slowN)+',кПа':10);
        end;}
         inc(slowN);
      end;
      //если параметр активен
      //перещелкиваем счетчик на новыю ячейку для записи
      Inc(colCount);
    end;
  end;
  //MyExcel.Visible:=true;
  //переключаемся при дальнейшей записи на след строку
  inc(rowCount);
  colCount:=1;
  //writeln(fileF,'');
end;
//==============================================================================

//==============================================================================
//
//==============================================================================
function GetNumber(numPar1:Integer;numPar2:Integer;numPar3:Integer):Integer;
var
  num:Integer;
begin
  if numPar1<>0 then
  begin
    num:=numPar1;
  end
  else if numPar2<>0 then
  begin
    num:=numPar2;
  end
  else if numPar3<>0 then
  begin
    num:=numPar3;
  end;

  if (num=6)or(num=5) then
  begin
    Dec(num);
  end;

  Result:=num;
end;
//==============================================================================

//==============================================================================
//Разбираем файловые буферы
//==============================================================================
procedure ParseFileBuffer(numValInFfileBufer:integer;flagWriteNumBlock:boolean);
var
  //сколько массивов обрабатывает процесс
  arrCount:integer;
  //номер массива с которого процесс должен обрабатывать
  iProcess:integer;
  //счетчик заполнения процессных структур
  //count:integer;
  //счетчик перебора массива индикаторов выполненных процессов
  i:integer;
  //iProc:integer;
  writeStr:string;
  //minSpeed:integer;
  //maxSpeed:integer;
  avSpeed:integer;
  //latStr:string;
  //lonStr:string;
  bool:Boolean;
  //счетчик канала
  iChannal:Integer;
  channalCurrentVal:integer;
  maxValNum:integer;

  //номер для правильной выборки из массива
  numberTr:Integer;

  count:Integer;
begin
  //посчитаем среднюю скорость
  avSpeed:= round((minSpeedTh+maxSpeedTh)/2);

  //выведем основныю инф. по блоку в строку
  //writeStr:=floatToStr(kadrCount)+#9+{dtStr}blockTimeTh+#9+IntToStr(avSpeed)+#9+
    //IntToStr(minSpeedTh)+#9+IntToStr(maxSpeedTh)+#9+latStrTh+#9+lonStrTh;

  SetCellValue(MyExcel,floatToStr(kadrCount),rowCount,colCount);
  Inc(colCount);
  SetCellValue(MyExcel,blockTimeTh,rowCount,colCount);
  Inc(colCount);
  SetCellValue(MyExcel,IntToStr(avSpeed),rowCount,colCount);
  Inc(colCount);
  SetCellValue(MyExcel,IntToStr(minSpeedTh),rowCount,colCount);
  Inc(colCount);
  SetCellValue(MyExcel,IntToStr(maxSpeedTh),rowCount,colCount);
  Inc(colCount);
  SetCellValue(MyExcel,latStrTh,rowCount,colCount);
  Inc(colCount);
  SetCellValue(MyExcel,lonStrTh,rowCount,colCount);
  Inc(colCount);

  blockFlag:=true;
  minSpeedTh:=-5;
  maxSpeedTh:=-5;

  //write(fileF,writeStr);

  //Обработка в одном потоке
  //обработка быстрых
  for iChannal:=1 to MAX_CH_COUNT_FAST do
  begin
    //проверяем подключен ли канал, если нет то и не проверяем его, там нули
    if (arrEnableChanals[iChannal].enabled) then
    begin
      //разбор файла поэлементно
      channalCurrentVal:=1;
      while channalCurrentVal<=numValInFfileBufer do
      begin
        if channalCurrentVal=1 then
        begin
          maxVal:=procArray[iChannal][channalCurrentVal];
        end
        else
        begin
          if maxVal<procArray[iChannal][channalCurrentVal] then
          begin
            maxVal:=procArray[iChannal][channalCurrentVal];
            //запоминаем номер пакета с макс. уровнем
            maxValNum:=channalCurrentVal;
          end;
        end;
        inc(channalCurrentVal);
      end;
      //получили максимальное значение в кодах
      //перед выводом преобраз его к физ величине
      if (iChannal>=1)and(iChannal<=24) then
      begin
        //быстрый параметр
        maxVal:=getColibValF(maxVal,arrKolibP5V[trunc(maxValNum/224)+1],
          arrkolibM5V[trunc(maxValNum/224)+1]);
        maxVal:=getAcs(maxVal,5,-5,arrEnableChanals[iChannal].begRange);


      end;

      //формируем строку для вывода
      //writeStr:=#9+floatToStrF(maxVal,ffFixed,3,3);
       //выведем содержимое максимума текущего проверяемого канала
      //write(fileF,writeStr);

      SetCellValue(MyExcel,floatToStrF(maxVal,ffFixed,3,3),rowCount,colCount);
      if maxVal*100>arrEnableChanals[iChannal].maxUserVal*100 then
      begin
        //если значение максимума канала превышает пользовательское значение максимума
        //за блок то заполняем ячейку красным цветом
        SetCellColor(MyExcel,3,rowCount,colCount);
      end;

      if maxVal*100<arrEnableChanals[iChannal].minUserVal*100 then
      begin
        //меньше минимума
        SetCellColor(MyExcel,3,rowCount,colCount);
      end;


      Inc(colCount);

      // form1.Memo1.Lines.Add('Канал '+intToStr(iChannal)+' Обработан!');
    end;
  end;

  count:=1;

  //обработка медленных 6 каналов
  for iChannal:=1 to MAX_CH_COUNT_SLOW+1 do
  begin
     if (arrEnableChanals[iChannal+MAX_CH_COUNT_FAST].enabled) then
     begin
        channalCurrentVal:=1;
        while channalCurrentVal<=iSlowArray-3 do ///!!!
        begin
          if channalCurrentVal=1 then
          begin
            maxVal:=slowArray[iChannal][channalCurrentVal];
          end
          else
          begin
            if maxVal<slowArray[iChannal][channalCurrentVal] then
            begin
              maxVal:=slowArray[iChannal][channalCurrentVal];
              //запоминаем номер пакета с макс. уровнем
              maxValNum:=channalCurrentVal;
            end;
          end;
          inc(channalCurrentVal);
        end;

        
        //проверяем какой это параметр Т,V,P
        if slowHelpArr[{iChannal}count]='T' then
        begin
          //град
          maxVal:=getT(maxVal,{110}20,{-40}4);
        end;
        if slowHelpArr[{iChannal}count]='V' then
        begin
          //%
          maxVal:=getV(maxVal,{100}20,4{0});
        end;
        if slowHelpArr[{iChannal}count]='P' then
        begin
          //кПа
          maxVal:=getP(maxVal,{2500}20,4{4});
        end;

        inc(count);

        //формируем строку для вывода
        //writeStr:=#9+floatToStrF(maxVal,ffFixed,5,3);
        //выведем содержимое максимума текущего проверяемого канала
        //write(fileF,writeStr);
        SetCellValue(MyExcel,floatToStrF(maxVal,ffFixed,5,3),rowCount,colCount);

        numberTr:=GetNumber(arrEnableChanals[iChannal+MAX_CH_COUNT_FAST].slowParT,
                            arrEnableChanals[iChannal+MAX_CH_COUNT_FAST].slowParV,
                            arrEnableChanals[iChannal+MAX_CH_COUNT_FAST].slowParP);


        if  (iChannal+MAX_CH_COUNT_FAST)<30 then
        begin
          if maxVal*100>arrEnableChanals[{iChannal}numberTr+MAX_CH_COUNT_FAST].maxUserVal*100 then
          begin
            //если значение максимума канала превышает пользовательское значение максимума
            //за блок то заполняем ячейку красным цветом
            SetCellColor(MyExcel,3,rowCount,colCount);
          end;

          if maxVal*100<arrEnableChanals[{iChannal}numberTr+MAX_CH_COUNT_FAST].minUserVal*100 then
          begin
            //если значение максимума канала превышает пользовательское значение максимума
            //за блок то заполняем ячейку красным цветом
            SetCellColor(MyExcel,3,rowCount,colCount);
          end;
          Inc(colCount);
        end;
     end;
  end;

  // form1.Memo1.Lines.Add('Блок '+intToStr(iBlock)+' Обработан!');
  //write(fileF,#13#10);
  inc(iBlock);
  //MyExcel.Visible:=true;
  //переключаемся в записи на след. строку
  inc(rowCount);
  colCount:=1;
  //iK20mA:=1;
  //iK4mA:=1;
  iK0V:=1;
  iKM5V:=1;
  iKP5V:=1;
  iSlowArray:=1;
  iSlowArrayOld:=1;
end;
//==============================================================================

//==============================================================================
//Разбор считанного блока данных.
//==============================================================================
procedure ParseReadBlock(blSize:cardinal;var pocketNum:integer;var numPointInK:integer;
var blCount:cardinal;pocketCount:integer);
var
  iPocket:Cardinal;
begin
  iPocket:=1;
  while iPocket<=blSize do
  begin
    //формируем пакет данных из считанного блока ИРУТ.
    SetDateToPocket(iPocket);
    //распределим значения пакета на буферы-каналы
    ParsePocketToSignalBlocks(pocketNum);
    //пакет записали.
    //переключаем буферы файлов на след позицию
    inc(pocketNum);
    //засчитываем значение как значение кадра
    inc(numPointInK);

    //проверяем не собрали ли нужное количество
    //точек равное чаcтоте дискретизации быстр.
    if pocketNum=poolFastVal then
    begin
      ParseFileBuffer(pocketNum,false);
      //увеличиваем счетчик целых блоков.
      if  pocketNum<=poolFastVal then
      begin
        inc(blCount);
      end;

      if blCount>High(Cardinal)-200 then
      begin
        blCount:=0;
      end;

      pocketNum:=1;
    end;

    //проверяем счетчик кадра
    if numPointInK=poolKadrSize then
    begin
      numPointInK:=1;
      inc(kadrCount);
      if kadrCount=High(integer) then
      begin
        kadrCount:=1;
      end;
    end;

    iPocket:=iPocket+length(pocket);
  end;
end;
//==============================================================================

//==============================================================================
//Основная процедура потока для записи логов пункт 3 ТЗ ИРУТ
//==============================================================================
procedure TThreadWriteLog.Execute;
var
  //iPosInBufPrev:=1;
  //поток чтения из файла
  readStream: TFileStream;
  //индекс файла в массиве файлов
  ind:integer;
  //счетчик для разбора счит. пакета по файлам-каналам
  //i:integer;
  //j:integer;
  //счетчик количества накопленных точек в блоке.
  countPointInBlock:integer;
  //счетчик количества накопленных точек в кадре.
  countPointInKadr:integer;
  //nameStr:string;
  flagEnableRead:boolean;
  //количество байт при доразборе данных
  numPointToEnd:cardinal;
  //
  //numConq:integer;
begin
  startFlagFast:=False;
  flagConq:=false;
  flagEnableRead:=true;

  ind:=0;
  //iStrArr:=1;
  iBlock:=1;
  kadrCount:=1;
  countPointInBlock:={0}1;
  countPointInKadr:=1;
  //flagRe:=false;
  blockCount:=0;
  //1 января 2008 года;
  timeCount:=DateTimeToUnix(Now);{1199145600+14400};
  //Открываем первый файл из списка на разбор
  readStream:=TFileStream.Create(SCRUTfileArr[ind].path,fmShareDenyNone{fmOpenRead});

  //предварительная подготовка файла логов
  PreWriteLogFile;

  //closefile(fileF);
  //Перебираем все найденные в каталоге файлы ИРУТа
  //form1.Memo1.Lines.Add(DateTimeToStr(Now)+' Начало LOG');
  //Работа с быстрыми и медленными
  //Перебираем все найденные в каталоге файлы ИРУТа
  while ind<length(SCRUTfileArr) do
  begin
    //проверяем не вариант ли это склеивания файлов ИРУТа
    if (flagConq) then
    begin
      flagConq:=false;
      //количество байт которое будет считано из нового открытого файла
      //с учетом пакетов из предидущего фала чтобы получить целый блок данных
      //читаем из файла блок размером чтобы получить целый блок данных
      readStream.Read(buff,blockSize);
      countPointInBlock:=1;
      //Разбор считанного блока данных
      ParseReadBlock(blockSize,countPointInBlock,countPointInKadr,
        blockCount,poolFastVal);
    end
    else
    begin
      //обычный блочный разбор файла
      if (flagEnableRead) then
      begin
        //читаем из файла блок намеченного размера
        readStream.Read(buff, blockSize);
        //Разбор считанного блока данных
        ParseReadBlock(blockSize,countPointInBlock,countPointInKadr,
          blockCount,poolFastVal);
      end
      else
      begin
        //запишем количество необработанных байт до конца файла
        numPointToEnd:=readStream.Size-readStream.Position;
        //считаем колич байт до конца файла
        readStream.Read(buff,readStream.Size-readStream.Position);
        //Разбор считанного блока данных
        ParseReadBlock(numPointToEnd,countPointInBlock,countPointInKadr,
          blockCount,trunc(numPointToEnd/POCKETSIZE));
      end;
    end;


    //form1.Memo1.Lines.Add(IntToStr(readStream.Position)+' из '+IntToStr(readStream.Size));
    if  readStream.Position>readStream.Size-blockSize then
    begin
      //флаг для корректировки размера блока считывания из файла
      flagEnableRead:=false;
    end;
    //проверяем не дочитали ли файл до конца
    if  readStream.Position>=readStream.Size then
    begin
      //файл обработали, закрыли и переключили индекс на следующий
      readStream.Free;
      inc(ind);
      //проверяем есть ли следующий файл на обработку
      if ind<length(SCRUTfileArr) then
      begin
        //открыли след. файл
        readStream:=TFileStream.Create(SCRUTfileArr[ind].path,fmShareDenyNone{fmOpenRead});
       // form1.Memo1.Lines.Add(intToStr(ind));
        //переводим программу в основной режим разбора файла
        flagEnableRead:=true;
        {if ind mod 2=1 then
          begin
            //коррекция обр. блоков
            inc(blockCount);
          end;}
        //если несколько файлов то дообрабатываем накопленные пакеты данных
        ParseFileBuffer(countPointInBlock,false);
        //флаг конкатенации файлов для того чтобы
        //прочитать нужное количество пакетов чтобы получить блок
        flagConq:=true;
      end
      else
      begin
        //т.к файл последний то обработаем количество точек которое накопилось
        //чтоб не терять данные
        inc(timeCount);
        ParseFileBuffer(countPointInBlock,true);
        countPointInBlock:=1;

        //form1.Memo1.Lines.Add(DateTimeToStr(Now)+' Конец LOG');
      end;
    end;

  end;

  //закрыли файл логов
  //CloseFile(fileF);

  //сохраняем excel файл логов
  SaveWorkBook(fileName,1);
  //закрываем excel файл логов
  StopExcel;






  //!!! запуск след потока обработки
  if form2.chk1.Checked then
  begin
    thWriteGist.Resume;
  end;
  logCompl:=true;
  //обработали все файлы освободили поток
  thWriteLog.Free;
  exit;
end;
//==============================================================================
end.

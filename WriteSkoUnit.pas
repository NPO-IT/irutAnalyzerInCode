unit WriteSkoUnit;
interface
uses
Classes, SysUtils, Dialogs, DateUtils, Forms, ConstUnit;
type
//входной тип для вычисления масс. спектра
//TByteArr=array [1..MAX_POINT_IN_SPECTR] of byte;

//возвращаемый тип спектра
//TIntArr=array [1..MAX_POINT_IN_SPECTR] of integer;
//TfastProc=array[1..FAST_VAL_NUM] of integer;
TarrBPF=array[1..BPF_P_SIZE] of integer;

//поток для записи
TThreadWriteSko = class(TThread)
  private
    { Private declarations }
  protected
    procedure Execute; override;
end;

//процесс обработки канала
TChannalProc=class(TThread)
private
  //счетчик кадра
  kadrCount:integer;
  //буфер значений для текущего обрабатываемого канала
  procArray:array [1..PROC_VAL_NUM] of {word}{byte}real;
  startFlagFast:boolean;
  //колибровки для быстрых
  kolibP5V:byte;
  kolibM5V:byte;
  kolib0V:byte;
  //мин. скорость
  minSpeedTh:integer;
  //макс. скорость
  maxSpeedTh:integer;
  //широта
  latStrTh:string;
  //долгота
  lonStrTh:string;
  //флаг для сбора времени начала блока
  blockFlag:Boolean;
  //время блока
  blockTimeTh:string;
  //массив содержимого текущего пакета
  pocket:array[1..POCKETSIZE]  of byte;
  //поток чтения из файла
  readStream: TFileStream;
  indFile:integer;
  //флаг склеивания пакетов из разных файлов для получения целого блока
  flagConq:boolean;
  //размер считываемого буфера из файла
  buff:array [1..BUFF_NUM] of byte;
  //счетчик количества накопленных точек в блоке.
  countPointInBlock:integer;
  //счетчик количества накопленных точек в кадре.
  countPointInKadr:integer;
  //счетчик блоков
  blockCount:cardinal;
  flagEnableRead:boolean;
  //количество байт при доразборе данных
  numPointToEnd:cardinal;

  //индекс разбираемого канала-потока
  indCh:integer;
  //writeNBlock:boolean;
  //мин. скорость за блок
  minSpeed:integer;
  //макс скорость за блок
  maxSpeed:integer;
  //массив массивов БПФ
  arrBPF:array[1..KOEF_R] of TarrBPF;
  //средний массив БПФ
  arrBpfAvr:array[1..BPF_P_SIZE] of integer;

  //количество записанных значений ско
  numWriteSko:integer;

  numPointBeg:integer;
  numPointEnd:integer;

  numPointInSpectr:integer;
  numPointInArrBPF:integer;
  //количество заполненнных точек в массиве диапазона
  numPointInArrF:integer;

  //текстовый файл результатов обработки канала
  fileCh:Text;


  //массив части точек массива быстрых параметров
  arrPointPart:array [1..BPF_P_SIZE] of double;
   //массив sko для всех частотных диапазонов
  sko:array[1..MAX_POINT_IN_FREQ_R] of real;
  //массив точек для текущего частотного диапазона обработки
  arrF:array[1..MAX_POINT_IN_FREQ_R] of integer;
  spArrOut:array[1..BPF_P_SIZE] of integer;

  //time
  timeGeosArrTh :array [1..4] of byte;
  //latitude
  latArrTh :array [1..4] of byte;
  //longtitude
  lonArrTh:array [1..4] of byte;
  //speed
  speedArrTh:array [1..2] of byte;

  //колибровки для медленных
  //kolib20mA:byte;
  //kolib4mA:byte;

  //процедура разбора считанного блока
  procedure ParseReadBlock(blSize:cardinal;var pocketNum:integer;
    var numPointInK:integer;var blCount:cardinal;pocketCount:integer);
  //Формирование пакета данных ИРУТ для дальнейшего разбора
  procedure SetDateToPocket(iPock:integer);
  procedure ParsePocketToSignalBlocksFast(iPosInBuf:integer);
  function CollectCounterTh(iByteDj:integer):byte;
  function CollectTimeTh(iB:integer;count:byte):string;
  function CollectLatitudeTh(iB:integer;count:byte):string;
  function CollectLongtitudeTh(iB:integer;count:byte):string;
  function CollectSpeedTh(iB:integer;count:byte):string;
  procedure ParseFileBuffer(numValInFfileBufer:integer;flagWriteNumBlock:boolean);
  //обработка 1 канала
  procedure ParseBuf(numValInFfileBufer:integer);
  function CalculateSpectr(arrPointPartNum:integer):integer;
  //вывод 1 канала
  procedure WriteBuf;
  function testCh(chNumber:integer;currentPocketNum:integer):boolean;
  //из кода в В
  function getColibValF(kodVal:{byte}real;kP:byte;kM:byte):real;
  //из В в м/c2
  function getAcs(volt:double;kP:double;kM:double;diap:double):double;
  function getColibValS(kodVal:{byte}real;k20mA:byte;k4mA:byte):real;
  function CalcMin(var arr:array of integer;numSpeedPoint:integer):integer;
  function CalcMax(var arr:array of integer;numSpeedPoint:integer):integer;
  function CalcAvrBPFarr(numPointBPFarr:integer):integer;
  function CalcNumP(freq:real;numPoint:integer;pollFreq:real):integer;
  function CalcAvrVal(var arr:array of integer):integer;
  function CalcSKO(var arr:array of integer;arrMaxPoint:integer;bpfLength:integer):real;


protected
  procedure Execute; override;
public
  property ind: integer read indCh write indCh;
end;


var
  //поток для параллельной работы
  thWriteSko: TThreadWriteSko;
  channalThread:array[1..MAX_CH_COUNT] of TChannalProc;
implementation
uses Unit1, Math;
//---------------------------------------------------------------------
//==============================================================================
//Функция проверяет содержит ли пакет нужный параметр.
//передается номер канала и номер текущего пришедшего пакета
//==============================================================================
function TChannalProc.testCh(chNumber:integer;currentPocketNum:integer):boolean;
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
//Функция перевода быстрых в вольты
//==============================================================================
function TChannalProc.getColibValF(kodVal:{byte}real;kP:byte;kM:byte):real;
begin
 //10 это размах от -5 до 5
 Result:=((kodVal-kM)/(kP-kM))*10-5;
end;
//==============================================================================

//==============================================================================
//Функция перевода быстрых из вольт в м/c2
//==============================================================================
function TChannalProc.getAcs(volt:double;kP:double;kM:double;diap:double):double;
begin
 //abs(diap*2) это размах от -5В до 5В
 Result:=((volt-kM)/(kP-kM))*abs(diap*2)+diap;
end;
//==============================================================================

//==============================================================================
//Функция перевода медленных в мА
//==============================================================================
function TChannalProc.getColibValS(kodVal:{byte}real;k20mA:byte;k4mA:byte):real;
begin
  //16 это размах 20-4
  Result:=((kodVal-k4mA)/(k20mA-k4mA))*16+4;
end;
//==============================================================================

//==============================================================================
//Процедура записи файла канала-блока
//==============================================================================
procedure TChannalProc.WriteBuf;
var
  //fileName:string;
  //сформированная записываемая строка
  writeStr:string;
  i:integer;
begin
  //выведем основныю инф. по блоку в строку
  writeStr:=floatToStr(kadrCount)+#9+blockTimeTh+#9+
    intToStr(round((minSpeedTh+maxSpeedTh)/2))+#9+intToStr(minSpeedTh)+#9+
      intToStr(maxSpeedTh)+#9+latStrTh+#9+lonStrTh;

  //выведем значения skz для блока
  i:=1;
  while i<=numWriteSko do
  begin
    writeStr:=writeStr+#9+floatToStr(2*sko[i]/numPointInArrBPF);
    inc(i);
  end;
  write(fileCh,writeStr);
  writeln(fileCh,'');
end;
//==============================================================================



//==============================================================================
//Вычисление спектра сигнала. Возвращает количество заполненных значений
//==============================================================================
function TChannalProc.CalculateSpectr(arrPointPartNum:integer):integer;
var
  i:integer;
  j:integer;
  k:integer;
  //iPrev:integer;
  Ere:array of double;
  Eim:array of double;
  Ore:array of double;
  Oim:array of double;
  XoutRe:array of double;
  XoutIm:array of double;
  //размерность переданного массива.
  arrSize:integer;
  //половина размера массива
  arrSizeDiv2:integer;
  //koef:double;
begin
  Ere:=nil;
  Eim:=nil;
  Ore:=nil;
  Oim:=nil;

  XoutRe:=nil;
  XoutIm:=nil;

  arrSize:=arrPointPartNum;
  arrSizeDiv2:=trunc(arrPointPartNum/2);

  setLength(Ere,arrSizeDiv2);
  setLength(Eim,arrSizeDiv2);
  setLength(Ore,arrSizeDiv2);
  setLength(Oim,arrSizeDiv2);

  setLength(XoutRe,arrSize);
  setLength(XoutIm,arrSize);

  k:=1;
  for i:=0 to arrSizeDiv2-1 do
  begin
    j:=1;
    while j<=arrSizeDiv2 do
    begin
      Ere[i]:=Ere[i]+arrPointPart[2*j]*cosArrA[k]+
        arrPointPart[2*(j+1)]*cosArrA[k+1]+
          arrPointPart[2*(j+2)]*cosArrA[k+2]+
            arrPointPart[2*(j+3)]*cosArrA[k+3];

      Eim[i]:=Eim[i]-arrPointPart[2*j]*sinArrA[k]-
        arrPointPart[2*(j+1)]*sinArrA[k+1]-
          arrPointPart[2*(j+2)]*sinArrA[k+2]-
            arrPointPart[2*(j+3)]*sinArrA[k+3];

      Ore[i]:=Ore[i]+(arrPointPart[2*j+1]*cosArrA[k])+
        (arrPointPart[2*j+3]*cosArrA[k+1])+
          (arrPointPart[2*j+5]*cosArrA[k+2])+
            (arrPointPart[2*j+7]*cosArrA[k+3]);

      Oim[i]:=Oim[i]-(arrPointPart[2*j+1]*sinArrA[k])-
        (arrPointPart[2*j+3]*sinArrA[k+1])-
          (arrPointPart[2*j+5]*sinArrA[k+2])-
            (arrPointPart[2*j+7]*sinArrA[k+3]);
      k:=k+4;
      j:=j+4;
    end;
  end;

  for i:=1 to arrSizeDiv2 do
  begin
    XoutRe[i-1]:=(Ere[i-1]+Oim[i-1]*sinArrB[i]+
      Ore[i-1]*cosArrB[i]);
    XoutIm[i-1]:=(Eim[i-1]+Oim[i-1]*cosArrB[i]-
      Ore[i-1]*sinArrB[i]);

    spArrOut[i]:=round(Sqrt(Sqr(XoutRe[i-1])+Sqr(XoutIm[i-1])));

    XoutRe[i+arrSizeDiv2-1]:=(Ere[i-1]-Oim[i-1]*sinArrB[i]-
      Ore[i-1]*cosArrB[i]) ;
    XoutIm[i+arrSizeDiv2-1]:=(Eim[i-1]-Oim[i-1]*cosArrB[i]+
      Ore[i-1]*sinArrB[i]) ;

    spArrOut[i+arrSizeDiv2]:=round(Sqrt(sqr(XoutRe[i+arrSizeDiv2-1])+
      sqr(XoutIm[i+arrSizeDiv2-1])));
  end;

  result:=i+arrSizeDiv2-1;
end;
//==============================================================================

//==============================================================================
//Процедура разбора одного канала-блока
//==============================================================================
procedure TChannalProc.ParseBuf(numValInFfileBufer:integer);
var
  fileBufCount:integer;
  i:integer;
  k:integer;
  j:integer;
  iSpArOut:integer;
begin
  //minSpeed:=50;
  //maxSpeed:=54;
  //minSpeedTh:=50;
  //maxSpeedTh:=54;     //!!!!!!!!!!!!!!!!!!!!!!!!

  //проверяем не нулевые ли скорости
  if (minSpeedTh<>0)and(minSpeedTh<>0) then
  begin
    if (1-minSpeedTh/maxSpeedTh)<=procentD then
    begin
      //разбор файла поэлементно
      fileBufCount:=1;
      j:=1;
      i:=1;
      k:=1;
      while fileBufCount<=numValInFfileBufer do   //!!!
      begin
        if j<=trunc(numValInFfileBufer/KOEF_R) then
        begin
          //заполняем в буфер для вычисления БПФ
          arrPointPart[k]:=procArray[fileBufCount];
          inc(j);
          inc(k);
          inc(fileBufCount);
        end
        else
        begin
          //накопили необходимую часть точек
          //Посчитаем БПФ, на выходе получим массив
          numPointInSpectr:=CalculateSpectr(k-1);
          for iSpArOut:=1 to numPointInSpectr do
          begin
            arrBPF[i][iSpArOut]:=spArrOut[iSpArOut];
          end;
          inc(i);
          j:=1;
          k:=1;
          if i>KOEF_R then
          begin
            break;
          end;
        end;
      end;

      //разбили блок на KOEF_R массивов БПФ
      //вычислим средний массив БПФ
      numPointInArrBPF:=CalcAvrBPFarr(numPointInSpectr);
      i:=1;
      //перебираем все частотные диапазоны
      while i<=numFreqRange do
      begin
        //вычислим номера точек в среднем массиве БПФ
        numPointBeg:=CalcNumP(arrFreqRange[i].beginRange,numPointInArrBPF,
        poolFastFreq);
        numPointEnd:=CalcNumP(arrFreqRange[i].endRange,numPointInArrBPF,
        poolFastFreq);
        dec(numPointEnd);
        //перезаписываем точки в спец массив
        k:=1;
        for j:=numPointBeg to numPointEnd do
        begin
          arrF[k]:=arrBpfAvr[j];
          inc(k);
        end;
        numPointInArrF:=k-1;
        //находим СКО и заносим в массив ско
        sko[i]:=CalcSKO(arrF,numPointInArrF,numPointInArrBPF);
        inc(i);
      end;
      numWriteSko:=i-1;
      WriteBuf;
    end;
  end;
  //WriteBuf;
  //form1.Memo1.Lines.Add('Номер процесса'+intToStr(indCh)+' Все!');
end;
//==============================================================================

//==============================================================================
//Разбираем файловые буферы
//==============================================================================
procedure TChannalProc.ParseFileBuffer(numValInFfileBufer:integer;flagWriteNumBlock:boolean);
begin
  ParseBuf(numValInFfileBufer);
  blockFlag:=true;
  //form1.Memo1.Lines.Add('Блок обработали!');
end;
//==============================================================================

//==============================================================================
//Функция для сбора счетчика пакета. Передается номер младшего байта. Вернет счетчик
//==============================================================================
function TChannalProc.CollectCounterTh(iByteDj:integer):byte;
begin
  result:=pocket[iByteDj];
end;
//==============================================================================

//==============================================================================
//Собираем значение времени
//==============================================================================
function TChannalProc.CollectTimeTh(iB:integer;count:byte):string;
var
  timeGEOS_int:Int64;
  dT:TDateTime;
  dtStr:string;
  timeGEOS:cardinal;
begin
  if count=3 then
  begin
    timeGeosArrTh[4]:=pocket[iB];
    timeGEOS:=(timeGeosArrTh[1] shl 24)+(timeGeosArrTh[2] shl 16)+
      (timeGeosArrTh[3] shl 8)+timeGeosArrTh[4];
    //приводим время ГЕОС в UnixTime
    timeGEOS_int:=timeGEOS+1199145600{+14400};
    //приводим к формату dateTime
    dT:=UnixToDateTime(timeGEOS_int);
    //приводим время к строке
    DateTimeToString(dtStr,'dd.mm.yyyy hh:mm:ss',dT);
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
function TChannalProc.CollectLatitudeTh(iB:integer;count:byte):string;
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
function TChannalProc.CollectLongtitudeTh(iB:integer;count:byte):string;
var
  lon :double;
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
function TChannalProc.CollectSpeedTh(iB:integer;count:byte):string;
var
  speed:word;
begin
  if count=15 then
  begin
    speedArrTh[2]:=pocket[iB];
    speed:=(speedArrTh[1] shl 8)+ speedArrTh[2];
    result:=intToStr(speed);
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
//Разбор пакета ИРУТ по буферам файлов-каналов
//==============================================================================
procedure TChannalProc.ParsePocketToSignalBlocksFast(iPosInBuf:integer);
var
  //i:integer;
  j:integer;
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
        //Form1.Memo1.Lines.Add('Время '+blockTimeTh );
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
  end;

  //проверяем что пришел пакет с калибровкой -5В
  if (testCh(NUM_P_M5V,counter)) then
  begin
    //-5В
    kolibM5V:=pocket[length(pocket)];
  end;

  //проверяем что пришел пакет с калибровкой 0В
  if (testCh(NUM_P_0V,counter)) then
  begin
    //0 В
    kolib0V:=pocket[length(pocket)];

    //перебираем все каналы быстрых
    if not startFlagFast then
    begin
      for j:=1 to iPosInBuf-1 do
      begin
        procArray[j]:=getColibValF(procArray[j],kolibP5V,kolibM5V);
        procArray[j]:=getAcs(procArray[j],5,-5,arrEnableChanals[indCh].begRange);
      end;
    end;

    //флаг начала перевода значений быстрых в вольты
    startFlagFast:=true;
  end;

  //проверяем нашли калибровки +5 -5 или нет
  if (startFlagFast)then
  begin
    procArray[iPosInBuf]:=getColibValF(pocket[indCh+1],kolibP5V,kolibM5V);

    procArray[iPosInBuf]:=getAcs(procArray[iPosInBuf],5,-5,arrEnableChanals[indCh].begRange);
    //form1.Memo1.Lines.Add('Поток-канал№'+intTostr(indCh)+'Элемент№'+intToStr(iPosInBuf));
  end
  else
  begin
    procArray[iPosInBuf]:=pocket[indCh+1];
  end;
end;
//==============================================================================

//==============================================================================
//
//==============================================================================
procedure TChannalProc.SetDateToPocket(iPock:integer);
var
  i:integer;
  j:integer;
begin
  //перепишем данные в пакет
  i:=1;
  j:=iPock;

  //в пакет запишем только данные счетчика пакета, значение разб. в потоке канала
  //значение медл. параметра
  //1б счетчик пакета
  pocket[i]:=buff[j];
  //1б значение канала
  pocket[i+indCh]:=buff[j+indCh];
  //1б медл. параметр
  pocket[i+(POCKETSIZE-1)]:=buff[j+(POCKETSIZE-1)];
end;
//==============================================================================

//==============================================================================
//
//==============================================================================
procedure TChannalProc.ParseReadBlock(blSize:cardinal;var pocketNum:integer;var numPointInK:integer;
var blCount:cardinal;pocketCount:integer);
var
  iPocket:integer;
begin
  iPocket:=1;
  //разбираем блок
  while iPocket<=blSize do
  begin
    //запишем пакет
    SetDateToPocket(iPocket);
    //распределим пакет по каналам
    ParsePocketToSignalBlocksFast(pocketNum);
    //переключаем буферы файлов на след позицию
    inc(pocketNum);
    //засчитываем значение как значение кадра
    inc(numPointInK);


    //проверяем не собрали ли нужное количество точек равное чаcтоте дискретизации быстр.
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

procedure TChannalProc.Execute;
var
  i:Integer;
  fileName:string;
  writeStr:string;
begin
  //подготовка процесса к работе
  blockFlag:=True;
  indFile:=0;
  flagConq:=False;
  countPointInBlock:=1;
  countPointInKadr:=0;
  blockCount:=0;
  flagEnableRead:=True;
  numPointToEnd:=0;
  minSpeedTh:=-5;
  maxSpeedTh:=-5;
  startFlagFast:=False;
  kadrCount:=1;
  //связали первый файл с файловым потоком.
  readStream:=TFileStream.Create(SCRUTfileArr[indFile].path,fmShareDenyNone);
  //открыли на запись. При повторной записи предидущее содержимое затрется
  fileName:=ExtractFileDir(ParamStr(0))+'\Report\'+'\skz\'+
    'Process'+IntToStr(indCh)+'_skz'+'.xls';
  AssignFile(fileCh,fileName);
  Rewrite(fileCh);
  writeStr:='№кадра'+#9+'Дата и время начала блока'+
  #9+'Средняя скорость'+#9+'Мин. скорость'+#9+'Макс. скорость'+
  #9+'Широта'+#9+'Долгота';
  //заполним частотные диапазоны
  i:=1;
  while i<=numFreqRange do
  begin
    writeStr:=writeStr+#9+floatToStr(arrFreqRange[i].beginRange)+'   '+
    floatToStr(arrFreqRange[i].endRange)+' Гц';
    inc(i);
  end;
  write(fileCh,writeStr);
  writeln(fileCh,'');


  while indFile<length(SCRUTfileArr) do
  begin
    //проверяем не вариант ли это склеивания файлов ИРУТа
    if (flagConq) then
    begin
      flagConq:=false;
      //количество байт которое будет считано из нового открытого файла
      //с учетом пакетов из предидущего файла чтобы получить целый блок данных
      //читаем из файла блок размером чтобы получить целый блок данных
      readStream.Read(buff,blockSize);
      countPointInBlock:=1;
      //Разбор считанного блока данных
      ParseReadBlock(blockSize,countPointInBlock,countPointInKadr,blockCount,poolFastVal);
    end
    else
    begin
      //обычный блочный разбор файла
      if (flagEnableRead) then
      begin
        //читаем из файла блок намеченного размера
        readStream.Read(buff, blockSize);
        //Разбор считанного блока данных
        ParseReadBlock(blockSize,countPointInBlock,countPointInKadr,blockCount,poolFastVal);
      end
      else
      begin
        //запишем количество необработанных байт до конца файла
        numPointToEnd:=readStream.Size-readStream.Position;
        //считаем колич байт до конца файла
        readStream.Read(buff,readStream.Size-readStream.Position);
        //Разбор считанного блока данных
        ParseReadBlock(numPointToEnd,countPointInBlock,countPointInKadr,blockCount,trunc(numPointToEnd/POCKETSIZE));
      end;
    end;

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
      inc(indFile);
      //проверяем есть ли следующий файл на обработку
      if indFile<length(SCRUTfileArr) then
      begin
        //открыли след. файл
        readStream:=TFileStream.Create(SCRUTfileArr[indFile].path,fmShareDenyNone{fmOpenRead});
        //переводим программу в основной режим разбора файла
        flagEnableRead:=true;
        {if indFile mod 2=1 then
        begin
          //коррекция обр. блоков
          inc(blockCount);
        end;}
        //если несколько файлов то дообрабатываем накопленные пакеты данных
        ParseFileBuffer(countPointInBlock,false);    //!!!
        //флаг конкатенации файлов для того чтобы
        //прочитать нужное количество пакетов чтобы получить блок
        flagConq:=true;
      end
      else
      begin
        //т.к файл последний то обработаем количество точек которое накопилось
        //чтоб не терять данные
        //!!! последний блок не обрабатываем
        //ParseFileBuffer(countPointInBlock,true);
        CloseFile(fileCh);
        countPointInBlock:=1;
        arrEnbChannal[indCh]:=True;
        //канал обработан
        Form1.gProgress1.Progress:=Form1.gProgress1.Progress+3;
      end;
    end;
  end;
end;

//==============================================================================
// Находим min скорость
//==============================================================================
function TChannalProc.CalcMin(var arr:array of integer;numSpeedPoint:integer):integer;
var
  i:integer;
  min:integer;
begin
  min:=arr[0];
  for i:=1 to numSpeedPoint-1 do
  begin
    if min>arr[i] then
    begin
      min:=arr[i];
    end;
  end;
  result:=min;
end;
//==============================================================================

//==============================================================================
// Находим max скорость
//==============================================================================
function TChannalProc.CalcMax(var arr:array of integer;numSpeedPoint:integer):integer;
var
  i:integer;
  max:integer;
begin
  max:=arr[0];
  for i:=1 to numSpeedPoint-1 do
  begin
    if max<arr[i] then
    begin
      max:=arr[i];
    end;
  end;
  result:=max;
end;
//==============================================================================

//==============================================================================
//Находим средний массив БПФ.Возвращает количество заполненных значений среднего
//среднего массива БПФ
//==============================================================================
function TChannalProc.CalcAvrBPFarr(numPointBPFarr:integer):integer;
var
  igroup:integer;
  jNumPointInGroup:integer;
  sum:integer;
  avrBPFval:integer;
begin
  igroup:=1;
  jNumPointInGroup:=1;
  sum:=0;
  //avrBPFval:=0;
  //перебираем все значения массива БПФ
  while jNumPointInGroup<=numPointBPFarr do
  begin
    //складываем значений всех массивов одного индекса
    while igroup<=KOEF_R do
    begin
      sum:=sum+arrBPF[igroup][jNumPointInGroup];
      inc(igroup);
    end;
    //находим среднее значение из получ. суммы
    avrBPFval:=round(sum/KOEF_R);
    //заносим значение в массив средних значений
    arrBpfAvr[jNumPointInGroup]:=avrBPFval;
    sum:=0;
    igroup:=1;
    inc(jNumPointInGroup);
  end;
  result:=jNumPointInGroup-1;
end;
//==============================================================================

//==============================================================================
//Вычисление номера точки в массиве БПФ от переданной частоты обработки
//Возвращает номер точки
//==============================================================================
function TChannalProc.CalcNumP(freq:real;numPoint:integer;pollFreq:real):integer;
begin
  result:=round(freq*(numPoint/pollFreq)+0.1);
end;
//==============================================================================

//==============================================================================
//Вычисление среднего значения переданного массива
//==============================================================================
function TChannalProc.CalcAvrVal(var arr:array of integer):integer;
var
  i:integer;
  sum:integer;
begin
  i:=0;
  sum:=0;
  while i<=length(arr)-1 do
  begin
    sum:=sum+arr[i];
    inc(i);
  end;
  result:=round(sum/length(arr));
end;
//==============================================================================

//==============================================================================
//
//==============================================================================
function TChannalProc.CalcSKO(var arr:array of integer;arrMaxPoint:integer;bpfLength:integer):real;
var
  sum:integer;
  i:integer;
begin
  sum:=0;
  i:=0;
  while i<=arrMaxPoint-1 do
  begin
    sum:=sum+sqr(round(arr[i]/bpfLength));
    inc(i);
  end;
  result:=sqrt(sum);
end;
//==============================================================================
//----------------------------------------------------------------------

//==============================================================================
//Основная процедура потока для записи СКО пункт 2 ТЗ ИРУТ
//==============================================================================
procedure TThreadWriteSko.Execute;
var
  i:Integer;
begin
  //РАБОТА ТОЛЬКО С БЫСТРЫМИ
  for i:=1 to MAX_CH_COUNT_FAST do
  begin
    arrEnbChannal[i]:=False;
  end;

  //Перебираем все найденные в каталоге файлы ИРУТа
  //form1.Memo1.Lines.Add(DateTimeToStr(Now)+' Начало SKO');
  //проверяем какие каналы у нас подключены
  for i:=1 to MAX_CH_COUNT_FAST do
  begin
    if (arrEnableChanals[i].enabled) then
    begin
      //канал подлючен. под каждый канал свой поток
      channalThread[i]:=TChannalProc.Create(true);
      channalThread[i].Priority:=tpHigher;
      channalThread[i].indCh:=i;
      channalThread[i].FreeOnTerminate:=true;
      channalThread[i].Resume;
    end
    else
    begin
      //если канал обрабатывать не надо, то засчитываем его обработанным
      arrEnbChannal[i]:=True;
    end;
  end;
  //включили таймер завершения потока
  Form1.tmr1.Enabled:=true;
  Form1.tmr1.Tag:=MAX_CH_COUNT_FAST;
end;
//==============================================================================
end.

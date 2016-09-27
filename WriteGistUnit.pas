unit WriteGistUnit;

interface
uses
Classes, SysUtils, Dialogs, Math,  Forms,ConstUnit;
type
//поток для записи
TThreadWriteGist = class(TThread)
  private
    { Private declarations }
  protected
    procedure Execute; override;
end;

// тип для хранения записи попадания в подинтервал(интервал)
TStrikeRec=record
  //интервал
  interval:double;
  //количество попаданий в интервал
  countStrike:cardinal;
end;
//массив записей попаданий
TStrikeRecArr=array [1..INTERVAL_NUM] of TStrikeRec;
//TfastProc=array [1..FAST_VAL_NUM] of integer;

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
  //флаг для сбора времени начала блока
  blockFlag:Boolean;
  //время блока
  //blockTimeTh:string;
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

  //количество заполненных точек подинтервалов
  numPointSubInterval:integer;

  //колибровочные массивы
  arrKolibP5V:array [1..MAX_COLIB_P] of Byte;
  iKP5V:Cardinal;
  arrKolibM5V:array [1..MAX_COLIB_P] of Byte;
  iKM5V:Cardinal;
  arrkolib0V:array [1..MAX_COLIB_P] of Byte;
  iK0V:Cardinal;
  //arrKolib4mA:array [1..MAX_COLIB_P] of Byte;
  iK4mA:Cardinal;
  //arrKolib20mA:array [1..MAX_COLIB_P] of Byte;
  iK20mA:Cardinal;

  //индекс разбираемого канала-потока
  indCh:integer;
  fileCh:Text;
  //массив записей  попадания в подинтервал(интервал)
  countsStrikeArr:array [1..INTERVAL_NUM] of TStrikeRec;

  //колибровки для медленных
  //kolib20mA:byte;
  //kolib4mA:byte;

  //заполнение массива попаданий для каждого канала
  procedure FillIntervalArray;
  //процедура разбора считанного блока
  procedure ParseReadBlock(blSize:cardinal;var pocketNum:integer;
    var numPointInK:integer;var blCount:cardinal;pocketCount:integer);
  //Формирование пакета данных ИРУТ для дальнейшего разбора
  procedure SetDateToPocket(iPock:integer);
  procedure ParsePocketToSignalBlocksFast(iPosInBuf:integer);
  function CollectCounterTh(iByteDj:integer):byte;

  procedure ParseFileBuffer(numValInFfileBufer:integer;flagWriteNumBlock:boolean);
  //обработка 1 канала
  procedure ParseBuf(numValInFfileBufer:integer;writeNBlock:Boolean);
  //вывод 1 канала
  procedure WriteBuf;
  function testCh(chNumber:integer;currentPocketNum:integer):boolean;
  //приведение быстрого значения из кода в вольты
  function getColibValF(kodVal:{byte}real;kP:byte;kM:byte):real;
  //приведение быстрого значения из вольт в м/c2
  function getAcs(volt:real;kP:double;kM:double;diap:double):double;
  //function getColibValS(kodVal:{byte}real;k20mA:byte;k4mA:byte):real;

protected
  procedure Execute; override;
public
  property ind: integer read indCh write indCh;
end;

var
  //поток чтения
  thWriteGist: TThreadWriteGist;
  channalThread:array[1..MAX_CH_COUNT] of TChannalProc;
implementation
uses
Unit1,WriteSkoUnit;


//==============================================================================
//Заполнение и иниализация масссива подинтервалов с числов попаданий в них
//==============================================================================
procedure TChannalProc.FillIntervalArray;
var
  i:double;
  iFile:integer;
  ddd:double;//поправка
begin
  ddd:=-0.1;
  iFile:=1;//перед разбором проинициализируем структуру для подсчета попаданий в подинтервалы

  i:=fastProcBegLimit;//посчитаем количество подинтервалов(интервалов)
  countInterval:=1;
  while round(i*NUM_PRECIGION)<=round((fastProcEndLimit)*NUM_PRECIGION) do
  begin
    countsStrikeArr[countInterval].interval:=RoundTo(i,-3);//округляаем с точность 3 цифры после запятой
    if round(i*NUM_PRECIGION)=round(ddd*NUM_PRECIGION) then
    begin
      i:=0;
    end
    else
    begin
      i:=i+fastInterval;
    end;
    inc(countInterval);
  end;
  dec(countInterval);//на последнем шаге лишний счет.
  if iFile=1 then//запомним количество заполненных границ подинтервала
  begin
    numPointSubInterval:=countInterval;
  end;
end;
//==============================================================================



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
function TChannalProc.getAcs(volt:real;kP:double;kM:double;diap:double):double;
begin
 //abs(diap*2) это размах от -5В до 5В
 Result:=((volt-kM)/(kP-kM))*abs(diap*2)+diap;
end;
//==============================================================================

//==============================================================================
//Функция перевода медленных в мА
//==============================================================================
{function TChannalProc.getColibValS(kodVal:{byte}//real;k20mA:byte;k4mA:byte):real;
{begin
  //16 это размах 20-4
  Result:=((kodVal-k4mA)/(k20mA-k4mA))*16+4;
end;}
//==============================================================================


//==============================================================================
//Процедура записи файла канала-блока
//==============================================================================
procedure TChannalProc.WriteBuf;
var
  writeStr:string;
  //счетик перебора записей файла гистрограммы
  iWriteCount:integer;
begin
  //записываем каждый файл в формате интервал колич.попаданий
  iWriteCount:=1;
  //-2 т.к -1 это последнее барьерное значение которое не входит
  while iWriteCount<=numPointSubInterval-1{-1} do
  begin
    //строка на запись
    writeStr:=FloatToStr(countsStrikeArr[iWriteCount].interval+
      (fastInterval/2))+#9+IntToStr(countsStrikeArr[iWriteCount].countStrike);
    writeLn(fileCh,writeStr);
    inc(iWriteCount);
  end;

  writeStr:='Количество целых обработанных блоков'+#9+intToStr(blockCount);
  writeLn(fileCh,writeStr);
  
  //CloseFile(fileCh);
end;
//==============================================================================


//==============================================================================
//Процедура разбора одного канала-блока
//==============================================================================
procedure TChannalProc.ParseBuf(numValInFfileBufer:integer;writeNBlock:Boolean);
var
  fileBufCount:integer;
  inlCount:integer;
  a:double;
begin
  //разбор файла поэлементно
  fileBufCount:=1;
  while fileBufCount<=numValInFfileBufer-1 do   //!!!
  begin
    //проверяем в какой интервал элемент вошел
    inlCount:=1;
    while inlCount<=numPointSubInterval-1 do   ///!!!
    begin
      //приведение к физ. величине
      a:=getColibValF(procArray[fileBufCount],arrKolibP5V[trunc(fileBufCount/224)+1],
        arrkolibM5V[trunc(fileBufCount/224)+1]);
      a:=getAcs(a,5,-5,arrEnableChanals[indCh].begRange);

      //вкл. левую границу
      if a*NUM_PRECIGION=countsStrikeArr[1].interval*NUM_PRECIGION then
      begin
        inc(countsStrikeArr[1].countStrike);
      end;

      //проверяем, от левого края интервала до 0
      if (((a*NUM_PRECIGION>countsStrikeArr[inlCount].interval*NUM_PRECIGION)and
          (a*NUM_PRECIGION<=countsStrikeArr[inlCount+1].interval*NUM_PRECIGION))and
          (a<0)) then
      begin
        if a*NUM_PRECIGION=(-1)*fastInterval*NUM_PRECIGION then
        begin
          inc(countsStrikeArr[inlCount-1].countStrike);
        end
        else
        begin
          //нашли попадание. учли и вышли из цикла поиска
          inc(countsStrikeArr[inlCount].countStrike);
        end;
        break;
      end;

       //включаем  правую границу
      if a*NUM_PRECIGION=countsStrikeArr[numPointSubInterval-1].interval*NUM_PRECIGION then
      begin
        inc(countsStrikeArr[numPointSubInterval-1].countStrike);
      end;

      //проверяем, от 0 до правого края
      if (((a*NUM_PRECIGION>=countsStrikeArr[inlCount].interval*NUM_PRECIGION)and
          (a*NUM_PRECIGION<countsStrikeArr[inlCount+1].interval*NUM_PRECIGION))and
          (a>0)) then
      begin
        if a*NUM_PRECIGION=fastInterval*NUM_PRECIGION then
        begin
          inc(countsStrikeArr[inlCount+1].countStrike);
        end
        else
        begin
          //нашли попадание. учли и вышли из цикла поиска
          inc(countsStrikeArr[inlCount].countStrike);
        end;
        break;
      end;

      //заполняем интервал перехода через 0
      if a*NUM_PRECIGION=0 then
      begin
        //присваиваем значение интервалу переходу через 0
        inc(countsStrikeArr[trunc(numPointSubInterval/2)].countStrike);
        break;
      end;

      inc(inlCount);
    end;
    inc(fileBufCount);
  end;

  if writeNBlock then
  begin
    //последний канал послед. файла
    WriteBuf;
  end;
end;
//==============================================================================

//==============================================================================
//Разбираем файловые буферы
//==============================================================================
procedure TChannalProc.ParseFileBuffer(numValInFfileBufer:integer;flagWriteNumBlock:boolean);
begin
  ParseBuf(numValInFfileBufer,flagWriteNumBlock);
  blockFlag:=true;
  iKP5V:=1;
  iKM5V:=1;
  iK0V:=1;
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
//Разбор пакета ИРУТ по буферам файлов-каналов
//==============================================================================
procedure TChannalProc.ParsePocketToSignalBlocksFast(iPosInBuf:integer);
var
  //номер текущего пакета
  counter:byte;
begin
   //получим номер пакета
  counter:=CollectCounterTh(1);

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
  //запись быстрых
  //WriteFast(iPosInBuf);
  procArray[iPosInBuf]:=pocket[indCh+1];
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


//==============================================================================
//
//==============================================================================
procedure TChannalProc.Execute;
var
  fileName:string;
begin
  //заполнение массива диапазонов
  FillIntervalArray;
  iKP5V:=1;
  iKM5V:=1;
  iK0V:=1;
  iK4mA:=1;
  iK20mA:=1;
  
  //подготовка процесса к работе
  blockFlag:=True;
  indFile:=0;
  flagConq:=False;
  countPointInBlock:=1;
  countPointInKadr:=0;
  blockCount:=0;
  flagEnableRead:=True;
  numPointToEnd:=0;
  //minSpeedTh:=-5;
  //maxSpeedTh:=-5;
  startFlagFast:=False;
  kadrCount:=1;
  //связали первый файл с файловым потоком.
  readStream:=TFileStream.Create(SCRUTfileArr[indFile].path,fmShareDenyNone);

  //открыли на запись. При повторной записи предидущее содержимое затрется
  //формируем имя файла
  fileName:=ExtractFileDir(ParamStr(0))+'\Report\'+'\hist\'+
    'Process'+IntToStr(indCh)+'_hist'+'.xls';
  AssignFile(fileCh,fileName);
  //открыли на запись. При повторной записи предидущее содержимое затрется
  Rewrite(fileCh);


  while indFile<length(SCRUTfileArr) do
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
        //form1.Memo1.Lines.Add('Канал '+intTostr(indCh)+' Номер файла '+intToStr(indFile));
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
        ParseFileBuffer(countPointInBlock,true);
        //сбросили накопленные счетчики для возможности разбора с начала
        {for i:=1 to FILE_NUM_GIST do
        begin
          for j:=1 to INTERVAL_NUM do
          begin
            countsStrikeArr[i][j].interval:=0;
            countsStrikeArr[i][j].countStrike:=0;
          end }
        CloseFile(fileCh);
        countPointInBlock:=1;
        arrEnbChannal[indCh]:=True;
        Form1.gProgress1.Progress:=Form1.gProgress1.Progress+1;
      end;
    end;
  end;
end;
//==============================================================================




//==============================================================================
//Основная процедура потока для записи гистограммы мгновенных.Пункт 1 ТЗ ИРУТ
//==============================================================================
procedure TThreadWriteGist.Execute;
var
  i:Integer;
begin
  //РАБОТА ТОЛЬКО С БЫСТРЫМИ
  for i:=1 to MAX_CH_COUNT_FAST do
  begin
    arrEnbChannal[i]:=False;
  end;

  //Перебираем все найденные в каталоге файлы ИРУТа
  //form1.Memo1.Lines.Add(DateTimeToStr(Now)+' Начало GIST');

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
  Form1.tmr2.Enabled:=true;
  Form1.tmr2.Tag:=MAX_CH_COUNT_FAST;
end;
//==============================================================================
end.

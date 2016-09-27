unit ConstUnit;

interface
uses
  Classes, SysUtils, Dialogs, DateUtils, Forms, Windows, Messages;
const
  //unit1
  //TRACK_SIZE_KOEF=224;//коэф. масштабирования для ТрекБара
  RTPOCKETNUM=31;// количество обр. пакетов за 10 мс таймера в реалтайме
  //MAXNUMINDOUBLE=1.79E25;
  //MAXFORERROR=1.7E10;//барьер для обхода сбоев про сборе времени
  //максимальное количество датчиков подкл. к ИРУТ 24+3
  //MAX_SENSOR_COUNT=27;
  //максимальное число всех каналов
  MAX_CH_COUNT={29}30;
  //максимальное число быстрых каналов
  MAX_CH_COUNT_FAST=24;
  //максимальное число медленных каналов
  MAX_CH_COUNT_SLOW=5;
  //максимальное количество частотных диапазонов обработки (ТЗ п.2)
  MAX_FREQ_RANGES={100000}100000; //старый вариант  100000
  //константа точности округления
  NUM_PRECIGION=100;
  //константа максимального значения массивов косинусов и синусов
  MAX_T_NUM={10000}4000;//старый вариант 4000
  MAX_T_NUM2=16000000;//старый вариант 16000000
  //количество байт в пакете
  POCKETSIZE=26;
  //константа для получения физич. величин
  SDVIG=100;
  //максимальное количество байт в буфере чтения из файла
  BUFF_NUM=20000000;
  //количество процессов. Равно количеству ядер
  NUM_PROCESS=24;
  //Максимальное количество процессов для обработки пункта 1 ТЗ
  PROC_NUM=100;
  //Максимальное количество выполненных процессов по обработке
  COMPL_PROC_NUM=100;
  //количество пакетов считываемое за раз за 1 раз из файла
  //целесообразно назначать количество пакетов в 10 раз больше
  //чем количество точек в одном интервале обработки (poolFastVal*10)
  READ_POCKET_NUM=600000;
  //количество подинтервалов 1 пункт ТЗ
  INTERVAL_NUM={100000}1000;//старый вариант 1000
  //количество значений в каждом буфере канала
  //FAST_VAL_NUM=1000000;

  //log
  //количество файлов-гистограмм. 24 быстрых + 5 медленных
  FILE_NUM_LOG=MAX_CH_COUNT;
  //количество значений в каждом буфере канала
  PROC_VAL_NUM={4800000}100000;//старый вариант 100000 . 1600 частота на 300сек
  //номер пакета с калибровкой +5 В
  NUM_P_P5V=22;
  //номер пакета с калибровкой -5 В
  NUM_P_M5V=23;
  //номер пакета с калибровкой 0 В
  NUM_P_0V=24;
  //номер первого пакета с колибровкой в 20 мА
  F_NUM_P_20mA=32;
  //номер первого пакета с колибровкой в 4 мА
  F_NUM_P_4mA=33;

  //gist
  //количество файлов-гистограмм
  FILE_NUM_GIST=MAX_CH_COUNT_FAST;

  //sko
  //количество файлов-гистограмм
  FILE_NUM_SKZ=MAX_CH_COUNT_FAST;
  //коэффициент разбиения
  KOEF_R=12;
  //колич. точек для подсчета спектра
  //MAX_POINT_IN_SPECTR=512;
  //максимальный размер буфера скоростей
  //SIZE_BUF_SPEED=1000;
  //макс. размер блока с учетом частоты опроса 1600 и длит. 5 мин.
  //максимальный размер буфера БПФ
  BPF_P_SIZE={5000000}500000;//старый вариант 500000
  //NUM_ARR_PART=10000;
  MAX_POINT_IN_FREQ_R={1000000}100000;//старый вариант 100000
  //MAX_POINT_INT_STR_ARR=100000;
  MAX_COLIB_P={1000000}100000;//старый вариант 100000
type

//TProc=array [1..PROC_VAL_NUM] of {word}{byte}real;
//тип краткой информации по датчику
TChanalType=record
  enabled:boolean;
  typeS:string;

  //в зависимости от типа датчика будут задаваться те или иные номера каналов

  //диапазоны измерения
  //от
  begRange:Double;
  //до
  endRange:Double;

  //номер канала для выборки температуры
  slowParT:integer;
  //номер канала для выборки влажности
  slowParV:integer;
  //номер канала для выборки давления
  slowParP:integer;

  //настройки каналов для отображения превышения пользовательского уровня
  minUserVal:Double;
  maxUserVal:Double;
end;


var
  

  //startFlagSlow:boolean=false;

  //байтовый размер чтения из файла данных
  blockSize:cardinal;

  //

  //массив обработанных каналов
  arrEnbChannal:array[1..MAX_CH_COUNT] of Boolean;


  //отдельный массив для медленных
  slowArray:array[1..MAX_CH_COUNT_SLOW+1] of array [1..30000{300000}] of real;
  //счетчик медленных
  iSlowArray:Cardinal=1;
  iSlowArrayOld:Cardinal=1;

  //размер считываемого буфера будет зависеть от частоты опроса и длит. обр. интервала
  //!!!
  //buff:array[1..POCKETSIZE*60000] of byte;
  //buff:array of byte;


  //массив подкл. {датчиков} каналов
  arrEnableChanals:array [1..MAX_CH_COUNT] of TChanalType;

  //вспомогательный массив для правильного преобразования каналов
  slowHelpArr:array[1..{MAX_CH_COUNT_SLOW}MAX_CH_COUNT_SLOW+1] of string;
  //iPosInBufPrev:integer=26;
  //массив флагов завершенности процессов обработки
  //arrComplProc:array[1..COMPL_PROC_NUM] of boolean;
  //flagCompl:Boolean;

  //флаги заверш. потоков
  skoCompl:boolean=false;
  gistCompl:Boolean=false;
  logCompl:boolean=False;

  // procedure SetDateToPocket(iPock:integer);
  //procedure WriteFast(iPos:integer);
  //procedure WriteSlow(ich:integer;iPos:Integer;count:integer);
  procedure getChRange(sens:double;chNum:integer);
implementation
{uses
Unit1;}


//==============================================================================
// Получение диапазона канала по его чувствительности в м/c2
//==============================================================================
procedure getChRange(sens:double;chNum:integer);
begin
   if FloatToStr(sens)='1.019' then
   begin
     arrEnableChanals[chNum].begRange:=-4.9;
     arrEnableChanals[chNum].endRange:=4.9;
   end;
   if FloatToStr(sens)='0.509' then
   begin
     arrEnableChanals[chNum].begRange:=-9.8;
     arrEnableChanals[chNum].endRange:=9.8;
   end;
   if FloatToStr(sens)='0.254' then
   begin
     arrEnableChanals[chNum].begRange:=-19.6;
     arrEnableChanals[chNum].endRange:=19.6;
   end;
   if FloatToStr(sens)='0.101' then
   begin
     arrEnableChanals[chNum].begRange:=-49;
     arrEnableChanals[chNum].endRange:=49;
   end;
   if FloatToStr(sens)='0.050' then
   begin
     arrEnableChanals[chNum].begRange:=-98;
     arrEnableChanals[chNum].endRange:=98;
   end;
   if FloatToStr(sens)='0.025' then
   begin
     arrEnableChanals[chNum].begRange:=-196;
     arrEnableChanals[chNum].endRange:=196;
   end;
   if FloatToStr(sens)='0.01' then
   begin
     arrEnableChanals[chNum].begRange:=-490;
     arrEnableChanals[chNum].endRange:=490;
   end;
   if FloatToStr(sens)='0.005' then
   begin
     arrEnableChanals[chNum].begRange:=-980;
     arrEnableChanals[chNum].endRange:=980;
   end;
   {case sens of
      1.019:
      begin
        arrEnableChanals[chNum].begRange:=-4.9;
        arrEnableChanals[chNum].endRange:=4.9;
      end;
      0.509:
      begin
        arrEnableChanals[chNum].begRange:=-9.8;
        arrEnableChanals[chNum].endRange:=9.8;
      end;
      0.254:
      begin
        arrEnableChanals[chNum].begRange:=-19.6;
        arrEnableChanals[chNum].endRange:=19.6;
      end;
      0.101:
      begin
        arrEnableChanals[chNum].begRange:=-49;
        arrEnableChanals[chNum].endRange:=49;
      end;
      0.050:
      begin
        arrEnableChanals[chNum].begRange:=-98;
        arrEnableChanals[chNum].endRange:=98;
      end;
      0.025:
      begin
        arrEnableChanals[chNum].begRange:=-196;
        arrEnableChanals[chNum].endRange:=196;
      end;
      0.01:
      begin
        arrEnableChanals[chNum].begRange:=-490;
        arrEnableChanals[chNum].endRange:=490;
      end;
      0.005:
      begin
        arrEnableChanals[chNum].begRange:=-980;
        arrEnableChanals[chNum].endRange:=980;
      end;
   end;}
end;
//==============================================================================



end.

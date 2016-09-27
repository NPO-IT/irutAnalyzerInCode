unit ConstUnit;

interface
uses
  Classes, SysUtils, Dialogs, DateUtils, Forms, Windows, Messages;
const
  //unit1
  //TRACK_SIZE_KOEF=224;//����. ��������������� ��� ��������
  RTPOCKETNUM=31;// ���������� ���. ������� �� 10 �� ������� � ���������
  //MAXNUMINDOUBLE=1.79E25;
  //MAXFORERROR=1.7E10;//������ ��� ������ ����� ��� ����� �������
  //������������ ���������� �������� �����. � ���� 24+3
  //MAX_SENSOR_COUNT=27;
  //������������ ����� ���� �������
  MAX_CH_COUNT={29}30;
  //������������ ����� ������� �������
  MAX_CH_COUNT_FAST=24;
  //������������ ����� ��������� �������
  MAX_CH_COUNT_SLOW=5;
  //������������ ���������� ��������� ���������� ��������� (�� �.2)
  MAX_FREQ_RANGES={100000}100000; //������ �������  100000
  //��������� �������� ����������
  NUM_PRECIGION=100;
  //��������� ������������� �������� �������� ��������� � �������
  MAX_T_NUM={10000}4000;//������ ������� 4000
  MAX_T_NUM2=16000000;//������ ������� 16000000
  //���������� ���� � ������
  POCKETSIZE=26;
  //��������� ��� ��������� �����. �������
  SDVIG=100;
  //������������ ���������� ���� � ������ ������ �� �����
  BUFF_NUM=20000000;
  //���������� ���������. ����� ���������� ����
  NUM_PROCESS=24;
  //������������ ���������� ��������� ��� ��������� ������ 1 ��
  PROC_NUM=100;
  //������������ ���������� ����������� ��������� �� ���������
  COMPL_PROC_NUM=100;
  //���������� ������� ����������� �� ��� �� 1 ��� �� �����
  //������������� ��������� ���������� ������� � 10 ��� ������
  //��� ���������� ����� � ����� ��������� ��������� (poolFastVal*10)
  READ_POCKET_NUM=600000;
  //���������� ������������� 1 ����� ��
  INTERVAL_NUM={100000}1000;//������ ������� 1000
  //���������� �������� � ������ ������ ������
  //FAST_VAL_NUM=1000000;

  //log
  //���������� ������-����������. 24 ������� + 5 ���������
  FILE_NUM_LOG=MAX_CH_COUNT;
  //���������� �������� � ������ ������ ������
  PROC_VAL_NUM={4800000}100000;//������ ������� 100000 . 1600 ������� �� 300���
  //����� ������ � ����������� +5 �
  NUM_P_P5V=22;
  //����� ������ � ����������� -5 �
  NUM_P_M5V=23;
  //����� ������ � ����������� 0 �
  NUM_P_0V=24;
  //����� ������� ������ � ����������� � 20 ��
  F_NUM_P_20mA=32;
  //����� ������� ������ � ����������� � 4 ��
  F_NUM_P_4mA=33;

  //gist
  //���������� ������-����������
  FILE_NUM_GIST=MAX_CH_COUNT_FAST;

  //sko
  //���������� ������-����������
  FILE_NUM_SKZ=MAX_CH_COUNT_FAST;
  //����������� ���������
  KOEF_R=12;
  //�����. ����� ��� �������� �������
  //MAX_POINT_IN_SPECTR=512;
  //������������ ������ ������ ���������
  //SIZE_BUF_SPEED=1000;
  //����. ������ ����� � ������ ������� ������ 1600 � ����. 5 ���.
  //������������ ������ ������ ���
  BPF_P_SIZE={5000000}500000;//������ ������� 500000
  //NUM_ARR_PART=10000;
  MAX_POINT_IN_FREQ_R={1000000}100000;//������ ������� 100000
  //MAX_POINT_INT_STR_ARR=100000;
  MAX_COLIB_P={1000000}100000;//������ ������� 100000
type

//TProc=array [1..PROC_VAL_NUM] of {word}{byte}real;
//��� ������� ���������� �� �������
TChanalType=record
  enabled:boolean;
  typeS:string;

  //� ����������� �� ���� ������� ����� ���������� �� ��� ���� ������ �������

  //��������� ���������
  //��
  begRange:Double;
  //��
  endRange:Double;

  //����� ������ ��� ������� �����������
  slowParT:integer;
  //����� ������ ��� ������� ���������
  slowParV:integer;
  //����� ������ ��� ������� ��������
  slowParP:integer;

  //��������� ������� ��� ����������� ���������� ����������������� ������
  minUserVal:Double;
  maxUserVal:Double;
end;


var
  

  //startFlagSlow:boolean=false;

  //�������� ������ ������ �� ����� ������
  blockSize:cardinal;

  //

  //������ ������������ �������
  arrEnbChannal:array[1..MAX_CH_COUNT] of Boolean;


  //��������� ������ ��� ���������
  slowArray:array[1..MAX_CH_COUNT_SLOW+1] of array [1..30000{300000}] of real;
  //������� ���������
  iSlowArray:Cardinal=1;
  iSlowArrayOld:Cardinal=1;

  //������ ������������ ������ ����� �������� �� ������� ������ � ����. ���. ���������
  //!!!
  //buff:array[1..POCKETSIZE*60000] of byte;
  //buff:array of byte;


  //������ �����. {��������} �������
  arrEnableChanals:array [1..MAX_CH_COUNT] of TChanalType;

  //��������������� ������ ��� ����������� �������������� �������
  slowHelpArr:array[1..{MAX_CH_COUNT_SLOW}MAX_CH_COUNT_SLOW+1] of string;
  //iPosInBufPrev:integer=26;
  //������ ������ ������������� ��������� ���������
  //arrComplProc:array[1..COMPL_PROC_NUM] of boolean;
  //flagCompl:Boolean;

  //����� ������. �������
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
// ��������� ��������� ������ �� ��� ���������������� � �/c2
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

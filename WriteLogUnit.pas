unit WriteLogUnit;

interface
uses
Classes, SysUtils, Dialogs, DateUtils, Forms,ConstUnit, ExcelWorkUnit;
const
  ExcelApp = 'Excel.Application';
type
//����� ��� ������
TThreadWriteLog = class(TThread)
  private
    { Private declarations }
  protected
    procedure Execute; override;
end;

//��� ������ ��� ��������� ������ ������� ������ � �����
{TProcess=class(TThread)
private
  //� ������ ������� �������� ���������
  indBeg:integer;
  //������� �������� ���� ������������
  numArr:integer;
  //����� ��������
  prNum:integer;
  //�����. ��� ����� � �������
  numP:integer;
  //writeNBlock:boolean;
  //��������� 1 ������
  procedure ParseBuf(arrNum:integer;numValInFfileBufer:integer);
  //����� 1 ������
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
  //����� ��� ������������ ������
  thWriteLog: TThreadWriteLog;
  //������� �����
  kadrCount:integer;
  //��������� ���� ������
  fileF:text;
  //���������� ��� �������� �������� �������
  timeCount:int64;
  //������� ������
  blockCount:cardinal;
  //������ ���������
  //thLogArr:array[1..PROC_NUM] of TProcess;
  //������������ �������� �� ����
  maxVal:{word}real=0;
  iBlock:integer;
  //������ ������� �������� ��� ������� �����
  procArray:array [1..MAX_CH_COUNT] of TProc;
  //������������� �������
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

  //���������� ��� �������
  kolibP5V:byte;
  kolibM5V:byte;
  kolib0V:byte;

  //���������� ��� ���������
  kolib20mA:byte;
  kolib4mA:byte;
  //������ ������ ������������� ��������� ���������
  arrComplProc:array[1..COMPL_PROC_NUM] of boolean;

  //������ ����������� �������� ������
  pocket:array[1..POCKETSIZE]  of byte;

  buff:array [1..BUFF_NUM] of byte;

  startFlagFast:boolean;

  flagConq:Boolean;

  //���� ��� ����� ������� ������ �����
  blockFlag:Boolean=true;

  //����� �����
  blockTimeTh:string;
  minSpeedTh:integer=-5;
  maxSpeedTh:integer=-5;
  latStrTh:string;
  lonStrTh:string;

  fileName:string;


  //������� ���������� �����
  colCount:Integer;
  //������� ���������� �����
  rowCount:Integer;

implementation
uses
Unit1,WriteGistUnit,TestChUnit;

//==============================================================================
//������� �������� ������� � ������
//==============================================================================
function getColibValF(kodVal:{byte}real;kP:byte;kM:byte):real;
begin
 //10 ��� ������ �� -5 �� 5
 Result:=((kodVal-kM)/(kP-kM))*10-5;
end;
//==============================================================================

//==============================================================================
//������� �������� ������� �� ����� � �/c2
//==============================================================================
function getAcs(volt:double;kP:double;kM:double;diap:double):real;
begin
 //abs(diap*2) ��� ������ �� -5� �� 5�
 Result:=((volt-kM)/(kP-kM))*abs(diap*2)+diap;
end;
//==============================================================================

//==============================================================================
//������� �������� ��������� � ��
//==============================================================================
function getColibValS(kodVal:{byte}real;k20mA:byte;k4mA:byte):real;
begin
  //16 ��� ������ 20-4
  Result:=((kodVal-k4mA)/(k20mA-k4mA))*16+4;
end;
//==============================================================================

//==============================================================================
//������� �������� ��������� � �������
//==============================================================================
function getT(kodVal:{byte}real;kP:integer;kM:integer):real;
begin
 //150 ��� ������ �� -40 �� 110
 Result:=((kodVal-kM)/(kP-kM))*{10}150-{5}40;
end;
//==============================================================================

//==============================================================================
//������� �������� ��������� � �������� ���������
//==============================================================================
function getV(kodVal:{byte}real;kP:integer;kM:integer):real;
begin
 //10 ��� ������ �� 0 �� 100
 Result:=((kodVal-kM)/(kP-kM))*100;
end;
//==============================================================================

//==============================================================================
//������� �������� ��������� � ��������
//==============================================================================
function getP(kodVal:{byte}real;kP:integer;kM:integer):real;
begin
 //2496 ��� ������ �� 4 �� 2496
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
    //��������� ��������� �� �����, ���� ��� ��������� ��� �������� ������
    if (arrEnableChanals[i].enabled) then
    begin
      //��������� ����� ���������� +5 -5 ��� ���
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
//������� ��� ����� �������� ������. ���������� ����� �������� �����. ������ �������
//==============================================================================
function CollectCounterTh(iByteDj:integer):byte;
begin
  result:=pocket[iByteDj];
end;
//==============================================================================

//==============================================================================
//�������� �������� �������
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
    //�������� ����� ���� � UnixTime
    timeGEOS_int:=timeGEOS+1199145600{+14400};
    //�������� � ������� dateTime
    dT:=UnixToDateTime(timeGEOS_int);
    //�������� ����� � ������
    DateTimeToString(dtStr,'dd.mm.yyyy hh:mm:ss',dT);
    //����� �������
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
//�������� �������� ������
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
    latStr:=floatToStr(gradLat)+'� '+floatToStr(minLat)+''' '+floatToStr(secLat)+'"';
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
//�������� �������� �������
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
    lonStr:=floatToStr(gradLon)+'� '+floatToStr(minLon)+''' '+floatToStr(secLon)+'"';
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
//�������� ��������
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
//������� ��������� �������� �� ����� ������ ��������.
//���������� ����� ������ � ����� �������� ���������� ������
//==============================================================================
function testCh(chNumber:integer;currentPocketNum:integer):boolean;
var
  //��� �������
  step:integer;
  //��������� ����� �������� ������, �������� ������� �� ������ ������
  begPocketNum:integer;
  //�������� ������� ������ ������
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
      //1 �����
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
      //6 �����
      begPocketNum:=31;
      endPocketNum:=191;
    end;
    //�����. 20��
    7:
    begin
      begPocketNum:=32;
      endPocketNum:=192;
    end;
    //�����. 4��
    8:
    begin
      //6 �����
      begPocketNum:=33;
      endPocketNum:=193;
    end;

    //���������� +5�
    22:
    begin
      begPocketNum:=22;
      endPocketNum:=22;
    end;
     //���������� -5�
    23:
    begin
      begPocketNum:=23;
      endPocketNum:=23;
    end;
     //���������� 0�
    24:
    begin
      begPocketNum:=24;
      endPocketNum:=24;
    end;
  end;
  //������������� ����� ������� ������ ��� ����������� ������ ������
  i:=begPocketNum;
  //���������� ��� ��������� ������ ��� ����������� ������
  while i<=endPocketNum do
  begin
    //���� ������� ����� ����� ���� ���������
    if i=currentPocketNum then
    begin
      //����� � �����
      bool:=true;
      break;
    end;
    i:=i+step;
  end;
  result:=bool;
end;
//==============================================================================

//==============================================================================
//������ ������ ���� �� ������� ������-�������
//==============================================================================
procedure ParsePocketToSignalBlocks(iPosInBuf:integer);
var
  i:integer;
  j:integer;
  //iWrite:integer;
  //����� �������� ������
  counter:byte;

  time:string;
  lat:string;
  lon:string;
  speed:string;
  speedI:integer;
begin
  //������� ����� ������
  counter:=CollectCounterTh(1);

  //�����
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

  //������
  if ((counter>=4) and (counter<=7)) then
  begin
    lat:=CollectLatitudeTh(length(pocket),counter);
    if lat<>'nil' then
    begin
      latStrTh:=lat;
    end;
  end;

  //�������
  if ((counter>=8) and (counter<=11)) then
  begin
    lon:=CollectLongtitudeTh(length(pocket),counter);
    if lon<>'nil' then
    begin
      lonStrTh:=lon;
    end;
  end;

  //��������
  if ((counter>=14) and (counter<=15)) then
  begin
    speed:=CollectSpeedTh(length(pocket),counter);
    if speed<>'nil' then
    begin
      speedI:=StrToInt(speed);
      if ((minSpeedTh=-5) and (maxSpeedTh=-5)) then
      begin
        //������ ���� �������� �� ����
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


  //��������� ��� ������ ����� � ����������� +5�
  if (testCh(NUM_P_P5V,counter)) then
  begin
    //+5�
    kolibP5V:=pocket[length(pocket)];
    arrKolibP5V[iKP5V]:=kolibP5V;
    Inc(iKP5V);
  end;

  //��������� ��� ������ ����� � ����������� -5�
  if (testCh(NUM_P_M5V,counter)) then
  begin
    //-5�
    kolibM5V:=pocket[length(pocket)];
    arrkolibM5V[iKM5V]:=kolibM5V;
    Inc(iKM5V);
  end;

  //��������� ��� ������ ����� � ����������� 0�
  if (testCh(NUM_P_0V,counter)) then
  begin
    //0 �
    kolib0V:=pocket[length(pocket)];
    arrkolib0V[iK0V]:=kolib0V;
    Inc(iK0V);
  end;

  //=====
  //���������� ��������� ����������
  //�����1
  if (testCh(1,counter)) then
  begin
    slowArray[1][iSlowArray]:=pocket[length(pocket)];
  end;
  //�����2
  if (testCh(2,counter)) then
  begin
    slowArray[2][iSlowArray]:=pocket[length(pocket)];
  end;
  //�����3
  if (testCh(3,counter)) then
  begin
    slowArray[3][iSlowArray]:=pocket[length(pocket)];
  end;
  //�����4
  if (testCh(4,counter)) then
  begin
    slowArray[4][iSlowArray]:=pocket[length(pocket)];
  end;
  //�����5
  if (testCh(5,counter)) then
  begin
    slowArray[5][iSlowArray]:=pocket[length(pocket)];
  end;
  //�����6
  if (testCh(6,counter)) then
  begin
    slowArray[6][iSlowArray]:=pocket[length(pocket)];
    inc(iSlowArray);
  end;
  //���������,��� ������ ����� � �����. 20��
  if (testCh(7,counter)) then
  begin
    kolib20mA:=pocket[length(pocket)];
  end;
  //��������� ��� ������ ����� � �����. 4��
  if (testCh(8,counter)) then
  begin
    kolib4mA:=pocket[length(pocket)];
    //��������� ��������� � ��
    for i:=1 to 6 do
    begin
      for j:=iSlowArrayOld to iSlowArray-1 do
      begin
        slowArray[i][j]:=getColibValS(slowArray[i][j],kolib20mA,kolib4mA);
        //��������� ����� ��� �������� �,V,P
        {if slowHelpArr[i]='T' then
        begin
          //����
          slowArray[i][j]:=getT(slowArray[i][j],110,-40);
        end;
        if slowHelpArr[i]='V' then
        begin
          //%
          slowArray[i][j]:=getV(slowArray[i][j],100,0);
        end;
        if slowHelpArr[i]='P' then
        begin
          //���
          slowArray[i][j]:=getP(slowArray[i][j],2500,4);
        end;}

      end;
    end;
    iSlowArrayOld:=iSlowArray;
    //startFlagSlow:=true;
  end;
  //======

  //������ �������
  WriteFast(iPosInBuf);

  //������ ���������
  //WriteSlow(25,iPosInBuf,counter);
end;
//==============================================================================

//==============================================================================
//������������ ������ ������ ���� ��� ����������� �������
//==============================================================================
procedure SetDateToPocket(iPock:integer);
var
  i:integer;
  j:integer;
begin
  //��������� ������ � �����
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
//��������� ������� ������ ������-�����
//==============================================================================
{procedure TProcess.ParseBuf(arrNum:integer;numValInFfileBufer:integer);
var
  fileBufCount:integer;
  //�������������� ������������ ������
  writeStr:string;
  maxValNum:Integer;
begin
  //arrNum-���������� �������
  //g
  if arrNum<=FILE_NUM_LOG then
  begin
    //��������� ��������� �� �����, ���� ��� �� � �� ��������� ���, ��� ����
    if (arrEnableChanals[arrNum].enabled) then
    begin
      //������ ����� �����������
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

      //�������� ������������ �������� � �����
      //����� ������� �������� ��� � ��� ��������
      if (arrNum>=1)and(arrNum<=24) then
      begin
        //Form1.mmo1.Lines.Add('ddddd');
        //������� ��������
        maxVal:=getColibValF(maxVal,arrKolibP5V[trunc(maxValNum/224)+1],
          arrkolibM5V[trunc(maxValNum/224)+1]);

        maxVal:=getAcs(maxVal,5,-5,arrEnableChanals[arrNum].begRange);
      end;
      //��������� ������ ��� ������
      writeStr:=#9+floatToStrF(maxVal,ffFixed,3,3);
      //������� ���������� ��������� �������� ������������ ������
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
//��������������� ���������� ����� �� �������
//==============================================================================
procedure PreWriteLogFile;
var
  i:integer;

  slowN:integer;


begin
  colCount:=1;
  rowCount:=1;
  slowN:=1;
  //��������� ��� �����
  fileName:=ExtractFileDir(ParamStr(0))+'\Report'+'\log\'+'Log'+'.xls'; // xlsx

  //���������� � ������ � excel ������
  RunExcel(True,false);
  //���������� ������� �����
  AddWorkBook(True);
  //��������� ����� ������� �����
  //1 ��� ������ ������� �����, � ����1 ��� �� ��������
  //ActivateSheet(1,'����1');

  SetCellValue(MyExcel,'������',rowCount,colCount);
  Inc(colCount);
  SetCellValue(MyExcel,'���� � ����� ������ �����',rowCount,colCount);
  Inc(colCount);
  SetCellValue(MyExcel,'������� ��������',rowCount,colCount);
  Inc(colCount);
  SetCellValue(MyExcel,'���. ��������',rowCount,colCount);
  Inc(colCount);
  SetCellValue(MyExcel,'����. ��������',rowCount,colCount);
  Inc(colCount);
  SetCellValue(MyExcel,'������',rowCount,colCount);
  Inc(colCount);
  SetCellValue(MyExcel,'�������',rowCount,colCount);
  Inc(colCount);
  //������� ��� ������
  {AssignFile(fileF,fileName);
  Rewrite(fileF);
  write(fileF,'������':20);
  write(fileF,#9+'���� � ����� ������ �����':40);
  write(fileF,#9+'������� ��������':40);
  write(fileF,#9+'���. ��������':40);
  write(fileF,#9+'����. ��������':40);
  write(fileF,#9+'������':40);
  write(fileF,#9+'�������':40);}


  //��� ������� � ���������
  for i:=1 to MAX_CH_COUNT do
  begin
    // ������� �� �����
    if  (arrEnableChanals[i].enabled) then
    begin
      //�������?
      if arrEnableChanals[i].typeS='fast' then
      begin
        SetCellValue(MyExcel,'��'+intToStr(i)+',�/c2',rowCount,colCount);
        //write(fileF,#9+'��'+intToStr(i)+',�/c2':10);

        //form1.Memo1.Lines.Add('+ '+'fast '+intToStr(i));
      end;
       //���������?
      if ((arrEnableChanals[i].typeS='slowTV')or
          (arrEnableChanals[i].typeS='slowP')) then
      begin
        if slowHelpArr[slowN]='T' then
        begin
          //������������� ��������
          SetCellValue(MyExcel,'��'+intToStr(slowN)+',�',rowCount,colCount);
          //write(fileF,#9+'��'+intToStr(slowN)+',�':10);
        end;

        if slowHelpArr[slowN]='V' then
        begin
          //����������� ��������
          SetCellValue(MyExcel,'��'+intToStr(slowN)+',%',rowCount,colCount);
          //write(fileF,#9+'��'+intToStr(slowN)+',%':10);
        end;

        if slowHelpArr[slowN]='P' then
        begin
          //�������� ��������
          SetCellValue(MyExcel,'��'+intToStr(slowN)+',���',rowCount,colCount);
          //write(fileF,#9+'��'+intToStr(slowN)+',���':10);
        end;



        {if arrEnableChanals[i].slowParT<>0 then
        begin
          //������������� ��������
          write(fileF,#9+'��'+intToStr(slowN)+',�':10);
        end;
        if arrEnableChanals[i].slowParV<>0 then
        begin
          //����������� ��������
          write(fileF,#9+'��'+intToStr(slowN)+',%':10);
        end;
        if arrEnableChanals[i].slowParP<>0 then
        begin
          //�������� ��������
          write(fileF,#9+'��'+intToStr(slowN)+',���':10);
        end;}
         inc(slowN);
      end;
      //���� �������� �������
      //������������� ������� �� ����� ������ ��� ������
      Inc(colCount);
    end;
  end;
  //MyExcel.Visible:=true;
  //������������� ��� ���������� ������ �� ���� ������
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
//��������� �������� ������
//==============================================================================
procedure ParseFileBuffer(numValInFfileBufer:integer;flagWriteNumBlock:boolean);
var
  //������� �������� ������������ �������
  arrCount:integer;
  //����� ������� � �������� ������� ������ ������������
  iProcess:integer;
  //������� ���������� ���������� ��������
  //count:integer;
  //������� �������� ������� ����������� ����������� ���������
  i:integer;
  //iProc:integer;
  writeStr:string;
  //minSpeed:integer;
  //maxSpeed:integer;
  avSpeed:integer;
  //latStr:string;
  //lonStr:string;
  bool:Boolean;
  //������� ������
  iChannal:Integer;
  channalCurrentVal:integer;
  maxValNum:integer;

  //����� ��� ���������� ������� �� �������
  numberTr:Integer;

  count:Integer;
begin
  //��������� ������� ��������
  avSpeed:= round((minSpeedTh+maxSpeedTh)/2);

  //������� �������� ���. �� ����� � ������
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

  //��������� � ����� ������
  //��������� �������
  for iChannal:=1 to MAX_CH_COUNT_FAST do
  begin
    //��������� ��������� �� �����, ���� ��� �� � �� ��������� ���, ��� ����
    if (arrEnableChanals[iChannal].enabled) then
    begin
      //������ ����� �����������
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
            //���������� ����� ������ � ����. �������
            maxValNum:=channalCurrentVal;
          end;
        end;
        inc(channalCurrentVal);
      end;
      //�������� ������������ �������� � �����
      //����� ������� �������� ��� � ��� ��������
      if (iChannal>=1)and(iChannal<=24) then
      begin
        //������� ��������
        maxVal:=getColibValF(maxVal,arrKolibP5V[trunc(maxValNum/224)+1],
          arrkolibM5V[trunc(maxValNum/224)+1]);
        maxVal:=getAcs(maxVal,5,-5,arrEnableChanals[iChannal].begRange);


      end;

      //��������� ������ ��� ������
      //writeStr:=#9+floatToStrF(maxVal,ffFixed,3,3);
       //������� ���������� ��������� �������� ������������ ������
      //write(fileF,writeStr);

      SetCellValue(MyExcel,floatToStrF(maxVal,ffFixed,3,3),rowCount,colCount);
      if maxVal*100>arrEnableChanals[iChannal].maxUserVal*100 then
      begin
        //���� �������� ��������� ������ ��������� ���������������� �������� ���������
        //�� ���� �� ��������� ������ ������� ������
        SetCellColor(MyExcel,3,rowCount,colCount);
      end;

      if maxVal*100<arrEnableChanals[iChannal].minUserVal*100 then
      begin
        //������ ��������
        SetCellColor(MyExcel,3,rowCount,colCount);
      end;


      Inc(colCount);

      // form1.Memo1.Lines.Add('����� '+intToStr(iChannal)+' ���������!');
    end;
  end;

  count:=1;

  //��������� ��������� 6 �������
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
              //���������� ����� ������ � ����. �������
              maxValNum:=channalCurrentVal;
            end;
          end;
          inc(channalCurrentVal);
        end;

        
        //��������� ����� ��� �������� �,V,P
        if slowHelpArr[{iChannal}count]='T' then
        begin
          //����
          maxVal:=getT(maxVal,{110}20,{-40}4);
        end;
        if slowHelpArr[{iChannal}count]='V' then
        begin
          //%
          maxVal:=getV(maxVal,{100}20,4{0});
        end;
        if slowHelpArr[{iChannal}count]='P' then
        begin
          //���
          maxVal:=getP(maxVal,{2500}20,4{4});
        end;

        inc(count);

        //��������� ������ ��� ������
        //writeStr:=#9+floatToStrF(maxVal,ffFixed,5,3);
        //������� ���������� ��������� �������� ������������ ������
        //write(fileF,writeStr);
        SetCellValue(MyExcel,floatToStrF(maxVal,ffFixed,5,3),rowCount,colCount);

        numberTr:=GetNumber(arrEnableChanals[iChannal+MAX_CH_COUNT_FAST].slowParT,
                            arrEnableChanals[iChannal+MAX_CH_COUNT_FAST].slowParV,
                            arrEnableChanals[iChannal+MAX_CH_COUNT_FAST].slowParP);


        if  (iChannal+MAX_CH_COUNT_FAST)<30 then
        begin
          if maxVal*100>arrEnableChanals[{iChannal}numberTr+MAX_CH_COUNT_FAST].maxUserVal*100 then
          begin
            //���� �������� ��������� ������ ��������� ���������������� �������� ���������
            //�� ���� �� ��������� ������ ������� ������
            SetCellColor(MyExcel,3,rowCount,colCount);
          end;

          if maxVal*100<arrEnableChanals[{iChannal}numberTr+MAX_CH_COUNT_FAST].minUserVal*100 then
          begin
            //���� �������� ��������� ������ ��������� ���������������� �������� ���������
            //�� ���� �� ��������� ������ ������� ������
            SetCellColor(MyExcel,3,rowCount,colCount);
          end;
          Inc(colCount);
        end;
     end;
  end;

  // form1.Memo1.Lines.Add('���� '+intToStr(iBlock)+' ���������!');
  //write(fileF,#13#10);
  inc(iBlock);
  //MyExcel.Visible:=true;
  //������������� � ������ �� ����. ������
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
//������ ���������� ����� ������.
//==============================================================================
procedure ParseReadBlock(blSize:cardinal;var pocketNum:integer;var numPointInK:integer;
var blCount:cardinal;pocketCount:integer);
var
  iPocket:Cardinal;
begin
  iPocket:=1;
  while iPocket<=blSize do
  begin
    //��������� ����� ������ �� ���������� ����� ����.
    SetDateToPocket(iPocket);
    //����������� �������� ������ �� ������-������
    ParsePocketToSignalBlocks(pocketNum);
    //����� ��������.
    //����������� ������ ������ �� ���� �������
    inc(pocketNum);
    //����������� �������� ��� �������� �����
    inc(numPointInK);

    //��������� �� ������� �� ������ ����������
    //����� ������ ��c���� ������������� �����.
    if pocketNum=poolFastVal then
    begin
      ParseFileBuffer(pocketNum,false);
      //����������� ������� ����� ������.
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

    //��������� ������� �����
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
//�������� ��������� ������ ��� ������ ����� ����� 3 �� ����
//==============================================================================
procedure TThreadWriteLog.Execute;
var
  //iPosInBufPrev:=1;
  //����� ������ �� �����
  readStream: TFileStream;
  //������ ����� � ������� ������
  ind:integer;
  //������� ��� ������� ����. ������ �� ������-�������
  //i:integer;
  //j:integer;
  //������� ���������� ����������� ����� � �����.
  countPointInBlock:integer;
  //������� ���������� ����������� ����� � �����.
  countPointInKadr:integer;
  //nameStr:string;
  flagEnableRead:boolean;
  //���������� ���� ��� ��������� ������
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
  //1 ������ 2008 ����;
  timeCount:=DateTimeToUnix(Now);{1199145600+14400};
  //��������� ������ ���� �� ������ �� ������
  readStream:=TFileStream.Create(SCRUTfileArr[ind].path,fmShareDenyNone{fmOpenRead});

  //��������������� ���������� ����� �����
  PreWriteLogFile;

  //closefile(fileF);
  //���������� ��� ��������� � �������� ����� �����
  //form1.Memo1.Lines.Add(DateTimeToStr(Now)+' ������ LOG');
  //������ � �������� � ����������
  //���������� ��� ��������� � �������� ����� �����
  while ind<length(SCRUTfileArr) do
  begin
    //��������� �� ������� �� ��� ���������� ������ �����
    if (flagConq) then
    begin
      flagConq:=false;
      //���������� ���� ������� ����� ������� �� ������ ��������� �����
      //� ������ ������� �� ����������� ���� ����� �������� ����� ���� ������
      //������ �� ����� ���� �������� ����� �������� ����� ���� ������
      readStream.Read(buff,blockSize);
      countPointInBlock:=1;
      //������ ���������� ����� ������
      ParseReadBlock(blockSize,countPointInBlock,countPointInKadr,
        blockCount,poolFastVal);
    end
    else
    begin
      //������� ������� ������ �����
      if (flagEnableRead) then
      begin
        //������ �� ����� ���� ����������� �������
        readStream.Read(buff, blockSize);
        //������ ���������� ����� ������
        ParseReadBlock(blockSize,countPointInBlock,countPointInKadr,
          blockCount,poolFastVal);
      end
      else
      begin
        //������� ���������� �������������� ���� �� ����� �����
        numPointToEnd:=readStream.Size-readStream.Position;
        //������� ����� ���� �� ����� �����
        readStream.Read(buff,readStream.Size-readStream.Position);
        //������ ���������� ����� ������
        ParseReadBlock(numPointToEnd,countPointInBlock,countPointInKadr,
          blockCount,trunc(numPointToEnd/POCKETSIZE));
      end;
    end;


    //form1.Memo1.Lines.Add(IntToStr(readStream.Position)+' �� '+IntToStr(readStream.Size));
    if  readStream.Position>readStream.Size-blockSize then
    begin
      //���� ��� ������������� ������� ����� ���������� �� �����
      flagEnableRead:=false;
    end;
    //��������� �� �������� �� ���� �� �����
    if  readStream.Position>=readStream.Size then
    begin
      //���� ����������, ������� � ����������� ������ �� ���������
      readStream.Free;
      inc(ind);
      //��������� ���� �� ��������� ���� �� ���������
      if ind<length(SCRUTfileArr) then
      begin
        //������� ����. ����
        readStream:=TFileStream.Create(SCRUTfileArr[ind].path,fmShareDenyNone{fmOpenRead});
       // form1.Memo1.Lines.Add(intToStr(ind));
        //��������� ��������� � �������� ����� ������� �����
        flagEnableRead:=true;
        {if ind mod 2=1 then
          begin
            //��������� ���. ������
            inc(blockCount);
          end;}
        //���� ��������� ������ �� �������������� ����������� ������ ������
        ParseFileBuffer(countPointInBlock,false);
        //���� ������������ ������ ��� ���� �����
        //��������� ������ ���������� ������� ����� �������� ����
        flagConq:=true;
      end
      else
      begin
        //�.� ���� ��������� �� ���������� ���������� ����� ������� ����������
        //���� �� ������ ������
        inc(timeCount);
        ParseFileBuffer(countPointInBlock,true);
        countPointInBlock:=1;

        //form1.Memo1.Lines.Add(DateTimeToStr(Now)+' ����� LOG');
      end;
    end;

  end;

  //������� ���� �����
  //CloseFile(fileF);

  //��������� excel ���� �����
  SaveWorkBook(fileName,1);
  //��������� excel ���� �����
  StopExcel;






  //!!! ������ ���� ������ ���������
  if form2.chk1.Checked then
  begin
    thWriteGist.Resume;
  end;
  logCompl:=true;
  //���������� ��� ����� ���������� �����
  thWriteLog.Free;
  exit;
end;
//==============================================================================
end.

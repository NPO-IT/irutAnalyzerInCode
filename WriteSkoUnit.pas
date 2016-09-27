unit WriteSkoUnit;
interface
uses
Classes, SysUtils, Dialogs, DateUtils, Forms, ConstUnit;
type
//������� ��� ��� ���������� ����. �������
//TByteArr=array [1..MAX_POINT_IN_SPECTR] of byte;

//������������ ��� �������
//TIntArr=array [1..MAX_POINT_IN_SPECTR] of integer;
//TfastProc=array[1..FAST_VAL_NUM] of integer;
TarrBPF=array[1..BPF_P_SIZE] of integer;

//����� ��� ������
TThreadWriteSko = class(TThread)
  private
    { Private declarations }
  protected
    procedure Execute; override;
end;

//������� ��������� ������
TChannalProc=class(TThread)
private
  //������� �����
  kadrCount:integer;
  //����� �������� ��� �������� ��������������� ������
  procArray:array [1..PROC_VAL_NUM] of {word}{byte}real;
  startFlagFast:boolean;
  //���������� ��� �������
  kolibP5V:byte;
  kolibM5V:byte;
  kolib0V:byte;
  //���. ��������
  minSpeedTh:integer;
  //����. ��������
  maxSpeedTh:integer;
  //������
  latStrTh:string;
  //�������
  lonStrTh:string;
  //���� ��� ����� ������� ������ �����
  blockFlag:Boolean;
  //����� �����
  blockTimeTh:string;
  //������ ����������� �������� ������
  pocket:array[1..POCKETSIZE]  of byte;
  //����� ������ �� �����
  readStream: TFileStream;
  indFile:integer;
  //���� ���������� ������� �� ������ ������ ��� ��������� ������ �����
  flagConq:boolean;
  //������ ������������ ������ �� �����
  buff:array [1..BUFF_NUM] of byte;
  //������� ���������� ����������� ����� � �����.
  countPointInBlock:integer;
  //������� ���������� ����������� ����� � �����.
  countPointInKadr:integer;
  //������� ������
  blockCount:cardinal;
  flagEnableRead:boolean;
  //���������� ���� ��� ��������� ������
  numPointToEnd:cardinal;

  //������ ������������ ������-������
  indCh:integer;
  //writeNBlock:boolean;
  //���. �������� �� ����
  minSpeed:integer;
  //���� �������� �� ����
  maxSpeed:integer;
  //������ �������� ���
  arrBPF:array[1..KOEF_R] of TarrBPF;
  //������� ������ ���
  arrBpfAvr:array[1..BPF_P_SIZE] of integer;

  //���������� ���������� �������� ���
  numWriteSko:integer;

  numPointBeg:integer;
  numPointEnd:integer;

  numPointInSpectr:integer;
  numPointInArrBPF:integer;
  //���������� ������������ ����� � ������� ���������
  numPointInArrF:integer;

  //��������� ���� ����������� ��������� ������
  fileCh:Text;


  //������ ����� ����� ������� ������� ����������
  arrPointPart:array [1..BPF_P_SIZE] of double;
   //������ sko ��� ���� ��������� ����������
  sko:array[1..MAX_POINT_IN_FREQ_R] of real;
  //������ ����� ��� �������� ���������� ��������� ���������
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

  //���������� ��� ���������
  //kolib20mA:byte;
  //kolib4mA:byte;

  //��������� ������� ���������� �����
  procedure ParseReadBlock(blSize:cardinal;var pocketNum:integer;
    var numPointInK:integer;var blCount:cardinal;pocketCount:integer);
  //������������ ������ ������ ���� ��� ����������� �������
  procedure SetDateToPocket(iPock:integer);
  procedure ParsePocketToSignalBlocksFast(iPosInBuf:integer);
  function CollectCounterTh(iByteDj:integer):byte;
  function CollectTimeTh(iB:integer;count:byte):string;
  function CollectLatitudeTh(iB:integer;count:byte):string;
  function CollectLongtitudeTh(iB:integer;count:byte):string;
  function CollectSpeedTh(iB:integer;count:byte):string;
  procedure ParseFileBuffer(numValInFfileBufer:integer;flagWriteNumBlock:boolean);
  //��������� 1 ������
  procedure ParseBuf(numValInFfileBufer:integer);
  function CalculateSpectr(arrPointPartNum:integer):integer;
  //����� 1 ������
  procedure WriteBuf;
  function testCh(chNumber:integer;currentPocketNum:integer):boolean;
  //�� ���� � �
  function getColibValF(kodVal:{byte}real;kP:byte;kM:byte):real;
  //�� � � �/c2
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
  //����� ��� ������������ ������
  thWriteSko: TThreadWriteSko;
  channalThread:array[1..MAX_CH_COUNT] of TChannalProc;
implementation
uses Unit1, Math;
//---------------------------------------------------------------------
//==============================================================================
//������� ��������� �������� �� ����� ������ ��������.
//���������� ����� ������ � ����� �������� ���������� ������
//==============================================================================
function TChannalProc.testCh(chNumber:integer;currentPocketNum:integer):boolean;
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
//������� �������� ������� � ������
//==============================================================================
function TChannalProc.getColibValF(kodVal:{byte}real;kP:byte;kM:byte):real;
begin
 //10 ��� ������ �� -5 �� 5
 Result:=((kodVal-kM)/(kP-kM))*10-5;
end;
//==============================================================================

//==============================================================================
//������� �������� ������� �� ����� � �/c2
//==============================================================================
function TChannalProc.getAcs(volt:double;kP:double;kM:double;diap:double):double;
begin
 //abs(diap*2) ��� ������ �� -5� �� 5�
 Result:=((volt-kM)/(kP-kM))*abs(diap*2)+diap;
end;
//==============================================================================

//==============================================================================
//������� �������� ��������� � ��
//==============================================================================
function TChannalProc.getColibValS(kodVal:{byte}real;k20mA:byte;k4mA:byte):real;
begin
  //16 ��� ������ 20-4
  Result:=((kodVal-k4mA)/(k20mA-k4mA))*16+4;
end;
//==============================================================================

//==============================================================================
//��������� ������ ����� ������-�����
//==============================================================================
procedure TChannalProc.WriteBuf;
var
  //fileName:string;
  //�������������� ������������ ������
  writeStr:string;
  i:integer;
begin
  //������� �������� ���. �� ����� � ������
  writeStr:=floatToStr(kadrCount)+#9+blockTimeTh+#9+
    intToStr(round((minSpeedTh+maxSpeedTh)/2))+#9+intToStr(minSpeedTh)+#9+
      intToStr(maxSpeedTh)+#9+latStrTh+#9+lonStrTh;

  //������� �������� skz ��� �����
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
//���������� ������� �������. ���������� ���������� ����������� ��������
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
  //����������� ����������� �������.
  arrSize:integer;
  //�������� ������� �������
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
//��������� ������� ������ ������-�����
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

  //��������� �� ������� �� ��������
  if (minSpeedTh<>0)and(minSpeedTh<>0) then
  begin
    if (1-minSpeedTh/maxSpeedTh)<=procentD then
    begin
      //������ ����� �����������
      fileBufCount:=1;
      j:=1;
      i:=1;
      k:=1;
      while fileBufCount<=numValInFfileBufer do   //!!!
      begin
        if j<=trunc(numValInFfileBufer/KOEF_R) then
        begin
          //��������� � ����� ��� ���������� ���
          arrPointPart[k]:=procArray[fileBufCount];
          inc(j);
          inc(k);
          inc(fileBufCount);
        end
        else
        begin
          //�������� ����������� ����� �����
          //��������� ���, �� ������ ������� ������
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

      //������� ���� �� KOEF_R �������� ���
      //�������� ������� ������ ���
      numPointInArrBPF:=CalcAvrBPFarr(numPointInSpectr);
      i:=1;
      //���������� ��� ��������� ���������
      while i<=numFreqRange do
      begin
        //�������� ������ ����� � ������� ������� ���
        numPointBeg:=CalcNumP(arrFreqRange[i].beginRange,numPointInArrBPF,
        poolFastFreq);
        numPointEnd:=CalcNumP(arrFreqRange[i].endRange,numPointInArrBPF,
        poolFastFreq);
        dec(numPointEnd);
        //�������������� ����� � ���� ������
        k:=1;
        for j:=numPointBeg to numPointEnd do
        begin
          arrF[k]:=arrBpfAvr[j];
          inc(k);
        end;
        numPointInArrF:=k-1;
        //������� ��� � ������� � ������ ���
        sko[i]:=CalcSKO(arrF,numPointInArrF,numPointInArrBPF);
        inc(i);
      end;
      numWriteSko:=i-1;
      WriteBuf;
    end;
  end;
  //WriteBuf;
  //form1.Memo1.Lines.Add('����� ��������'+intToStr(indCh)+' ���!');
end;
//==============================================================================

//==============================================================================
//��������� �������� ������
//==============================================================================
procedure TChannalProc.ParseFileBuffer(numValInFfileBufer:integer;flagWriteNumBlock:boolean);
begin
  ParseBuf(numValInFfileBufer);
  blockFlag:=true;
  //form1.Memo1.Lines.Add('���� ����������!');
end;
//==============================================================================

//==============================================================================
//������� ��� ����� �������� ������. ���������� ����� �������� �����. ������ �������
//==============================================================================
function TChannalProc.CollectCounterTh(iByteDj:integer):byte;
begin
  result:=pocket[iByteDj];
end;
//==============================================================================

//==============================================================================
//�������� �������� �������
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
    //�������� ����� ���� � UnixTime
    timeGEOS_int:=timeGEOS+1199145600{+14400};
    //�������� � ������� dateTime
    dT:=UnixToDateTime(timeGEOS_int);
    //�������� ����� � ������
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
//�������� �������� ������
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
//������ ������ ���� �� ������� ������-�������
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
        //Form1.Memo1.Lines.Add('����� '+blockTimeTh );
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
  end;

  //��������� ��� ������ ����� � ����������� -5�
  if (testCh(NUM_P_M5V,counter)) then
  begin
    //-5�
    kolibM5V:=pocket[length(pocket)];
  end;

  //��������� ��� ������ ����� � ����������� 0�
  if (testCh(NUM_P_0V,counter)) then
  begin
    //0 �
    kolib0V:=pocket[length(pocket)];

    //���������� ��� ������ �������
    if not startFlagFast then
    begin
      for j:=1 to iPosInBuf-1 do
      begin
        procArray[j]:=getColibValF(procArray[j],kolibP5V,kolibM5V);
        procArray[j]:=getAcs(procArray[j],5,-5,arrEnableChanals[indCh].begRange);
      end;
    end;

    //���� ������ �������� �������� ������� � ������
    startFlagFast:=true;
  end;

  //��������� ����� ���������� +5 -5 ��� ���
  if (startFlagFast)then
  begin
    procArray[iPosInBuf]:=getColibValF(pocket[indCh+1],kolibP5V,kolibM5V);

    procArray[iPosInBuf]:=getAcs(procArray[iPosInBuf],5,-5,arrEnableChanals[indCh].begRange);
    //form1.Memo1.Lines.Add('�����-�����'+intTostr(indCh)+'�������'+intToStr(iPosInBuf));
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
  //��������� ������ � �����
  i:=1;
  j:=iPock;

  //� ����� ������� ������ ������ �������� ������, �������� ����. � ������ ������
  //�������� ����. ���������
  //1� ������� ������
  pocket[i]:=buff[j];
  //1� �������� ������
  pocket[i+indCh]:=buff[j+indCh];
  //1� ����. ��������
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
  //��������� ����
  while iPocket<=blSize do
  begin
    //������� �����
    SetDateToPocket(iPocket);
    //����������� ����� �� �������
    ParsePocketToSignalBlocksFast(pocketNum);
    //����������� ������ ������ �� ���� �������
    inc(pocketNum);
    //����������� �������� ��� �������� �����
    inc(numPointInK);


    //��������� �� ������� �� ������ ���������� ����� ������ ��c���� ������������� �����.
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

procedure TChannalProc.Execute;
var
  i:Integer;
  fileName:string;
  writeStr:string;
begin
  //���������� �������� � ������
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
  //������� ������ ���� � �������� �������.
  readStream:=TFileStream.Create(SCRUTfileArr[indFile].path,fmShareDenyNone);
  //������� �� ������. ��� ��������� ������ ���������� ���������� ��������
  fileName:=ExtractFileDir(ParamStr(0))+'\Report\'+'\skz\'+
    'Process'+IntToStr(indCh)+'_skz'+'.xls';
  AssignFile(fileCh,fileName);
  Rewrite(fileCh);
  writeStr:='������'+#9+'���� � ����� ������ �����'+
  #9+'������� ��������'+#9+'���. ��������'+#9+'����. ��������'+
  #9+'������'+#9+'�������';
  //�������� ��������� ���������
  i:=1;
  while i<=numFreqRange do
  begin
    writeStr:=writeStr+#9+floatToStr(arrFreqRange[i].beginRange)+'   '+
    floatToStr(arrFreqRange[i].endRange)+' ��';
    inc(i);
  end;
  write(fileCh,writeStr);
  writeln(fileCh,'');


  while indFile<length(SCRUTfileArr) do
  begin
    //��������� �� ������� �� ��� ���������� ������ �����
    if (flagConq) then
    begin
      flagConq:=false;
      //���������� ���� ������� ����� ������� �� ������ ��������� �����
      //� ������ ������� �� ����������� ����� ����� �������� ����� ���� ������
      //������ �� ����� ���� �������� ����� �������� ����� ���� ������
      readStream.Read(buff,blockSize);
      countPointInBlock:=1;
      //������ ���������� ����� ������
      ParseReadBlock(blockSize,countPointInBlock,countPointInKadr,blockCount,poolFastVal);
    end
    else
    begin
      //������� ������� ������ �����
      if (flagEnableRead) then
      begin
        //������ �� ����� ���� ����������� �������
        readStream.Read(buff, blockSize);
        //������ ���������� ����� ������
        ParseReadBlock(blockSize,countPointInBlock,countPointInKadr,blockCount,poolFastVal);
      end
      else
      begin
        //������� ���������� �������������� ���� �� ����� �����
        numPointToEnd:=readStream.Size-readStream.Position;
        //������� ����� ���� �� ����� �����
        readStream.Read(buff,readStream.Size-readStream.Position);
        //������ ���������� ����� ������
        ParseReadBlock(numPointToEnd,countPointInBlock,countPointInKadr,blockCount,trunc(numPointToEnd/POCKETSIZE));
      end;
    end;

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
      inc(indFile);
      //��������� ���� �� ��������� ���� �� ���������
      if indFile<length(SCRUTfileArr) then
      begin
        //������� ����. ����
        readStream:=TFileStream.Create(SCRUTfileArr[indFile].path,fmShareDenyNone{fmOpenRead});
        //��������� ��������� � �������� ����� ������� �����
        flagEnableRead:=true;
        {if indFile mod 2=1 then
        begin
          //��������� ���. ������
          inc(blockCount);
        end;}
        //���� ��������� ������ �� �������������� ����������� ������ ������
        ParseFileBuffer(countPointInBlock,false);    //!!!
        //���� ������������ ������ ��� ���� �����
        //��������� ������ ���������� ������� ����� �������� ����
        flagConq:=true;
      end
      else
      begin
        //�.� ���� ��������� �� ���������� ���������� ����� ������� ����������
        //���� �� ������ ������
        //!!! ��������� ���� �� ������������
        //ParseFileBuffer(countPointInBlock,true);
        CloseFile(fileCh);
        countPointInBlock:=1;
        arrEnbChannal[indCh]:=True;
        //����� ���������
        Form1.gProgress1.Progress:=Form1.gProgress1.Progress+3;
      end;
    end;
  end;
end;

//==============================================================================
// ������� min ��������
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
// ������� max ��������
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
//������� ������� ������ ���.���������� ���������� ����������� �������� ��������
//�������� ������� ���
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
  //���������� ��� �������� ������� ���
  while jNumPointInGroup<=numPointBPFarr do
  begin
    //���������� �������� ���� �������� ������ �������
    while igroup<=KOEF_R do
    begin
      sum:=sum+arrBPF[igroup][jNumPointInGroup];
      inc(igroup);
    end;
    //������� ������� �������� �� �����. �����
    avrBPFval:=round(sum/KOEF_R);
    //������� �������� � ������ ������� ��������
    arrBpfAvr[jNumPointInGroup]:=avrBPFval;
    sum:=0;
    igroup:=1;
    inc(jNumPointInGroup);
  end;
  result:=jNumPointInGroup-1;
end;
//==============================================================================

//==============================================================================
//���������� ������ ����� � ������� ��� �� ���������� ������� ���������
//���������� ����� �����
//==============================================================================
function TChannalProc.CalcNumP(freq:real;numPoint:integer;pollFreq:real):integer;
begin
  result:=round(freq*(numPoint/pollFreq)+0.1);
end;
//==============================================================================

//==============================================================================
//���������� �������� �������� ����������� �������
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
//�������� ��������� ������ ��� ������ ��� ����� 2 �� ����
//==============================================================================
procedure TThreadWriteSko.Execute;
var
  i:Integer;
begin
  //������ ������ � ��������
  for i:=1 to MAX_CH_COUNT_FAST do
  begin
    arrEnbChannal[i]:=False;
  end;

  //���������� ��� ��������� � �������� ����� �����
  //form1.Memo1.Lines.Add(DateTimeToStr(Now)+' ������ SKO');
  //��������� ����� ������ � ��� ����������
  for i:=1 to MAX_CH_COUNT_FAST do
  begin
    if (arrEnableChanals[i].enabled) then
    begin
      //����� ��������. ��� ������ ����� ���� �����
      channalThread[i]:=TChannalProc.Create(true);
      channalThread[i].Priority:=tpHigher;
      channalThread[i].indCh:=i;
      channalThread[i].FreeOnTerminate:=true;
      channalThread[i].Resume;
    end
    else
    begin
      //���� ����� ������������ �� ����, �� ����������� ��� ������������
      arrEnbChannal[i]:=True;
    end;
  end;
  //�������� ������ ���������� ������
  Form1.tmr1.Enabled:=true;
  Form1.tmr1.Tag:=MAX_CH_COUNT_FAST;
end;
//==============================================================================
end.

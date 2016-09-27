unit WriteGistUnit;

interface
uses
Classes, SysUtils, Dialogs, Math,  Forms,ConstUnit;
type
//����� ��� ������
TThreadWriteGist = class(TThread)
  private
    { Private declarations }
  protected
    procedure Execute; override;
end;

// ��� ��� �������� ������ ��������� � �����������(��������)
TStrikeRec=record
  //��������
  interval:double;
  //���������� ��������� � ��������
  countStrike:cardinal;
end;
//������ ������� ���������
TStrikeRecArr=array [1..INTERVAL_NUM] of TStrikeRec;
//TfastProc=array [1..FAST_VAL_NUM] of integer;

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
  //���� ��� ����� ������� ������ �����
  blockFlag:Boolean;
  //����� �����
  //blockTimeTh:string;
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

  //���������� ����������� ����� �������������
  numPointSubInterval:integer;

  //������������� �������
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

  //������ ������������ ������-������
  indCh:integer;
  fileCh:Text;
  //������ �������  ��������� � �����������(��������)
  countsStrikeArr:array [1..INTERVAL_NUM] of TStrikeRec;

  //���������� ��� ���������
  //kolib20mA:byte;
  //kolib4mA:byte;

  //���������� ������� ��������� ��� ������� ������
  procedure FillIntervalArray;
  //��������� ������� ���������� �����
  procedure ParseReadBlock(blSize:cardinal;var pocketNum:integer;
    var numPointInK:integer;var blCount:cardinal;pocketCount:integer);
  //������������ ������ ������ ���� ��� ����������� �������
  procedure SetDateToPocket(iPock:integer);
  procedure ParsePocketToSignalBlocksFast(iPosInBuf:integer);
  function CollectCounterTh(iByteDj:integer):byte;

  procedure ParseFileBuffer(numValInFfileBufer:integer;flagWriteNumBlock:boolean);
  //��������� 1 ������
  procedure ParseBuf(numValInFfileBufer:integer;writeNBlock:Boolean);
  //����� 1 ������
  procedure WriteBuf;
  function testCh(chNumber:integer;currentPocketNum:integer):boolean;
  //���������� �������� �������� �� ���� � ������
  function getColibValF(kodVal:{byte}real;kP:byte;kM:byte):real;
  //���������� �������� �������� �� ����� � �/c2
  function getAcs(volt:real;kP:double;kM:double;diap:double):double;
  //function getColibValS(kodVal:{byte}real;k20mA:byte;k4mA:byte):real;

protected
  procedure Execute; override;
public
  property ind: integer read indCh write indCh;
end;

var
  //����� ������
  thWriteGist: TThreadWriteGist;
  channalThread:array[1..MAX_CH_COUNT] of TChannalProc;
implementation
uses
Unit1,WriteSkoUnit;


//==============================================================================
//���������� � ����������� �������� ������������� � ������ ��������� � ���
//==============================================================================
procedure TChannalProc.FillIntervalArray;
var
  i:double;
  iFile:integer;
  ddd:double;//��������
begin
  ddd:=-0.1;
  iFile:=1;//����� �������� ����������������� ��������� ��� �������� ��������� � ������������

  i:=fastProcBegLimit;//��������� ���������� �������������(����������)
  countInterval:=1;
  while round(i*NUM_PRECIGION)<=round((fastProcEndLimit)*NUM_PRECIGION) do
  begin
    countsStrikeArr[countInterval].interval:=RoundTo(i,-3);//���������� � �������� 3 ����� ����� �������
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
  dec(countInterval);//�� ��������� ���� ������ ����.
  if iFile=1 then//�������� ���������� ����������� ������ ������������
  begin
    numPointSubInterval:=countInterval;
  end;
end;
//==============================================================================



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
function TChannalProc.getAcs(volt:real;kP:double;kM:double;diap:double):double;
begin
 //abs(diap*2) ��� ������ �� -5� �� 5�
 Result:=((volt-kM)/(kP-kM))*abs(diap*2)+diap;
end;
//==============================================================================

//==============================================================================
//������� �������� ��������� � ��
//==============================================================================
{function TChannalProc.getColibValS(kodVal:{byte}//real;k20mA:byte;k4mA:byte):real;
{begin
  //16 ��� ������ 20-4
  Result:=((kodVal-k4mA)/(k20mA-k4mA))*16+4;
end;}
//==============================================================================


//==============================================================================
//��������� ������ ����� ������-�����
//==============================================================================
procedure TChannalProc.WriteBuf;
var
  writeStr:string;
  //������ �������� ������� ����� ������������
  iWriteCount:integer;
begin
  //���������� ������ ���� � ������� �������� �����.���������
  iWriteCount:=1;
  //-2 �.� -1 ��� ��������� ��������� �������� ������� �� ������
  while iWriteCount<=numPointSubInterval-1{-1} do
  begin
    //������ �� ������
    writeStr:=FloatToStr(countsStrikeArr[iWriteCount].interval+
      (fastInterval/2))+#9+IntToStr(countsStrikeArr[iWriteCount].countStrike);
    writeLn(fileCh,writeStr);
    inc(iWriteCount);
  end;

  writeStr:='���������� ����� ������������ ������'+#9+intToStr(blockCount);
  writeLn(fileCh,writeStr);
  
  //CloseFile(fileCh);
end;
//==============================================================================


//==============================================================================
//��������� ������� ������ ������-�����
//==============================================================================
procedure TChannalProc.ParseBuf(numValInFfileBufer:integer;writeNBlock:Boolean);
var
  fileBufCount:integer;
  inlCount:integer;
  a:double;
begin
  //������ ����� �����������
  fileBufCount:=1;
  while fileBufCount<=numValInFfileBufer-1 do   //!!!
  begin
    //��������� � ����� �������� ������� �����
    inlCount:=1;
    while inlCount<=numPointSubInterval-1 do   ///!!!
    begin
      //���������� � ���. ��������
      a:=getColibValF(procArray[fileBufCount],arrKolibP5V[trunc(fileBufCount/224)+1],
        arrkolibM5V[trunc(fileBufCount/224)+1]);
      a:=getAcs(a,5,-5,arrEnableChanals[indCh].begRange);

      //���. ����� �������
      if a*NUM_PRECIGION=countsStrikeArr[1].interval*NUM_PRECIGION then
      begin
        inc(countsStrikeArr[1].countStrike);
      end;

      //���������, �� ������ ���� ��������� �� 0
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
          //����� ���������. ���� � ����� �� ����� ������
          inc(countsStrikeArr[inlCount].countStrike);
        end;
        break;
      end;

       //��������  ������ �������
      if a*NUM_PRECIGION=countsStrikeArr[numPointSubInterval-1].interval*NUM_PRECIGION then
      begin
        inc(countsStrikeArr[numPointSubInterval-1].countStrike);
      end;

      //���������, �� 0 �� ������� ����
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
          //����� ���������. ���� � ����� �� ����� ������
          inc(countsStrikeArr[inlCount].countStrike);
        end;
        break;
      end;

      //��������� �������� �������� ����� 0
      if a*NUM_PRECIGION=0 then
      begin
        //����������� �������� ��������� �������� ����� 0
        inc(countsStrikeArr[trunc(numPointSubInterval/2)].countStrike);
        break;
      end;

      inc(inlCount);
    end;
    inc(fileBufCount);
  end;

  if writeNBlock then
  begin
    //��������� ����� ������. �����
    WriteBuf;
  end;
end;
//==============================================================================

//==============================================================================
//��������� �������� ������
//==============================================================================
procedure TChannalProc.ParseFileBuffer(numValInFfileBufer:integer;flagWriteNumBlock:boolean);
begin
  ParseBuf(numValInFfileBufer,flagWriteNumBlock);
  blockFlag:=true;
  iKP5V:=1;
  iKM5V:=1;
  iK0V:=1;
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
//������ ������ ���� �� ������� ������-�������
//==============================================================================
procedure TChannalProc.ParsePocketToSignalBlocksFast(iPosInBuf:integer);
var
  //����� �������� ������
  counter:byte;
begin
   //������� ����� ������
  counter:=CollectCounterTh(1);

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
  //������ �������
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


//==============================================================================
//
//==============================================================================
procedure TChannalProc.Execute;
var
  fileName:string;
begin
  //���������� ������� ����������
  FillIntervalArray;
  iKP5V:=1;
  iKM5V:=1;
  iK0V:=1;
  iK4mA:=1;
  iK20mA:=1;
  
  //���������� �������� � ������
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
  //������� ������ ���� � �������� �������.
  readStream:=TFileStream.Create(SCRUTfileArr[indFile].path,fmShareDenyNone);

  //������� �� ������. ��� ��������� ������ ���������� ���������� ��������
  //��������� ��� �����
  fileName:=ExtractFileDir(ParamStr(0))+'\Report\'+'\hist\'+
    'Process'+IntToStr(indCh)+'_hist'+'.xls';
  AssignFile(fileCh,fileName);
  //������� �� ������. ��� ��������� ������ ���������� ���������� ��������
  Rewrite(fileCh);


  while indFile<length(SCRUTfileArr) do
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
        //form1.Memo1.Lines.Add('����� '+intTostr(indCh)+' ����� ����� '+intToStr(indFile));
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
        ParseFileBuffer(countPointInBlock,true);
        //�������� ����������� �������� ��� ����������� ������� � ������
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
//�������� ��������� ������ ��� ������ ����������� ����������.����� 1 �� ����
//==============================================================================
procedure TThreadWriteGist.Execute;
var
  i:Integer;
begin
  //������ ������ � ��������
  for i:=1 to MAX_CH_COUNT_FAST do
  begin
    arrEnbChannal[i]:=False;
  end;

  //���������� ��� ��������� � �������� ����� �����
  //form1.Memo1.Lines.Add(DateTimeToStr(Now)+' ������ GIST');

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
  Form1.tmr2.Enabled:=true;
  Form1.tmr2.Tag:=MAX_CH_COUNT_FAST;
end;
//==============================================================================
end.

unit SensorLimitUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls,TestChUnit,Unit1,WriteSkoUnit,ConstUnit,
  WriteGistUnit,WriteLogUnit;

type
  TForm3 = class(TForm)
    grp1: TGroupBox;
    pnl1: TPanel;
    lbl1: TLabel;
    lblMax: TLabel;
    edt1: TEdit;
    pnl2: TPanel;
    lbl2: TLabel;
    edt2: TEdit;
    pnl3: TPanel;
    lbl3: TLabel;
    edt3: TEdit;
    pnl4: TPanel;
    lbl5: TLabel;
    edt4: TEdit;
    pnl5: TPanel;
    lbl6: TLabel;
    edt5: TEdit;
    lbl7: TLabel;
    pnl6: TPanel;
    lbl8: TLabel;
    edt6: TEdit;
    pnl7: TPanel;
    lbl4: TLabel;
    edt7: TEdit;
    pnl8: TPanel;
    lbl9: TLabel;
    edt8: TEdit;
    pnl9: TPanel;
    lbl10: TLabel;
    edt9: TEdit;
    pnl10: TPanel;
    lbl11: TLabel;
    edt10: TEdit;
    pnl11: TPanel;
    lbl12: TLabel;
    edt11: TEdit;
    lbl13: TLabel;
    pnl12: TPanel;
    lbl14: TLabel;
    edt12: TEdit;
    pnl13: TPanel;
    lbl15: TLabel;
    edt13: TEdit;
    pnl14: TPanel;
    lbl16: TLabel;
    edt14: TEdit;
    pnl15: TPanel;
    lbl17: TLabel;
    edt15: TEdit;
    pnl16: TPanel;
    lbl18: TLabel;
    edt16: TEdit;
    pnl17: TPanel;
    lbl19: TLabel;
    edt17: TEdit;
    lbl20: TLabel;
    pnl18: TPanel;
    lbl21: TLabel;
    edt18: TEdit;
    pnl19: TPanel;
    lbl22: TLabel;
    edt19: TEdit;
    pnl20: TPanel;
    lbl23: TLabel;
    edt20: TEdit;
    pnl21: TPanel;
    lbl24: TLabel;
    edt21: TEdit;
    pnl22: TPanel;
    lbl25: TLabel;
    edt22: TEdit;
    pnl23: TPanel;
    lbl26: TLabel;
    edt23: TEdit;
    lbl27: TLabel;
    pnl24: TPanel;
    lbl28: TLabel;
    edt24: TEdit;
    lbl29: TLabel;
    lbl30: TLabel;
    lbl31: TLabel;
    grp2: TGroupBox;
    lbl32: TLabel;
    lbl33: TLabel;
    lbl34: TLabel;
    lbl35: TLabel;
    lbl36: TLabel;
    lbl37: TLabel;
    lbl38: TLabel;
    lbl39: TLabel;
    edt25: TEdit;
    edt26: TEdit;
    lbl40: TLabel;
    lbl41: TLabel;
    edt27: TEdit;
    edt28: TEdit;
    grp3: TGroupBox;
    lbl42: TLabel;
    lbl43: TLabel;
    lbl44: TLabel;
    lbl45: TLabel;
    lbl46: TLabel;
    lbl47: TLabel;
    edt29: TEdit;
    edt30: TEdit;
    edt31: TEdit;
    edt32: TEdit;
    grp4: TGroupBox;
    lbl48: TLabel;
    lbl50: TLabel;
    lbl51: TLabel;
    edt33: TEdit;
    edt34: TEdit;
    btn1: TButton;
    lbl49: TLabel;
    procedure btn1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form3: TForm3;

procedure InitSensorLimitForm;
procedure startExecute;  
implementation

{$R *.dfm}


//==============================================================================
//
//==============================================================================
function TestStr(testField:string):Boolean;
var
  i:Integer;
  strLen:Integer;
  bool:Boolean;
begin
  bool:=True;
  strLen:=Length(testField);
  for i:=1 to strLen do
  begin
    if i=1 then
    begin
      //только символы -,0-9
      if not((ord(testField[i])=45)or((ord(testField[i])>=48)and(ord(testField[i])<=57))) then
      begin
        bool:=False;
        Break;
      end;
    end
    else
    begin
      //только символы .,0-9
      if not((ord(testField[i])=46)or((ord(testField[i])>=48)and(ord(testField[i])<=57))) then
      begin
        bool:=False;
        Break;
      end;
    end;
  end;
  Result:=bool;
end;
//==============================================================================

//==============================================================================
//
//==============================================================================
function TestMaxVal(testField:string;maxVal:Double):Boolean; overload;
var
  bool:Boolean;
begin
  if StrToFloat(testField)*100>maxVal*100 then
  begin
    bool:=false;
  end
  else
  begin
    bool:=true;
  end;

  result:=bool;
end;
//==============================================================================

//==============================================================================
//
//==============================================================================
function TestMaxVal(testFieldMin:string;testFieldMax:string;minVal:Double;maxVal:Double):Boolean; overload;
var
  bool:Boolean;
begin
  if ((StrToFloat(testFieldMin)*100<minVal*100)or(StrToFloat(testFieldMax)*100>maxVal*100)) then
  begin
    bool:=false;
  end
  else
  begin
    bool:=True;
  end;

  result:=bool;
end;
//==============================================================================





//==============================================================================
//
//==============================================================================
function TestSensorsParam():Boolean;
var
  i:Integer;
  bool:Boolean;
begin
  bool:=true;
  for i:=1 to MAX_CH_COUNT-1 do
  begin
      case i of
        1:
        begin
          if (arrEnableChanals[i].enabled) then
          begin
            if TestStr(Form3.edt1.Text) then
            begin
              if not TestMaxVal(Form3.edt1.Text,arrEnableChanals[i].endRange) then
              begin
                bool:=false;
                Break;
              end;

              arrEnableChanals[i].maxUserVal:=StrToFloat(Form3.edt1.Text);
              arrEnableChanals[i].minUserVal:=arrEnableChanals[i].maxUserVal*(-1);
            end
            else
            begin
              bool:=false;
              Break;
            end;
          end
          else
          begin
          end;
        end;
        2:
        begin
          if (arrEnableChanals[i].enabled) then
          begin
            if TestStr(Form3.edt2.Text) then
            begin
              if not TestMaxVal(Form3.edt2.Text,arrEnableChanals[i].endRange) then
              begin
                bool:=false;
                Break;
              end;
              arrEnableChanals[i].maxUserVal:=StrToFloat(Form3.edt2.Text);
              arrEnableChanals[i].minUserVal:=arrEnableChanals[i].maxUserVal*(-1);
            end
            else
            begin
              bool:=false;
              Break;
            end;
          end
          else
          begin
          end;
        end;
        3:
        begin
          if (arrEnableChanals[i].enabled) then
          begin
            if TestStr(Form3.edt3.Text) then
            begin
              if not TestMaxVal(Form3.edt3.Text,arrEnableChanals[i].endRange) then
              begin
                bool:=false;
                Break;
              end;
              arrEnableChanals[i].maxUserVal:=StrToFloat(Form3.edt3.Text);
              arrEnableChanals[i].minUserVal:=arrEnableChanals[i].maxUserVal*(-1);
            end
            else
            begin
              bool:=false;
              Break;
            end;
          end
          else
          begin
          end;
        end;
        4:
        begin
          if (arrEnableChanals[i].enabled) then
          begin
            if TestStr(Form3.edt4.Text) then
            begin
              if not TestMaxVal(Form3.edt4.Text,arrEnableChanals[i].endRange) then
              begin
                bool:=false;
                Break;
              end;
              arrEnableChanals[i].maxUserVal:=StrToFloat(Form3.edt4.Text);
              arrEnableChanals[i].minUserVal:=arrEnableChanals[i].maxUserVal*(-1);
            end
            else
            begin
              bool:=false;
              Break;
            end;
          end
          else
          begin
          end;
        end;
        5:
        begin
          if (arrEnableChanals[i].enabled) then
          begin
            if TestStr(Form3.edt5.Text) then
            begin
              if not TestMaxVal(Form3.edt5.Text,arrEnableChanals[i].endRange) then
              begin
                bool:=false;
                Break;
              end;
              arrEnableChanals[i].maxUserVal:=StrToFloat(Form3.edt5.Text);
              arrEnableChanals[i].minUserVal:=arrEnableChanals[i].maxUserVal*(-1);
            end
            else
            begin
              bool:=false;
              Break;
            end;
          end
          else
          begin
          end;
        end;
        6:
        begin
          if (arrEnableChanals[i].enabled) then
          begin
            if TestStr(Form3.edt6.Text) then
            begin
              if not TestMaxVal(Form3.edt6.Text,arrEnableChanals[i].endRange) then
              begin
                bool:=false;
                Break;
              end;
              arrEnableChanals[i].maxUserVal:=StrToFloat(Form3.edt6.Text);
              arrEnableChanals[i].minUserVal:=arrEnableChanals[i].maxUserVal*(-1);
            end
            else
            begin
              bool:=false;
              Break;
            end;
          end
          else
          begin
          end;
        end;
        7:
        begin
          if (arrEnableChanals[i].enabled) then
          begin
            if TestStr(Form3.edt7.Text) then
            begin
              if not TestMaxVal(Form3.edt7.Text,arrEnableChanals[i].endRange) then
              begin
                bool:=false;
                Break;
              end;
              arrEnableChanals[i].maxUserVal:=StrToFloat(Form3.edt7.Text);
              arrEnableChanals[i].minUserVal:=arrEnableChanals[i].maxUserVal*(-1);
            end
            else
            begin
              bool:=false;
              Break;
            end;
          end
          else
          begin
          end;
        end;
        8:
        begin
          if (arrEnableChanals[i].enabled) then
          begin
            if TestStr(Form3.edt8.Text) then
            begin
              if not TestMaxVal(Form3.edt8.Text,arrEnableChanals[i].endRange) then
              begin
                bool:=false;
                Break;
              end;
              arrEnableChanals[i].maxUserVal:=StrToFloat(Form3.edt8.Text);
              arrEnableChanals[i].minUserVal:=arrEnableChanals[i].maxUserVal*(-1);
            end
            else
            begin
              bool:=false;
              Break;
            end;
          end
          else
          begin
          end;
        end;
        9:
        begin
          if (arrEnableChanals[i].enabled) then
          begin
            if TestStr(Form3.edt9.Text) then
            begin
              if not TestMaxVal(Form3.edt9.Text,arrEnableChanals[i].endRange) then
              begin
                bool:=false;
                Break;
              end;
              arrEnableChanals[i].maxUserVal:=StrToFloat(Form3.edt9.Text);
              arrEnableChanals[i].minUserVal:=arrEnableChanals[i].maxUserVal*(-1);
            end
            else
            begin
              bool:=false;
              Break;
            end;
          end
          else
          begin
          end;
        end;
        10:
        begin
          if (arrEnableChanals[i].enabled) then
          begin
            if TestStr(Form3.edt10.Text) then
            begin
              if not TestMaxVal(Form3.edt10.Text,arrEnableChanals[i].endRange) then
              begin
                bool:=false;
                Break;
              end;
              arrEnableChanals[i].maxUserVal:=StrToFloat(Form3.edt10.Text);
              arrEnableChanals[i].minUserVal:=arrEnableChanals[i].maxUserVal*(-1);
            end
            else
            begin
              bool:=false;
              Break;
            end;
          end
          else
          begin
          end;
        end;
        11:
        begin
          if (arrEnableChanals[i].enabled) then
          begin
            if TestStr(Form3.edt11.Text) then
            begin
              if not TestMaxVal(Form3.edt11.Text,arrEnableChanals[i].endRange) then
              begin
                bool:=false;
                Break;
              end;
              arrEnableChanals[i].maxUserVal:=StrToFloat(Form3.edt11.Text);
              arrEnableChanals[i].minUserVal:=arrEnableChanals[i].maxUserVal*(-1);
            end
            else
            begin
              bool:=false;
              Break;
            end;
          end
          else
          begin
          end;
        end;
        12:
        begin
          if (arrEnableChanals[i].enabled) then
          begin
            if TestStr(Form3.edt12.Text) then
            begin
              if not TestMaxVal(Form3.edt12.Text,arrEnableChanals[i].endRange) then
              begin
                bool:=false;
                Break;
              end;
              arrEnableChanals[i].maxUserVal:=StrToFloat(Form3.edt12.Text);
              arrEnableChanals[i].minUserVal:=arrEnableChanals[i].maxUserVal*(-1);
            end
            else
            begin
              bool:=false;
              Break;
            end;
          end
          else
          begin
          end;
        end;
        13:
        begin
          if (arrEnableChanals[i].enabled) then
          begin
            if TestStr(Form3.edt13.Text) then
            begin
              if not TestMaxVal(Form3.edt13.Text,arrEnableChanals[i].endRange) then
              begin
                bool:=false;
                Break;
              end;
              arrEnableChanals[i].maxUserVal:=StrToFloat(Form3.edt13.Text);
              arrEnableChanals[i].minUserVal:=arrEnableChanals[i].maxUserVal*(-1);
            end
            else
            begin
              bool:=false;
              Break;
            end;
          end
          else
          begin
          end;
        end;
        14:
        begin
          if (arrEnableChanals[i].enabled) then
          begin
            if TestStr(Form3.edt14.Text) then
            begin
              if not TestMaxVal(Form3.edt14.Text,arrEnableChanals[i].endRange) then
              begin
                bool:=false;
                Break;
              end;
              arrEnableChanals[i].maxUserVal:=StrToFloat(Form3.edt14.Text);
              arrEnableChanals[i].minUserVal:=arrEnableChanals[i].maxUserVal*(-1);
            end
            else
            begin
              bool:=false;
              Break;
            end;
          end
          else
          begin
          end;
        end;
        15:
        begin
          if (arrEnableChanals[i].enabled) then
          begin
            if TestStr(Form3.edt15.Text) then
            begin
              if not TestMaxVal(Form3.edt15.Text,arrEnableChanals[i].endRange) then
              begin
                bool:=false;
                Break;
              end;
              arrEnableChanals[i].maxUserVal:=StrToFloat(Form3.edt15.Text);
              arrEnableChanals[i].minUserVal:=arrEnableChanals[i].maxUserVal*(-1);
            end
            else
            begin
              bool:=false;
              Break;
            end;
          end
          else
          begin
          end;
        end;
        16:
        begin
          if (arrEnableChanals[i].enabled) then
          begin
            if TestStr(Form3.edt16.Text) then
            begin
              if not TestMaxVal(Form3.edt16.Text,arrEnableChanals[i].endRange) then
              begin
                bool:=false;
                Break;
              end;
              arrEnableChanals[i].maxUserVal:=StrToFloat(Form3.edt16.Text);
              arrEnableChanals[i].minUserVal:=arrEnableChanals[i].maxUserVal*(-1);
            end
            else
            begin
              bool:=false;
              Break;
            end;
          end
          else
          begin
          end;
        end;
        17:
        begin
          if (arrEnableChanals[i].enabled) then
          begin
            if TestStr(Form3.edt17.Text) then
            begin
              if not TestMaxVal(Form3.edt17.Text,arrEnableChanals[i].endRange) then
              begin
                bool:=false;
                Break;
              end;
              arrEnableChanals[i].maxUserVal:=StrToFloat(Form3.edt17.Text);
              arrEnableChanals[i].minUserVal:=arrEnableChanals[i].maxUserVal*(-1);
            end
            else
            begin
              bool:=false;
              Break;
            end;
          end
          else
          begin
          end;
        end;
        18:
        begin
          if (arrEnableChanals[i].enabled) then
          begin
            if TestStr(Form3.edt18.Text) then
            begin
              if not TestMaxVal(Form3.edt18.Text,arrEnableChanals[i].endRange) then
              begin
                bool:=false;
                Break;
              end;
              arrEnableChanals[i].maxUserVal:=StrToFloat(Form3.edt18.Text);
              arrEnableChanals[i].minUserVal:=arrEnableChanals[i].maxUserVal*(-1);
            end
            else
            begin
              bool:=false;
              Break;
            end;
          end
          else
          begin
          end;
        end;
        19:
        begin
          if (arrEnableChanals[i].enabled) then
          begin
            if TestStr(Form3.edt19.Text) then
            begin
              if not TestMaxVal(Form3.edt19.Text,arrEnableChanals[i].endRange) then
              begin
                bool:=false;
                Break;
              end;
              arrEnableChanals[i].maxUserVal:=StrToFloat(Form3.edt19.Text);
              arrEnableChanals[i].minUserVal:=arrEnableChanals[i].maxUserVal*(-1);
            end
            else
            begin
              bool:=false;
              Break;
            end;
          end
          else
          begin
          end;
        end;
        20:
        begin
          if (arrEnableChanals[i].enabled) then
          begin
            if TestStr(Form3.edt20.Text) then
            begin
              if not TestMaxVal(Form3.edt20.Text,arrEnableChanals[i].endRange) then
              begin
                bool:=false;
                Break;
              end;
              arrEnableChanals[i].maxUserVal:=StrToFloat(Form3.edt20.Text);
              arrEnableChanals[i].minUserVal:=arrEnableChanals[i].maxUserVal*(-1);
            end
            else
            begin
              bool:=false;
              Break;
            end;
          end
          else
          begin
          end;
        end;
        21:
        begin
          if (arrEnableChanals[i].enabled) then
          begin
            if TestStr(Form3.edt21.Text) then
            begin
              if not TestMaxVal(Form3.edt21.Text,arrEnableChanals[i].endRange) then
              begin
                bool:=false;
                Break;
              end;
              arrEnableChanals[i].maxUserVal:=StrToFloat(Form3.edt21.Text);
              arrEnableChanals[i].minUserVal:=arrEnableChanals[i].maxUserVal*(-1);
            end
            else
            begin
              bool:=false;
              Break;
            end;
          end
          else
          begin
          end;
        end;
        22:
        begin
          if (arrEnableChanals[i].enabled) then
          begin
            if TestStr(Form3.edt22.Text) then
            begin
              if not TestMaxVal(Form3.edt22.Text,arrEnableChanals[i].endRange) then
              begin
                bool:=false;
                Break;
              end;
              arrEnableChanals[i].maxUserVal:=StrToFloat(Form3.edt22.Text);
              arrEnableChanals[i].minUserVal:=arrEnableChanals[i].maxUserVal*(-1);
            end
            else
            begin
              bool:=false;
              Break;
            end;
          end
          else
          begin
          end;
        end;
        23:
        begin
          if (arrEnableChanals[i].enabled) then
          begin
            if TestStr(Form3.edt23.Text) then
            begin
              if not TestMaxVal(Form3.edt23.Text,arrEnableChanals[i].endRange) then
              begin
                bool:=false;
                Break;
              end;
              arrEnableChanals[i].maxUserVal:=StrToFloat(Form3.edt23.Text);
              arrEnableChanals[i].minUserVal:=arrEnableChanals[i].maxUserVal*(-1);
            end
            else
            begin
              bool:=false;
              Break;
            end;
          end
          else
          begin
          end;
        end;
        24:
        begin
          if (arrEnableChanals[i].enabled) then
          begin
            if TestStr(Form3.edt24.Text) then
            begin
              if not TestMaxVal(Form3.edt24.Text,arrEnableChanals[i].endRange) then
              begin
                bool:=false;
                Break;
              end;
              arrEnableChanals[i].maxUserVal:=StrToFloat(Form3.edt24.Text);
              arrEnableChanals[i].minUserVal:=arrEnableChanals[i].maxUserVal*(-1);
            end
            else
            begin
              bool:=false;
              Break;
            end;
          end
          else
          begin
          end;
        end;
        25:
        begin
          if (arrEnableChanals[i].enabled) then
          begin
            if ((TestStr(Form3.edt25.Text))and(TestStr(Form3.edt26.Text))) then
            begin
              if not TestMaxVal(Form3.edt25.Text,Form3.edt26.Text,
                arrEnableChanals[i].begRange,arrEnableChanals[i].endRange) then
              begin
                bool:=false;
                Break;
              end;
              arrEnableChanals[i].minUserVal:=StrToFloat(Form3.edt25.Text);
              arrEnableChanals[i].maxUserVal:=StrToFloat(Form3.edt26.Text);
            end
            else
            begin
              bool:=false;
              Break;
            end;
          end
          else
          begin
          end;
        end;
        26:
        begin
          if (arrEnableChanals[i].enabled) then
          begin
            if ((TestStr(Form3.edt27.Text))and(TestStr(Form3.edt28.Text))) then
            begin
              if not TestMaxVal(Form3.edt27.Text,Form3.edt28.Text,
                arrEnableChanals[i].begRange,arrEnableChanals[i].endRange) then
              begin
                bool:=false;
                Break;
              end;
              arrEnableChanals[i].minUserVal:=StrToFloat(Form3.edt27.Text);
              arrEnableChanals[i].maxUserVal:=StrToFloat(Form3.edt28.Text);
            end
            else
            begin
              bool:=false;
              Break;
            end;
          end
          else
          begin
          end;
        end;
        27:
        begin
          if (arrEnableChanals[i].enabled) then
          begin
            if ((TestStr(Form3.edt29.Text))and(TestStr(Form3.edt30.Text))) then
            begin
              if not TestMaxVal(Form3.edt29.Text,Form3.edt30.Text,
                arrEnableChanals[i].begRange,arrEnableChanals[i].endRange) then
              begin
                bool:=false;
                Break;
              end;
              arrEnableChanals[i].minUserVal:=StrToFloat(Form3.edt29.Text);
              arrEnableChanals[i].maxUserVal:=StrToFloat(Form3.edt30.Text);
            end
            else
            begin
              bool:=false;
              Break;
            end;
          end
          else
          begin
          end;
        end;
        28:
        begin
          if (arrEnableChanals[i].enabled) then
          begin
            if ((TestStr(Form3.edt31.Text))and(TestStr(Form3.edt32.Text))) then
            begin
              if not TestMaxVal(Form3.edt31.Text,Form3.edt32.Text,
                arrEnableChanals[i].begRange,arrEnableChanals[i].endRange) then
              begin
                bool:=false;
                Break;
              end;
              arrEnableChanals[i].minUserVal:=StrToFloat(Form3.edt31.Text);
              arrEnableChanals[i].maxUserVal:=StrToFloat(Form3.edt32.Text);
            end
            else
            begin
              bool:=false;
              Break;
            end;
          end
          else
          begin
          end;
        end;
        29:
        begin
          if (arrEnableChanals[i].enabled) then
          begin
            if ((TestStr(Form3.edt33.Text))and(TestStr(Form3.edt34.Text))) then
            begin
              if not TestMaxVal(Form3.edt33.Text,Form3.edt34.Text,
              arrEnableChanals[i].begRange,arrEnableChanals[i].endRange) then
              begin
                bool:=false;
                Break;
              end;
              arrEnableChanals[i].minUserVal:=StrToFloat(Form3.edt33.Text);
              arrEnableChanals[i].maxUserVal:=StrToFloat(Form3.edt34.Text);
            end
            else
            begin
              bool:=false;
              Break;
            end;
          end
          else
          begin
          end;
        end;
      end;
  end;
  result:=bool;
end;
//==============================================================================


//==============================================================================
//
//==============================================================================
procedure startExecute;
begin
  ShowMessage('Обработка началась!');
  if form2.chk3.Checked then
  begin
    //3 пункт обработки. Абсолютные максимумы процессов за обр. интервал
    thWriteLog:=TThreadWriteLog.Create(false);
    thWriteLog.Priority:=tpNormal{tpHigher};
  end
  else
  begin
    logCompl:=True;
  end;

  if form2.chk1.Checked then
  begin
    //1 пункт обработки . Гистограммы мгновенных
    thWriteGist:=TThreadWriteGist.Create(true{false});
    thWriteGist.Priority:=tpNormal{tpHigher};
    if not form2.chk3.Checked then
    begin
      thWriteGist.Resume;
    end;
  end
  else
  begin
    gistCompl:=True;
  end;

  if form2.chk2.Checked then
  begin
    //2 пункт обработки. Скз
    thWriteSko:=TThreadWriteSko.Create({false}true);
    thWriteSko.Priority:={tpNormal}tpHigher;
    if not form2.chk1.Checked then
    begin
      thWriteSko.Resume;
    end;
  end
  else
  begin
    skoCompl:=True;
  end;
  //включаем таймер окончания проверок
  form1.tmrEnd3.Enabled:=True;
end;
//==============================================================================


procedure TForm3.btn1Click(Sender: TObject);
begin
  //Проверим что все значения в форме введены
  if (TestSensorsParam) then
  begin
    form3.Hide;
    //старт выполнения выбранных проверок
    startExecute;
  end
  else
  begin
    ShowMessage('Проверьте правильность введенных параметров!');
  end;
end;

//==============================================================================
//
//==============================================================================
procedure InitSensorLimitForm;
var
  i:Integer;
begin
  for i:=1 to MAX_CH_COUNT-1 do
  begin
      case i of
        1:
        begin
          //расставим доступность элементов
          if (arrEnableChanals[i].enabled) then
          begin
            Form3.edt1.Enabled:=True;
            Form3.pnl1.Color:=clMoneyGreen;

            //формируем предельное значение для проверки как максимум канала -0.1
            Form3.edt1.Text:=FloatToStr(arrEnableChanals[i].endRange-0.1);
          end
          else
          begin
            Form3.edt1.Enabled:=false;
            Form3.pnl1.Color:=clBtnFace;
          end;
        end;
        2:
        begin
          //расставим доступность элементов
          if (arrEnableChanals[i].enabled) then
          begin
            Form3.edt2.Enabled:=True;
            Form3.pnl2.Color:=clMoneyGreen;

            Form3.edt2.Text:=FloatToStr(arrEnableChanals[i].endRange-0.1);
          end
          else
          begin
            Form3.edt2.Enabled:=false;
            Form3.pnl2.Color:=clBtnFace;
          end;
        end;
        3:
        begin
          //расставим доступность элементов
          if (arrEnableChanals[i].enabled) then
          begin
            Form3.edt3.Enabled:=True;
            Form3.pnl3.Color:=clMoneyGreen;

            Form3.edt3.Text:=FloatToStr(arrEnableChanals[i].endRange-0.1);
          end
          else
          begin
            Form3.edt3.Enabled:=false;
            Form3.pnl3.Color:=clBtnFace;
          end;
        end;
        4:
        begin
          //расставим доступность элементов
          if (arrEnableChanals[i].enabled) then
          begin
            Form3.edt4.Enabled:=True;
            Form3.pnl4.Color:=clMoneyGreen;

            Form3.edt4.Text:=FloatToStr(arrEnableChanals[i].endRange-0.1);
          end
          else
          begin
            Form3.edt4.Enabled:=false;
            Form3.pnl4.Color:=clBtnFace;
          end;
        end;
        5:
        begin
          //расставим доступность элементов
          if (arrEnableChanals[i].enabled) then
          begin
            Form3.edt5.Enabled:=True;
            Form3.pnl5.Color:=clMoneyGreen;

            Form3.edt5.Text:=FloatToStr(arrEnableChanals[i].endRange-0.1);
          end
          else
          begin
            Form3.edt5.Enabled:=false;
            Form3.pnl5.Color:=clBtnFace;
          end;
        end;
        6:
        begin
          //расставим доступность элементов
          if (arrEnableChanals[i].enabled) then
          begin
            Form3.edt6.Enabled:=True;
            Form3.pnl6.Color:=clMoneyGreen;

            Form3.edt6.Text:=FloatToStr(arrEnableChanals[i].endRange-0.1);
          end
          else
          begin
            Form3.edt6.Enabled:=false;
            Form3.pnl6.Color:=clBtnFace;
          end;
        end;
        7:
        begin
          //расставим доступность элементов
          if (arrEnableChanals[i].enabled) then
          begin
            Form3.edt7.Enabled:=True;
            Form3.pnl7.Color:=clMoneyGreen;

            Form3.edt7.Text:=FloatToStr(arrEnableChanals[i].endRange-0.1);
          end
          else
          begin
            Form3.edt7.Enabled:=false;
            Form3.pnl7.Color:=clBtnFace;
          end;
        end;
        8:
        begin
          //расставим доступность элементов
          if (arrEnableChanals[i].enabled) then
          begin
            Form3.edt8.Enabled:=True;
            Form3.pnl8.Color:=clMoneyGreen;

            Form3.edt8.Text:=FloatToStr(arrEnableChanals[i].endRange-0.1);
          end
          else
          begin
            Form3.edt8.Enabled:=false;
            Form3.pnl8.Color:=clBtnFace;
          end;
        end;
        9:
        begin
          //расставим доступность элементов
          if (arrEnableChanals[i].enabled) then
          begin
            Form3.edt9.Enabled:=True;
            Form3.pnl9.Color:=clMoneyGreen;

            Form3.edt9.Text:=FloatToStr(arrEnableChanals[i].endRange-0.1);
          end
          else
          begin
            Form3.edt9.Enabled:=false;
            Form3.pnl9.Color:=clBtnFace;
          end;
        end;
        10:
        begin
          //расставим доступность элементов
          if (arrEnableChanals[i].enabled) then
          begin
            Form3.edt10.Enabled:=True;
            Form3.pnl10.Color:=clMoneyGreen;

            Form3.edt10.Text:=FloatToStr(arrEnableChanals[i].endRange-0.1);
          end
          else
          begin
            Form3.edt10.Enabled:=false;
            Form3.pnl10.Color:=clBtnFace;
          end;
        end;
        11:
        begin
          //расставим доступность элементов
          if (arrEnableChanals[i].enabled) then
          begin
            Form3.edt11.Enabled:=True;
            Form3.pnl11.Color:=clMoneyGreen;

            Form3.edt11.Text:=FloatToStr(arrEnableChanals[i].endRange-0.1);
          end
          else
          begin
            Form3.edt11.Enabled:=false;
            Form3.pnl11.Color:=clBtnFace;
          end;
        end;
        12:
        begin
          //расставим доступность элементов
          if (arrEnableChanals[i].enabled) then
          begin
            Form3.edt12.Enabled:=True;
            Form3.pnl12.Color:=clMoneyGreen;

            Form3.edt12.Text:=FloatToStr(arrEnableChanals[i].endRange-0.1);
          end
          else
          begin
            Form3.edt12.Enabled:=false;
            Form3.pnl12.Color:=clBtnFace;
          end;
        end;
        13:
        begin
          //расставим доступность элементов
          if (arrEnableChanals[i].enabled) then
          begin
            Form3.edt13.Enabled:=True;
            Form3.pnl13.Color:=clMoneyGreen;

            Form3.edt13.Text:=FloatToStr(arrEnableChanals[i].endRange-0.1);
          end
          else
          begin
            Form3.edt13.Enabled:=false;
            Form3.pnl13.Color:=clBtnFace;
          end;
        end;
        14:
        begin
          //расставим доступность элементов
          if (arrEnableChanals[i].enabled) then
          begin
            Form3.edt14.Enabled:=True;
            Form3.pnl14.Color:=clMoneyGreen;

            Form3.edt14.Text:=FloatToStr(arrEnableChanals[i].endRange-0.1);
          end
          else
          begin
            Form3.edt14.Enabled:=false;
            Form3.pnl14.Color:=clBtnFace;
          end;
        end;
        15:
        begin
          //расставим доступность элементов
          if (arrEnableChanals[i].enabled) then
          begin
            Form3.edt15.Enabled:=True;
            Form3.pnl15.Color:=clMoneyGreen;

            Form3.edt15.Text:=FloatToStr(arrEnableChanals[i].endRange-0.1);
          end
          else
          begin
            Form3.edt15.Enabled:=false;
            Form3.pnl15.Color:=clBtnFace;
          end;
        end;
        16:
        begin
          //расставим доступность элементов
          if (arrEnableChanals[i].enabled) then
          begin
            Form3.edt16.Enabled:=True;
            Form3.pnl16.Color:=clMoneyGreen;

            Form3.edt16.Text:=FloatToStr(arrEnableChanals[i].endRange-0.1);
          end
          else
          begin
            Form3.edt16.Enabled:=false;
            Form3.pnl16.Color:=clBtnFace;
          end;
        end;
        17:
        begin
          //расставим доступность элементов
          if (arrEnableChanals[i].enabled) then
          begin
            Form3.edt17.Enabled:=True;
            Form3.pnl17.Color:=clMoneyGreen;

            Form3.edt17.Text:=FloatToStr(arrEnableChanals[i].endRange-0.1);
          end
          else
          begin
            Form3.edt17.Enabled:=false;
            Form3.pnl17.Color:=clBtnFace;
          end;
        end;
        18:
        begin
          //расставим доступность элементов
          if (arrEnableChanals[i].enabled) then
          begin
            Form3.edt18.Enabled:=True;
            Form3.pnl18.Color:=clMoneyGreen;

            Form3.edt18.Text:=FloatToStr(arrEnableChanals[i].endRange-0.1);
          end
          else
          begin
            Form3.edt18.Enabled:=false;
            Form3.pnl18.Color:=clBtnFace;
          end;
        end;
        19:
        begin
          //расставим доступность элементов
          if (arrEnableChanals[i].enabled) then
          begin
            Form3.edt19.Enabled:=True;
            Form3.pnl19.Color:=clMoneyGreen;

            Form3.edt19.Text:=FloatToStr(arrEnableChanals[i].endRange-0.1);
          end
          else
          begin
            Form3.edt19.Enabled:=false;
            Form3.pnl19.Color:=clBtnFace;
          end;
        end;
        20:
        begin
          //расставим доступность элементов
          if (arrEnableChanals[i].enabled) then
          begin
            Form3.edt20.Enabled:=True;
            Form3.pnl20.Color:=clMoneyGreen;

            Form3.edt20.Text:=FloatToStr(arrEnableChanals[i].endRange-0.1);
          end
          else
          begin
            Form3.edt20.Enabled:=false;
            Form3.pnl20.Color:=clBtnFace;
          end;
        end;
        21:
        begin
          //расставим доступность элементов
          if (arrEnableChanals[i].enabled) then
          begin
            Form3.edt21.Enabled:=True;
            Form3.pnl21.Color:=clMoneyGreen;

            Form3.edt21.Text:=FloatToStr(arrEnableChanals[i].endRange-0.1);
          end
          else
          begin
            Form3.edt21.Enabled:=false;
            Form3.pnl21.Color:=clBtnFace;
          end;
        end;
        22:
        begin
          //расставим доступность элементов
          if (arrEnableChanals[i].enabled) then
          begin
            Form3.edt22.Enabled:=True;
            Form3.pnl22.Color:=clMoneyGreen;

            Form3.edt22.Text:=FloatToStr(arrEnableChanals[i].endRange-0.1);
          end
          else
          begin
            Form3.edt22.Enabled:=false;
            Form3.pnl22.Color:=clBtnFace;
          end;
        end;
        23:
        begin
          //расставим доступность элементов
          if (arrEnableChanals[i].enabled) then
          begin
            Form3.edt23.Enabled:=True;
            Form3.pnl23.Color:=clMoneyGreen;

            Form3.edt23.Text:=FloatToStr(arrEnableChanals[i].endRange-0.1);
          end
          else
          begin
            Form3.edt23.Enabled:=false;
            Form3.pnl23.Color:=clBtnFace;
          end;
        end;
        24:
        begin
          //расставим доступность элементов
          if (arrEnableChanals[i].enabled) then
          begin
            Form3.edt24.Enabled:=True;
            Form3.pnl24.Color:=clMoneyGreen;

            Form3.edt24.Text:=FloatToStr(arrEnableChanals[i].endRange-0.1);
          end
          else
          begin
            Form3.edt24.Enabled:=false;
            Form3.pnl24.Color:=clBtnFace;
          end;
        end;
        25:
        begin
          //расставим доступность элементов
          if (arrEnableChanals[i].enabled) then
          begin
            Form3.edt25.Enabled:=true;
            Form3.edt26.Enabled:=true;
            Form3.grp2.Color:=clMoneyGreen;

            Form3.edt25.Text:=FloatToStr(arrEnableChanals[i].begRange+0.1);
            Form3.edt26.Text:=FloatToStr(arrEnableChanals[i].endRange-0.1);
          end
          else
          begin
            Form3.edt25.Enabled:=false;
            Form3.edt26.Enabled:=false;
            Form3.grp2.Color:=clBtnFace;
          end;
        end;
        26:
        begin
          //расставим доступность элементов
          if (arrEnableChanals[i].enabled) then
          begin
            Form3.edt27.Enabled:=true;
            Form3.edt28.Enabled:=true;
            Form3.grp2.Color:=clMoneyGreen;

            Form3.edt27.Text:=FloatToStr(arrEnableChanals[i].begRange+0.1);
            Form3.edt28.Text:=FloatToStr(arrEnableChanals[i].endRange-0.1);
          end
          else
          begin
            Form3.edt27.Enabled:=false;
            Form3.edt28.Enabled:=false;
            Form3.grp2.Color:=clBtnFace;
          end;
        end;
        27:
        begin
          //расставим доступность элементов
          if (arrEnableChanals[i].enabled) then
          begin
            Form3.edt29.Enabled:=true;
            Form3.edt30.Enabled:=true;
            Form3.grp3.Color:=clMoneyGreen;

            Form3.edt29.Text:=FloatToStr(arrEnableChanals[i].begRange+0.1);
            Form3.edt30.Text:=FloatToStr(arrEnableChanals[i].endRange-0.1);
          end
          else
          begin
            Form3.edt29.Enabled:=false;
            Form3.edt30.Enabled:=false;
            Form3.grp3.Color:=clBtnFace;
          end;
        end;
        28:
        begin
          //расставим доступность элементов
          if (arrEnableChanals[i].enabled) then
          begin
            Form3.edt31.Enabled:=true;
            Form3.edt32.Enabled:=true;
            Form3.grp3.Color:=clMoneyGreen;

            Form3.edt31.Text:=FloatToStr(arrEnableChanals[i].begRange+0.1);
            Form3.edt32.Text:=FloatToStr(arrEnableChanals[i].endRange-0.1);
          end
          else
          begin
            Form3.edt31.Enabled:=false;
            Form3.edt32.Enabled:=false;
            Form3.grp3.Color:=clBtnFace;
          end;
        end;
        29:
        begin
         //расставим доступность элементов
          if (arrEnableChanals[i].enabled) then
          begin
            Form3.edt33.Enabled:=true;
            Form3.edt34.Enabled:=true;
            Form3.grp4.Color:=clMoneyGreen;

            Form3.edt33.Text:=FloatToStr(arrEnableChanals[i].begRange+0.1);
            Form3.edt34.Text:=FloatToStr(arrEnableChanals[i].endRange-0.1);
          end
          else
          begin
            Form3.edt33.Enabled:=false;
            Form3.edt34.Enabled:=false;
            Form3.grp4.Color:=clBtnFace;
          end;
        end;
      end;
  end;
end;
//==============================================================================







end.

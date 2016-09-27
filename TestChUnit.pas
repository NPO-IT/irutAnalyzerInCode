unit TestChUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TForm2 = class(TForm)
    startTestBut: TButton;
    chk1: TCheckBox;
    chk2: TCheckBox;
    chk3: TCheckBox;
    lbl1: TLabel;
    procedure startTestButClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

implementation
uses SensorLimitUnit;

{$R *.dfm}

procedure TForm2.startTestButClick(Sender: TObject);
begin
  form2.Hide;

  //��������� ����� �� ������ �������� �������� ����������� ����������
  if (Form2.chk3.Checked) then
  begin
    //���������� ����� � ���. ����������� ��������
    //��������� ��������� �����
    InitSensorLimitForm;
    form3.Show;
  end
  else
  begin
    //��������� �������� ��� ���. ������
    startExecute;
  end;
end;

end.

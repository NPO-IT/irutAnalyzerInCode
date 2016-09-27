program SCRUTJTPlayer;

uses
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  WriteSkoUnit in 'WriteSkoUnit.pas',
  ConstUnit in 'ConstUnit.pas',
  WriteGistUnit in 'WriteGistUnit.pas',
  WriteLogUnit in 'WriteLogUnit.pas',
  TestChUnit in 'TestChUnit.pas' {Form2},
  SensorLimitUnit in 'SensorLimitUnit.pas' {Form3},
  ExcelWorkUnit in 'ExcelWorkUnit.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TForm2, Form2);
  Application.CreateForm(TForm3, Form3);
  Application.Run;
end.

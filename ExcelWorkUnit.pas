unit ExcelWorkUnit;
interface
uses ComObj, ActiveX, Variants, Windows, Messages, SysUtils, Classes;

const
  ExcelApp = 'Excel.Application';
var
  MyExcel: OleVariant;
  activeSheetObj:OleVariant;

//===
function CheckExcelInstall:boolean;
function CheckExcelRun: boolean;
function RunExcel(DisableAlerts:boolean=true; Visible: boolean=false): boolean;
function AddWorkBook(AutoRun:boolean=true):boolean;
function GetAllWorkBooks:TStringList;
function SaveWorkBook(FileName:TFileName; WBIndex:integer):boolean;
function StopExcel:boolean;
function ActivateSheet(WBIndex:integer; SheetName:string):boolean;
function SetCellValue(var excelWorkObj:OleVariant;pasteStr:string;yCoord:Cardinal;xCoord:Cardinal):Boolean;
function GetCellValue(var excelWorkObj:OleVariant;yCoord:Cardinal;xCoord:Cardinal):string;
function SetCellColor(var excelWorkObj:OleVariant;colorInd:Integer;yCoord:Cardinal;xCoord:Cardinal):Boolean;
implementation


//==============================================================================
//�������� ���������� �� Excel �� ��. True or False
//==============================================================================
function CheckExcelInstall:boolean;
var
  ClassID: TCLSID;
  Rez : HRESULT;
begin
  // ���� CLSID OLE-�������
  Rez := CLSIDFromProgID(PWideChar(WideString(ExcelApp)), ClassID);
  if Rez = S_OK then
  begin
    // ������ ������
    Result := true
  end
  else
  begin
    Result := false;
  end;  
end;
//==============================================================================

//==============================================================================
//�������� ������� �� Excel �� ��. ���� �� �� �������� ������ �� ���������� �������
//��� ���
//==============================================================================
function CheckExcelRun: boolean;
begin
  try
    MyExcel:=GetActiveOleObject(ExcelApp);
    Result:=True;
  except
    Result:=false;
  end;
end;
//==============================================================================

//==============================================================================
//������ Excel
//==============================================================================
function RunExcel(DisableAlerts:boolean=true; Visible: boolean=false): boolean;
begin
  try
    {��������� ���������� �� Excel}
    if CheckExcelInstall then
    begin
      //���������� ������������� �����������(��� ������� �� � �������� ������)
      CoInitialize(nil);

      MyExcel:=CreateOleObject(ExcelApp);
      //����������/�� ���������� ��������� ��������� Excel (����� �� ����������)
      MyExcel.Application.EnableEvents:=DisableAlerts;
      MyExcel.Visible:=Visible;
      Result:=true;
    end
    else
    begin
      MessageBox(0,'���������� MS Excel �� ����������� �� ���� ����������',
        '������',MB_OK+MB_ICONERROR);
      Result:=false;
    end;
  except
    Result:=false;
  end;
end;
//==============================================================================

//==============================================================================
//���������� ������ ������� ����� 
//==============================================================================
function AddWorkBook(AutoRun:boolean=true):boolean;
begin
  if CheckExcelRun then
  begin
    //excel ��� �������
    //���������� ������� �����
    MyExcel.WorkBooks.Add;
    Result:=true;
  end
  else
  begin
    //���� �������� �������� AutoRun=true �� �������� excel � ������� �����
    if AutoRun then
    begin
      RunExcel;
      MyExcel.WorkBooks.Add;
      Result:=true;
    end
    else
    begin
      Result:=false;
    end;
  end;
end;
//==============================================================================

//==============================================================================
//��������� ������ ������� ���� Excel. ��������� ������ � 0.
//==============================================================================
function GetAllWorkBooks:TStringList;
var i:integer;
begin
  try
    Result:=TStringList.Create;
    for i:=1 to MyExcel.WorkBooks.Count do
    begin
      Result.Add(MyExcel.WorkBooks.Item[i].FullName);
    end;
  except
    MessageBox(0,'������ ������������ �������� ����','������',MB_OK+MB_ICONERROR);
  end;
end;
//==============================================================================

//==============================================================================
//���������� ������� �����.
//==============================================================================
function SaveWorkBook(FileName:TFileName; WBIndex:integer):boolean;
begin
  try
    MyExcel.DisplayAlerts := False; 
    MyExcel.WorkBooks.Item[WBIndex].SaveAs(FileName);
    if MyExcel.WorkBooks.Item[WBIndex].Saved then
    begin
      Result:=true;
    end
    else
    begin
      Result:=false;
    end;
  except
    Result:=false;
  end;
end;
//==============================================================================

//==============================================================================
//��������� Excel
//==============================================================================
function StopExcel:boolean;
begin
  try
    if MyExcel.Visible then
    begin
      MyExcel.Visible:=false;
    end;
    MyExcel.Quit;
    MyExcel:=Unassigned;
    Result:=True;
  except
    Result:=false;
  end;
end;
//==============================================================================

//==============================================================================
//������� ��������� ����� ������� ����� ��� ������ � ���.
//WBIndex-������ ������� �����. SheetName-�������� ����� ��� ���������
//�����
//MyExcel.ActiveWorkBook.Sheets.Item[i].Activate;
//==============================================================================
function ActivateSheet(WBIndex:integer; SheetName:string):boolean;
var
  i:integer;
  str:string;
begin
  Result:=false;
  try
    if WBIndex>MyExcel.WorkBooks.Count then
    begin
      raise Exception.Create('����� �������� ������ ��� WorkBooks. ��������� ����� ��������');
    end
    else
    begin
      for i:=1 to MyExcel.WorkBooks[WBIndex].Sheets.Count do
      begin
        str:=AnsiLowerCase(MyExcel.WorkBooks[WBIndex].Sheets.Item[i].Name);
        if str=AnsiLowerCase(SheetName) then
        begin
          activeSheetObj:=MyExcel.WorkBooks[WBIndex].Sheets.Item[i].Activate;
          Result:=true;
          break;
        end;
      end;  
    end;
  except
    raise Exception.Create('��������� ����� ��������� � �������');
  end;
end;
//==============================================================================

//==============================================================================
//������� �������� ���������� ������ ���������� ������. 
//==============================================================================
function SetCellColor(var excelWorkObj:OleVariant;colorInd:Integer;yCoord:Cardinal;xCoord:Cardinal):Boolean;
begin
  try
    excelWorkObj.{ActiveWorkBook.ActiveWorkSheet.}Workbooks[1].WorkSheets[1].Cells[yCoord,xCoord].Interior.ColorIndex:=colorInd;
    result:=true;
  except
    raise Exception.Create('������ ���������� ������');
    result:=false;
  end;
end;
//==============================================================================




//==============================================================================
//������� ������ ����������� �������� � ���������� ����� ������(y,x) �������� �����,
//��������� �����.
// C5 (5,3)
//==============================================================================
function SetCellValue(var excelWorkObj:OleVariant;pasteStr:string;yCoord:Cardinal;xCoord:Cardinal):Boolean;
begin
  try
    excelWorkObj.{ActiveWorkBook.ActiveWorkSheet.}Workbooks[1].WorkSheets[1].Cells[yCoord,xCoord].value:=pasteStr;
    //���������� �������������� ����� ��� ������ �������� ������
    excelWorkObj.{ActiveWorkBook.ActiveWorkSheet.}Workbooks[1].WorkSheets[1].Cells[yCoord,xCoord].Columns.AutoFit;

   // excelWorkObj.Cells[yCoord,xCoord].value:=pasteStr;
    //���������� �������������� ����� ��� ������ �������� ������
   // excelWorkObj.Cells[yCoord,xCoord].Columns.AutoFit;
    result:=true;
  except
    raise Exception.Create('������ ������ ������');
    result:=false;
  end;
end;
//==============================================================================

//==============================================================================
//������� ���������� ���������� ���������� ������. ������ ���������� � ���� ���������
//==============================================================================
function GetCellValue(var excelWorkObj:OleVariant;yCoord:Cardinal;xCoord:Cardinal):string;
begin
  try
    Result:=excelWorkObj.ActiveWorkBook.ActiveWorkSheet.Cells[yCoord,xCoord].Text;
  except
    raise Exception.Create('������ ������ ������');
    Result:='';
  end;
end;
//==============================================================================

end.

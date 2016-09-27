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
//Проверка установлен ли Excel на ПК. True or False
//==============================================================================
function CheckExcelInstall:boolean;
var
  ClassID: TCLSID;
  Rez : HRESULT;
begin
  // Ищем CLSID OLE-объекта
  Rez := CLSIDFromProgID(PWideChar(WideString(ExcelApp)), ClassID);
  if Rez = S_OK then
  begin
    // Объект найден
    Result := true
  end
  else
  begin
    Result := false;
  end;  
end;
//==============================================================================

//==============================================================================
//Проверка запущен ли Excel на ПК. Если да то получаем ссылку на запущенный процесс
//или нет
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
//Запуск Excel
//==============================================================================
function RunExcel(DisableAlerts:boolean=true; Visible: boolean=false): boolean;
begin
  try
    {проверяем установлен ли Excel}
    if CheckExcelInstall then
    begin
      //производим инициализацию интерфейсов(для запуска не в основном потоке)
      CoInitialize(nil);

      MyExcel:=CreateOleObject(ExcelApp);
      //показывать/не показывать системные сообщения Excel (лучше не показывать)
      MyExcel.Application.EnableEvents:=DisableAlerts;
      MyExcel.Visible:=Visible;
      Result:=true;
    end
    else
    begin
      MessageBox(0,'Приложение MS Excel не установлено на этом компьютере',
        'Ошибка',MB_OK+MB_ICONERROR);
      Result:=false;
    end;
  except
    Result:=false;
  end;
end;
//==============================================================================

//==============================================================================
//Добавление пустой рабочей книги 
//==============================================================================
function AddWorkBook(AutoRun:boolean=true):boolean;
begin
  if CheckExcelRun then
  begin
    //excel уже запущен
    //добавление рабочей книги
    MyExcel.WorkBooks.Add;
    Result:=true;
  end
  else
  begin
    //если передали параметр AutoRun=true то запустим excel и добавим книгу
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
//Получение списка рабочих книг Excel. Нумерация списка с 0.
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
    MessageBox(0,'Ошибка перечисления открытых книг','Ошибка',MB_OK+MB_ICONERROR);
  end;
end;
//==============================================================================

//==============================================================================
//Сохранение рабочей книги.
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
//Закрываем Excel
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
//Функция активации листа рабочей книги для работы с ним.
//WBIndex-индекс рабочей книги. SheetName-название листа для активации
//проще
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
      raise Exception.Create('Задан неверный индекс для WorkBooks. Активация листа прервана');
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
    raise Exception.Create('Активация листа завершена с ошибкой');
  end;
end;
//==============================================================================

//==============================================================================
//Функция заливает переданную ячейку переданным цветом. 
//==============================================================================
function SetCellColor(var excelWorkObj:OleVariant;colorInd:Integer;yCoord:Cardinal;xCoord:Cardinal):Boolean;
begin
  try
    excelWorkObj.{ActiveWorkBook.ActiveWorkSheet.}Workbooks[1].WorkSheets[1].Cells[yCoord,xCoord].Interior.ColorIndex:=colorInd;
    result:=true;
  except
    raise Exception.Create('Ошибка заполнения ячейки');
    result:=false;
  end;
end;
//==============================================================================




//==============================================================================
//Функция записи переданного значения в переданный номер ячейки(y,x) активной книги,
//активного листа.
// C5 (5,3)
//==============================================================================
function SetCellValue(var excelWorkObj:OleVariant;pasteStr:string;yCoord:Cardinal;xCoord:Cardinal):Boolean;
begin
  try
    excelWorkObj.{ActiveWorkBook.ActiveWorkSheet.}Workbooks[1].WorkSheets[1].Cells[yCoord,xCoord].value:=pasteStr;
    //выполнение автоподстройки ячеек под размер вводимой строки
    excelWorkObj.{ActiveWorkBook.ActiveWorkSheet.}Workbooks[1].WorkSheets[1].Cells[yCoord,xCoord].Columns.AutoFit;

   // excelWorkObj.Cells[yCoord,xCoord].value:=pasteStr;
    //выполнение автоподстройки ячеек под размер вводимой строки
   // excelWorkObj.Cells[yCoord,xCoord].Columns.AutoFit;
    result:=true;
  except
    raise Exception.Create('Ошибка записи ячейки');
    result:=false;
  end;
end;
//==============================================================================

//==============================================================================
//Функция возвращает содержимое переданной ячейки. Ячейка передается в виде координат
//==============================================================================
function GetCellValue(var excelWorkObj:OleVariant;yCoord:Cardinal;xCoord:Cardinal):string;
begin
  try
    Result:=excelWorkObj.ActiveWorkBook.ActiveWorkSheet.Cells[yCoord,xCoord].Text;
  except
    raise Exception.Create('Ошибка чтения ячейки');
    Result:='';
  end;
end;
//==============================================================================

end.

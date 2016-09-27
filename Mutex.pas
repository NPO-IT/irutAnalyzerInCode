unit Mutex;

interface

implementation
uses
  Windows;

var
  M: THandle;
  MutexName: array[0..255] of Char;

function StopRunCopy: boolean;
var
  i: integer;
begin
  MutexName:='SCRUTJTPlayer';
  M:=CreateMutex(nil, false, MutexName); // M = 0 ���� �� ������� ������� �������
  result:= (M = 0) or (GetLastError = ERROR_ALREADY_EXISTS);
end;

procedure ShowErrMsg;
begin
  MessageBox(0, '������ ��������� ��� �������! ���������� ��������� ��� ���� �����.',
    MutexName, MB_ICONSTOP or MB_OK)
end;

initialization

  if StopRunCopy then
    begin
      ShowErrMsg;
      halt
    end;

finalization

  if M <> 0 then CloseHandle(M);

end.


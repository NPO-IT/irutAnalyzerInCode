unit GistUnit;

interface
uses
Classes, SysUtils, Dialogs, Math;
type
//����� ��� ������
TThreadGist = class(TThread)
  private
    { Private declarations }
  protected
    procedure Execute; override;
end;
var
//����� ������
thWriteGist: TThreadGist;
implementation

//============================================================================


end.

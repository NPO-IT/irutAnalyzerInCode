unit GistUnit;

interface
uses
Classes, SysUtils, Dialogs, Math;
type
//поток для записи
TThreadGist = class(TThread)
  private
    { Private declarations }
  protected
    procedure Execute; override;
end;
var
//поток чтения
thWriteGist: TThreadGist;
implementation

//============================================================================


end.

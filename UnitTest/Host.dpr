program Host;

{$APPTYPE CONSOLE}

uses
  SysUtils, CodeProxy;

Type
  TCodeEntry = Procedure ();
  
var
  CodeBase: Pointer;
  CodeSize: LongWord;

begin
  if TestMakeSpyCode (CodeBase, CodeSize) then
  begin
    TCodeEntry (CodeBase);
    ReadLn;
  end;
end.

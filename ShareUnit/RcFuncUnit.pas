unit RcFuncUnit;

interface
uses windows, classes, sysutils, WideStrings;

function GetRCStringList (ResType, ResName: String): TStringList;
function GetRCDataMemory (ResType, ResName: String): TCustomMemoryStream;
function GetRCDataMMemory (ResType, ResName: String): TMemoryStream;

function RcAnsiSLToWideSL (ResType, ResName: String): TWideStringList;
function RcAnsiSLToWideString (ResType, ResName: String): WideString;
function RcAnsiSLToString (ResType, ResName: String): String;

implementation

function GetRCDataMemory (ResType, ResName: String): TCustomMemoryStream;
begin
  Result := TResourceStream.create(hinstance, ResName, PChar(ResType));
  Result.Seek(0, soFromBeginning);
end;

function GetRCDataMMemory (ResType, ResName: String): TMemoryStream;
var
  RS: TResourceStream;
begin
  Result := TMemoryStream.Create;
  RS := TResourceStream.create(hinstance, ResName, PChar(ResType));
  if RS.Size > 0 then
    Result.LoadFromStream(RS);
  RS.Free;
  Result.Seek(0, soFromBeginning);
end;


function GetRCStringList (ResType, ResName: String): TStringList;
var
  ResMM: TCustomMemoryStream;
begin
  ResMM := GetRCDataMemory (ResType, ResName);
  Result := TStringList.Create;
  Result.LoadFromStream(ResMM);
  ResMM.Free;
end;

function RcAnsiSLToWideSL (ResType, ResName: String): TWideStringList;
var
  RawSL: TStringList;
begin
  RawSL := GetRCStringList (ResType, ResName);
  Result := TWideStringList.Create;
  Result.AddStrings(RawSL);
  RawSL.Free;
end;

function RcAnsiSLToWideString (ResType, ResName: String): WideString;
var
  RawWSL: TWideStringList;
begin
  RawWSL := RcAnsiSLToWideSL (ResType, ResName);
  Result := RawWSL.Text;
  RawWSL.Free;
end;

function RcAnsiSLToString (ResType, ResName: String): String;
var
  RawWSL: TStringList;
begin
  RawWSL := GetRCStringList (ResType, ResName);
  Result := RawWSL.Text;
  RawWSL.Free;
end;

end.

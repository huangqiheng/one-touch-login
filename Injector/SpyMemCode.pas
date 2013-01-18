unit SpyMemCode;

interface
uses Windows;

Type
  LPTSpyMemCodeData = ^TSpyMemCodeData;
  TSpyMemCodeData = Packed Record
    Size: Integer;
    OnService: BOOL;
    RunResult: DWORD;
    ServiceTimeLeft: DWORD;
    ProcessNameOffset: Integer;
    SpyEventOffset: Integer;
    SpyCodeOffset: Integer;
    SpyCodeMaxSize: Integer;
    CodeBuffer: Array[0..0] of char;
  end;

  
implementation



end.

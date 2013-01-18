unit ThreadTempMemory;

interface

uses windows, classes;

const
  DEFAULT_TIMEOUT = 60 * 1000;
  DEFAULT_CHECK_PERIOD = 30 * 1000;

function GetThreadMem (Size: DWORD): Pointer; Stdcall;

implementation

uses SyncObjs, IntList;

Type
  LPTMemRecord = ^TMemRecord;
  TMemRecord = record
    Address: Pointer;
    OriSize: Integer;
    TimeOutTick: DWORD;
  end;

var
  ThreadMemLst: TintList;
  Lock: TCriticalSection;
  LastCheckTick: DWORD;

function GetThreadMem (Size: DWORD): Pointer; Stdcall;
var
  Tid: DWORD;
  Item: LPTMemRecord;
  Index: Integer;
begin                 
  Result := nil;
  if Size = 0 then exit;

  if not assigned (ThreadMemLst) then
  begin
    ThreadMemLst := TintList.Create;
    Lock := TCriticalSection.Create;
    LastCheckTick := GetTickCount;
  end;

  Tid := GetCurrentThreadID;

  Lock.Enter;
  Try
    Index := ThreadMemLst.IndexOf(Tid);
    if Index >= 0 then
    begin             
      Item := Pointer(ThreadMemLst.Objects[Index]);
      if DWORD(Item.OriSize) < Size then
      begin
        Item.OriSize := Size;
        ReAllocMem (Item.Address, Item.OriSize);
      end;          
    end else
    begin
      GetMem (Item, SizeOf(TMemRecord));
      Item.OriSize := Size;
      GetMem (Item.Address, Item.OriSize);
      ThreadMemLst.AddObject (Tid, Pointer(Item));
    end;

    Item.TimeOutTick := GetTickCount + DEFAULT_TIMEOUT;
    Result := Item.Address;

    if GetTickCount - LastCheckTick > DEFAULT_CHECK_PERIOD then
    begin
      for Index := ThreadMemLst.Count - 1 downto 0 do
      begin
        Item := Pointer(ThreadMemLst.Objects[Index]);
        if GetTickCount > Item.TimeOutTick then
        begin
          FreeMem (Item.Address);
          FreeMem (Item);
          ThreadMemLst.Delete(Index);
        end;
      end;
      LastCheckTick := GetTickCount;
    end;
  finally
    Lock.Leave;
  end;  
end;

end.
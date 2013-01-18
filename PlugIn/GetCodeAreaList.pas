unit GetCodeAreaList;
//注意：并非线程安全，有耗时函数

interface

uses windows, sysutils, classes;

Type
  LPTFuncNode = ^TFuncNode;
  TFuncNode = record
    EntryPoint: Pointer;
    Module: THandle;
    Recursive: BOOL;
    CodeBegin: Pointer;
    CodeLen: Integer;   
    CallToTarget: TList;
    CallFroms: TList;
    CodeList: TList;
    CodeStr: String;
  end;

  LPTFlatNode = ^TFlatNode;
  TFlatNode = packed record
    Size: Integer;
    Module: THandle;
    Recursive: BOOL;
    EntryPoint: Pointer;
    CodeBegin: Pointer;
    CodeLen: Integer;
    CallToTargetCount: Integer;
    CallFromCount: Integer;
    Buffer: Array[0..0] of Char;  //先放CallTo，再放CallFrom
  end;

  LPTFlatNodeLst = ^TFlatNodeLst;
  TFlatNodeLst = packed record
    Size: Integer;
    Count: Integer;
    Buffer: Array[0..0] of Char;
  end;

function AddImageNodeToList (NodeLst: TList; Image: THandle): LPTFuncNode;
function AddNodeToList (NodeLst: TList; Data: Pointer; FunEntry: Pointer): LPTFuncNode;
function FindNodeByEntry (NodeLst: TList; CodeEntry: Pointer): LPTFuncNode;
function FindNodeByAddress (NodeLst: TList; CallFrom: Pointer): LPTFuncNode;
function FreeNodeByEntry (NodeLst: TList; CodeEntry: Pointer): BOOL;
function ClearNodeList (NodeLst: TList): BOOL;

function ExtractFlatData (NodeLst: TList): LPTFlatNodeLst;
function ExtractToFile (NodeLst: TList; FileName: String): BOOL;
function LoadFromFlatData (NodeLst: TList; Data: LPTFlatNodeLst): BOOL;
function LoadFormFileData (NodeLst: TList; FileName: String): BOOL;
function LoadFromList (NodeLst: TList; OtherLst: TList): BOOL;
function LoadSingleNode (NodeLst: TList; ToRead: LPTFuncNode): BOOL;
function DuplicateList (NodeLst: TList): TList;
function GetImageFlatNodeLst (Image: THandle): LPTFlatNodeLst;

var
  AppTerminated: BOOL = False;


Type
  TtdCompareFunc = function (aData1, aData2 : pointer) : integer;
            
function TDTListSortedInsertPos(aList : TList; aItem : pointer; aCompare : TtdCompareFunc; var IsExists: BOOL) : integer;
function NodeCompareFunc (IterNode: LPTFuncNode; EntryPoint: Pointer) : integer;
procedure AddToList (List: TList; Item: Pointer);
function Node_AddItem (NodeLst: TList; Node: LPTFuncNode): BOOL;
procedure AddCallFrom (AimNode: LPTFuncNode; CallFrom: Pointer);

implementation

{$ifdef Unit_Test_Mode}
uses DisAsmStr, FindAddress;   //仅单元测试用
{$else}
  {$ifdef Release_Library_Mode}
  uses PlugKernelLib;  //使用PlugKernel.dll模式
  {$else}
  uses ImportUnit;   //默认就是插件模式
  {$endif}
{$endif}



function TDTListSortedInsertPos(aList : TList; aItem : pointer;
                             aCompare : TtdCompareFunc; var IsExists: BOOL) : integer;
var
  L, R, M : integer;
  CompareResult : integer;
begin
  IsExists := False;
  L := 0;
  R := pred(aList.Count);
  while (L <= R) do begin
    M := (L + R) div 2;
    CompareResult := aCompare(aList.List^[M], aItem);
    if (CompareResult < 0) then
      L := succ(M)
    else if (CompareResult > 0) then
      R := pred(M)
    else begin
      Result := M;
      IsExists := True;
      Exit;
    end;
  end;
  Result := L;
end;

function TDTListSortedIndexOf(aList : TList; aItem : pointer;
                              aCompare : TtdCompareFunc) : integer;
var
  IsExists: BOOL;
begin
  Result := TDTListSortedInsertPos (aList, aItem, aCompare, IsExists);
  if IsExists then Exit;
  Result := -1;
end;

function TDTListSortedInsert(aList : TList; aItem : pointer;
                             aCompare : TtdCompareFunc) : integer;
var
  IsExists: BOOL;
begin
  Result := TDTListSortedInsertPos (aList, aItem, aCompare, IsExists);
  if IsExists then Exit;
  aList.Insert(Result, aItem);
end;

function NodeCompareFunc (IterNode: LPTFuncNode; EntryPoint: Pointer) : integer;
begin
  Result := Integer(IterNode.EntryPoint) - Integer(EntryPoint);
end;

function Node_IndexOf (NodeLst: TList; EntryPoint: Pointer): Integer;
begin
  Result := TDTListSortedIndexOf (NodeLst, EntryPoint, TtdCompareFunc(@NodeCompareFunc));
end;

function Node_AddItem (NodeLst: TList; Node: LPTFuncNode): BOOL;
var
  AllReadyExists: BOOL;
  InsertIndex: Integer;
begin
  Result := False;
  InsertIndex := TDTListSortedInsertPos (NodeLst, Node.EntryPoint, TtdCompareFunc(@NodeCompareFunc), AllReadyExists);
  if not AllReadyExists then
  begin
    NodeLst.Insert(InsertIndex, Node);
    Result := True;
  end;
end;

////////////////////////
////////////////////////

function FindNodeByEntry (NodeLst: TList; CodeEntry: Pointer): LPTFuncNode;
var
  Index: Integer;
begin     
  Index := Node_IndexOf (NodeLst, CodeEntry);
  if Index >= 0 then
    Result := NodeLst[Index]
  else
    Result := NIL;
end;

function DeleteNodeByItem (NodeLst: TList; Node: LPTFuncNode): BOOL;
var
  Index: Integer;
begin
  Result := False;
  Index := Node_IndexOf (NodeLst, Node.EntryPoint);
  if Index >= 0 then
  begin            
    NodeLst.Delete(Index);
    Result := True;
  end;
end;

/////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////


procedure AddToList (List: TList; Item: Pointer);
begin
  if Assigned (List) then
    if Assigned (Item) then
      if List.IndexOf(Item) = -1 then
        List.Add (Item);
end;

function IsMemoryRange (Base: Pointer; Size: Integer; Address: Pointer): BOOL;
begin                           
  Result := (DWORD(Address) >= DWORD(Base)) and
            (DWORD(Address) < (DWORD(Base) + DWORD(Size)));
end;
                  
function FindNodeByAddress (NodeLst: TList; CallFrom: Pointer): LPTFuncNode;
var
  Index, RecodeIndex: Integer;
  MinOffset, IterOffset: DWORD;
  Item: LPTFuncNode;
begin
  Result := nil;
  RecodeIndex := -1;
  MinOffset := High(DWORD);
  for Index := 0 to NodeLst.Count - 1 do
  begin
    if AppTerminated then exit;
    Item := NodeLst[Index];
    if IsMemoryRange (Item.CodeBegin, Item.CodeLen, CallFrom) then
    begin
      IterOffset := DWORD(CallFrom) - DWORD(Item.CodeBegin);
      if IterOffset < MinOffset then
      begin
        MinOffset := IterOffset;
        RecodeIndex := Index;
      end;
    end;                     
  end;

  if RecodeIndex >= 0 then
    Result := NodeLst[RecodeIndex];
end;


function NewANode : LPTFuncNode;
begin
  New (Result);
  Result.CodeList := TList.Create;
  Result.CallToTarget := TList.Create;
  Result.CallFroms := TList.Create;
  Result.CodeStr := '';
end;

function GetANote (CallTo: Pointer; Out FunInfo: LPTFuncInfos): LPTFuncNode; Stdcall;
begin
  Result := nil;
  Try
    FunInfo := GetFuncStruct (CallTo);
  Except
    Exit;
  end;
  if FunInfo = nil then exit;

  Result := NewANode; 
  Result.EntryPoint := FunInfo.EntryPoint;
  Result.CodeBegin := FunInfo.CodeBegin;
  Result.CodeLen :=FunInfo.CodeLen;
  Result.Recursive := False;
end;

procedure FreeANode (Node: LPTFuncNode);
begin
  Node.CallToTarget.Free;
  Node.CallFroms.Free;
  Node.CodeList.Free;
  Dispose (Node);
end;

function ClearNodeList (NodeLst: TList): BOOL;
var
  Node: LPTFuncNode;
begin
  Result := False;
  if not Assigned (NodeLst) then exit;
  for Node in NodeLst do
    FreeANode (Node);
  NodeLst.Clear;
  Result := True;
end;              
function FreeNodeByEntry (NodeLst: TList; CodeEntry: Pointer): BOOL;
var
  Item: LPTFuncNode;
  Index: Integer;
begin
  Result := False;
  Index := Node_IndexOf (NodeLst, CodeEntry);  
  if Index >= 0 then
  begin
    Item := NodeLst[Index];
    NodeLst.Delete(Index);
    FreeANode (Item);
    Result := True;
  end;
end;

procedure AddCallFrom (AimNode: LPTFuncNode; CallFrom: Pointer);
begin
  AddToList (AimNode.CallFroms, CallFrom);
end;

Type
  LPTIterObj = ^TIterObj;
  TIterObj = record
    CallFromAddr: Pointer;
    ImageBase: Pointer;
    ImageSize: integer;
  end;

//NodeList = nil： 不递归向里面搜索，只返回FunEntry当层函数信息
//Data = nil； 说明这是入口，并非递归中间层次
function AddNodeToList (NodeLst: TList; Data: Pointer; FunEntry: Pointer): LPTFuncNode;

var
  IterObjRaw: TIterObj;
  IterData: LPTIterObj;
  FNode, NextNode, NodeToFree: LPTFuncNode;
  FunInfo: LPTFuncInfos;
  Index: Integer;
  SubCallTo, SubCallFrom: Pointer;
  OutofMyImage: BOOL;
  Item: LPTFarCallData;
begin
  Result := Nil;
  if AppTerminated then Exit;    

  //为新入口初始化
  if Data = Nil then
  begin   
    if Assigned (NodeLst) then
    begin
      FNode := FindNodeByEntry (NodeLst, FunEntry);
      if Assigned (FNode) then
      begin
        Result := FNode;
        Exit;
      end;
    end;
    IterData := @IterObjRaw;
    IterData.ImageBase := GetImageBase (FunEntry);
    IterData.ImageSize := GetModuleSize (THandle(IterData.ImageBase));
    IterData.CallFromAddr := NIL;
  end else
    IterData := Data;

  //生成要分析函数的节点
  FNode := GetANote (FunEntry, FunInfo);
  if not Assigned (FNode) then exit;

  //记录模块句柄    
  OutofMyImage := not IsMemoryRange (IterData.ImageBase, IterData.ImageSize, FunEntry);
  if OutofMyImage then
  begin
    FNode.Module := THandle(GetImageBase (FunEntry));
    FNode.Recursive := False;
  end else
  begin
    FNode.Module := THandle(IterData.ImageBase);
    FNode.Recursive := True;
  end;

  if Assigned (NodeLst) then
  begin
    //收录该函数
    Node_AddItem (NodeLst, FNode);
    //加入CallFrom统计，NodeLst=nil的情况是入口，是不需统计CallFrom的
    AddCallFrom (FNode, IterData.CallFromAddr);
  end;

  //加入CallTo统计和递归
  Item :=  Pointer (Integer(FunInfo) + FunInfo.FarCallsOffset);
  for Index := 0 to FunInfo.FarCallsCount - 1 do
  begin
    SubCallTo := Item.Target;
    SubCallFrom := Item.CodeAddr1;
    IterData.CallFromAddr := SubCallFrom;
    NodeToFree := NIL;

    if Assigned (NodeLst) then
    begin
      //查看这个节点是否完整
      NextNode := FindNodeByEntry (NodeLst, SubCallTo);
      if Assigned (NextNode) then
      begin
        AddCallFrom (NextNode, IterData.CallFromAddr);
        //针对第一次由于OutofMyImage而忽略处理的CallTo目标
        if THandle(IterData.ImageBase) = NextNode.Module then
        if not NextNode.Recursive then
        if DeleteNodeByItem (NodeLst, NextNode) then
        begin
          NodeToFree := NextNode;
          NextNode := nil;
        end;
      end;

      //查看这个CallTo节点是否已经分析过
      if NextNode = nil then
        if FNode.Recursive then
          AddNodeToList (NodeLst, IterData, SubCallTo);

      if Assigned (NodeToFree) then
      begin
        LoadSingleNode (NodeLst, NodeToFree);
        FreeANode (NodeToFree);
      end;
    end;

    FNode.CallToTarget.Add(SubCallTo);
    Inc (Item);
  end;              
  Result := FNode;
end;


Type    
  LPTCodeSection = ^TCodeSection;
  TCodeSection = record
    CodeBase: Pointer;
    CodeSize: Integer
  end;
  
  LPTSenderLst = ^TSenderLst;
  TSenderLst = record
    Sections: TList;
    OkList: TList;
    NoList: TList;
  end;    


function OutOfCodeSegment (SectionList: TList; Address: Pointer): BOOL;
var
  CS: LPTCodeSection;
begin
  Result := False;
  for CS in SectionList do
    if IsMemoryRange (CS.CodeBase, CS.CodeSize, Address) then
      Exit;
  Result := True;
end;

Function RelocEnumProc (Sender: LPTSenderLst; RelocType: DWORD; RelocAddr: Pointer): BOOL; Stdcall;
Const
  IMAGE_REL_BASED_ABSOLUTE=0;
  IMAGE_REL_BASED_HIGHLOW=3;
var
  AimAddr: Pointer;
begin
  if AppTerminated then
  begin
    Result := False;
    Exit;
  end;
  
  Result := True;
  AimAddr := PPointer(RelocAddr)^;
  if RelocType <> IMAGE_REL_BASED_HIGHLOW then Exit;
  if Sender.NoList.IndexOf(AimAddr) >= 0 then Exit;
  if Sender.OkList.IndexOf(AimAddr) >= 0 then Exit;

  Repeat
    if OutOfCodeSegment (Sender.Sections, AimAddr) then Break;
    if PWORD(AimAddr)^ = $FFFF then Break;
    if PDWORD(AimAddr)^ = 0 then Break;
    if GetFuncStruct (AimAddr) = nil then Break;
    Sender.OkList.Add(AimAddr);
    Exit;
  until True;

  Sender.NoList.Add(AimAddr);
end;

procedure EnumCodeCallback (NodeLst: TList; CodeBase: Pointer; CodeSize: Integer); Stdcall;
var
  CS: LPTCodeSection;
begin
  New(CS);
  CS.CodeBase := CodeBase;
  CS.CodeSize := CodeSize;
  NodeLst.Add(CS);
end;

function ExportEnumProc (OkList: TList; Name: PChar; Index: Integer; Entry: Pointer): BOOL; Stdcall;
begin
  if AppTerminated then
  begin
    Result := False;
    Exit;
  end;

  Result := True;
  if assigned (Entry) then
    OkList.Add(Entry);
end;

function CallScaner (OkList: TList; CodeStruct: LPTCodeInfos): BOOL; Stdcall;
begin
  Result := False;
  if AppTerminated then Exit;
  OkList.Add(CodeStruct.This);
  Result := True;
end;


FUNCTION ScanE8FF15Call (CodeBase: Pointer; CodeSize: Integer; Enumer, Sender : Pointer): BOOL; Stdcall;
var                                                                  
  ScanBase: PByte;
  MaxPos: DWORD;
  CheckRet: LPTCodeInfos;
  CodeRet: TCodeInfos;
begin
  Result := False;
  ScanBase := CodeBase;
  MaxPos := DWORD(ScanBase) + DWORD(CodeSize);
  Repeat
    if (ScanBase^ = $E8) or (PWORD(ScanBase)^ = $15FF) then
    begin
      CheckRet := GetCodeStruct(Pointer(ScanBase));
      if Assigned (CheckRet) then
        if CheckRet.Call then
        begin                      
          CodeRet := CheckRet^;
          if Assigned (CodeRet.Target) then
            if GetFuncStruct (CodeRet.Target) <> nil then
              if not CallScaner (Sender, @CodeRet) then exit;
          Inc (ScanBase, CodeRet.CodeLen);
          Continue;
        end;
    end;
    Inc (ScanBase);
  until DWORD(ScanBase) >= MaxPos;
  Result := true;
end;


function AddImageNodeToList (NodeLst: TList; Image: THandle): LPTFuncNode;
var
  Address, AimEntry: Pointer;
  SenderLst: TSenderLst;
  CS: LPTCodeSection;
  FoundNode: LPTFuncNode;
  CodeInfo: LPTCodeInfos;
  IterObj: TIterObj;
begin
  if Image = 0 then
    Image := GetModuleHandle (nil);
    
  Address := GetEntryPoint (Image);
  Result := AddNodeToList (NodeLst, nil, Address);

  SenderLst.Sections := TList.Create; 
  SenderLst.OkList := TList.Create;
  SenderLst.NoList := TList.Create;

  //收集输出函数入口
  EnumExports (Image, @ExportEnumProc, SenderLst.OkList);

  //收集从定位入口
  GetCodeSectionMemory (Image, @EnumCodeCallback, SenderLst.Sections);
  EnumRelocations (Image, @RelocEnumProc, @SenderLst);

  //批量加入收集到的节点
  for Address in SenderLst.OkList do
  begin
    if AppTerminated then exit;
    AddNodeToList (NodeLst, nil, Address);
  end;                                     

  //扫描段内E8直接Call，和FF15直接call
  SenderLst.OkList.Clear;
  for CS in SenderLst.Sections do
    ScanE8FF15Call (CS.CodeBase, CS.CodeSize, @CallScaner, SenderLst.OkList);

  //批量加入收集到的call，填入结构关系
  IterObj.ImageBase := Pointer(Image);
  IterObj.ImageSize := GetModuleSize(Image);
  for Address in SenderLst.OkList do
  begin
    CodeInfo := GetCodeStruct (Address);
    if Assigned (CodeInfo) then
    begin
      AimEntry := CodeInfo.Target;
      FoundNode := FindNodeByEntry (NodeLst, AimEntry);
      if not Assigned (FoundNode) then
      begin
        IterObj.CallFromAddr := Address;
        AddNodeToList (NodeLst, @IterObj, AimEntry);
      end else
        AddCallFrom (FoundNode, Address);
    end;
  end;
                       
  for Address in SenderLst.Sections do Dispose (Address);
  SenderLst.Sections.Free;
  SenderLst.OkList.Free;
  SenderLst.NoList.Free;
end;

function ExtractToFile (NodeLst: TList; FileName: String): BOOL;
var
  Data: LPTFlatNodeLst;
  FSM: TFileStream;
begin
  Result := False;
  Data := ExtractFlatData (NodeLst);
  if Data.Count = 0 then exit;

  if FileExists (FileName) then
    DeleteFile (FileName);

  FSM := TFileStream.Create (FileName, fmCreate);
  FSM.Seek(0, soFromBeginning);
  Result := FSM.Write(Data^, Data.Size) = Data.Size;
  FSM.Free;

  FreeMem (Data);
end;

function ExtractFlatData (NodeLst: TList): LPTFlatNodeLst;
var
  FNode: LPTFuncNode;
  TmpLst: TList;
  ToAddItem: LPTFlatNode;
  ToAddSize, TotalSize: Integer;
  PtrList: PPointerArray;
  Index, AddOffset: Integer;
begin
  Result := nil;
  TmpLst := TList.Create;
  TotalSize := 0;
  
  for FNode in NodeLst do
  begin
    if AppTerminated then exit;
    ToAddSize := SizeOf(TFlatNode) + (FNode.CallToTarget.Count + FNode.CallFroms.Count) * SizeOf(Pointer);
    GetMem (ToAddItem, ToAddSize);
    ToAddItem.Size := ToAddSize;
    ToAddItem.Module := FNode.Module;
    ToAddItem.Recursive := FNode.Recursive;
    ToAddItem.EntryPoint := FNode.EntryPoint;
    ToAddItem.CodeBegin := FNode.CodeBegin;
    ToAddItem.CodeLen := FNode.CodeLen;
    ToAddItem.CallToTargetCount := FNode.CallToTarget.Count;
    ToAddItem.CallFromCount := FNode.CallFroms.Count;

    PtrList := @ToAddItem.Buffer[0];
    for Index := 0 to ToAddItem.CallToTargetCount - 1 do
      PtrList[Index] := FNode.CallToTarget[Index];

    PtrList := @ToAddItem.Buffer[ToAddItem.CallToTargetCount * SizeOf(Pointer)];
    for Index := 0 to ToAddItem.CallFromCount - 1 do
      PtrList[Index] := FNode.CallFroms[Index];

    Inc (TotalSize, ToAddItem.Size);
    TmpLst.Add(ToAddItem);
  end;

  TotalSize := SizeOf(TFlatNodeLst) + TotalSize;
  GetMem (Result, TotalSize);
  Result.Size := TotalSize;
  Result.Count := TmpLst.Count;

  AddOffset := 0;
  for Index := 0 to TmpLst.Count - 1 do
  begin
    ToAddItem := TmpLst[Index];
    CopyMemory (@Result.Buffer[AddOffset], ToAddItem, ToAddItem.Size);
    Inc (AddOffset, ToAddItem.Size);
    FreeMem (ToAddItem);   
  end;

  TmpLst.Free;
end;

function LoadFormFileData (NodeLst: TList; FileName: String): BOOL;
var
  FlatMM: TMemoryStream;
begin
  Result := False;
  FlatMM := TMemoryStream.Create();
  FlatMM.LoadFromFile(FileName);

  if FlatMM.Size > SizeOf(TFlatNodeLst) then
    Result := LoadFromFlatData (NodeLst, FlatMM.Memory);
  
  FlatMM.Free;
end;

function LoadFromFlatData (NodeLst: TList; Data: LPTFlatNodeLst): BOOL;
var
  AimNode: LPTFuncNode;
  Index, Index2, ReadOffset: Integer;
  ToRead: LPTFlatNode;
  PtrList: PPointerArray;
begin
  Result := False;
  ReadOffset := 0;
  for Index := 0 to Data.Count - 1 do
  begin
    if AppTerminated then exit;  
    ToRead := @Data.Buffer[ReadOffset];    

    AimNode := FindNodeByEntry (NodeLst, ToRead.EntryPoint);

    if AimNode = nil then
    begin
      AimNode := NewANode;
      AimNode.EntryPoint := ToRead.EntryPoint;
      Node_AddItem (NodeLst, AimNode);
    end;

    AimNode.Module := ToRead.Module;
    if ToRead.Recursive then
      AimNode.Recursive := ToRead.Recursive;
    AimNode.CodeBegin := ToRead.CodeBegin;
    AimNode.CodeLen := ToRead.CodeLen;    

    PtrList := @ToRead.Buffer[0];
    for Index2 := 0 to ToRead.CallToTargetCount - 1 do
      AddToList (AimNode.CallToTarget, PtrList[Index2]);

    PtrList := @ToRead.Buffer[ToRead.CallToTargetCount * SizeOf(Pointer)];
    for Index2 := 0 to ToRead.CallFromCount - 1 do
      AddToList (AimNode.CallFroms, PtrList[Index2]);

    Inc (ReadOffset, ToRead.Size);
  end;

  Result := ReadOffset > 0;
end;


Procedure CopyNodeToNode (CopyFrom, CopyTo: LPTFuncNode; IsOverride: BOOL = True);
var
  Item: Pointer;
begin
  CopyTo.EntryPoint := CopyFrom.EntryPoint;
  CopyTo.Module := CopyFrom.Module;
  CopyTo.CodeBegin := CopyFrom.CodeBegin;
  CopyTo.CodeLen := CopyFrom.CodeLen;
  CopyTo.CodeStr :=CopyFrom.CodeStr;

  if IsOverride then
  begin
    CopyTo.Recursive := CopyFrom.Recursive;
    
    CopyTo.CodeList.Clear;
    for Item in CopyFrom.CodeList do
      CopyTo.CodeList.Add (Item);

    CopyTo.CallToTarget.Clear;
    for Item in CopyFrom.CallToTarget do
      CopyTo.CallToTarget.Add (Item);

    CopyTo.CallFroms.Clear;
    for Item in CopyFrom.CallFroms do
      CopyTo.CallFroms.Add (Item);
  end else
  begin
    if CopyFrom.Recursive then
      CopyTo.Recursive := CopyFrom.Recursive;

    for Item in CopyFrom.CodeList do
      AddToList (CopyTo.CodeList, Item);

    for Item in CopyFrom.CallToTarget do
      AddToList (CopyTo.CallToTarget, Item);

    for Item in CopyFrom.CallFroms do
      AddToList (CopyTo.CallFroms, Item);
  end;
end;

             
function LoadSingleNode (NodeLst: TList; ToRead: LPTFuncNode): BOOL;
var
  AimNode: LPTFuncNode;
begin
  AimNode := FindNodeByEntry (NodeLst, ToRead.EntryPoint);

  if AimNode = nil then
  begin
    AimNode := NewANode;
    Node_AddItem (NodeLst, AimNode);
  end;

  CopyNodeToNode (ToRead, AimNode, False);

  Result := True;
end;

function LoadFromList (NodeLst: TList; OtherLst: TList): BOOL;
var
  ToRead: LPTFuncNode;
  Index: Integer;
begin
  Result := False;
  for Index := 0 to OtherLst.Count - 1 do
  begin
    if AppTerminated then exit;  
    ToRead := OtherLst[Index];
    LoadSingleNode (NodeLst, ToRead);
  end;             
  Result := NodeLst.Count > 0;
end;

function DuplicateList (NodeLst: TList): TList;
var
  ToRead, AimNode: LPTFuncNode;
  Index: Integer;
begin
  Result := TList.Create;

  for Index := 0 to NodeLst.Count - 1 do
  begin
    if AppTerminated then exit;
    ToRead := NodeLst[Index];

    AimNode := NewANode;
    CopyNodeToNode (ToRead, AimNode);
                          
    Result.Add(AimNode);
  end;
end;

function GetImageFlatNodeLst (Image: THandle): LPTFlatNodeLst;
var
  NodeLst: TList;
begin
  NodeLst := TList.Create;
  AddImageNodeToList (NodeLst, Image);  
  Result := ExtractFlatData (NodeLst);
  ClearNodeList (NodeLst);
  NodeLst.Free;
end;


end.

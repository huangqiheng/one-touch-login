unit CallStructForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Menus, StdCtrls, ExtCtrls, MainExeIni;

type
  TCallStructureForm = class(TForm)
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    Panel1: TPanel;
    Splitter3: TSplitter;
    ListBox2: TListBox;
    ListBox4: TListBox;
    StaticText2: TStaticText;
    Panel2: TPanel;
    Splitter4: TSplitter;
    ListBox1: TListBox;
    ListBox5: TListBox;
    StaticText1: TStaticText;
    Panel3: TPanel;
    StaticText3: TStaticText;
    ListBox3: TListBox;
    PopupMenu1: TPopupMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    procedure ListBox2Click(Sender: TObject);
    procedure ListBox1DblClick(Sender: TObject);
    procedure ListBox1Click(Sender: TObject);
    procedure N2Click(Sender: TObject);
  private
    { Private declarations }
  public
    procedure ViewAAddress (Address: Pointer);
  end;

//更新调用结构库内容
Procedure UpdateLibNodeList (ShareList: TList); Stdcall;

//清理缓存的系统DLL库文件
Procedure ClearUpLibNodeList;

//手动添加一个已经明确的函数入口
Procedure LoadANodeToList (CallFrom, EntryPoint: Pointer);

//获取某代码地址的反汇编代码块
function GetCodeAddrDisasm (CodeAddr: Pointer): String;

//清理缓冲的反汇编代码
procedure ClearCacheDisasmText (CodeAddr: Pointer);

//找出反汇编文本中，指定代码所在的行数
function FoundCodeIndex (SL: TStrings; CodeAddr: Pointer; BeginIndex: Integer = 0): Integer;

var
  IsOnService: BOOL;
  CallStructList: TList; //调用结构树
  FragmentAsmSL: TList;  //通过GetCodeDisAsm得到的LPTCodeInfos列表

implementation

{$R *.dfm}

uses GetCodeAreaList, TrapDbgLibUnit, DbgInfoForm, ModuleFuncList,
  PlugKernelLib;

///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////

function CompareAddress (aData1 : LPTCodeInfos; CodeAddr: Pointer) : integer;
begin
  Result := Integer(aData1.This) - Integer(CodeAddr);
end;

function IsRetCode (Addr: Pointer): BOOL;
var
  RetSign: PByte absolute Addr;
begin
  Result := RetSign^ in [$C2,$C3,$CA,$CB];
end;


function GetForwardAsmRet (Index: Integer; JmpList: TList): TStringList;
var
  Item, NextItem: LPTCodeInfos;
begin
  Result := TStringList.Create;
  Repeat
    Item := FragmentAsmSL [Index];
    //记录jmp模块目标
    if Item.Jmp then
      AddToList (JmpList, Item);
    Result.Add(Item.AsmStr);
    //遇到ret指令为止
    if IsRetCode (@Item.Code[0]) then Exit;

    inc (Index);
    if Index >= FragmentAsmSL.Count then Exit;
    NextItem := FragmentAsmSL [Index];
  until Item.Next <> NextItem.This;
end;


function GetBackwardAsmRet (Index: Integer; JmpList: TList): TStringList;
var
  Item, PreItem: LPTCodeInfos;
begin
  Result := TStringList.Create;

  while Index > 0 do
  begin
    Item := FragmentAsmSL [Index];
    Dec (Index);
    PreItem := FragmentAsmSL [Index];

    if PreItem.Next <> Item.This then Break;
    if IsRetCode (@PreItem.Code[0]) then Break;  //遇到ret指令为止

    Result.Insert(0, PreItem.AsmStr);
    if Item.Jmp then         //记录jmp模块目标
      AddToList (JmpList, Item);
  end;
end;

//获取指定地址开始的代码块的反汇编数组，直到ret返回为止
function RequestCodeAreaDisasm (AreaBase: Pointer; JmpList: TList): TStringList;
var
  Item, NewItem: LPTCodeInfos;
  NewSL: TStringList;
  PosIndex: Integer;
  IsExists: BOOL;
begin
  Result := TStringList.Create;
  if AreaBase = nil then exit;

  PosIndex := TDTListSortedInsertPos (FragmentAsmSL, AreaBase, TtdCompareFunc(@CompareAddress), IsExists);
  if IsExists then
  begin
    NewSL := GetForwardAsmRet (PosIndex, JmpList);
    Result.AddStrings(NewSL);
    NewSL.Free;
    Exit;
  end;

  //向调试目标请求反汇编代码数组，直到Ret返回
  Item := Cmd_GetCodeDisAsmRet (AreaBase);
  if Assigned (Item) then
  begin
    while Assigned (Item.This) do
    begin
      PosIndex := TDTListSortedInsertPos (FragmentAsmSL, Item.This, TtdCompareFunc(@CompareAddress), IsExists);
      if IsExists then  Break;

      New (NewItem);
      NewItem^ := Item^;
      FragmentAsmSL.Insert(PosIndex, NewItem);

      if NewItem.Call then
        if Assigned (NewItem.Target) then
          LoadANodeToList (NewItem.This, NewItem.Target);

      if NewItem.Jmp then
        AddToList (JmpList, NewItem);
      Result.Add(NewItem.AsmStr);

      Inc (Item);
    end;
  end;
end;

Procedure AbsorbStrings (Own: TStrings; var Target: TStrings);
begin
  Own.AddStrings(Target);
  FreeAndNil (Target);
end;


function GetSierialDisasm (CodeAddr: Pointer): TStringList;
var
  IsExists: BOOL;
  PosIndex: Integer;
  JmpList: TList;
  Item: LPTCodeInfos;
  NewSL: TStringList;
  CodeInfos: TCodeInfos;
begin
  Result := TStringList.Create;
  JmpList := TList.Create;

  PosIndex := TDTListSortedInsertPos (FragmentAsmSL, CodeAddr, TtdCompareFunc(@CompareAddress), IsExists);

  if IsExists then
  begin
    //往后添加
    NewSL := GetBackwardAsmRet (PosIndex, JmpList);
    AbsorbStrings (Result, TStrings(NewSL));

    //向前添加
    NewSL := GetForwardAsmRet (PosIndex, JmpList);
    AbsorbStrings (Result, TStrings(NewSL));
  end else
  begin
    CodeInfos.Target := CodeAddr;
    CodeInfos.This := CodeAddr;
    CodeInfos.Jmp := True;   
    JmpList.Add(@CodeInfos);
  end;

  //处理JmpList中的各个代码区
  While JmpList.Count > 0 do
  Begin
    Item := JmpList[0];
    JmpList.Delete(0);
    if Assigned (Item.Target) then
      if ABS(Integer(Item.Target) - Integer(Item.This)) < $100 then
      begin
        NewSL := RequestCodeAreaDisasm (Item.Target, nil);
        AbsorbStrings (Result, TStrings(NewSL));
      end;
  end;

  JmpList.Free;
end;


///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////

var
  AddedNodeList: TList;  //已添加的dll句柄列表
  LibNodeList: TList;    //已添加的dll库的节点
  PEEntryList: TStringList;  //dll入口列表

function GetANote (CallTo: Pointer; Out FunInfo: LPTFuncInfos): LPTFuncNode; Stdcall;
begin
  Result := nil;
  Try
    FunInfo := Cmd_GetFuncDisAsm (CallTo);
  Except
    Exit;
  end;
  if FunInfo = nil then exit;

  New (Result);       
  Result.EntryPoint := FunInfo.EntryPoint;
  Result.CodeBegin := FunInfo.CodeBegin;
  Result.CodeLen :=FunInfo.CodeLen;
  Result.CallToTarget := TList.Create;
  Result.CallFroms := TList.Create;
  Result.CodeList := TList.Create;
  Result.Recursive := False;
end;

Procedure LoadANodeToList (CallFrom, EntryPoint: Pointer);
var
  FNode, NextNode: LPTFuncNode;
  FunInfo: LPTFuncInfos;
  Item: LPTFarCallData;
  Index: Integer;
  SubCallTo, SubCallFrom: Pointer;
begin
  FNode := FindNodeByEntry (CallStructList, EntryPoint);
  if Assigned (FNode) then
  begin
    AddToList (FNode.CallFroms, CallFrom);
    Exit;
  end;
                
  FNode := GetANote (EntryPoint, FunInfo);
  if not Assigned (FNode) then exit;
  FNode.Module := DWORD(EntryPoint) and $FFFF0000;

  //收录该函数
  Node_AddItem (CallStructList, FNode);
  //加入CallFrom统计，NodeLst=nil的情况是入口，是不需统计CallFrom的
  AddCallFrom (FNode, CallFrom);

  //加入CallTo统计和递归
  Item :=  Pointer (Integer(FunInfo) + FunInfo.FarCallsOffset);
  for Index := 0 to FunInfo.FarCallsCount - 1 do
  begin
    SubCallTo := Item.Target;
    SubCallFrom := Item.CodeAddr1;

    //查看这个节点是否完整
    NextNode := FindNodeByEntry (CallStructList, SubCallTo);
    if Assigned (NextNode) then
      AddCallFrom (NextNode, SubCallFrom);

    FNode.CallToTarget.Add(SubCallTo);
    Inc (Item);
  end;
end;

Procedure ExtractCodeList (CodeStr: String; CodeList: TList);
var
  Index: Integer;
  Line: String;
  AddrStr: String;
  Val64: Int64;
  Found: Pointer;
begin
  if CodeStr = '' then exit;
  
  with TStringList.Create do
  try
    Text := CodeStr;
    for Index := 0 to Count - 1 do
    begin
      Line := Strings[Index];
      if Length(Line) >= 8 then
      begin
        AddrStr := '$' + Copy (Line, 1, 8);
        if TryStrToInt64 (AddrStr, Val64) then
        begin
          Found := Pointer(Val64);
          AddToList (CodeList, Found);
        end;
      end;
    end;
  finally
    Free;
  end;
end;

function IsSingleInstruct (OptStr: String): BOOL;
begin
  Result := False;
  Repeat
    if OptStr = 'ret' then break;
    if OptStr = 'enter' then break;
    if OptStr = 'leave' then break;
    Exit;
  until True;
  Result := True;
end;

function FoundCodeIndex (SL: TStrings; CodeAddr: Pointer; BeginIndex: Integer = 0): Integer;
var
  CodeStr, Line: String;
  Index: Integer;
  CheckSL: TStringList;
begin
  Result := -1;
  CodeStr := IntToHex(DWORD(CodeAddr), 8);
  CodeStr := LowerCase (CodeStr);

  for Index := BeginIndex to SL.Count - 1 do
  begin
    Line := SL[Index];

    if Length(Line) > 8 then
      if Pint64(@Line[1])^ = Pint64(@CodeStr[1])^ then
      begin
        CheckSL := GetSplitBlankList (Line);
        if CheckSL.Count >= 3 then
          if CheckSL[CheckSL.Count - 1] <> 'point' then
          begin
            Result := Index;
            CheckSL.Free;
            Exit;
          end;

        if CheckSL.Count = 2 then
          if IsSingleInstruct (CheckSL[1]) then
          begin
            Result := Index;
            CheckSL.Free;
            Exit;
          end;

        CheckSL.Free;
      end;
  end;
end;

//请求反汇编代码
Procedure RemoteUpdateNodeDisasm (Node: LPTFuncNode; Force: BOOL = False);
var
  FuncInfos: LPTFuncInfos;
begin
  if Force then
    Node.CodeList.Clear;

  if Node.CodeList.Count = 0 then
  begin
    FuncInfos := Cmd_GetFuncDisAsm (Node.EntryPoint);
    if Assigned (FuncInfos) then
    begin
      Node.CodeStr := StrPas(@FuncInfos.AsmStr[0]);
      ExtractCodeList (Node.CodeStr, Node.CodeList);
    end;
  end;
end;

function IsIncludeByNode (Node: LPTFuncNode; CodeAddr: Pointer): BOOL;
begin
  //填充代码地址列表CodeList
  RemoteUpdateNodeDisasm (Node);

  //匹配代码地址，定位入口
  Result := Node.CodeList.IndexOf(CodeAddr) >= 0;
end;

function FindNearNodeByAddress (CodeAddr: Pointer): LPTFuncNode;
var
  Index, CheckIndex: Integer;
  Item: LPTFuncNode;
  IsExists: BOOL;
begin
  Index := TDTListSortedInsertPos (CallStructList, CodeAddr, TtdCompareFunc(@NodeCompareFunc), IsExists);

  //输入的CodeAddr是入口地址
  if IsExists then
  begin
    Result := CallStructList[Index];
    Exit;
  end;

  //找出入口地址究竟是多少？ 由近及远查
  CheckIndex := Index - 1;
  Repeat
    if (CheckIndex >= 0) and (CheckIndex < CallStructList.Count) then
    begin
      Item := CallStructList[CheckIndex];

      if IsIncludeByNode (Item, CodeAddr) then
      begin
        Result := Item;
        Exit;
      end;
    end;
    Inc (CheckIndex);
  until Abs(CheckIndex) - Abs(Index) > 1;

  Result := NIL;
end;


procedure ClearForwardAsmRet (CodeAddr: Pointer);
var
  Item, NextItem: LPTCodeInfos;
  DelPos: Integer;
  NextCode: Pointer;
  IsExists: BOOL;
begin
  DelPos := TDTListSortedInsertPos (FragmentAsmSL, CodeAddr, TtdCompareFunc(@CompareAddress), IsExists);
  if not IsExists then Exit;

  Repeat
    Item := FragmentAsmSL [DelPos];
    FragmentAsmSL.Delete(DelPos);
    NextCode := Item.Next;

    //遇到ret指令为止
    if IsRetCode (@Item.Code[0]) then
    begin
      FreeMem (Item);    
      Exit;
    end;
    Dispose (Item);

    if DelPos >= FragmentAsmSL.Count - 1 then Exit;
    NextItem := FragmentAsmSL [DelPos];
  until NextCode <> NextItem.This;
end;

procedure ClearCacheDisasmText (CodeAddr: Pointer);
var
  FuncNode: LPTFuncNode;
begin
  if CodeAddr = nil then exit;

  FuncNode := FindNearNodeByAddress (CodeAddr);
  if Assigned (FuncNode) then
  begin
    FuncNode.CodeList.Clear;
    FuncNode.CodeStr := '';
  end else
  begin
    ClearForwardAsmRet (CodeAddr);
  end;
end;

function GetCodeAddrDisasm (CodeAddr: Pointer): String;
var
  FuncNode: LPTFuncNode;
  FragAsmSL: TStringList;
begin
  Result := '';
  FuncNode := FindNearNodeByAddress (CodeAddr);
  if Assigned (FuncNode) then
  begin
    RemoteUpdateNodeDisasm (FuncNode);
    Result := FuncNode.CodeStr;
  end;

  if Result = '' then
  begin
    FragAsmSL := GetSierialDisasm (CodeAddr);
    Result := FragAsmSL.Text;
    FragAsmSL.Free;
  end;
end;

function GetSystemBootTime: String;
var
  T1: Int64;
  T2,T3: Comp;
  T4: TDateTime;
begin
  T1 := GetTickCount;                               {从开机到现在的毫秒数}
  T2 := TimeStampToMSecs(DateTimeToTimeStamp(Now)); {从 0001-1-1 到当前时间的毫秒数}
  T3 := T2 - T1;                                    {从 0001-1-1 到开机时刻的毫秒数}
  T4 := TimeStampToDateTime(MSecsToTimeStamp(T3));  {从 0001-1-1 到开机时刻的时间}
  Result := DateTimeToStr(T4);                   {显示开机时间}
end;

const
  SaveSection = 'LibSave';
  LibSaveVer = 'LibraryVersion';
  LibHandleLst = 'LibHandleLst';

Procedure ClearUpLibNodeList;
var
  LibSaveFile: String;
begin
  ClearNodeList (LibNodeList);
  AddedNodeList.Clear;
  EraseSection (SaveSection);
  LibSaveFile := MakeFileNameByExt ('.libsave');
  DeleteFile (LibSaveFile);     
end;

Procedure UpdateLibNodeList (ShareList: TList); Stdcall;  
var
  AimMainNodes, RetNodes: LPTFlatNodeLst;
  Item: Pointer;
  ModuleName, SavedTime, SavedList, LibSaveFile: String;
  BeginTick, StartTick: DWORD;
  Image: THandle;
  EntryNode: LPTFuncNode;
  NewList, TempList, OldList: TList;
  LibChanged: BOOL;
  ItemSL: TStringList;
  ItemStr: String;
  Val64: Int64;
  BeforeCount: Integer;
begin
  if ShareList = nil then
  begin
    AppTerminated := True;
    Exit;
  end;

  IsOnService := False;
  StartTick := GetTickCount;   

  //先生成目标程序的调用结构，暂时供使用。
  BeginTick := GetTickCount;
  RetNodes := Cmd_GetModuleNodes (0);
  if not Assigned (RetNodes) then
  begin
    DbgPrinter ('Cmd_GetModuleNodes ERROR!');
    Exit;
  end;                   

  GetMem (AimMainNodes, RetNodes.Size);
  CopyMemory (AimMainNodes, RetNodes, RetNodes.Size);

  //替换调用结构树
  TempList := CallStructList;
  NewList := TList.Create;
  LoadFromFlatData (NewList, AimMainNodes);
  CallStructList := NewList;
  ClearNodeList (TempList);
  TempList.Free;
  DbgPrinter ('Analysis [%d][init-%d]：%s', [GetTickCount-BeginTick, CallStructList.Count, GetAimModule]);


  //检查开机时间，使用缓存的公共库文件
  LibSaveFile := MakeFileNameByExt ('.libsave');
  if LibNodeList.Count = 0 then
  begin
    SavedTime := ReadConfig (SaveSection, LibSaveVer, '');
    if SavedTime = GetSystemBootTime then
      if FileExists (LibSaveFile) then
        if LoadFormFileData (LibNodeList, LibSaveFile) then
        begin
          SavedList := ReadConfig (SaveSection, LibHandleLst, '');
          ItemSL := GetSplitBlankList (SavedList, [',']);
          for ItemStr in ItemSL do
            if Length(ItemStr) = 9 then
              if TryStrToInt64 (ItemStr, Val64) then
                AddedNodeList.Add(Pointer(Val64));
          ItemSL.Free;

          DbgPrinter ('Load %s', [LibSaveFile]);
        end;
  end;

  //追加欠缺的公共库文件的调用结构
  LibChanged := False;
  for Item in ShareList do
  begin
    if AppTerminated then Exit;

    if AddedNodeList.IndexOf(Item) = -1 then
    begin
      LibChanged := True;
      AddedNodeList.Add(Item);
      Image := THandle(Item);
      ModuleName := GetModuleName (Image);
      BeginTick := GetTickCount;

      BeforeCount := LibNodeList.Count;
      EntryNode := AddImageNodeToList (LibNodeList, Image);
      if Assigned (EntryNode) then
        PEEntryList.AddObject (ExtractFileName(ModuleName), EntryNode.EntryPoint)
      else
        DbgPrinter ('%s EntryPoint ERROR.', [ExtractFileName(ModuleName)]);

      DbgPrinter ('Analysis [%d][%d-%d]：%s', [GetTickCount-BeginTick, LibNodeList.Count - BeforeCount, LibNodeList.Count, ModuleName]);
    end;
  end;

  //如果库文件发生变化
  if LibChanged then
  begin
    EraseSection (SaveSection);
    if ExtractToFile (LibNodeList, LibSaveFile) then
    begin
      SavedList := '';
      for Item in AddedNodeList do
        SavedList := SavedList + ',$' + IntToHex(DWORD(Item), 8);
      Delete (SavedList, 1, 1);

      WriteConfig (SaveSection, LibHandleLst, SavedList);
      WriteConfig (SaveSection, LibSaveVer, GetSystemBootTime, True);
      DbgPrinter ('Saved %s', [LibSaveFile]);
    end;
  end;

  //建立新版本
  TempList := DuplicateList (LibNodeList);
  LoadFromFlatData (TempList, AimMainNodes);
  FreeMem (AimMainNodes);

  //清理旧版本
  OldList := CallStructList;
  CallStructList := TempList;
  ClearNodeList (OldList);
  OldList.Free;

  DbgPrinter ('Analysis time: %d  totalCount: %d', [GetTickCount-StartTick, CallStructList.Count]);
  ShareList.Free;
  IsOnService := True;
end;

function InputHexAddr (var Address: Pointer): BOOL;
var
  Input: String;
  OutVal: Int64;
begin
  Result := False;
  Input := InputBox ('请输入一个要显示的函数地址', '十六进制地址：', '');
  if Input <> '' then
  begin
    if Input[1] <> '$' then
      Input := '$' + Input;
    if TryStrToInt64 (Input, OutVal) then
    begin
      Address := Pointer(OutVal);
      Result := True;
    end;
  end;
end;

function ExtractLibName (ModHandle: THandle): String;
begin
  Result := ExtractFileName(GetModuleName (ModHandle));
  SetLength (Result, Length(Result) - Length(ExtractFileExt(Result)));
end;


Procedure ViewCallFrom (Listbox: TListBox; CallFroms: TList);
var
  Item: Pointer;
  ScanNode: LPTFuncNode;
  ModuleName: String;
  ModHandle: THandle;
begin
  for Item in CallFroms do
  begin
    ScanNode := FindNearNodeByAddress (Item);
    if Assigned (ScanNode) then
    begin
      ModHandle := ScanNode.Module;
    end else
      ModHandle := THandle (GetImageBase(Item));

    ModuleName := ExtractLibName(ModHandle);
    Listbox.Items.Add(ModuleName + '.$'+IntToHex(DWORD(Item), 8));
  end;
end;

Procedure ViewCallTo (Listbox: TListBox; CallTos: TList);
var
  Item: Pointer;
  ScanNode: LPTFuncNode;
  ModuleName: String;
  ModHandle: THandle;
begin
  for Item in CallTos do
  begin
    ScanNode := FindNodeByEntry (CallStructList, Item);
    if Assigned (ScanNode) then
    begin
      ModHandle := ScanNode.Module;
    end else
      ModHandle := THandle (GetImageBase(Item));

    ModuleName := ExtractLibName(ModHandle);
    Listbox.Items.Add(ModuleName + '.$'+IntToHex(DWORD(Item), 8));
  end;
end;

procedure TCallStructureForm.ViewAAddress (Address: Pointer);
var
  DisAsmStr: String;
  FuncNode: LPTFuncNode;
  FragAsmSL: TStringList;
begin
  if Assigned (Address) then
  begin
    FuncNode := FindNearNodeByAddress (Address);

    self.ListBox1.Clear;  // call from
    self.ListBox2.Clear;  // call to

    if Assigned (FuncNode) then
    begin
      RemoteUpdateNodeDisasm (FuncNode);
      DisAsmStr := FuncNode.CodeStr;
      ViewCallFrom (self.ListBox1, FuncNode.CallFroms);
      ViewCallFrom (self.ListBox2, FuncNode.CallToTarget);
    end else
    begin
      FragAsmSL := GetSierialDisasm (Address);
      DisAsmStr := FragAsmSL.Text;
      FragAsmSL.Free;
    end;

    Self.ListBox3.Items.Text := DisAsmStr; 
  end;
end;

function GetAddrByLineItem (Line: String): Pointer;
var
  Val64: Int64;
  Index: Integer;
begin
  Result := nil;
  Index := Pos('$',Line);
  Line := Copy(Line, Index, Length(line) - Index + 1);
  SetLength (Line, 9);

  if TryStrToInt64 (Line, Val64) then
    Result := Pointer(Val64);
end;

function GetListClickAddress (Sender: TObject; var Address: Pointer): BOOL;
var
  Listbox: TListBox absolute Sender;
  Index: Integer;
  Line: String;
begin
  Result := false;
  Index := Listbox.ItemIndex;
  if Index = -1 then exit;

  Line := Listbox.Items[Index];
  Address := GetAddrByLineItem (Line);

  Result := Assigned (Address);
end;


procedure TCallStructureForm.ListBox1Click(Sender: TObject);
var
  Addr: Pointer;
  FNode: LPTFuncNode;
begin
  if GetListClickAddress (Sender, Addr) then
  begin
    FNode := FindNearNodeByAddress (Addr);
    if Assigned (FNode) then
    begin
      RemoteUpdateNodeDisasm (FNode);
      ListBox5.Items.Text := FNode.CodeStr; 
      ListBox5.ItemIndex := FoundCodeIndex (ListBox5.Items, Addr);
    end;
  end;
end;

procedure TCallStructureForm.ListBox2Click(Sender: TObject);
var
  Addr: Pointer; 
  FNode: LPTFuncNode;
begin
  if GetListClickAddress (Sender, Addr) then
  begin
    FNode := FindNodeByEntry (CallStructList, Addr);
    if Assigned (FNode) then
    begin
      RemoteUpdateNodeDisasm (FNode);
      ListBox4.Items.Text := FNode.CodeStr;
    end;
  end;
end;

procedure TCallStructureForm.ListBox1DblClick(Sender: TObject);
var
  Addr: Pointer;
begin
  if GetListClickAddress (Sender, Addr) then
    ViewAAddress(Addr);
end;

procedure TCallStructureForm.N2Click(Sender: TObject);
var
  Address: Pointer;
begin
  if InputHexAddr (Address) then
    ViewAAddress (Address);
end;

initialization
  CallStructList := TList.Create;
  AddedNodeList := TList.Create;
  LibNodeList := TList.Create;
  PEEntryList := TStringList.Create;
  FragmentAsmSL := TList.Create;


end.

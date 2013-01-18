unit DbgInfoForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

Const     
  WM_DBG_MSG = WM_USER + 100;

type
  TDbgPrint = class(TForm)
    Memo1: TMemo;
    procedure FormShow(Sender: TObject);
  private
    procedure RecvDbgMessage(var msg:TMessage);message WM_DBG_MSG;
  public
  end;

var
  DbgPrint: TDbgPrint;
  
//使用消息队列来缓冲调试信息的输出，防止了类方法的访问违规
Procedure DbgPrinter (Head, Msg: String); overload;
Procedure DbgPrinter (Msg: String); overload;
Procedure DbgPrinter (const FmtStr: string; const Args: array of const); overload;


implementation

uses PlugKernelLib;

{$R *.dfm}

const
  DbgHead = 'Debuger';                        

procedure TDbgPrint.FormShow(Sender: TObject);
begin
  DbgPrinter ('PlugKernel.dll版本号：' + Version);
end;

procedure TDbgPrint.RecvDbgMessage(var msg:TMessage);
var
  PostBuff: PChar;
begin
  PostBuff := Pointer (msg.WParam);
  self.Memo1.Lines.Add(StrPas(PostBuff));
  FreeMem(PostBuff);
end;

var
  DbgFormHandle: THandle = 0;
  CacheList: TList = nil;

Procedure DbgPrinter (Head, Msg: String);
var
  PostBuff: PChar;
  Item: Pointer;
begin
  if Application.Terminated then exit;

  Head := '[' + Head + ']';
  Msg := format ('%-10s %-10s %s', [TimeToStr(now), Head, Msg]);

  //句柄开始时，总是有效的
  if DbgFormHandle = 0 then
    if Assigned (DbgPrint) then
      DbgFormHandle := DbgPrint.Handle;

  GetMem (PostBuff, Length(Msg) + 1);
  CopyMemory (PostBuff, PChar(Msg), Length(Msg));
  PostBuff [Length(Msg)] := #0;

  if DbgFormHandle = 0 then
  begin
    if CacheList = nil then
      CacheList := TList.Create;
    CacheList.Add(Pointer(PostBuff));
    Exit; 
  end else
  begin
    if Assigned (CacheList) then
    begin
      for Item in CacheList do
        PostMessage (DbgFormHandle, WM_DBG_MSG, Integer(Item), 0);
      FreeAndNil (CacheList);
    end;
  end;

  PostMessage (DbgFormHandle, WM_DBG_MSG, Integer(PostBuff), 0);
end;

Procedure DbgPrinter (Msg: String); overload;
begin
  DbgPrinter (DbgHead, Msg);
end;

Procedure DbgPrinter (const FmtStr: string; const Args: array of const);
begin
  DbgPrinter (Format (FmtStr, Args));
end;

end.

(******************************************************************************)
(* SPGetSid - Retrieve the current user's SID in text format                  *)
(*                                                                            *)
(* Copyright (c) 2004 Shorter Path Software                                   *)
(* http://www.shorterpath.com                                                 *)
(******************************************************************************)


{
  SID is a data structure of variable length that identifies user, group,
  and computer accounts.
  Every account on a network is issued a unique SID when the account is first created.
  Internal processes in Windows refer to an account's SID
  rather than the account's user or group name.
}


unit SPGetSid;

interface

uses
  Windows, SysUtils;

function GetCurrentUserSid: string;

function IsUserAdminPrivilege(const strUserName: String; var bAdminPrivilege: BOOL): BOOL;
function IsAdmin: Boolean;

implementation

uses LM;

const
  HEAP_ZERO_MEMORY = $00000008;
  SID_REVISION     = 1; // Current revision level

type
  PTokenUser = ^TTokenUser;
  TTokenUser = packed record
    User: TSidAndAttributes;
  end;

function ConvertSid(Sid: PSID; pszSidText: PChar; var dwBufferLen: DWORD): BOOL;
var
  psia: PSIDIdentifierAuthority;
  dwSubAuthorities: DWORD;
  dwSidRev: DWORD;
  dwCounter: DWORD;
  dwSidSize: DWORD;
begin
  Result := False;

  dwSidRev := SID_REVISION;

  if not IsValidSid(Sid) then Exit;

  psia := GetSidIdentifierAuthority(Sid);

  dwSubAuthorities := GetSidSubAuthorityCount(Sid)^;

  dwSidSize := (15 + 12 + (12 * dwSubAuthorities) + 1) * SizeOf(Char);

  if (dwBufferLen < dwSidSize) then
  begin
    dwBufferLen := dwSidSize;
    SetLastError(ERROR_INSUFFICIENT_BUFFER);
    Exit;
  end;

  StrFmt(pszSidText, 'S-%u-', [dwSidRev]);

  if (psia.Value[0] <> 0) or (psia.Value[1] <> 0) then
    StrFmt(pszSidText + StrLen(pszSidText),
      '0x%.2x%.2x%.2x%.2x%.2x%.2x',
      [psia.Value[0], psia.Value[1], psia.Value[2],
      psia.Value[3], psia.Value[4], psia.Value[5]])
  else
    StrFmt(pszSidText + StrLen(pszSidText),
      '%u',
      [DWORD(psia.Value[5]) +
      DWORD(psia.Value[4] shl 8) +
      DWORD(psia.Value[3] shl 16) +
      DWORD(psia.Value[2] shl 24)]);

  dwSidSize := StrLen(pszSidText);

  for dwCounter := 0 to dwSubAuthorities - 1 do
  begin
    StrFmt(pszSidText + dwSidSize, '-%u',
      [GetSidSubAuthority(Sid, dwCounter)^]);
    dwSidSize := StrLen(pszSidText);
  end;

  Result := True;
end;

function ObtainTextSid(hToken: THandle; pszSid: PChar;
  var dwBufferLen: DWORD): BOOL;
var
  dwReturnLength: DWORD;
  dwTokenUserLength: DWORD;
  tic: TTokenInformationClass;
  ptu: Pointer;
begin
  Result := False;
  dwReturnLength := 0;
  dwTokenUserLength := 0;
  tic := TokenUser;
  ptu := nil;

  if not GetTokenInformation(hToken, tic, ptu, dwTokenUserLength, dwReturnLength) then
  begin
    if GetLastError = ERROR_INSUFFICIENT_BUFFER then
    begin
      ptu := HeapAlloc(GetProcessHeap, HEAP_ZERO_MEMORY, dwReturnLength);
      if ptu = nil then Exit;
      dwTokenUserLength := dwReturnLength;
      dwReturnLength    := 0;

      if not GetTokenInformation(hToken, tic, ptu, dwTokenUserLength,  dwReturnLength) then
        Exit;
    end 
    else 
      Exit;
  end;

  if not ConvertSid((PTokenUser(ptu).User).Sid, pszSid, dwBufferLen) then Exit;

  if not HeapFree(GetProcessHeap, 0, ptu) then Exit;

  Result := True;
end;

function GetCurrentUserSid: string;
var
  hAccessToken: THandle;
  bSuccess: BOOL;
  dwBufferLen: DWORD;
  szSid: array[0..260] of Char;
begin
  Result := '';

  bSuccess := OpenThreadToken(GetCurrentThread, TOKEN_QUERY, True,
    hAccessToken);
  if not bSuccess then
  begin
    if GetLastError = ERROR_NO_TOKEN then
      bSuccess := OpenProcessToken(GetCurrentProcess, TOKEN_QUERY,
        hAccessToken);
  end;
  if bSuccess then
  begin
    ZeroMemory(@szSid, SizeOf(szSid));
    dwBufferLen := SizeOf(szSid);

    if ObtainTextSid(hAccessToken, szSid, dwBufferLen) then
      Result := szSid;
    CloseHandle(hAccessToken);
  end;
end;



const 
  SECURITY_NT_AUTHORITY: TSIDIdentifierAuthority = 
    (Value: (0, 0, 0, 0, 0, 5));
  SECURITY_BUILTIN_DOMAIN_RID = $00000020; 
  DOMAIN_ALIAS_RID_ADMINS = $00000220; 



function IsAdmin: Boolean;
var
  hAccessToken: THandle; 
  ptgGroups: PTokenGroups; 
  dwInfoBufferSize: DWORD; 
  psidAdministrators: PSID; 
  x: Integer; 
  bSuccess: BOOL; 
begin 
  Result   := False; 
  bSuccess := OpenThreadToken(GetCurrentThread, TOKEN_QUERY, True, 
    hAccessToken); 
  if not bSuccess then 
  begin 
    if GetLastError = ERROR_NO_TOKEN then 
      bSuccess := OpenProcessToken(GetCurrentProcess, TOKEN_QUERY, 
        hAccessToken); 
  end; 
  if bSuccess then 
  begin 
    GetMem(ptgGroups, 1024); 
    bSuccess := GetTokenInformation(hAccessToken, TokenGroups, 
      ptgGroups, 1024, dwInfoBufferSize); 
    CloseHandle(hAccessToken); 
    if bSuccess then 
    begin 
      AllocateAndInitializeSid(SECURITY_NT_AUTHORITY, 2, 
        SECURITY_BUILTIN_DOMAIN_RID, DOMAIN_ALIAS_RID_ADMINS, 
        0, 0, 0, 0, 0, 0, psidAdministrators); 
      {$R-} 
      for x := 0 to ptgGroups.GroupCount - 1 do 
        if EqualSid(psidAdministrators, ptgGroups.Groups[x].Sid) then 
        begin 
          Result := True; 
          Break; 
        end; 
      {$R+} 
      FreeSid(psidAdministrators); 
    end; 
    FreeMem(ptgGroups); 
  end; 
end;


function IsUserAdminPrivilege(const strUserName: String; var bAdminPrivilege: BOOL): BOOL;
var
  Sid: PSID;
  cbSid, cbDomain, dwErr: DWORD;
  bufDomain: LPTSTR;
  peUse: SID_NAME_USE;        
  pAutho: PSIDIdentifierAuthority;
  AdminAuth: TSIDIdentifierAuthority;
  info: USER_INFO_1;
  TheUser:Array[0..255] Of WideChar;
  MyPtr: Pointer;
begin
  bAdminPrivilege := FALSE;   

  cbSid :=   0;
  cbDomain   :=   0;

  LookupAccountName(NIL,PChar(strUserName),NIL, cbSid, NIL, cbDomain,peUse);
  if cbSid > 0 then
  begin
    Sid := AllocMem (cbSid);
    bufDomain := AllocMem (cbDomain);

    if LookupAccountName(NIL,PChar(strUserName),Sid, cbSid, bufDomain, cbDomain, peUse) then
    begin
      pAutho := GetSidIdentifierAuthority (Sid);
      dwErr := GetLastError();
      if dwErr > 0 then
      begin
        AdminAuth := SECURITY_NT_AUTHORITY;

        bAdminPrivilege := not CompareMem (pAutho, @AdminAuth, sizeof(SID_IDENTIFIER_AUTHORITY));
      end;
    end;
    FreeMem (Sid);
    FreeMem (bufDomain);
  end;

  if bAdminPrivilege then
  begin
    Result := True;
    Exit;
  end;

  StringToWideChar(strUserName, @TheUser, 255);

  MyPtr:=nil;     
  Result := NetUserGetInfo(NIL, @TheUser, 1, MyPtr) = NERR_Success;
  
  If MyPtr <> nil Then
  begin
    info := USER_INFO_1(MyPtr^);                      
    bAdminPrivilege   :=   info.usri1_priv   =  USER_PRIV_ADMIN;
    NetApiBufferFree (MyPtr);
  end;
     
end;


end.
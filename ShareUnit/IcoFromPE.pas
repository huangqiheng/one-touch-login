unit IcoFromPE;

interface

uses windows, ImgList;

function LoadIconToImageList (PeFile: String; ImageList: TCustomImageList; GragValue: Integer = 0): Integer;


implementation

uses ShellApi, Graphics, SpecialFolderUnit;

procedure GrayBitmap(ABitmap: TBitmap; Value: integer);
var
  Pixel: PRGBTriple;
  w, h: Integer;
  x, y: Integer;
  avg: integer;
begin
  ABitmap.PixelFormat := pf24Bit;
  w := ABitmap.Width;
  h := ABitmap.Height;
  for y := 0 to h - 1 do
  begin
    Pixel := ABitmap.ScanLine[y];
    for x := 0 to w - 1 do
    begin
      avg := ((Pixel^.rgbtRed + Pixel^.rgbtGreen + Pixel^.rgbtBlue) div 3)
        + Value;
      if avg > 240 then avg := 240;
      Pixel^.rgbtRed := avg;
      Pixel^.rgbtGreen := avg;
      Pixel^.rgbtBlue := avg;
      Inc(Pixel);
    end;
  end;
end;


function LoadIconToImageList (PeFile: String; ImageList: TCustomImageList; GragValue: Integer = 0): Integer;
var
  ExtraIco: THandle;
  ico: TIcon;
  Bitmap : TBitmap;
  DefDir: String;
begin
  ExtraIco :=  ExtractIcon (HInstance, PChar(PeFile), 0);
  if ExtraIco = 0 then
  begin
    DefDir := GetSpecialFolder (sfWindows) + '\system32\cmd.exe';
    ExtraIco := ExtractIcon (HInstance, PChar(DefDir), 0);
  end;

  ico := TIcon.Create;
  ico.Handle := ExtraIco;
  Result := ImageList.AddIcon(ico);
  ico.Free;   

  if Result = -1 then
  begin
    Result := 0;
    Exit;
  end;

  if GragValue > 0 then
  begin
    Bitmap := TBitmap.Create;
    if ImageList.GetBitmap(Result, Bitmap) then
    begin
      ImageList.Delete(Result);
      GrayBitmap (Bitmap, GragValue);
      Result := ImageList.Add(Bitmap, nil);
    end;
    Bitmap.Free;
  end;          
end;


end.
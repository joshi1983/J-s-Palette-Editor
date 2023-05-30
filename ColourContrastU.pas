unit ColourContrastU;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls;

type
  TColourContrastFrm = class(TForm)
    ScrollBar1: TScrollBar;
    Label1: TLabel;
    Label2: TLabel;
    OKBtn: TButton;
    CancelBtn: TButton;
    procedure ScrollBar1Change(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure CancelBtnClick(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
  private
    TempPalette: array[0..255] of tColor;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  ColourContrastFrm: TColourContrastFrm;

implementation

uses PaletteU,math;

{$R *.DFM}
function GetColourContrast(c: tColor;v: byte): tColor;
var
  r,green,b: integer;
  gray: integer;
begin
     r:=GetRValue(c);
     green:=GetGValue(c);
     b:=GetBValue(c);
     Gray:=(r+green+b) div 3;
     r:=gray-(((gray-r)*v) div 128);
     green:=gray-(((gray-green)*v) div 128);
     b:=gray-(((gray-b)*v) div 128);

     result:=rgb(min(max(r,0),255),min(max(green,0),255),min(max(b,0),255));
end;

procedure TColourContrastFrm.ScrollBar1Change(Sender: TObject);
var
  x: integer;
begin
     for x:=high(PaletteData) downto 0 do
     begin
          PaletteData[x]:=GetColourContrast(TempPalette[x],ScrollBar1.Position);
     end;
     PaletteViewer.UpdateDisplay;
end;

procedure TColourContrastFrm.FormShow(Sender: TObject);
var
  x: integer;
begin
     for x:=high(PaletteDatA) downto 0 do
         TempPalette[x]:=PaletteData[x];
     ScrollBar1.Position:=128;
end;

procedure TColourContrastFrm.CancelBtnClick(Sender: TObject);
var
  x: integer;
begin
     for x:=high(PaletteData) downto 0 do
         PaletteData[x]:=TempPalette[x];
     PaletteViewer.UpdateDisplay;
     Close;
end;

procedure TColourContrastFrm.OKBtnClick(Sender: TObject);
begin
     Close;
end;

end.

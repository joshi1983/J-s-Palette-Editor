unit PaletteU;
// created by Josh Greig
// when using any code from this project, give proper credit to me.

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,stdctrls,extctrls,
  Menus, ComCtrls;

type
  PalEntry = record
     Panel: tPanel;  // the panel that holds the shape
  end;
  Palette16Object = record
    Entries: array[0..15] of PalEntry; // displays for each palette entry
    Panel: tPanel; // a panel to hold all the palette entries
    Title: tLabel; // the label for the palette
  end;
  TPaletteViewer = class(TForm)
    ColorDialog1: TColorDialog;
    SavePalBTN: TButton;
    OKBTN: TButton;
    SaveDialog1: TSaveDialog;
    OpenDialog1: TOpenDialog;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    LoadPalette1: TMenuItem;
    SavePalette1: TMenuItem;
    LoadBTN: TButton;
    BrightnessAdjuster1: TMenuItem;
    BlackTransparentColours1: TMenuItem;
    InvertColours1: TMenuItem;
    Edit1: TMenuItem;
    StatusBar1: TStatusBar;
    Createhtmldocumentation1: TMenuItem;
    N1: TMenuItem;
    Close1: TMenuItem;
    SaveHTMLDialog1: TSaveDialog;
    PresetPalettes1: TMenuItem;
    Gray1: TMenuItem;
    CreateSourceCode1: TMenuItem;
    CreateSourceDialog: TSaveDialog;
    GrayScale161: TMenuItem;
    N2: TMenuItem;
    CreateGBAsourcefile1: TMenuItem;
    Help1: TMenuItem;
    N3: TMenuItem;
    AboutJsPaletteEditor1: TMenuItem;
    UsingJsPaletteEditor1: TMenuItem;
    GrayScale1: TMenuItem;
    N4: TMenuItem;
    ColourContrastAdjuster1: TMenuItem;
    SwapRedandBlue1: TMenuItem;
    AllBlack1: TMenuItem;
    ImportFromBitmap1: TMenuItem;
    procedure Initialize;
    procedure UpdateDisplay;
    procedure DefaultPanels;
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure PaletteEntryClick(Sender: tObject);
    procedure PaletteEntryMouseMove(Sender: TObject; Shift: TShiftState;
    X, Y: Integer);
    procedure LoadPalBTNClick(Sender: TObject);
    procedure SavePalBTNClick(Sender: TObject);
    procedure OKBTNClick(Sender: TObject);
    procedure BrightnessAdjuster1Click(Sender: TObject);
    procedure BlackTransparentColours1Click(Sender: TObject);
    procedure InvertColours1Click(Sender: TObject);
    procedure SavePalBTNMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure Createhtmldocumentation1Click(Sender: TObject);
    procedure Close1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Gray1Click(Sender: TObject);
    procedure CreateSourceCode1Click(Sender: TObject);
    procedure GrayScale161Click(Sender: TObject);
    procedure CreateGBAsourcefile1Click(Sender: TObject);
    procedure UsingJsPaletteEditor1Click(Sender: TObject);
    procedure AboutJsPaletteEditor1Click(Sender: TObject);
    procedure GrayScale1Click(Sender: TObject);
    procedure ColourContrastAdjuster1Click(Sender: TObject);
    procedure SwapRedandBlue1Click(Sender: TObject);
    procedure AllBlack1Click(Sender: TObject);
    procedure ImportFromBitmap1Click(Sender: TObject);
  private
         PaletteObject: array[0..15] of Palette16Object;
         // this is an array of objects used to display the colour palette
         MouseOverEntry: tpoint;
         MouseOverRow: byte;
         PanelUnderChanged: boolean;
         { Private declarations }
  public
        Edited: boolean;
        { Public declarations }
  end;

var
  PaletteViewer: TPaletteViewer;
   PaletteData: array[0..255] of tcolor;
   // this is the palette that is edited.

const
     bvActive = bvRaised;
     bvDefault = bvNone;

implementation
uses Math, PaletteContrastU, ShellApi, ColourContrastU;
{$R *.DFM}

function Colour16to32(colour16: word): tcolor;
begin
     result:=((colour16 and $1F) shl 3) or ((colour16 shr 5 and $1F) shl 11) or ((colour16 shr 10 and $1f) shl 19);
end;

function RedBlueSwap(c: tcolor): tcolor;
begin
     result:=rgb(GetBValue(c),GetGValue(c),GetRValue(c));
end;

function GBAColour16to32B(GBAcolour16: word): tcolor;
begin
     result:=((GBAcolour16 shr 10 and $1F) shl 3) or ((GBAcolour16 shr 5 and $1F) shl 11) or ((GBAcolour16 and $1f) shl 19);
end;

function pf32To16(c: integer): word;
var
 r,g,b: byte;
begin
     c:=c shr 8;
     r:=c and $FF;
     g:=c and $FF00 shr 8;
     b:=c and $FF0000 shr 16;
     result:=(r shr 3) or ((g shr 3) shl 5) or ((b shr 3) shl 10);
end;

function Colour32To16(c: integer): word;
var
 r,g,b: byte;
begin
     r:=c and $FF;
     g:=c and $FF00 shr 8;
     b:=c and $FF0000 shr 16;
     result:=(b shr 3) or ((g shr 3) shl 5) or ((r shr 3) shl 10);
end;

function Colour32BTo16(c: integer): word;
var // convert a tcolor to 16 bit gba style colour
 r,g,b: byte;
begin
     r:=c and $FF;
     g:=c and $FF00 shr 8;
     b:=c and $FF0000 shr 16;
     result:=(r shr 3) or ((g shr 3) shl 5) or ((b shr 3) shl 10);
end;

function GetProgDir: string;
var
  x: integer;
begin
     result:=Application.Exename;
     x:=length(result);
     while (x>1)and(result[x]<>'\') do
           dec(x);
     result:=copy(result,1,x-1);
end;

procedure LoadTilePalette(fn: string);
var
  f: file;
  c: integer;
  NumEntry: word;
  buf: array[0..255] of tcolor;
begin
     if not FileExists(fn) then
        exit;
     AssignFile(f,fn);
     Reset(f,1);
     BlockRead(f,buf,$16); // load in the header portion of the file
     if buf[0]<>$46464952 then     // 'RIFF'
     begin // Check to make sure the file is in Microsoft Palette format.
          ShowMessage('This file can''t be loaded because it is not in a supported format.');
          CloseFile(f);
          exit;
     end;
     BlockRead(f,NumEntry,2); // load in the header portion of the file
     NumEntry:=min(256,NumEntry);
     BlockRead(f,buf,NumEntry shl 2); // load the palette portion
     for c:=NumEntry-1 downto 0 do
         PaletteData[c]:=buf[c];
     CloseFile(f);
end;

procedure LoadJascPalette(fn: string);
var
  tf: Textfile;
  pc,StartEntry: integer;
  c: integer;
  r,g,b: byte;
  s: string;
begin
     if not FileExists(fn) then
        exit;
     AssignFile(tf,fn);
     Reset(tf);
     ReadLn(tf,s);
     if s<>'JASC-PAL' then // not a valid Jasc Palette file
     begin
          CloseFile(tf);
          LoadTilePalette(fn);
          Exit;
     end;
     ReadLn(tf,s); // s='0100'
     if s<>'0100' then
        ShowMessage('There is an unexpected value in the file.  '+
        'Please contact the developer about this message while loading a Jasc palette.');
     ReadLn(tf,s); // s=ie. '16'
     pc:=strtoint(s)-1;
     if pc<255 then
     begin
          s:=InputBox('Select Palette 16','Type a number(0..15) of the palette row to load into', '0');
          StartEntry:=StrToInt(s) shl 4;
     end
     else
         StartEntry:=0;
     if pc+StartEntry>255 then
        pc:=255-StartEntry;
     for c:=0 to pc do
     begin
          ReadLn(tf,s);
          r:=pos(' ',s);
          b:=strtoint(copy(s,1,r-1));
          s:=copy(s,r+1,999);
          r:=pos(' ',s);
          g:=strtoint(copy(s,1,r-1));
          s:=copy(s,r+1,999);
          r:=strtoint(s);
          PaletteData[c+StartEntry]:=rgb(b,g,r);
          if eof(tf) then
             exit;
     end;
     CloseFile(tf);
end;

procedure LoadTilePaletteFromACT(fn: string);
var
  f: file;
  c,c2: integer;
  buf: array[0..$2FF] of byte;
begin
     if not FileExists(fn) then
        exit;
     AssignFile(f,fn);
     Reset(f,1);
     BlockRead(f,buf[0],$300); // load the palette portion
     for c:=0 to 255 do
     begin
          c2:=c*3;
          PaletteData[c]:=rgb(buf[c2],buf[c2+1],buf[c2+2]);
     end;
     CloseFile(f);
     PaletteViewer.UpdateDisplay;
end;

procedure LoadTilePaletteFromGBAPal(fn: string);
var
  f: file;
  buf: array[0..255] of word;
  x: integer;
begin
     AssignFile(f,fn);
     Reset(f,1);
     BlockRead(f,buf[0],$200);
     for x:=255 downto 0 do
         PaletteData[x]:=Colour16to32(buf[x]);
     CloseFile(f);
end;

procedure LoadPaletteFromBitmap(fn: string);
var
   f: file;
   nr,n: integer;
   buf: array[0..$435] of byte; // stores the header and palette data
begin
     if FileExists(fn) then
     begin
          AssignFile(f,fn);
          Reset(f,1);
          BlockRead(f,buf,$36+$400,nr);
          if (buf[$1C]<=8) then // monochrome, 4-bit, 8-bit palettes
          begin
               n:=1 shl buf[$1C];
               PaletteViewer.AllBlack1Click(PaletteViewer);
               move(buf[$36],PaletteData[0],4*n);
               PaletteViewer.SwapRedandBlue1Click(PaletteViewer);
          end
          else
              ShowMessage('This bitmap does not use a colour palette.');
          CloseFile(f);
     end
     else
         ShowMessage('File not found: '+fn);
end;

procedure LoadPaletteFromIcon(fn: string);
var
   f: file;
   nr,n: integer;
   ColourCount: byte;
   IconCount: word;
   buf: array[0..$27] of byte; // stores the header and palette data
begin
     if FileExists(fn) then
     begin
          AssignFile(f,fn);
          Reset(f,1);
          BlockRead(f,n,4); // read in the header section
          if n<>$10000 then // format check
          begin
               ShowMessage('Invalid Windows icon file');
               CloseFile(f);
               Exit;
          end;
          BlockRead(f,IconCount,2); // read in the header section
          BlockRead(f,buf,16,nr);
          ColourCount:=buf[2];
          for n:=2 to IconCount do // read in the icon entries
          begin
               BlockRead(f,buf,16,nr);
               if nr<16 then
               begin
                    ShowMessage('Error: could not load palette');
                    CloseFile(f);
                    Exit;
               end;
          end;
          PaletteViewer.AllBlack1Click(PaletteViewer);
          BlockRead(f,buf,$28);
          // read in the bitmap header, the contents don't matter for loading palettes
          if ColourCount=0 then // 256 colours
             BlockRead(f,PaletteData[0],$400)
          else
              BlockRead(f,PaletteData[0],4*ColourCount);
          PaletteViewer.SwapRedandBlue1Click(PaletteViewer);
          CloseFile(f);
     end
     else
         ShowMessage('File not found: '+fn);
end;

function LastPos(ch: char;str1: string): integer;
var
  c: integer;
begin
     result:=0;
     for c:=length(str1) downto 1 do
         if str1[c]=ch then
         begin
              result:=c;
              break;
         end;
end;

function ExtentionPos(fn: string): integer;
var
 c: integer;
begin
     c:=LastPos('.',fn);
     if c<1 then
        result:=0
     else
     begin
          if pos('\',copy(fn,c,999))>0 then
             result:=0
          else
              result:=c;
     end;
end;

function GetFNWithExtentionAs(fn,extStr: string): string;
var
  c: integer;
begin
     c:=Extentionpos(fn);
     if c>0 then
     begin
          fn:=copy(fn,1,c);
          result:=fn+extStr;
     end
     else
        result:=fn+'.'+extStr;
end;

function MyGetExtention(fn: string): string;
var
  c: integer;
begin
     c:=Extentionpos(fn);
     if c>0 then
          result:=LowerCase(copy(fn,c+1,999))
     else
         result:='';
end;

procedure SaveTilePalette(fn: string);
var
  f: file;
  c: word;
  buf: array[0..255] of tcolor;
const
   FHeader: array[0..$17] of byte = ($52,$49,$46,$46,$10,$04,$00,$00,$50,$41,$4C,
   $20,$64,$61,$74,$61,$04,$04,$00,$00,$00,$03,$00,$01);
begin
     fn:=GetFNWithExtentionAs(fn,'pal');
     AssignFile(f,fn);
     Rewrite(f,1);
     BlockWrite(f,FHeader,SizeOf(FHeader));
     for c:=high(PaletteData) downto 0 do
         buf[c]:=PaletteData[c];
     BlockWrite(f,buf[0],SizeOf(buf));
     CloseFile(f);
end;

procedure SaveTilePaletteAsJascPal(fn: string);
var
  tf: Textfile;
  colour32: tcolor;
  s: string;
  c: word;
begin
     fn:=GetFNWithExtentionAs(fn,'pal');
     AssignFile(tf,fn);
     Rewrite(tf);
     WriteLn(tf,'JASC-PAL');
     WriteLn(tf,'0100');
     WriteLn(tf,inttostr(high(PaletteData)+1));

     for c:=0 to High(PaletteData) do
     begin
          colour32:=PaletteData[c];
          s:=inttostr(GetBValue(colour32))+' '+inttostr(GetGValue(colour32))+
          ' '+inttostr(GetRValue(colour32));
          WriteLn(tf,s);
     end;
     CloseFile(tf);
end;

procedure SaveTilePaletteAsACT(fn: string);
var
  f: file;
  c,c2: word;
  c32: tcolor;
  buf: array[0..$2FF] of byte;
begin
     fn:=GetFNWithExtentionAs(fn,'act');
     AssignFile(f,fn);
     Rewrite(f,1);
        for c:=0 to High(PaletteData) do
        begin
             c32:=PaletteData[c];
             c2:=c*3;
             buf[c2]:=c32 and $FF;           // red
             buf[c2+1]:=c32 and $FF00 shr 8;   // green
             buf[c2+2]:=c32 and $FF0000 shr 16; // blue
        end;
     BlockWrite(f,buf[0],SizeOf(buf));
     CloseFile(f);
end;

procedure SaveTilePaletteAsGBAPal(fn: string);
var
  f: file;
  x: integer;
  buf: array[0..255] of word;
begin
     fn:=GetFNWithExtentionAs(fn,'GBAPal');
     AssignFile(f,fn);
     Rewrite(f,1);
     for x:=high(PaletteData) downto 0 do
         buf[x]:=Colour32Bto16(PaletteData[x]);
     BlockWrite(f,buf[0],$200);
     CloseFile(f);
end;

function GetPanelMatch(Sender: tobject): tpoint;
var
  pal16,pale: byte;
  found: boolean;
begin
     found:=false;
     for pal16:=15 downto 0 do
     begin
         for pale:=15 downto 0 do
             if Sender=PaletteViewer.PaletteObject[pal16].entries[pale].panel then
             begin
                  found:=true;
                  result:=point(pale,pal16);
                  break; // now, pal16 and pale will keep their values
             end;
         if found then
            break;
     end;
     if not found then
        result:=point(-1,-1);
end;

procedure TPaletteViewer.PaletteEntryClick(Sender: tObject);
var
  found: boolean;
  p1: tpoint;
begin
     p1:=GetPanelMatch(Sender);
     found:=p1.x>=0;
     if not found then exit;
     PaletteObject[MouseOverEntry.y].entries[MouseOverEntry.x].Panel.BevelOuter:=bvRaised;
     MouseOverEntry:=p1;
     PaletteObject[p1.y].entries[p1.x].panel.BevelOuter:=bvLowered;
     if found then
     begin
          ColorDialog1.Color:=(PaletteData[p1.x+p1.y shl 4]);
          if ColorDialog1.Execute then
          begin
               PaletteObject[p1.y].entries[p1.x].panel.Color:=ColorDialog1.Color;
               PaletteData[p1.x+p1.y shl 4]:=(ColorDialog1.Color);
               edited:=true;
          end;
     end;
end;

procedure TPaletteViewer.PaletteEntryMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
var
  found: boolean;
  p1: tpoint;
begin
     p1:=GetPanelMatch(Sender);
     found:=p1.x>=0;
     if not found then exit;
     PaletteObject[MouseOverEntry.y].entries[MouseOverEntry.x].Panel.BevelOuter:=bvDefault;
     PaletteObject[MouseOverRow].panel.BevelOuter:=bvDefault;
     MouseOverEntry:=p1;
     MouseOverRow:=p1.y;
     PaletteObject[p1.y].entries[p1.x].panel.BevelOuter:=bvActive;
     PaletteObject[MouseOverRow].panel.BevelOuter:=bvActive;
     StatusBar1.Panels[0].Text:='Column: '+inttostr(p1.x);
     StatusBar1.Panels[1].Text:='Row: '+inttostr(p1.y);
     PanelUnderChanged:=true;
end;

procedure TPaletteViewer.Initialize;
var
  pal16,pale: byte;
const
   TitleWidth = 25;
   DisplayTop = 2;
begin
     SaveDialog1.filename:=GetProgDir+'\.';
     OpenDialog1.filename:=GetProgDir+'\.';
     SaveHTMLDialog1.filename:=GetProgDir+'\.';
     CreateSourceDialog.filename:=GetProgDir+'\.';
     MouseOverEntry:=point(0,0); // a point that doesn't exist
     MouseOverRow:=0; // a point that doesn't exist
     PanelUnderChanged:=false;
     for pal16:=15 downto 0 do
     with PaletteObject[pal16] do
     begin
          panel:=tPanel.Create(PaletteViewer);
          with Panel do
          begin
               Left:=5;
               Top:=DisplayTop+ pal16 * 18;
               Width:=TitleWidth+275;
               Height:=16;
               parent:=PaletteViewer;
               BevelOuter:=bvDefault;
               visible:=true;
          end;
          Title:=tlabel.Create(Panel);
          with Title do
          begin
               Parent:=Panel;
               Caption:=inttostr(pal16);
               left:=2;
               top:=1;
               visible:=true;
          end;
          for pale:=15 downto 0 do
          with Entries[pale] do
          begin
               Panel:=tPanel.Create(PaletteObject[pal16].Panel);
               with Panel do
               begin
                    Left:=TitleWidth+pale shl 4;
                    Top:=2;
                    Width:=14;
                    height:=12;
                    Color:=clBlack;
                    OnClick:=PaletteEntryClick;
                    OnMouseMove:=PaletteEntryMouseMove;
                    BevelOuter:=bvDefault;
                    parent:=PaletteObject[pal16].Panel;
                    visible:=true;
               end;
          end;
     end;
     Gray1Click(PaletteViewer);
end;

procedure TPaletteViewer.FormDestroy(Sender: TObject);
var
  pal16,pale: byte;
begin
     for pal16:=15 downto 0 do
     with PaletteObject[pal16] do
     begin
          Title.Destroy;
          Title:=nil;
          for pale:=15 downto 0 do
          with Entries[pale] do
          begin
               Panel.Destroy;
               Panel:=nil;
          end;
          Panel.Destroy;
          Panel:=nil;
     end;
end;

procedure TPaletteViewer.UpdateDisplay;
var
  pal16,pale: byte;
begin
     for pal16:=15 downto 0 do
     with PaletteObject[pal16] do
     begin
          for pale:=15 downto 0 do
          with Entries[pale] do
               Panel.Color:=(PaletteData[pale+pal16 shl 4]);
     end;
end;

procedure TPaletteViewer.DefaultPanels;
var
  pal16,pale: byte;
begin
     if PanelUnderChanged then
     begin
        for pal16:=15 downto 0 do
        with PaletteObject[pal16] do
        begin
             PaletteObject[pal16].Panel.BevelOuter:=bvDefault;
             for pale:=15 downto 0 do
             with Entries[pale] do
                  Panel.BevelOuter:=bvDefault;
        end;
        PanelUnderChanged:=false;
     end;
end;

procedure TPaletteViewer.FormShow(Sender: TObject);
begin
     Edited:=false;
     UpdateDisplay;
end;

procedure TPaletteViewer.LoadPalBTNClick(Sender: TObject);
var
  fn: string;
begin
     if OpenDialog1.Execute then
     begin
          fn:=Opendialog1.Filename;
          if not FileExists(fn) then
          begin
               ShowMessage('File not found: '+fn);
               exit;
          end;
          case Opendialog1.FilterIndex of
            1: if MyGetExtention(fn)='act' then
                   LoadTilePaletteFromACT(fn)
               else if MyGetExtention(fn)='gbapal' then
                   LoadTilePaletteFromGBAPal(fn)
               else
                   LoadJascPalette(fn);
            2: if MyGetExtention(fn)='bmp' then
                  LoadPaletteFromBitmap(fn)
               else
                   LoadPaletteFromIcon(fn);
            3: LoadJascPalette(fn);
              // this will try loading in a few formats to find the correct one used by the file.
            4: LoadTilePaletteFromACT(fn);
            5: LoadTilePaletteFromGBAPal(fn);
          end;
          UpdateDisplay;
          Edited:=true;
     end;
end;

procedure TPaletteViewer.SavePalBTNClick(Sender: TObject);
begin
     SaveDialog1.FilterIndex:=1; // Microsoft Palette
     if SaveDialog1.Execute then
     begin
          case SaveDialog1.FilterIndex of
           1: SaveTilePalette(SaveDialog1.Filename);
           2: SaveTilePaletteAsJascPal(SaveDialog1.Filename);
           3: SaveTilePaletteAsACT(SaveDialog1.Filename);
           4: SaveTilePaletteAsGBAPal(SaveDialog1.Filename);
          end;
     end;
end;

procedure TPaletteViewer.OKBTNClick(Sender: TObject);
begin
     Close;
end;

procedure TPaletteViewer.BrightnessAdjuster1Click(Sender: TObject);
begin
     ContrastFrm.ShowModal;
end;

procedure TPaletteViewer.BlackTransparentColours1Click(Sender: TObject);
var
 x: integer;
begin
     for x:=15 downto 0 do
         PaletteData[x shl 4]:=0;
     UpdateDisplay;
end;

procedure TPaletteViewer.InvertColours1Click(Sender: TObject);
var
 x: integer;
begin
     for x:=255 downto 0 do
         PaletteData[x]:=(not PaletteData[x]) and $FFFFFF;
         // $7FFF is used to mask the highest order bit because I don't know what it is for.
     UpdateDisplay;
end;

procedure TPaletteViewer.SavePalBTNMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
     DefaultPanels;
end;

procedure TPaletteViewer.Createhtmldocumentation1Click(Sender: TObject);
var
  tf: TextFile;
  s: string;
  r,i: byte;
begin
     if SaveHTMLDialog1.Execute then
     begin
          SaveHTMLDialog1.FileName:=GetFNWithExtentionAs(SaveHTMLDialog1.FileName,'html');
          AssignFile(tf,SaveHTMLDialog1.FileName);
          Rewrite(tf);
          WriteLn(tf,'<HTML>');
          WriteLn(tf,'<!--- Created with J''s Palette Editor ---!>');
          WriteLn(tf,'<HEAD>');
          WriteLn(tf,'<TITLE>Palette</TITLE>');
          WriteLn(tf,'<SCRIPT Language="JavaScript">');
          WriteLn(tf,'var Palette=new Array(');
          for r:=0 to 15 do
          begin
               s:='  ';
               for i:=0 to 15 do
               begin
                    s:=s+'''#'+IntToHex(RedBlueSwap(PaletteData[i+(r shl 4)]),6)+'''';
                    if (i<>15)or(r<>15) then
                       s:=s+',';
               end;
               WriteLn(tf,s);
               WriteLn(tf,'   // palette row '+inttostr(r));
          end;
          WriteLn(tf,'  );');
          WriteLn(tf,'');
          WriteLn(tf,'  function MouseMove(i,r)');
          WriteLn(tf,'  {');
          WriteLn(tf,'     status=''Value: ''+Palette[(r<<4)+i]+'', Row: ''+r+'', Index: ''+i;');
          WriteLn(tf,'  }');
          WriteLn(tf,'');
          WriteLn(tf,'  function WriteTable()');
          WriteLn(tf,'  {');
          WriteLn(tf,'      document.write(''<TABLE  Border=1><CAPTION><STRONG>Colour Palette</STRONG></CAPTION>'');');
          WriteLn(tf,'      document.write(''<TR><TD></TD>'');');
          WriteLn(tf,'      for (var i=0;i<16;i++)');
          WriteLn(tf,'           document.write(''<TD>''+i+''</TD>'');');
          WriteLn(tf,'      document.write(''</TR>'');');
          WriteLn(tf,'      for (var r=0;r<16;r++)');
          WriteLn(tf,'      {');
          WriteLn(tf,'           document.write(''<TR>'');');
          WriteLn(tf,'           document.write(''<TD><B>Row ''+r+''</B></TD>'');');
          WriteLn(tf,'           for (var i=0;i<16;i++)');
          WriteLn(tf,'           {');
          WriteLn(tf,'               document.write(''<TD BGColor="''+Palette[(r<<4)+i]+''"'');');
          WriteLn(tf,'               document.write(''Height="20" Width="20" OnMouseMove="MouseMove(''+i+'',''+r+'');"></TD>'')');
          WriteLn(tf,'           }');
          WriteLn(tf,'           document.write(''</TR>'')');
          WriteLn(tf,'      }');
          WriteLn(tf,'      document.write(''</TABLE>'');');
          WriteLn(tf,'  }');
          WriteLn(tf,'  WriteTable();');
          WriteLn(tf,'');
          WriteLn(tf,'</SCRIPT>');
          WriteLn(tf,'</HEAD>');
          WriteLn(tf,'<BODY>');
          WriteLn(tf,'<SUB>Created with J''s Palette Editor</SUB>');
          WriteLn(tf,'</BODY>');
          WriteLn(tf,'</HTML>');
          CloseFile(tf);
     end;
end;

procedure TPaletteViewer.Close1Click(Sender: TObject);
begin
     Close;
end;

procedure TPaletteViewer.FormCreate(Sender: TObject);
begin
     Initialize;
end;

procedure TPaletteViewer.Gray1Click(Sender: TObject);
var
  x: byte;
begin
     for x:=255 downto 0 do
         PaletteData[x]:=rgb(x,x,x);
     UpdateDisplay;
end;

procedure CreateCHeader(fn: string);
var
  tf: textfile;
  x: integer;
  s: string;
begin
     fn:=GetFNWithExtentionAs(fn,'h');
     assignfile(tf,fn);
     Rewrite(tf);
     WriteLn(tf,'// created with J''s Palette Editor');
     WriteLn(tf,'const dword Palette[256] = {');
     s:='  ';
     for x:=0 to high(PaletteData) do
     begin
          s:=s+'0x'+inttohex(PaletteData[x],8)+', ';
          if Length(s)>80 then
          begin
               WriteLn(tf,s);
               s:='  ';
          end;
     end;
     WriteLn(tf,s);
     WriteLn(tf,' };');
     CloseFile(tf);
end;

procedure CreateJavaScript(fn: string);
var
  tf: textfile;
  s: string;
  x: integer;
begin
     fn:=GetFNWithExtentionAs(fn,'js');
     assignfile(tf,fn);
     Rewrite(tf);
     WriteLn(tf,'// created with J''s Palette Editor');
     WriteLn(tf,'var PaletteEntries = new Array(');
     s:='  ';
     for x:=0 to high(PaletteData) do
     begin
          s:=s+'''#'+inttohex(RedBlueSwap(PaletteData[x]),6)+'''';
          if x<>High(PaletteData) then
             s:=s+', ';
          if Length(s)>80 then
          begin
               WriteLn(tf,s);
               s:='  ';
          end;
     end;
     WriteLn(tf,s);
     WriteLn(tf,' );');
     CloseFile(tf);
end;

procedure CreateDelphiUnit(fn: string);
var
  tf: textfile;
  x: integer;
  s: string;
begin
     fn:=GetFNWithExtentionAs(fn,'pas');
     assignfile(tf,fn);
     Rewrite(tf);
     WriteLn(tf,'{ created with J''s Palette Editor }');
     WriteLn(tf,'unit PaletteUnit;');
     WriteLn(tf,'');
     WriteLn(tf,'interface');
     WriteLn(tf,'');
     WriteLn(tf,'const');
     WriteLn(tf,'  ColourPalette: array[0..255] of integer = (');
     s:='  ';
     for x:=0 to high(PaletteData) do
     begin
          s:=s+'$'+inttohex(PaletteData[x],8);
          if x<>high(PaletteData) then
             s:=s+', ';
          if Length(s)>80 then // break lines
          begin
               WriteLn(tf,s);
               s:='  ';
          end;
     end;
     WriteLn(tf,s);
     WriteLn(tf,'  );');
     WriteLn(tf,'');
     WriteLn(tf,'implementation');
     WriteLn(tf,'');
     WriteLn(tf,'end.');
     CloseFile(tf);
end;

procedure TPaletteViewer.CreateSourceCode1Click(Sender: TObject);
var
  fn: string;
begin
     if CreateSourceDialog.Execute then
     begin
          fn:=CreateSourceDialog.FileName;
          Case CreateSourceDialog.FilterIndex of
            1: CreateCHeader(fn);
            2: CreateJavaScript(fn);
            3: CreateDelphiUnit(fn);
            //4: CreateBasicModule(fn);
          end;
     end;
end;

procedure TPaletteViewer.GrayScale161Click(Sender: TObject);
var
  x,y: byte;
begin
     for y:=15 downto 0 do
         for x:=15 downto 0 do
             PaletteData[x+(y shl 4)]:=rgb(x shl 4,x shl 4,x shl 4);
     UpdateDisplay;
end;

procedure CreateGBASource(fn: string);
var
  tf: textfile;
  x: integer;
  s: string;
begin
     fn:=GetFNWithExtentionAs(fn,'h');
     AssignFile(tf,fn);
     Rewrite(tf);
     WriteLn(tf,'// created with J''s Palette Editor');
     WriteLn(tf,'const unsigned short Palette [256] = {');
     s:='   ';
     for x:=0 to high(PaletteData) do
     begin
          s:=s+'0x'+IntToHex(Colour32bto16(PaletteData[x]),4);
          if x<>High(PaletteData) then
             s:=s+', ';
          if length(s)>80 then
          begin
               WriteLn(tf,s);
               s:='';
          end;
     end;
     WriteLn(tf,'};');
     CloseFile(tf);
end;

procedure TPaletteViewer.CreateGBAsourcefile1Click(Sender: TObject);
begin
     CreateSourceDialog.FilterIndex:=1;
     if CreateSourceDialog.Execute then
        CreateGBASource(CreateSourceDialog.filename);
end;

function ExecuteFile(FileName, DefaultDir: string): HWND;
begin
     Result := ShellExecute(PaletteViewer.handle,nil,PChar(FileName), '',
     PChar(DefaultDir), SW_SHOWNORMAL);
end;

procedure OpenFolderFile(s: string);
var
  fn: string;
  x: integer;
begin
     fn:=GetProgDir; // get the directory containing this program without the last "\"
     x:=ExecuteFile(s,fn);
     if fileexists(fn+'\'+s) and (x<5) then
        showmessage('This should work because the file exists but for some reason it won''t open.');
     if x<5 then
     begin
        if not FileExists(fn+'\'+s) then
           ShowMessage('The file called "'+s+'" could not be found.');
     end;
end;

procedure TPaletteViewer.UsingJsPaletteEditor1Click(Sender: TObject);
begin
     OpenFolderFile('J''s Palette Editor.html');
end;

procedure TPaletteViewer.AboutJsPaletteEditor1Click(Sender: TObject);
begin
     // do NOT change this message
     ShowMessage( 'J''s Palette Editor'+#13
                  +'Created By Josh Greig'+#13
                  +'Version 1.02');
     // Also, when using any code from this project, give proper credit to me.
end;

procedure TPaletteViewer.GrayScale1Click(Sender: TObject);
var
  x,c: integer;
  g: byte;
begin
     for x:=high(PaletteData) downto 0 do
     begin
          c:=PaletteData[x];
          g:=(GetRValue(c)+GetGValue(c)+GetBValue(c)) div 3;
          PaletteData[x]:=rgb(g,g,g);
     end;
     UpdateDisplay;
end;

procedure TPaletteViewer.ColourContrastAdjuster1Click(Sender: TObject);
begin
     ColourContrastFrm.ShowModal;
end;

procedure TPaletteViewer.SwapRedandBlue1Click(Sender: TObject);
var
 x: integer;
begin
     for x:=255 downto 0 do
         PaletteData[x]:=RedBlueSwap(PaletteData[x]);
     UpdateDisplay;
end;

procedure TPaletteViewer.AllBlack1Click(Sender: TObject);
var
 x: integer;
begin
     for x:=255 downto 0 do
         PaletteData[x]:=clBlack;
     UpdateDisplay;
end;

procedure TPaletteViewer.ImportFromBitmap1Click(Sender: TObject);
begin
     OpenDialog1.FilterIndex:=2;
     LoadPalBTNClick(Sender);
     OpenDialog1.FilterIndex:=1;
end;

end.

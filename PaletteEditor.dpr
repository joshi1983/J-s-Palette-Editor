program PaletteEditor;
// created by Josh Greig
// when using any code from this project, give proper credit to me.
uses
  Forms,
  PaletteU in 'PaletteU.pas' {PaletteViewer},
  PaletteContrastU in 'PaletteContrastU.pas' {ContrastFrm},
  ColourContrastU in '..\..\..\..\..\..\My Documents\More\My Documents\My Programs\Teaching\Palette\ColourContrastU.pas' {ColourContrastFrm};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TPaletteViewer, PaletteViewer);
  Application.CreateForm(TContrastFrm, ContrastFrm);
  Application.CreateForm(TColourContrastFrm, ColourContrastFrm);
  Application.Run;
end.

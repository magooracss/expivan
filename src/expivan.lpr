program expivan;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, dbflaz, abbrevia, frm_pantallaprincipal, dmgeneral
  { you can add units after this };

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TDM_General, DM_General);
  Application.CreateForm(TfrmPantallaPrincipal, frmPantallaPrincipal);
  Application.Run;
end.


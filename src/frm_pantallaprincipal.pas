unit frm_pantallaprincipal;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, db, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  ComCtrls, EditBtn, StdCtrls, Buttons, DBGrids;

type

  { TfrmPantallaPrincipal }

  TfrmPantallaPrincipal = class(TForm)
    btnObtener: TBitBtn;
    btnExportar: TBitBtn;
    cbClientes: TComboBox;
    DBGrid2: TDBGrid;
    ds_compras: TDatasource;
    DBGrid1: TDBGrid;
    ds_ventas: TDatasource;
    edFIni: TDateEdit;
    edFFin: TDateEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    PCOperaciones: TPageControl;
    Panel1: TPanel;
    SD: TSaveDialog;
    st: TStatusBar;
    tabRetenciones: TTabSheet;
    tabPercepciones: TTabSheet;
    procedure btnExportarClick(Sender: TObject);
    procedure btnObtenerClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    procedure Inicializar;
  public
    { public declarations }
  end; 

var
  frmPantallaPrincipal: TfrmPantallaPrincipal;

implementation
{$R *.lfm}
uses
  dateutils
  ,dmgeneral
  ;

{ TfrmPantallaPrincipal }

procedure TfrmPantallaPrincipal.btnObtenerClick(Sender: TObject);
begin
  if DM_General.CargarClientes (Integer(cbClientes.Items.Objects[cbClientes.ItemIndex])) then
  begin
    case PCOperaciones.ActivePageIndex of
      0: DM_General.ObtenerRetenciones (edFIni.Date, edFFin.Date); //Retenciones
      1: DM_General.ObtenerPercepciones (edFIni.Date, edFFin.Date); //Percepciones
    end;
  end;
end;

procedure TfrmPantallaPrincipal.btnExportarClick(Sender: TObject);
begin
  if SD.Execute then
  begin
    case PCOperaciones.ActivePageIndex of
      0: DM_General.ExportarRetenciones (SD.FileName); //Retenciones
      1: DM_General.ExportarPercepciones (SD.FileName); //Percepciones
    end;
  end;
end;

procedure TfrmPantallaPrincipal.FormShow(Sender: TObject);
begin
  Inicializar;
end;

procedure TfrmPantallaPrincipal.Inicializar;
begin
  edFIni.Date:= StartOfTheMonth(Now);
  edFFin.Date:= EndOfTheMonth(Now);
  DM_General.cargarCombo (cbClientes);
end;

end.


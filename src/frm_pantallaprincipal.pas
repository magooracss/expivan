unit frm_pantallaprincipal;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, db, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  ComCtrls, EditBtn, StdCtrls, Buttons, DBGrids, IniPropStorage;

type

  { TfrmPantallaPrincipal }

  TfrmPantallaPrincipal = class(TForm)
    btnObtener: TBitBtn;
    btnExportar: TBitBtn;
    cbClientes: TComboBox;
    cbRegimenPercepcion: TComboBox;
    DBGrid2: TDBGrid;
    DBGrid3: TDBGrid;
    DBGrid4: TDBGrid;
    ds_compras: TDatasource;
    DBGrid1: TDBGrid;
    ds_ventas: TDatasource;
    edFIni: TDateEdit;
    edFFin: TDateEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    edLote: TLabeledEdit;
    Panel2: TPanel;
    PCOperaciones: TPageControl;
    Panel1: TPanel;
    rgRegimen: TRadioGroup;
    SD: TSaveDialog;
    st: TStatusBar;
    tabIVARetenciones: TTabSheet;
    tabIVAPercepciones: TTabSheet;
    tabIIBBRetenciones: TTabSheet;
    tabIIBBPercepciones: TTabSheet;
    procedure btnExportarClick(Sender: TObject);
    procedure btnObtenerClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    procedure Inicializar;
    procedure GrabarPosCb;
    procedure LevantarPosCb;
    function CodigoRegimen (laCadena: string): integer;
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
  ,IniFiles
  ,strutils

  ;

{ TfrmPantallaPrincipal }

procedure TfrmPantallaPrincipal.btnObtenerClick(Sender: TObject);
begin
  if DM_General.CargarClientes (Integer(cbClientes.Items.Objects[cbClientes.ItemIndex])) then
  begin
    case PCOperaciones.ActivePageIndex of
      0: DM_General.ObtenerRetencionesIVA (edFIni.Date, edFFin.Date); //RetencionesIVA
      1: if cbRegimenPercepcion.ItemIndex >= 0 then
         begin
          DM_General.ObtenerPercepcionesIVA (edFIni.Date, edFFin.Date); //PercepcionesIVA
          GrabarPosCb;
         end;
      2: DM_General.ObtenerRetencionesIIBB (edFIni.Date, edFFin.Date); //RetencionesIIBB
      3: DM_General.ObtenerPercepcionesIIBB (edFIni.Date, edFFin.Date); //PercepcionesIIBB
    end;
  end;
end;

procedure TfrmPantallaPrincipal.btnExportarClick(Sender: TObject);
var
  pos: integer;
  RutaArchivo: String;
begin
  if SD.Execute then
  begin
    RutaArchivo:= SD.FileName;
    case PCOperaciones.ActivePageIndex of
      0: DM_General.ExportarRetencionesIVA (rutaArchivo); //RetencionesIVA
      1: DM_General.ExportarPercepcionesIVA (rutaArchivo, codigoRegimen(cbRegimenPercepcion.Text)); //PercepcionesIVA
      2: begin
           DM_General.FormatearArchivoIIBB( rutaArchivo
                                          , Integer(cbClientes.Items.Objects[cbClientes.ItemIndex])
                                          , edFIni.Date
                                          , rgRegimen.ItemIndex
                                          , 'R'
                                          , TRIM(edLote.Text)
                                          );
           DM_General.ExportarRetencionesIIBB (rutaArchivo); //RetencionesIIBB
       //    DM_General.ComprimirArchivoIIBB(rutaArchivo);
         end;
      3: begin
           DM_General.FormatearArchivoIIBB( rutaArchivo
                                          , Integer(cbClientes.Items.Objects[cbClientes.ItemIndex])
                                          , edFIni.Date
                                          , rgRegimen.ItemIndex
                                          , 'P'
                                          , TRIM(edLote.Text)
                                          );
           DM_General.ExportarPercepcionesIIBB (rutaArchivo); //PercepcionesIIBB
        //   DM_General.ComprimirArchivoIIBB(rutaArchivo);
         end;
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
  PCOperaciones.ActivePage:= tabIIBBPercepciones;
  DM_General.cargarCombo (cbClientes);
  LevantarPosCb;
end;

procedure TfrmPantallaPrincipal.GrabarPosCb;
var
  archivo: TIniFile;
begin
  archivo:= TIniFile.Create(ExtractFilePath(ApplicationName)+ elIni);
  try
    archivo.WriteInteger(SEC_FRM,CB_CODREGPERCP, cbRegimenPercepcion.ItemIndex);
  finally
    archivo.Free;
  end;

end;


procedure TfrmPantallaPrincipal.LevantarPosCb;
var
  archivo: TIniFile;
begin
  archivo:= TIniFile.Create(ExtractFilePath(ApplicationName)+ elIni);
  try
    cbRegimenPercepcion.ItemIndex:= archivo.ReadInteger(SEC_FRM,CB_CODREGPERCP, 0 );
  finally
    archivo.Free;
  end;

end;

function TfrmPantallaPrincipal.CodigoRegimen(laCadena: string): integer;
begin
  Result:= StrToIntDef(ExtractWord(1,cbRegimenPercepcion.Text,['<','>']),0);
end;


end.


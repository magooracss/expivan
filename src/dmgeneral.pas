unit dmgeneral;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, dbf, FileUtil, stdCtrls, db;

type

  { TDM_General }

  TDM_General = class(TDataModule)
    tbClientes: TDbf;
    tbCompras: TDbf;
    tbVentas: TDbf;
    tbComprasCCUIT: TLargeintField;
    tbComprasCFECHA: TDateField;
    tbComprasCLETCOM: TStringField;
    tbComprasCNUMERO: TStringField;
    tbComprasCPERSE: TFloatField;
    tbComprasCTIPOCOM: TSmallintField;
    tbVentasVCUIT: TLargeintField;
    tbVentasVFECHA: TDateField;
    tbVentasVNUMERO: TLongintField;
    tbVentasVRETENCION: TFloatField;
    tbVentasVSUCURSAL: TSmallintField;
    procedure tbComprasFilterRecord(DataSet: TDataSet; var Accept: Boolean);
    procedure tbVentasFilterRecord(DataSet: TDataSet; var Accept: Boolean);
  private
     rutaCliente: string;
     fPerIni
     ,fPerFin
     ,fRetIni
     ,fRetFin: TDate; //Esto es por un bug en el filtro de TDBF;
     archivoSalida: TextFile;

     function VincularDBFs (ruta: string): boolean;
     function FechaY2K (laFecha: TDate): TDate;

     procedure PrepararArchivo (laruta: String);
     procedure EscribirLinea(laLinea: string);
     procedure CerrarArchivo;


     function FormatearCUIT (elCuit: String): String;
     function FormatearFecha (laFecha: TDate): String;
     function FormatearSucEmision (laCadena: String): String;
     function FormatearImporte (elImporte: Double; longitud: byte): String;

  public
    procedure CargarCombo (var elCombo: TComboBox);


    function CargarClientes (idcliente: integer):boolean;

    procedure ObtenerPercepciones (fIni, fFin: TDate);
    procedure ObtenerRetenciones (fIni, fFin: TDate);

    procedure ExportarPercepciones (rutaArchivo: string);
    procedure ExportarRetenciones (rutaArchivo: string);
  end; 

var
  DM_General: TDM_General;

implementation
{$R *.lfm}
uses
  IniFiles
  ,dateutils
  ,strutils
  ,dialogs
  ;

const
  fVENTAS = 'VENTA.DBF';
  fCOMPRAS = 'COMPRA.DBF';
  elIni = 'config.cfg';
  SEC_APP = 'APLICACION';
  APP_RUTA = 'DATOS';
  APP_CLIENTES = 'CLIENTES_BD';
  APP_CLIENTES_RUTA = 'CLIENTES_RUTA';

{ TDM_General }

procedure TDM_General.CargarCombo(var elCombo: TComboBox);
var
  archivo: TIniFile;
begin
  archivo:= TIniFile.Create(ExtractFilePath(ApplicationName)+ elIni);
  with tbClientes do
  begin
    if Active then Close;
    FilePath:= archivo.ReadString(SEC_APP,APP_CLIENTES_RUTA, EmptyStr );
    TableName:=archivo.ReadString(SEC_APP,APP_CLIENTES, EmptyStr );
    Open;
    elCombo.Clear;
    While Not EOF do
    begin
      elCombo.items.AddObject (FieldByName('cNombre').asString,TObject(FieldByName('cCodigo').asInteger));
      Next;
    end;
    close;
  end;
end;

function TDM_General.CargarClientes(idcliente: integer): boolean;
var
  archivo: TIniFile;
  strCliente:string;
begin
  archivo:= TIniFile.Create(ExtractFilePath(ApplicationName)+ elIni);
  strCliente:= '0000' + intToStr(idCliente);
  strCliente:= copy (strCliente, Length(strCliente)-3,4);
  Result:= VincularDBFs(archivo.ReadString(SEC_APP,APP_RUTA, EmptyStr) + strCliente + '\');
end;


function TDM_General.VincularDBFs(ruta: string): boolean;
var
  rCompras, rVentas: string;
begin
  rCompras:= ruta + fCOMPRAS;
  rVentas:= ruta + fVENTAS;
  if ( FileExists(rCompras) and FileExists(rVentas)) then
  begin
    Result:= true;
    rutaCliente:= ruta;
  end
  else
  begin
    Result:= false;
    rutaCliente:= EmptyStr;
  end;
end;

function TDM_General.FechaY2K(laFecha: TDate): TDate;
begin
  Result:= IncYear(laFecha, -100);
end;

procedure TDM_General.PrepararArchivo(laruta: String);
begin
  AssignFile(archivoSalida, laRuta);
  Rewrite(archivoSalida);
end;

procedure TDM_General.EscribirLinea(laLinea: string);
begin
  WriteLn(archivoSalida, laLinea);
end;

procedure TDM_General.CerrarArchivo;
begin
  CloseFile(archivoSalida);
end;

function TDM_General.FormatearCUIT(elCuit: String): String;
begin
  case Length(elCuit) of
   11 : Result:= Copy(elcuit,1,2)+'-'+Copy(elcuit,3,8)+'-'+Copy(elcuit,11,1);
   13 : Result:= elCuit;
  else
    Result:= Copy('0000000000000'+elcuit, Length('0000000000000'+elcuit)-12,13 );
  end;
end;

function TDM_General.FormatearFecha(laFecha: TDate): String;
begin

  if YearOf(laFecha) < 1950 then // Y2K
    laFecha:= IncYear(laFecha, 100);

  Result:= FormatDateTime('dd/mm/yyyy',lafecha);
end;

function TDM_General.FormatearSucEmision(laCadena: String): String;
begin
  if Length(laCadena) = 12 then
    Result:= laCadena
  else
    Result:= Copy('000000000000'+laCadena, Length('000000000000'+laCadena)-11,12 );
end;

function TDM_General.FormatearImporte(elImporte: Double; longitud: byte): String;
var
  mascara: string;
begin
  mascara:= '.00';
  mascara:= AddChar('0', mascara, longitud) ;

  Result:= FormatFloat(mascara ,elImporte);
end;


(*******************************************************************************
****  PERCEPCIONES
*******************************************************************************)

procedure TDM_General.tbComprasFilterRecord(DataSet: TDataSet;
  var Accept: Boolean);
begin
  Accept:= ((DataSet.FieldByName('cFecha').AsDateTime >= fPerIni)
            and (DataSet.FieldByName('cFecha').AsDateTime <= fPerFin)
            and (NOT DataSet.FieldByName('cPerse').IsNull)
            and (DataSet.FieldByName('cPerse').AsFloat <> 0)
           );
end;

procedure TDM_General.ObtenerPercepciones(fIni, fFin: TDate);
begin
  with tbCompras do
  begin
    DisableControls;
    if Active then close;
    FilePath:= rutaCliente;
    TableName:= fCOMPRAS;
    fPerIni:= fechaY2K (fIni);
    fPerFin:= fechaY2K (fFin);
    Open;

    Filtered:= true;
    EnableControls;
  end;
end;

procedure TDM_General.ExportarPercepciones(rutaArchivo: string);
var
  linea: string;
begin
  PrepararArchivo(rutaArchivo);
  with tbCompras do
  begin
    First;
    while Not EOF do
    begin
      linea:= FormatearCUIT(FieldByName('cCUIT').asString);
      linea:= linea + FormatearFecha (FieldByName('cFecha').asDateTime);
      linea:= linea + 'F';
      linea:= linea + FieldByName('cLetCom').asString;
      linea:= linea + FormatearSucEmision (FieldByName('cNumero').AsString);
      linea:= linea + FormatearImporte (FieldByName('cPerse').asFloat,11);
      EscribirLinea(linea);
      Next;
    end;
    CerrarArchivo;
  end;
end;


(*******************************************************************************
****  RETENCIONES
*******************************************************************************)

procedure TDM_General.tbVentasFilterRecord(DataSet: TDataSet;
  var Accept: Boolean);
begin
  Accept:= ((DataSet.FieldByName('vFecha').AsDateTime >= fRetIni)
            and (DataSet.FieldByName('vFecha').AsDateTime <= fRetFin)
            and (NOT DataSet.FieldByName('vRetencion').IsNull)
            and (DataSet.FieldByName('vRetencion').AsFloat <> 0)
           );
end;



procedure TDM_General.ObtenerRetenciones(fIni, fFin: TDate);
begin
  with tbVentas do
  begin
    DisableControls;
    if Active then close;
    FilePath:= rutaCliente;
    TableName:= fVENTAS;
    fRetIni:= fechaY2K (fIni);
    fRetFin:= fechaY2K (fFin);
    Open;

    Filtered:= true;
    EnableControls;
  end;
end;



procedure TDM_General.ExportarRetenciones(rutaArchivo: string);
var
  linea: string;
begin
  PrepararArchivo(rutaArchivo);
  with tbVentas do
  begin
    First;
    while Not EOF do
    begin
      linea:= FormatearCUIT(FieldByName('vCUIT').asString);
      linea:= linea + FormatearFecha (FieldByName('vFecha').asDateTime);
      linea:= linea + Copy ('0000'+ FieldByName('vSucursal').AsString,Length('0000'+ FieldByName('vSucursal').AsString)-3,4);
      linea:= linea + Copy ('00000000'+ FieldByName('vNumero').AsString,Length('00000000'+ FieldByName('vNumero').AsString)-7,8);
      linea:= linea + FormatearImporte (FieldByName('vRetencion').asFloat, 10);
      EscribirLinea(linea);
      Next;
    end;
    CerrarArchivo;
  end;
end;

end.


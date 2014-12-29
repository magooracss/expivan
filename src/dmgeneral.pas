unit dmgeneral;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, dbf, FileUtil, AbZipper, stdCtrls, db;

const
  fVENTAS = 'VENTA.DBF';
  fCOMPRAS = 'COMPRA.DBF';
  elIni = 'config.cfg';
  SEC_APP = 'APLICACION';
  APP_RUTA = 'DATOS';
  APP_CLIENTES = 'CLIENTES_BD';
  APP_CLIENTES_RUTA = 'CLIENTES_RUTA';
  SEC_FRM ='FORMULARIOS';
  CB_CODREGPERCP = 'IDX_COD_REG_PERCEP';

type

  { TDM_General }

  TDM_General = class(TDataModule)
    ArchivoZip: TAbZipper;
    tbClientes: TDbf;
    tbCompras: TDbf;
    tbComprasCBRUTO: TFloatField;
    tbVentas: TDbf;
    tbComprasCCUIT: TLargeintField;
    tbComprasCFECHA: TDateField;
    tbComprasCLETCOM: TStringField;
    tbComprasCNUMERO: TStringField;
    tbComprasCPERSE: TFloatField;
    tbComprasCTIPOCOM: TSmallintField;
    tbVentasVBRUTO: TFloatField;
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
     campoValorPer
     ,campoValorRet: string; //Es el campo donde obtiene el valor al filtrar;
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
     function FormatearCodigoRegimen (codigoRegimen: integer): string;

  public
    procedure CargarCombo (var elCombo: TComboBox);


    function CargarClientes (idcliente: integer):boolean;
    function CUITCliente (idcliente: integer):string;
    procedure FormatearArchivoIIBB( var rutaArchivo: String
                                  ; idCliente: integer
                                  ; fecha: TDate
                                  ; regimen: byte
                                  ; Tipo
                                  , Lote: string );



    procedure ObtenerPercepcionesIVA (fIni, fFin: TDate);
    procedure ObtenerRetencionesIVA (fIni, fFin: TDate);
    procedure ObtenerPercepcionesIIBB (fIni, fFin: TDate);
    procedure ObtenerRetencionesIIBB (fIni, fFin: TDate);

    procedure ExportarPercepcionesIVA (rutaArchivo: string; codigoRegimen: integer);
    procedure ExportarRetencionesIVA (rutaArchivo: string);
    procedure ExportarPercepcionesIIBB (rutaArchivo: string);
    procedure ExportarRetencionesIIBB (rutaArchivo: string);

    procedure ComprimirArchivoIIBB (rutaArchivo: string);

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

function TDM_General.CUITCliente(idcliente: integer): string;
begin
  with tbClientes do
  begin
    Open;
    if Locate('cCodigo', idCliente, [loCaseInsensitive] ) then
     Result:= FieldByName('cCUIT').asString
    else
      Result:= 'ERROR_EN_CUIT';
  end;
end;

procedure TDM_General.FormatearArchivoIIBB(var rutaArchivo: String; idCliente: integer;
  fecha: TDate; regimen: byte; Tipo, Lote: string);
var
  laRuta: String;
begin
  LaRuta:= ExtractFilePath(RutaArchivo);
  laRuta:= laRuta + CUITCliente(idCliente);
  laRuta:= laRuta + '-' + FormatDateTime('yyyymm',fecha);
  case regimen of
   0: laRuta:= laRuta + 'B';
   1: laRuta:= laRuta + 'M';
  end;
  laRuta:= laRuta + '-' + Tipo;
  laRuta:= laRuta + '-' + Lote;
  laRuta:= laRuta + '.txt';
  rutaArchivo:= laRuta;
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
var
  parte1, parte2: string;
begin
  if Length(laCadena) < 12 then
      laCadena:= Copy ('000000000000'+ laCadena,Length('000000000000'+ laCadena)-11,12);

  parte1:= Copy (laCadena,1,4);
  parte2:= Copy (laCadena,5,12);

  Result:=  parte1 + parte2;
end;

function TDM_General.FormatearImporte(elImporte: Double; longitud: byte): String;
var
  mascara: string;
begin
  mascara:= '.00';

  if elImporte < 0 then
   longitud:= longitud -1;  //Para evitar que ponga el signo fuera del rango de la mascara

  mascara:= AddChar('0', mascara, longitud) ;

  Result:= FormatFloat(mascara ,elImporte);
end;

function TDM_General.FormatearCodigoRegimen(codigoRegimen: integer): string;
var
  codigoRegStr: string;
begin
  codigoRegstr:= IntToStr(codigoRegimen);
  if Length(codigoRegStr) = 3 then
    Result:= codigoRegStr
  else
    Result:= Copy('000'+codigoRegStr, Length('000'+codigoRegStr)-2,3 );
end;


(*******************************************************************************
****  PERCEPCIONES
*******************************************************************************)

procedure TDM_General.tbComprasFilterRecord(DataSet: TDataSet;
  var Accept: Boolean);
begin
  Accept:= ((DataSet.FieldByName('cFecha').AsDateTime >= fPerIni)
            and (DataSet.FieldByName('cFecha').AsDateTime <= fPerFin)
            and (NOT DataSet.FieldByName(campoValorPer).IsNull)
            and (DataSet.FieldByName(campoValorPer).AsFloat <> 0)
           );
end;

procedure TDM_General.ObtenerPercepcionesIVA(fIni, fFin: TDate);
begin
  with tbCompras do
  begin
    DisableControls;
    campoValorPer:= 'cPerse' ;
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

procedure TDM_General.ExportarPercepcionesIVA(rutaArchivo: string; codigoRegimen: integer);
var
  linea: string;
begin
  PrepararArchivo(rutaArchivo);
  with tbCompras do
  begin
    First;
    while Not EOF do
    begin
      linea:= FormatearCodigoRegimen (codigoRegimen);
      linea:= linea + FormatearCUIT(FieldByName('cCUIT').asString);
      linea:= linea + FormatearFecha (FieldByName('cFecha').asDateTime);
      linea:= linea + '0000' + FormatearSucEmision (FieldByName('cNumero').AsString);
      linea:= linea + FormatearImporte (FieldByName('cPerse').asFloat,16);
      EscribirLinea(linea);
      Next;
    end;
    CerrarArchivo;
  end;
end;

procedure TDM_General.ObtenerPercepcionesIIBB(fIni, fFin: TDate);
begin
  with tbCompras do
  begin
    DisableControls;
    campoValorPer:= 'cBruto' ;
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



procedure TDM_General.ExportarPercepcionesIIBB(rutaArchivo: string);
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
      linea:= linea + FormatearImporte (FieldByName('cBruto').asFloat,11);
      linea:= linea + 'A'; //Modificaron el formato, ahora hay que informar si es Alta o Baja
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
            and (NOT DataSet.FieldByName(campoValorRet).IsNull)
            and (DataSet.FieldByName(campoValorRet).AsFloat <> 0)
           );
end;



procedure TDM_General.ObtenerRetencionesIVA(fIni, fFin: TDate);
begin
  with tbVentas do
  begin
    campoValorRet:= 'vRetencion';
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

procedure TDM_General.ObtenerRetencionesIIBB(fIni, fFin: TDate);
begin
  with tbVentas do
  begin
    campoValorRet:= 'vBruto';
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


procedure TDM_General.ExportarRetencionesIVA(rutaArchivo: string);
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



procedure TDM_General.ExportarRetencionesIIBB(rutaArchivo: string);
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
      linea:= linea + FormatearImporte (FieldByName('vBruto').asFloat, 10);
      linea:= linea + 'A'; //Modificaron el formato, ahora hay que informar si es Alta o Baja

      EscribirLinea(linea);
      Next;
    end;
    CerrarArchivo;
  end;
end;

procedure TDM_General.ComprimirArchivoIIBB(rutaArchivo: string);
var
  nombreZip: string;
begin
  nombreZip:= ExtractFilePath(rutaArchivo) + ExtractFileNameOnly(rutaArchivo)+ '.zip';
  ArchivoZip.FileName:= nombreZip;
  ArchivoZip.AddFiles(rutaArchivo,0);
  ArchivoZip.CloseArchive;
  ArchivoZip.Save;
end;

end.


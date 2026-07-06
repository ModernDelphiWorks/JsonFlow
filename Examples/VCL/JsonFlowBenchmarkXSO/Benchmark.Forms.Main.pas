unit Benchmark.Forms.Main;

// JsonFlow vs X-SuperObject Benchmark - Neon-identical methodology
// Escala Simple  (TUser)     : 10K, 20K, 30K, 40K, 50K
// Escala Complex (TCustomer) :  1K,  2K,  3K,  4K,  5K
//
// X-SuperObject: https://github.com/onryldz/x-superobject
//
// NOTA sobre enums: o X-SuperObject NAO suporta enum-as-string (trata enums
// estritamente como ordinal — XSuperObject.pas, tkEnumeration usa I[Member]).
// Como os arquivos de dados gravam enums como string ("Work", "HR"...), na
// fase de PREPARACAO (nao cronometrada) o JSON de entrada do X-SuperObject
// recebe os enums convertidos para ordinal. O JsonFlow continua lendo o JSON
// original com enums string. A saida do X-SuperObject tambem tera enums como
// inteiro — convencao nativa da biblioteca.

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.Diagnostics,
  System.Generics.Collections, System.Math, System.UITypes,
  System.IOUtils,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Imaging.pngimage,
  VCLTee.Chart, VCLTee.Series, VCLTee.TeEngine,
  XSuperObject,
  JsonFlow.Serializer, JsonFlow.Reader, JsonFlow.Interfaces,
  Benchmark.Entities;

const
  DATA_PATH     = 'Data\Benchmarks';
  USER_FILENAME = 'users-%dk.json';
  CUST_FILENAME = 'customers-%dk.json';
  USER_SCALE: array[0..4] of Integer = (10, 20, 30, 40, 50);
  CUST_SCALE: array[0..4] of Integer = ( 1,  2,  3,  4,  5);

  // Mesma paleta do benchmark original: JsonFlow = azul escuro, rival = laranja
  COLOR_JSONFLOW: TColor = $00A46534;
  COLOR_XSO     : TColor = $000A7AE6;

type
  TfrmBenchmark = class(TForm)
    pnlTop       : TPanel;
    rdSimple     : TRadioButton;
    rdComplex    : TRadioButton;
    chkSave      : TCheckBox;
    btnStart     : TButton;
    lblStatus    : TLabel;
    pnlBottom    : TPanel;
    imgLogo      : TImage;
    memResults   : TMemo;
    pnlCharts    : TPanel;
    pnlChartLeft : TPanel;
    pnlChartRight: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
  private
    FDataPath: string;
    FchtSer  : TChart;
    FchtDeser: TChart;
    FSerJF   : TBarSeries;
    FSerXSO  : TBarSeries;
    FDeserJF : TBarSeries;
    FDeserXSO: TBarSeries;
    procedure SetupCharts;
    procedure BenchmarkSimpleClass;
    procedure BenchmarkComplexClass;
    procedure BenchmarkFile(AEnvelope: TEnvelope; const AJsonWrapped: string; AScaleLabel: string);
    procedure SetStatus(const AText: string);
    procedure Log(const AText: string);
  end;

var
  frmBenchmark: TfrmBenchmark;

implementation

{$R *.dfm}

// X-SuperObject nao le enum como string: converte os valores conhecidos dos
// dados de benchmark para ordinal (TAddressType / TDepartment). Executado na
// fase de preparacao, FORA do cronometro.
function EnumStringsToOrdinals(const AJson: string): string;
begin
  Result := AJson;
  Result := StringReplace(Result, '"AddressType": "Personal"', '"AddressType": 0', [rfReplaceAll]);
  Result := StringReplace(Result, '"AddressType": "Work"',     '"AddressType": 1', [rfReplaceAll]);
  Result := StringReplace(Result, '"Dept": "HR"',              '"Dept": 0',        [rfReplaceAll]);
  Result := StringReplace(Result, '"Dept": "Sales"',           '"Dept": 1',        [rfReplaceAll]);
  Result := StringReplace(Result, '"Dept": "Marketing"',       '"Dept": 2',        [rfReplaceAll]);
  Result := StringReplace(Result, '"Dept": "Accounting"',      '"Dept": 3',        [rfReplaceAll]);
end;

{ TfrmBenchmark }

procedure TfrmBenchmark.FormCreate(Sender: TObject);
var
  LExeDir  : string;
  LLogoPath: string;
begin
  LExeDir := TPath.GetDirectoryName(Application.ExeName);

  // Procura a pasta Data no diretorio do executavel; se nao existir, usa a
  // pasta Data do benchmark original (JsonFlowBenchmark) para nao duplicar
  // ~31MB de arquivos JSON no repositorio.
  FDataPath := TPath.Combine(LExeDir, DATA_PATH);
  if not TDirectory.Exists(FDataPath) then
    FDataPath := TPath.GetFullPath(TPath.Combine(LExeDir, '..\JsonFlowBenchmark\' + DATA_PATH));
  if not TDirectory.Exists(FDataPath) then
    FDataPath := TPath.GetFullPath(TPath.Combine(LExeDir, '..\..\..\JsonFlowBenchmark\' + DATA_PATH));

  // Carrega a logo a partir da pasta assets
  LLogoPath := TPath.Combine(LExeDir, 'assets\jsonflow_logo.png');
  if TFile.Exists(LLogoPath) then
    imgLogo.Picture.LoadFromFile(LLogoPath);

  rdSimple.Checked := True;
  SetupCharts;
end;

procedure TfrmBenchmark.SetupCharts;

  procedure ConfigChart(AChart: TChart; const ATitle: string);
  begin
    AChart.View3D  := False;
    AChart.BevelOuter := bvNone;
    AChart.BackColor  := clWhite;
    AChart.Gradient.Visible := False;
    AChart.Title.Text.Text   := ATitle;
    AChart.Title.Font.Size   := 13;
    AChart.Title.Font.Style  := [fsBold];
    AChart.Title.Font.Color  := clRed;
    AChart.Legend.Visible    := True;
    AChart.Legend.Alignment  := laBottom;
    AChart.Legend.Font.Size  := 8;
    AChart.BottomAxis.Title.Caption    := '(smaller is better)';
    AChart.BottomAxis.Title.Font.Size  := 8;
    AChart.BottomAxis.Title.Font.Color := clGray;
    AChart.BottomAxis.LabelsFont.Size  := 8;
    AChart.LeftAxis.Title.Caption  := 'Milliseconds';
    AChart.LeftAxis.Title.Font.Size := 8;
    AChart.LeftAxis.LabelsFont.Size := 8;
  end;

  function AddBar(AChart: TChart; const ATitle: string; AColor: TColor): TBarSeries;
  begin
    Result := TBarSeries.Create(AChart);
    Result.Title           := ATitle;
    Result.SeriesColor     := AColor;
    Result.MultiBar        := mbSide;
    Result.BarWidthPercent := 50;
    Result.Marks.Visible   := True;
    Result.Marks.Style     := smsValue;
    Result.Marks.AutoPosition := True;
    Result.Marks.Font.Size := 7;
    Result.Marks.Color     := clInfoBk;
    AChart.AddSeries(Result);
  end;

begin
  FchtSer := TChart.Create(Self);
  FchtSer.Parent := pnlChartLeft;
  FchtSer.Align  := alClient;
  ConfigChart(FchtSer, 'Serialization');
  FSerJF  := AddBar(FchtSer, 'JsonFlow',     COLOR_JSONFLOW);
  FSerXSO := AddBar(FchtSer, 'XSuperObject', COLOR_XSO);

  FchtDeser := TChart.Create(Self);
  FchtDeser.Parent := pnlChartRight;
  FchtDeser.Align  := alClient;
  ConfigChart(FchtDeser, 'Deserialization');
  FDeserJF  := AddBar(FchtDeser, 'JsonFlow',     COLOR_JSONFLOW);
  FDeserXSO := AddBar(FchtDeser, 'XSuperObject', COLOR_XSO);
end;

procedure TfrmBenchmark.SetStatus(const AText: string);
begin
  lblStatus.Caption := AText;
  Application.ProcessMessages;
end;

procedure TfrmBenchmark.Log(const AText: string);
begin
  memResults.Lines.Add(AText);
  Application.ProcessMessages;
end;

// =============================================================================
// BenchmarkFile — core do benchmark, mesma metodologia do Neon/benchmark
// original (parse do texto JSON fora do cronometro nas duas bibliotecas).
//
// AJsonWrapped = '{"Items": [...]}'   (ja envolvido)
// AScaleLabel  = '1K', '2K', etc.
//
// Ordem igual ao benchmark original:
//   1. JsonFlow      Deser → JsonFlow      Ser → envelope.Clear
//   2. XSuperObject  Deser → XSuperObject  Ser
// =============================================================================
procedure TfrmBenchmark.BenchmarkFile(AEnvelope: TEnvelope;
  const AJsonWrapped: string; AScaleLabel: string);
var
  LSW          : TStopwatch;
  LXsoObj      : ISuperObject;
  LJFReader    : IJSONReader;
  LJFElem      : IJSONElement;
  LJFSer       : TJSONSerializer;
  LJFResultStr : string;
  LXsoResultStr: string;
begin
  LJFSer := nil;
  try
    try
      // ----------- Pre-parse (NAO cronometrado) -------------------------------
      // X-SuperObject recebe enums como ordinal (ver nota no topo da unit)
      if AEnvelope is TCustomersEnvelope then
        LXsoObj := SO(EnumStringsToOrdinals(AJsonWrapped))
      else
        LXsoObj := SO(AJsonWrapped);
      LJFReader := TJSONReader.Create;
      LJFElem   := LJFReader.Read(AJsonWrapped);
      LJFSer    := TJSONSerializer.Create;
    except
      on E: Exception do
      begin
        Log('Error preparing data: ' + E.ClassName + ': ' + E.Message);
        Exit;
      end;
    end;

    // =========================================================================
    // 1. JsonFlow — Deserialization
    // =========================================================================
    try
      LSW := TStopwatch.StartNew;
      LJFSer.ToObject(LJFElem, AEnvelope);
      LSW.Stop;
      FDeserJF.Add(LSW.ElapsedMilliseconds, AScaleLabel, clDefault);
      Log(Format('  Deserialization (JsonFlow):     %dms', [LSW.ElapsedMilliseconds]));
    except
      on E: Exception do Log('Error on JsonFlow Deserialization: ' + E.ClassName + ': ' + E.Message);
    end;

    // =========================================================================
    // 2. JsonFlow — Serialization
    // =========================================================================
    try
      LJFResultStr := '';
      LSW := TStopwatch.StartNew;
      LJFResultStr := LJFSer.SerializeToString(AEnvelope);
      LSW.Stop;
      FSerJF.Add(LSW.ElapsedMilliseconds, AScaleLabel, clDefault);
      Log(Format('  Serialization   (JsonFlow):     %dms', [LSW.ElapsedMilliseconds]));
    except
      on E: Exception do Log('Error on JsonFlow Serialization: ' + E.ClassName + ': ' + E.Message);
    end;

    // Limpa o envelope entre as duas bibliotecas
    try
      AEnvelope.Clear;
    except
      on E: Exception do Log('Error clearing envelope: ' + E.ClassName + ': ' + E.Message);
    end;

    // =========================================================================
    // 3. X-SuperObject — Deserialization
    //    AssignFromJSON(ISuperObject) preenche o envelope existente a partir
    //    do JSON ja parseado — analogo exato do JsonFlow ToObject(elem, obj).
    // =========================================================================
    try
      LSW := TStopwatch.StartNew;
      AEnvelope.AssignFromJSON(LXsoObj);
      LSW.Stop;
      FDeserXSO.Add(LSW.ElapsedMilliseconds, AScaleLabel, clDefault);
      Log(Format('  Deserialization (XSuperObject): %dms', [LSW.ElapsedMilliseconds]));
    except
      on E: Exception do Log('Error on XSuperObject Deserialization: ' + E.ClassName + ': ' + E.Message);
    end;

    // =========================================================================
    // 4. X-SuperObject — Serialization
    // =========================================================================
    try
      LXsoResultStr := '';
      LSW := TStopwatch.StartNew;
      LXsoResultStr := AEnvelope.AsJSON;
      LSW.Stop;
      FSerXSO.Add(LSW.ElapsedMilliseconds, AScaleLabel, clDefault);
      Log(Format('  Serialization   (XSuperObject): %dms', [LSW.ElapsedMilliseconds]));

      // Salva resultados se chkSave estiver marcada para auditoria
      if chkSave.Checked then
      begin
        var LResultDir := TPath.Combine(TPath.GetDirectoryName(Application.ExeName), 'Data\Results');
        ForceDirectories(LResultDir);
        var LFileName := AScaleLabel + '-';
        if AEnvelope is TUsersEnvelope then
          LFileName := LFileName + 'users.json'
        else
          LFileName := LFileName + 'customers.json';

        TFile.WriteAllText(TPath.Combine(LResultDir, 'JsonFlow-' + LFileName), LJFResultStr);
        TFile.WriteAllText(TPath.Combine(LResultDir, 'XSuperObject-' + LFileName), LXsoResultStr);
      end;
    except
      on E: Exception do Log('Error on XSuperObject Serialization: ' + E.ClassName + ': ' + E.Message);
    end;

    Log('----------------------------');
  finally
    if Assigned(LJFSer) then LJFSer.Free;
  end;
end;

// =============================================================================
// Simple Class: TUser — escala 10K, 20K, 30K, 40K, 50K (igual ao Neon)
// =============================================================================
procedure TfrmBenchmark.BenchmarkSimpleClass;
var
  I, LScale: Integer;
  LFileName : string;
  LJsonStr  : string;
  LWrapped  : string;
  LEnvelope : TUsersEnvelope;
begin
  FSerJF.Clear;   FSerXSO.Clear;
  FDeserJF.Clear; FDeserXSO.Clear;
  memResults.Clear;

  for I := 0 to 4 do
  begin
    LScale    := USER_SCALE[I];
    LFileName := TPath.Combine(FDataPath, Format(USER_FILENAME, [LScale]));
    SetStatus(Format('Benchmarking TUser class (%dK items)...', [LScale]));

    if not TFile.Exists(LFileName) then
    begin
      Log('File not found: ' + LFileName);
      Continue;
    end;

    LJsonStr := TFile.ReadAllText(LFileName);
    LWrapped := '{"Items":' + LJsonStr + '}';
    Log(Format('Benchmarking TUser  (%dK items)', [LScale]));

    LEnvelope := TUsersEnvelope.Create;
    try
      BenchmarkFile(LEnvelope, LWrapped, Format('%dK', [LScale]));
    finally
      LEnvelope.Free;
    end;
  end;

  SetStatus('Finish Benchmarking TUser class');
  Log('Finish Benchmarking TUser class');
  Log('----------------------------');
end;

// =============================================================================
// Complex Class: TCustomer — escala 1K, 2K, 3K, 4K, 5K (igual ao Neon)
// =============================================================================
procedure TfrmBenchmark.BenchmarkComplexClass;
var
  I, LScale: Integer;
  LFileName : string;
  LJsonStr  : string;
  LWrapped  : string;
  LEnvelope : TCustomersEnvelope;
begin
  FSerJF.Clear;   FSerXSO.Clear;
  FDeserJF.Clear; FDeserXSO.Clear;
  memResults.Clear;

  for I := 0 to 4 do
  begin
    LScale    := CUST_SCALE[I];
    LFileName := TPath.Combine(FDataPath, Format(CUST_FILENAME, [LScale]));
    SetStatus(Format('Benchmarking TCustomer class (%dK items)...', [LScale]));

    if not TFile.Exists(LFileName) then
    begin
      Log('File not found: ' + LFileName);
      Continue;
    end;

    LJsonStr := TFile.ReadAllText(LFileName);
    LWrapped := '{"Items":' + LJsonStr + '}';
    Log(Format('Benchmarking TCustomer (%dK items)', [LScale]));

    LEnvelope := TCustomersEnvelope.Create;
    try
      BenchmarkFile(LEnvelope, LWrapped, Format('%dK', [LScale]));
    finally
      LEnvelope.Free;
    end;
  end;

  SetStatus('Finish Benchmarking TCustomer class');
  Log('Finish Benchmarking TCustomer class');
  Log('----------------------------');
end;

procedure TfrmBenchmark.btnStartClick(Sender: TObject);
begin
  btnStart.Enabled := False;
  try
    if rdSimple.Checked then
      BenchmarkSimpleClass
    else
      BenchmarkComplexClass;
  finally
    btnStart.Enabled := True;
  end;
end;

end.

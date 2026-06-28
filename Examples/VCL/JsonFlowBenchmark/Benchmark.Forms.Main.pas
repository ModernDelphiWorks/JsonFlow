unit Benchmark.Forms.Main;

// JsonFlow Benchmark - Neon-identical methodology
// Escala Simple  (TUser)     : 10K, 20K, 30K, 40K, 50K
// Escala Complex (TCustomer) :  1K,  2K,  3K,  4K,  5K


interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.Diagnostics,
  System.Generics.Collections, System.Math, System.UITypes,
  System.IOUtils, System.JSON,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  VCLTee.Chart, VCLTee.Series, VCLTee.TeEngine,
  REST.Json,
  JsonFlow.Serializer, JsonFlow.Reader, JsonFlow.Interfaces,
  Benchmark.Entities;

const
  DATA_PATH     = 'Data\Benchmarks';
  USER_FILENAME = 'users-%dk.json';
  CUST_FILENAME = 'customers-%dk.json';
  USER_SCALE: array[0..4] of Integer = (10, 20, 30, 40, 50);
  CUST_SCALE: array[0..4] of Integer = ( 1,  2,  3,  4,  5);

  // Cores iguais ao Neon: JsonFlow = azul escuro, TJSON = laranja
  COLOR_JSONFLOW: TColor = $00A46534;
  COLOR_TJSON   : TColor = $000A7AE6;

type
  TfrmBenchmark = class(TForm)
    pnlTop       : TPanel;
    rdSimple     : TRadioButton;
    rdComplex    : TRadioButton;
    chkSave      : TCheckBox;
    btnStart     : TButton;
    lblStatus    : TLabel;
    pnlBottom    : TPanel;
    pnlLogo      : TPanel;
    lblJson      : TLabel;
    lblFlow      : TLabel;
    lblSub       : TLabel;
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
    FSerTJ   : TBarSeries;
    FDeserJF : TBarSeries;
    FDeserTJ : TBarSeries;
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

{ TfrmBenchmark }

procedure TfrmBenchmark.FormCreate(Sender: TObject);
begin
  // Procura a pasta Data diretamente no mesmo diretorio do executavel
  FDataPath := TPath.Combine(
    TPath.GetDirectoryName(Application.ExeName),
    DATA_PATH);

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
  FSerJF := AddBar(FchtSer, 'JsonFlow', COLOR_JSONFLOW);
  FSerTJ := AddBar(FchtSer, 'TJSON',    COLOR_TJSON);

  FchtDeser := TChart.Create(Self);
  FchtDeser.Parent := pnlChartRight;
  FchtDeser.Align  := alClient;
  ConfigChart(FchtDeser, 'Deserialization');
  FDeserJF := AddBar(FchtDeser, 'JsonFlow', COLOR_JSONFLOW);
  FDeserTJ := AddBar(FchtDeser, 'TJSON',    COLOR_TJSON);
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
// BenchmarkFile — core do benchmark, IDÊNTICO ao Neon BenchmarkFile.
//
// AJsonWrapped = '{"Items": [...]}'   (já envolvido)
// AScaleLabel  = '1K', '2K', etc.
//
// Ordem igual ao Neon:
//   1. JsonFlow  Deser  → JsonFlow  Ser  → envelope.Clear
//   2. TJSON     Deser  → TJSON     Ser
// =============================================================================
procedure TfrmBenchmark.BenchmarkFile(AEnvelope: TEnvelope;
  const AJsonWrapped: string; AScaleLabel: string);
var
  LSW         : TStopwatch;
  LTJsonObj   : TJSONObject;
  LTJsonResult: TJSONValue;
  LJFReader   : IJSONReader;
  LJFElem     : IJSONElement;
  LJFSer      : TJSONSerializer;
  LJFResultStr: string;
begin
  LTJsonObj := nil;
  LJFSer := nil;
  try
    try
      // ----------- Pré-parse (NÃO cronometrado) ---------------------------------
      LTJsonObj := TJSONObject.ParseJSONValue(AJsonWrapped) as TJSONObject;
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
      Log(Format('  Deserialization (JsonFlow): %dms', [LSW.ElapsedMilliseconds]));
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
      Log(Format('  Serialization   (JsonFlow): %dms', [LSW.ElapsedMilliseconds]));
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
    // 3. TJSON — Deserialization
    // =========================================================================
    try
      LSW := TStopwatch.StartNew;
      if AEnvelope is TUsersEnvelope then
      begin
        var LTemp := TJson.JsonToObject<TUsersEnvelope>(LTJsonObj);
        TUsersEnvelope(AEnvelope).Items := LTemp.Items;
        LTemp.Items := []; // Transfere a propriedade dos objetos para evitar que sejam liberados
        LTemp.Free;
      end
      else if AEnvelope is TCustomersEnvelope then
      begin
        var LTemp := TJson.JsonToObject<TCustomersEnvelope>(LTJsonObj);
        TCustomersEnvelope(AEnvelope).Items := LTemp.Items;
        LTemp.Items := []; // Transfere a propriedade dos objetos
        LTemp.Free;
      end;
      LSW.Stop;
      FDeserTJ.Add(LSW.ElapsedMilliseconds, AScaleLabel, clDefault);
      Log(Format('  Deserialization (TJSON):    %dms', [LSW.ElapsedMilliseconds]));
    except
      on E: Exception do Log('Error on TJSON Deserialization: ' + E.ClassName + ': ' + E.Message);
    end;

    // =========================================================================
    // 4. TJSON — Serialization
    // =========================================================================
    try
      var LTJsonStr: string := '';
      LSW := TStopwatch.StartNew;
      if AEnvelope is TUsersEnvelope then
        LTJsonStr := TJson.ObjectToJsonString(TUsersEnvelope(AEnvelope))
      else if AEnvelope is TCustomersEnvelope then
        LTJsonStr := TJson.ObjectToJsonString(TCustomersEnvelope(AEnvelope));
      LSW.Stop;
      FSerTJ.Add(LSW.ElapsedMilliseconds, AScaleLabel, clDefault);
      Log(Format('  Serialization   (TJSON):    %dms', [LSW.ElapsedMilliseconds]));

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
        TFile.WriteAllText(TPath.Combine(LResultDir, 'TJSON-' + LFileName), LTJsonStr);
      end;
    except
      on E: Exception do Log('Error on TJSON Serialization: ' + E.ClassName + ': ' + E.Message);
    end;

    Log('----------------------------');
  finally
    if Assigned(LTJsonObj) then LTJsonObj.Free;
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
  FSerJF.Clear;   FSerTJ.Clear;
  FDeserJF.Clear; FDeserTJ.Clear;
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
  FSerJF.Clear;   FSerTJ.Clear;
  FDeserJF.Clear; FDeserTJ.Clear;
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

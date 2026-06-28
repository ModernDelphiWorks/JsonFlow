unit Demo.Forms.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  System.Generics.Collections, Data.DB, FireDAC.Comp.Client, Datasnap.DBClient,
  JsonFlow.Interfaces, JsonFlow.Serializer, JsonFlow.Reader, JsonFlow.Objects,
  JsonFlow.Arrays, JsonFlow.SchemaValidator,
  Demo.Frame.Configuration, Demo.JsonFlow.Entities, Demo.JsonFlow.Converters;

type
  TScenario = (scSimple, scRecords, scComplex, scDelphi, scDataSet, scCustomTypes, scValidation);

  TfrmMain = class(TForm)
    pnlSidebar: TPanel;
    pnlLogo: TPanel;
    btnSimple: TButton;
    btnRecords: TButton;
    btnComplex: TButton;
    btnDelphi: TButton;
    btnDataSet: TButton;
    btnCustomTypes: TButton;
    btnValidation: TButton;
    pnlRight: TPanel;
    pnlTopBar: TPanel;
    lblTitle: TLabel;
    pnlConfigParent: TPanel;
    frameConfig: TframeConfiguration;
    pnlContent: TPanel;
    pnlVisual: TPanel;
    lblVisualTitle: TLabel;
    lblImageStatus: TLabel;
    pnlImageContainer: TPanel;
    imgVisual: TImage;
    pnlJSONPanel: TPanel;
    pnlActions: TPanel;
    btnSerialize: TButton;
    btnDeserialize: TButton;
    btnValidate: TButton;
    memJSON: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnSimpleClick(Sender: TObject);
    procedure btnRecordsClick(Sender: TObject);
    procedure btnComplexClick(Sender: TObject);
    procedure btnDelphiClick(Sender: TObject);
    procedure btnDataSetClick(Sender: TObject);
    procedure btnCustomTypesClick(Sender: TObject);
    procedure btnValidationClick(Sender: TObject);
    procedure btnSerializeClick(Sender: TObject);
    procedure btnDeserializeClick(Sender: TObject);
    procedure btnValidateClick(Sender: TObject);
  private
    FActiveScenario: TScenario;
    FSimpleEntity: TSimpleEntity;
    FComplexEntity: TComplexEntity;
    FContainerEntity: TContainerEntity;
    FDataSet: TClientDataSet;
    FCustomTypesEntity: TCustomTypesEntity;
    procedure SetScenario(const AScenario: TScenario);
    procedure UpdateScenarioUI;
    procedure LoadVisualImage;
    procedure SetupValidationScenario;
    procedure ShowSimpleEntity(AEntity: TSimpleEntity);
    procedure ShowComplexEntity(AEntity: TComplexEntity);
    procedure ShowContainerEntity(AEntity: TContainerEntity);
  end;

var
  frmMain: TfrmMain;

implementation

uses
  System.TypInfo, JsonFlow.Converter.Dataset, Demo.JsonFlow.Middlewares;

{$R *.dfm}

procedure TfrmMain.FormCreate(Sender: TObject);
var
  LOptions: TJSONSerializerOptions;
begin
  FSimpleEntity := nil;
  FComplexEntity := nil;
  FContainerEntity := nil;
  
  // Populate FDataSet with mock data
  FDataSet := TClientDataSet.Create(Self);
  FDataSet.FieldDefs.Add('ID', ftInteger);
  FDataSet.FieldDefs.Add('Name', ftString, 50);
  FDataSet.FieldDefs.Add('Active', ftBoolean);
  FDataSet.CreateDataSet;
  FDataSet.AppendRecord([10, 'Delphi Developer', True]);
  FDataSet.AppendRecord([20, 'JsonFlow Enthusiast', False]);
  
  LOptions := TJSONSerializerOptions.Default;
  LOptions.ProcessAttributes := True;
  LOptions.IgnoreNullValues := True;
  frameConfig.SetOptions(LOptions);
  
  SetScenario(scSimple);
  LoadVisualImage;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FSimpleEntity.Free;
  FComplexEntity.Free;
  FContainerEntity.Free;
  FDataSet.Free;
  FCustomTypesEntity.Free;
end;

procedure TfrmMain.SetScenario(const AScenario: TScenario);
begin
  FActiveScenario := AScenario;
  UpdateScenarioUI;
end;

procedure TfrmMain.UpdateScenarioUI;
begin
  btnSimple.Font.Style := [];
  btnRecords.Font.Style := [];
  btnComplex.Font.Style := [];
  btnDelphi.Font.Style := [];
  btnDataSet.Font.Style := [];
  btnCustomTypes.Font.Style := [];
  btnValidation.Font.Style := [];
  
  btnSerialize.Enabled := True;
  btnDeserialize.Enabled := True;
  btnValidate.Enabled := False;

  case FActiveScenario of
    scSimple:
    begin
      btnSimple.Font.Style := [fsBold];
      lblTitle.Caption := 'Scenario: Simple Types Serialization';
      memJSON.Text := '// Click "Serialize" to generate JSON';
    end;
    scRecords:
    begin
      btnRecords.Font.Style := [fsBold];
      lblTitle.Caption := 'Scenario: Records && Sets Serialization';
      memJSON.Text := '// Click "Serialize" to generate JSON';
    end;
    scComplex:
    begin
      btnComplex.Font.Style := [fsBold];
      lblTitle.Caption := 'Scenario: Complex Objects && Collections';
      memJSON.Text := '// Click "Serialize" to generate JSON';
    end;
    scDelphi:
    begin
      btnDelphi.Font.Style := [fsBold];
      lblTitle.Caption := 'Scenario: Delphi Native Types (StringList, DataSet)';
      memJSON.Text := '// Click "Serialize" to generate JSON';
    end;
    scDataSet:
    begin
      btnDataSet.Font.Style := [fsBold];
      lblTitle.Caption := 'Scenario: DataSet Serialization (TClientDataSet)';
      memJSON.Text := '// Click "Serialize" to generate JSON';
    end;
    scCustomTypes:
    begin
      btnCustomTypes.Font.Style := [fsBold];
      lblTitle.Caption := 'Scenario: Custom Types via Middlewares (Nullable, Date Formats)';
      memJSON.Text :=
        '// Middlewares registered in this scenario:' + sLineBreak +
        '//   - TMiddlewareNullableInteger  : handles TNullableInteger (null or number)' + sLineBreak +
        '//   - TMiddlewareBrazilianDate    : accepts ISO8601 and DD/MM/YYYY formats' + sLineBreak +
        '//' + sLineBreak +
        '// Click "Serialize" to generate the JSON.';
    end;
    scValidation:
    begin
      btnValidation.Font.Style := [fsBold];
      btnSerialize.Enabled := False;
      btnDeserialize.Enabled := False;
      SetupValidationScenario;
    end;
  end;
end;

procedure TfrmMain.btnSimpleClick(Sender: TObject);
begin
  SetScenario(scSimple);
end;

procedure TfrmMain.btnRecordsClick(Sender: TObject);
begin
  SetScenario(scRecords);
end;

procedure TfrmMain.btnComplexClick(Sender: TObject);
begin
  SetScenario(scComplex);
end;

procedure TfrmMain.btnDelphiClick(Sender: TObject);
begin
  SetScenario(scDelphi);
end;

procedure TfrmMain.btnDataSetClick(Sender: TObject);
begin
  SetScenario(scDataSet);
end;

procedure TfrmMain.btnCustomTypesClick(Sender: TObject);
begin
  SetScenario(scCustomTypes);
end;

procedure TfrmMain.btnValidationClick(Sender: TObject);
begin
  SetScenario(scValidation);
end;

procedure TfrmMain.btnSerializeClick(Sender: TObject);
var
  LOptions: TJSONSerializerOptions;
  LSerializer: TJSONSerializer;
  LJsonElement: IJSONElement;
begin
  memJSON.Clear;
  LOptions := TJSONSerializerOptions.Default;
  frameConfig.GetOptions(LOptions);
  
  LSerializer := TJSONSerializer.Create(LOptions);
  try
    case FActiveScenario of
      scSimple:
      begin
        if not Assigned(FSimpleEntity) then
          FSimpleEntity := TSimpleEntity.Create;
        FSimpleEntity.GUID := TGUID.NewGuid;
        LJsonElement := LSerializer.FromObject(FSimpleEntity);
      end;
      scRecords:
      begin
        if not Assigned(FComplexEntity) then
          FComplexEntity := TComplexEntity.Create;
        LJsonElement := LSerializer.FromObject(FComplexEntity);
      end;
      scComplex:
      begin
        if not Assigned(FContainerEntity) then
          FContainerEntity := TContainerEntity.Create;
        LJsonElement := LSerializer.FromObject(FContainerEntity);
      end;
      scDelphi:
      begin
        if not Assigned(FComplexEntity) then
          FComplexEntity := TComplexEntity.Create;
        LJsonElement := LSerializer.FromObject(FComplexEntity);
      end;
      scDataSet:
      begin
        var LDatasetConverter: TJSONDatasetConverter;
        var LDatasetOptions: TDatasetToJSONOptions;
        LDatasetOptions := TDatasetToJSONOptions.Default;
        LDatasetConverter := TJSONDatasetConverter.Create(LDatasetOptions);
        try
          memJSON.Text := LDatasetConverter.DatasetToJSON(FDataSet);
          Exit;
        finally
          LDatasetConverter.Free;
        end;
      end;
      scCustomTypes:
      begin
        if not Assigned(FCustomTypesEntity) then
          FCustomTypesEntity := TCustomTypesEntity.Create;

        // Registra os middlewares ANTES de serializar
        // Eles interceptam os tipos que o Delphi não trata nativamente
        LSerializer.Middlewares.Add(TMiddlewareNullableInteger.Create);
        LSerializer.Middlewares.Add(TMiddlewareBrazilianDate.Create);

        LJsonElement := LSerializer.FromObject(FCustomTypesEntity);
      end;
    end;
    
    if Assigned(LJsonElement) then
      memJSON.Text := LJsonElement.AsJSON(True)
    else
      memJSON.Text := '// Serialization failed or returned nil';
  finally
    LSerializer.Free;
  end;
end;

procedure TfrmMain.btnDeserializeClick(Sender: TObject);
var
  LOptions: TJSONSerializerOptions;
  LSerializer: TJSONSerializer;
  LJsonStr: string;
  LReader: IJSONReader;
  LJsonElement: IJSONElement;
begin
  LJsonStr := memJSON.Text;
  if LJsonStr.Trim.IsEmpty or LJsonStr.StartsWith('//') then
  begin
    ShowMessage('Please serialize an object or paste a valid JSON string first!');
    Exit;
  end;

  LOptions := TJSONSerializerOptions.Default;
  frameConfig.GetOptions(LOptions);

  LSerializer := TJSONSerializer.Create(LOptions);
  try
    LReader := TJSONReader.Create;
    try
      LJsonElement := LReader.Read(LJsonStr);
      if not Assigned(LJsonElement) then
        raise Exception.Create('Invalid JSON string');

      memJSON.Lines.Add('');

      case FActiveScenario of
        scSimple:
        begin
          var LTempEntity := TSimpleEntity.Create;
          try
            LSerializer.ToObject(LJsonElement, LTempEntity);
            ShowSimpleEntity(LTempEntity);
          finally
            LTempEntity.Free;
          end;
        end;
        scRecords:
        begin
          var LTempEntity := TComplexEntity.Create;
          try
            LSerializer.ToObject(LJsonElement, LTempEntity);
            ShowComplexEntity(LTempEntity);
          finally
            LTempEntity.Free;
          end;
        end;
        scComplex:
        begin
          var LTempEntity := TContainerEntity.Create;
          try
            LSerializer.ToObject(LJsonElement, LTempEntity);
            ShowContainerEntity(LTempEntity);
          finally
            LTempEntity.Free;
          end;
        end;
        scDelphi:
        begin
          var LTempEntity := TComplexEntity.Create;
          try
            LSerializer.ToObject(LJsonElement, LTempEntity);
            ShowComplexEntity(LTempEntity);
          finally
            LTempEntity.Free;
          end;
        end;
        scDataSet:
        begin
          var LDatasetConverter: TJSONDatasetConverter;
          var LDatasetOptions: TDatasetToJSONOptions;
          LDatasetOptions := TDatasetToJSONOptions.Default;
          LDatasetConverter := TJSONDatasetConverter.Create(LDatasetOptions);
          try
            FDataSet.EmptyDataSet;
            LDatasetConverter.JSONToDataset(LJsonStr, FDataSet);
            ShowMessage('DataSet deserialized successfully! Total records: ' + IntToStr(FDataSet.RecordCount));
          finally
            LDatasetConverter.Free;
          end;
        end;
        scCustomTypes:
        begin
          var LTempEntity := TCustomTypesEntity.Create;
          try
            // Registra os mesmos middlewares para a deserialização
            LSerializer.Middlewares.Add(TMiddlewareNullableInteger.Create);
            LSerializer.Middlewares.Add(TMiddlewareBrazilianDate.Create);

            LSerializer.ToObject(LJsonElement, LTempEntity);

            // Exibe resultado — Age pode ser null ou número, Score é null
            var LAgeStr: string;
            if LTempEntity.Age.HasValue then
              LAgeStr := IntToStr(LTempEntity.Age.Value)
            else
              LAgeStr := 'null';

            var LScoreStr: string;
            if LTempEntity.Score.HasValue then
              LScoreStr := IntToStr(LTempEntity.Score.Value)
            else
              LScoreStr := 'null';

            memJSON.Lines.Add('');
            memJSON.Lines.Add('// === Resultado da Deserialização ===');
            memJSON.Lines.Add('// Name:      ' + LTempEntity.Name);
            memJSON.Lines.Add('// Age:       ' + LAgeStr + '  (TNullableInteger)');
            memJSON.Lines.Add('// Score:     ' + LScoreStr + '  (TNullableInteger — null)');
            memJSON.Lines.Add('// BirthDate: ' + DateToStr(LTempEntity.BirthDate));
            memJSON.Lines.Add('// UpdatedAt: ' + DateTimeToStr(LTempEntity.UpdatedAt));
          finally
            LTempEntity.Free;
          end;
        end;
      end;
    except
      on E: Exception do
        ShowMessage('Deserialization error: ' + E.Message);
    end;
  finally
    LSerializer.Free;
  end;
end;

procedure TfrmMain.btnValidateClick(Sender: TObject);
var
  LReader: IJSONReader;
  LElement: IJSONElement;
  LObj: IJSONObject;
  LSchemaObj, LDataObj: IJSONElement;
  LValidator: IJSONSchemaValidator;
  LSchemaStr, LDataStr: string;
  LError: TValidationError;
begin
  LReader := TJSONReader.Create;
  try
    LElement := LReader.Read(memJSON.Text);
    if not Assigned(LElement) or not Supports(LElement, IJSONObject, LObj) then
    begin
      ShowMessage('Error: Main text must be a valid JSON object containing "schema" and "data" keys.');
      Exit;
    end;

    if not LObj.ContainsKey('schema') or not LObj.ContainsKey('data') then
    begin
      ShowMessage('Error: JSON must contain "schema" and "data" keys.');
      Exit;
    end;

    LSchemaObj := LObj.GetValue('schema');
    LDataObj := LObj.GetValue('data');

    LSchemaStr := LSchemaObj.AsJSON;
    LDataStr := LDataObj.AsJSON;

    LValidator := TJSONSchemaValidator.Create(jsvDraft7);
    
    memJSON.Lines.Add('');
    memJSON.Lines.Add('--- SCHEMA VALIDATION RESULTS ---');
    if LValidator.Validate(LDataStr, LSchemaStr) then
    begin
      memJSON.Lines.Add('STATUS: VALID!');
      memJSON.Lines.Add('The JSON data conforms to the schema.');
    end
    else
    begin
      memJSON.Lines.Add('STATUS: INVALID!');
      memJSON.Lines.Add('Errors found:');
      for LError in LValidator.GetErrors do
      begin
        memJSON.Lines.Add(Format('- Path: "%s" | Keyword: "%s" | Error: %s',
          [LError.Path, LError.Keyword, LError.Message]));
      end;
    end;
    memJSON.Lines.Add('---------------------------------');
  except
    on E: Exception do
      ShowMessage('Validation Parse Error: ' + E.Message);
  end;
end;

procedure TfrmMain.ShowSimpleEntity(AEntity: TSimpleEntity);
begin
  memJSON.Lines.Add('--- DESERIALIZED OBJECT PROPERTIES ---');
  memJSON.Lines.Add('Id: ' + IntToStr(AEntity.Id));
  memJSON.Lines.Add('GUID: ' + GUIDToString(AEntity.GUID));
  memJSON.Lines.Add('Active: ' + BoolToStr(AEntity.Active, True));
  memJSON.Lines.Add('Price: ' + FloatToStr(AEntity.Price));
  memJSON.Lines.Add('Name: ' + AEntity.Name);
  memJSON.Lines.Add('Code: ' + AEntity.Code);
  memJSON.Lines.Add('CreatedAt: ' + DateTimeToStr(AEntity.CreatedAt));
  memJSON.Lines.Add('--------------------------------------');
end;

procedure TfrmMain.ShowComplexEntity(AEntity: TComplexEntity);
begin
  memJSON.Lines.Add('--- DESERIALIZED OBJECT PROPERTIES ---');
  memJSON.Lines.Add('Speed: ' + GetEnumName(TypeInfo(TEnumSpeed), Ord(AEntity.Speed)));
  memJSON.Lines.Add('SpeedSet contains Low: ' + BoolToStr(TEnumSpeed.Low in AEntity.SpeedSet, True));
  memJSON.Lines.Add('SpeedSet contains Medium: ' + BoolToStr(TEnumSpeed.Medium in AEntity.SpeedSet, True));
  memJSON.Lines.Add('SpeedSet contains High: ' + BoolToStr(TEnumSpeed.High in AEntity.SpeedSet, True));
  memJSON.Lines.Add('WeekDays contains 2 (Mon): ' + BoolToStr(2 in AEntity.WeekDays, True));
  memJSON.Lines.Add('IntArray Length: ' + IntToStr(Length(AEntity.IntArray)));
  if Length(AEntity.IntArray) > 0 then
    memJSON.Lines.Add('IntArray[0]: ' + IntToStr(AEntity.IntArray[0]));
  memJSON.Lines.Add('Vector X: ' + FloatToStr(AEntity.Vector.X) + ', Y: ' + FloatToStr(AEntity.Vector.Y));
  memJSON.Lines.Add('Point X: ' + FloatToStr(AEntity.Point.X) + ', Y: ' + FloatToStr(AEntity.Point.Y) + ', Z: ' + FloatToStr(AEntity.Point.Z));
  memJSON.Lines.Add('Font Name: ' + AEntity.Font.Name + ', Size: ' + IntToStr(AEntity.Font.Size));
  memJSON.Lines.Add('Notes Count: ' + IntToStr(AEntity.Notes.Count));
  if AEntity.Notes.Count > 0 then
    memJSON.Lines.Add('First Note: ' + AEntity.Notes[0]);
  if Assigned(AEntity.Data) then
    memJSON.Lines.Add('DataSet Record Count: ' + IntToStr(AEntity.Data.RecordCount));
  memJSON.Lines.Add('--------------------------------------');
end;

procedure TfrmMain.ShowContainerEntity(AEntity: TContainerEntity);
begin
  memJSON.Lines.Add('--- DESERIALIZED OBJECT PROPERTIES ---');
  memJSON.Lines.Add('Description: ' + AEntity.Description);
  memJSON.Lines.Add('TempData: "' + AEntity.TempData + '" (Should be empty due to JSONIgnore)');
  if Assigned(AEntity.MainItem) then
    memJSON.Lines.Add('MainItem Name: ' + AEntity.MainItem.Name);
  if Assigned(AEntity.NotesList) then
  begin
    memJSON.Lines.Add('NotesList Count: ' + IntToStr(AEntity.NotesList.Count));
    if AEntity.NotesList.Count > 0 then
      memJSON.Lines.Add('First Note Title: ' + AEntity.NotesList[0].Title + ' - ' + AEntity.NotesList[0].Content);
  end;
  if Assigned(AEntity.NotesDict) then
    memJSON.Lines.Add('NotesDict Count: ' + IntToStr(AEntity.NotesDict.Count));
  memJSON.Lines.Add('--------------------------------------');
end;

procedure TfrmMain.SetupValidationScenario;
begin
  lblTitle.Caption := 'Scenario: Schema Validation (Draft 7)';
  btnValidate.Enabled := True;
  
  memJSON.Text := 
    '{' + sLineBreak +
    '  "schema": {' + sLineBreak +
    '    "$schema": "http://json-schema.org/draft-07/schema#",' + sLineBreak +
    '    "type": "object",' + sLineBreak +
    '    "properties": {' + sLineBreak +
    '      "id": { "type": "integer" },' + sLineBreak +
    '      "name": { "type": "string", "minLength": 3 },' + sLineBreak +
    '      "price": { "type": "number", "minimum": 0.0 }' + sLineBreak +
    '    },' + sLineBreak +
    '    "required": ["id", "name", "price"]' + sLineBreak +
    '  },' + sLineBreak +
    '  "data": {' + sLineBreak +
    '    "id": 42,' + sLineBreak +
    '    "name": "Je",' + sLineBreak +
    '    "price": -10.5' + sLineBreak +
    '  }' + sLineBreak +
    '}';
end;

procedure TfrmMain.LoadVisualImage;
var
  LAppPath: string;
  LImagePath: string;
begin
  LAppPath := ExtractFilePath(ParamStr(0));
  
  LImagePath := LAppPath + 'assets\jsonflow_diff.png';
  if not FileExists(LImagePath) then
    LImagePath := LAppPath + 'assets\jsonflow_logo.png';
    
  if not FileExists(LImagePath) then
  begin
    LImagePath := ExpandFileName(LAppPath + '..\..\assets\jsonflow_diff.png');
    if not FileExists(LImagePath) then
      LImagePath := ExpandFileName(LAppPath + '..\..\assets\jsonflow_logo.png');
  end;
  
  if FileExists(LImagePath) then
  begin
    try
      imgVisual.Picture.LoadFromFile(LImagePath);
      lblImageStatus.Caption := 'Loaded visual schema: ' + ExtractFileName(LImagePath);
      lblImageStatus.Font.Color := clGreen;
    except
      on E: Exception do
      begin
        lblImageStatus.Caption := 'Error loading image: ' + E.Message;
        lblImageStatus.Font.Color := clRed;
      end;
    end;
  end;
end;

end.

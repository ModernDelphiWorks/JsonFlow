unit Demo.JsonFlow.Entities;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  Data.DB,
  FireDAC.Comp.Client,
  Vcl.Graphics,
  JsonFlow.Serializer.Attributes,
  Demo.JsonFlow.Converters,
  Demo.JsonFlow.Middlewares;

type
  TEnumSpeed = (Low, Medium, High);
  TSetSpeed = set of TEnumSpeed;
  TSetWeekDays = set of 1..7;

  TMyRecord = record
    Name: string;
    Value: Integer;
  end;

  TVector3f = record
    X, Y, Z: Single;
  end;

  // Base Entity demonstrating inheritance
  TBaseEntity = class
  private
    FId: Integer;
    FGUID: TGUID;
  public
    constructor Create; virtual;
    property Id: Integer read FId write FId;
    [JSONConverter(TGUIDConverter)]
    property GUID: TGUID read FGUID write FGUID;
  end;

  // Simple Entity (Inherits from TBaseEntity)
  TSimpleEntity = class(TBaseEntity)
  private
    FActive: Boolean;
    FPrice: Double;
    FName: string;
    FCode: Char;
    FCreatedAt: TDateTime;
  public
    constructor Create; override;
    property Active: Boolean read FActive write FActive;
    property Price: Double read FPrice write FPrice;
    property Name: string read FName write FName;
    property Code: Char read FCode write FCode;
    property CreatedAt: TDateTime read FCreatedAt write FCreatedAt;
  end;

  // Complex Entity
  TComplexEntity = class
  private
    FSpeed: TEnumSpeed;
    FSpeedSet: TSetSpeed;
    FWeekDays: TSetWeekDays;
    FIntArray: TArray<Integer>;
    FStrArray: TArray<string>;
    FVector: TVector3f;
    FPoint: TPoint3D;
    FFont: TFont;
    FNotes: TStringList;
    FData: TDataSet;
  public
    constructor Create;
    destructor Destroy; override;

    property Speed: TEnumSpeed read FSpeed write FSpeed;
    [JSONConverter(TSetSpeedConverter)]
    property SpeedSet: TSetSpeed read FSpeedSet write FSpeedSet;
    [JSONConverter(TSetWeekDaysConverter)]
    property WeekDays: TSetWeekDays read FWeekDays write FWeekDays;
    property IntArray: TArray<Integer> read FIntArray write FIntArray;
    property StrArray: TArray<string> read FStrArray write FStrArray;
    [JSONConverter(TVector3fConverter)]
    property Vector: TVector3f read FVector write FVector;
    [JSONConverter(TPoint3DConverter)]
    property Point: TPoint3D read FPoint write FPoint;
    [JSONConverter(TFontConverter)]
    property Font: TFont read FFont write FFont;
    [JSONConverter(TStringListConverter)]
    property Notes: TStringList read FNotes write FNotes;
    [JSONConverter(TDataSetConverter)]
    property Data: TDataSet read FData write FData;
  end;

  // Nested Object
  TNoteItem = class
  private
    FTitle: string;
    FContent: string;
  public
    property Title: string read FTitle write FTitle;
    property Content: string read FContent write FContent;
  end;

  // Container Entity
  TContainerEntity = class
  private
    FMainItem: TSimpleEntity;
    FTempData: string;
    FDescription: string;
    FNotesList: TObjectList<TNoteItem>;
    FNotesDict: TObjectDictionary<string, TNoteItem>;
  public
    constructor Create;
    destructor Destroy; override;

    [JSONName('base_item')]
    property MainItem: TSimpleEntity read FMainItem write FMainItem;
    
    [JSONIgnore]
    property TempData: string read FTempData write FTempData;
    
    [JSONInclude(False, False)] // Ignore if null or empty
    property Description: string read FDescription write FDescription;
    
    [JSONConverter(TNoteItemListConverter)]
    property NotesList: TObjectList<TNoteItem> read FNotesList write FNotesList;
    
    [JSONConverter(TNoteItemDictionaryConverter)]
    property NotesDict: TObjectDictionary<string, TNoteItem> read FNotesDict write FNotesDict;
  end;

  // ---------------------------------------------------------------------------
  // Custom Types Entity — demonstra o uso de Middlewares
  //
  // Esta entidade possui campos que o Delphi não consegue serializar nativamente:
  //   • TNullableInteger — tipo Nullable customizado (sem suporte nativo no Delphi)
  //   • BirthDate (TDateTime) — serializado como ISO8601 pelo TMiddlewareBrazilianDate,
  //     mas aceita também formato DD/MM/YYYY na deserialização.
  //
  // Para que o JsonFlow consiga lidar com esses tipos, são registrados Middlewares
  // na instância do TJSONSerializer antes de chamar FromObject/ToObject.
  // ---------------------------------------------------------------------------
  TCustomTypesEntity = class
  private
    FName: string;
    FAge: TNullableInteger;    // Nullable: pode ter valor ou ser null no JSON
    FScore: TNullableInteger;  // Nullable: demonstra campo sem valor (null)
    FBirthDate: TDateTime;     // DateTime: aceita ISO8601 e DD/MM/YYYY
    FUpdatedAt: TDateTime;
  public
    constructor Create;
    property Name: string read FName write FName;
    property Age: TNullableInteger read FAge write FAge;
    property Score: TNullableInteger read FScore write FScore;
    property BirthDate: TDateTime read FBirthDate write FBirthDate;
    property UpdatedAt: TDateTime read FUpdatedAt write FUpdatedAt;
  end;

implementation

{ TCustomTypesEntity }

constructor TCustomTypesEntity.Create;
begin
  inherited Create;
  FName := 'Isaque Pinheiro';
  FAge  := TNullableInteger.From(32);    // tem valor → serializado como número
  FScore := TNullableInteger.Empty;      // sem valor → serializado como null
  FBirthDate := EncodeDate(1992, 3, 15);
  FUpdatedAt := Now;
end;

{ TBaseEntity }

constructor TBaseEntity.Create;
begin
  inherited Create;
  FId := 1;
  FGUID := TGUID.NewGuid;
end;

{ TSimpleEntity }

constructor TSimpleEntity.Create;
begin
  inherited Create;
  FActive := True;
  FPrice := 49.99;
  FName := 'Simple Entity Sample';
  FCode := 'S';
  FCreatedAt := Now;
end;

{ TComplexEntity }

constructor TComplexEntity.Create;
var
  LMemTable: TFDMemTable;
begin
  inherited Create;
  FSpeed := TEnumSpeed.Medium;
  FSpeedSet := [TEnumSpeed.Low, TEnumSpeed.High];
  FWeekDays := [2, 4, 6];
  
  SetLength(FIntArray, 3);
  FIntArray[0] := 100;
  FIntArray[1] := 200;
  FIntArray[2] := 300;

  SetLength(FStrArray, 2);
  FStrArray[0] := 'Delphi';
  FStrArray[1] := 'JsonFlow';

  FVector.X := 1.5;
  FVector.Y := 2.5;
  FVector.Z := 3.5;

  FPoint := TPoint3D.Create(10.1, 20.2, 30.3);

  FFont := TFont.Create;
  FFont.Name := 'Segoe UI';
  FFont.Size := 11;
  FFont.Color := clBlue;
  FFont.Style := [fsBold, fsItalic];

  FNotes := TStringList.Create;
  FNotes.Add('First line of notes.');
  FNotes.Add('Second line of notes.');

  // Initialize and populate a TFDMemTable safely
  FData := TFDMemTable.Create(nil);
  try
    TFDMemTable(FData).FieldDefs.Add('ID', ftInteger);
    TFDMemTable(FData).FieldDefs.Add('Description', ftString, 50);
    TFDMemTable(FData).FieldDefs.Add('Value', ftFloat);
    TFDMemTable(FData).CreateDataSet;
    
    TFDMemTable(FData).Append;
    TFDMemTable(FData).FieldByName('ID').AsInteger := 10;
    TFDMemTable(FData).FieldByName('Description').AsString := 'Item 1';
    TFDMemTable(FData).FieldByName('Value').AsFloat := 9.99;
    TFDMemTable(FData).Post;

    TFDMemTable(FData).Append;
    TFDMemTable(FData).FieldByName('ID').AsInteger := 20;
    TFDMemTable(FData).FieldByName('Description').AsString := 'Item 2';
    TFDMemTable(FData).FieldByName('Value').AsFloat := 19.99;
    TFDMemTable(FData).Post;
  except
    FreeAndNil(FData);
    raise;
  end;
end;

destructor TComplexEntity.Destroy;
begin
  FNotes.Free;
  FData.Free;
  FFont.Free;
  inherited;
end;

{ TContainerEntity }

constructor TContainerEntity.Create;
var
  LItem: TNoteItem;
begin
  inherited Create;
  FMainItem := TSimpleEntity.Create;
  FTempData := 'This should be ignored by the serializer';
  FDescription := 'A container class holding nested types';
  
  FNotesList := TObjectList<TNoteItem>.Create(True);
  
  LItem := TNoteItem.Create;
  try
    LItem.Title := 'Important';
    LItem.Content := 'Remember to write tests.';
    FNotesList.Add(LItem);
  except
    LItem.Free;
    raise;
  end;
  
  LItem := TNoteItem.Create;
  try
    LItem.Title := 'Todo';
    LItem.Content := 'Implement the modern VCL interface.';
    FNotesList.Add(LItem);
  except
    LItem.Free;
    raise;
  end;

  FNotesDict := TObjectDictionary<string, TNoteItem>.Create([doOwnsValues]);
  
  LItem := TNoteItem.Create;
  try
    LItem.Title := 'Config';
    LItem.Content := 'ProcessAttributes := True';
    FNotesDict.Add('key1', LItem);
  except
    LItem.Free;
    raise;
  end;
end;

destructor TContainerEntity.Destroy;
begin
  FNotesDict.Free;
  FNotesList.Free;
  FMainItem.Free;
  inherited;
end;

end.

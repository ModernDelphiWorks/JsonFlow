unit JsonFlow.TestsSerializerCollections;

interface

uses
  DUnitX.TestFramework,
  System.Rtti,
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  JsonFlow.Interfaces,
  JsonFlow.Value,
  JsonFlow.Objects,
  JsonFlow.Arrays,
  JsonFlow.Reader,
  JsonFlow.Serializer;

type
  TCollItem = class
  private
    FName: String;
    FAge: Integer;
  public
    property Name: String read FName write FName;
    property Age: Integer read FAge write FAge;
  end;

  TCollOwner = class
  private
    FTitle: String;
    FItems: TObjectList<TCollItem>;
    FTags: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    property Title: String read FTitle write FTitle;
    property Items: TObjectList<TCollItem> read FItems write FItems;
    property Tags: TStringList read FTags write FTags;
  end;

  TPersonItem = class(TCollectionItem)
  private
    FName: String;
  published
    property Name: String read FName write FName;
  end;

  // Middleware que substitui o valor da propriedade 'Name' — usado para
  // provar que o caminho stream (SerializeToString) honra middlewares.
  TMaskNameMiddleware = class(TInterfacedObject, IEventMiddleware, IGetValueMiddleware)
  public
    procedure GetValue(const AInstance: TObject; const AProperty: TRttiProperty;
      var AValue: Variant; var ABreak: Boolean);
  end;

  [TestFixture]
  TJSONSerializerCollectionTests = class
  public
    [Test]
    procedure TestObjectListTopLevelDOM;
    [Test]
    procedure TestObjectListTopLevelStream;
    [Test]
    procedure TestObjectListPropertyBothPaths;
    [Test]
    procedure TestStringListProperty;
    [Test]
    procedure TestGenericListOfInteger;
    [Test]
    procedure TestClassicTList;
    [Test]
    procedure TestTCollection;
    [Test]
    procedure TestEmptyCollections;
    [Test]
    procedure TestRoundtripObjectListProperty;
    [Test]
    procedure TestRoundtripTopLevelObjectList;
    [Test]
    procedure TestDeserializeClassicTListRaises;
    [Test]
    procedure TestStreamHonorsGetMiddleware;
  end;

implementation

{ TCollOwner }

constructor TCollOwner.Create;
begin
  FItems := TObjectList<TCollItem>.Create(True);
  FTags := TStringList.Create;
end;

destructor TCollOwner.Destroy;
begin
  FTags.Free;
  FItems.Free;
  inherited;
end;

{ TMaskNameMiddleware }

procedure TMaskNameMiddleware.GetValue(const AInstance: TObject;
  const AProperty: TRttiProperty; var AValue: Variant; var ABreak: Boolean);
begin
  if AProperty.Name = 'Name' then
  begin
    AValue := '***';
    ABreak := True;
  end;
end;

function NewItem(const AName: String; AAge: Integer): TCollItem;
begin
  Result := TCollItem.Create;
  Result.Name := AName;
  Result.Age := AAge;
end;

{ TJSONSerializerCollectionTests }

procedure TJSONSerializerCollectionTests.TestObjectListTopLevelDOM;
var
  LSerializer: TJSONSerializer;
  LList: TObjectList<TCollItem>;
begin
  LSerializer := TJSONSerializer.Create;
  try
    LList := TObjectList<TCollItem>.Create(True);
    try
      LList.Add(NewItem('Ana', 30));
      LList.Add(NewItem('Bia', 25));
      Assert.AreEqual('[{"Name":"Ana","Age":30},{"Name":"Bia","Age":25}]',
        LSerializer.FromObject(LList).AsJSON);
    finally
      LList.Free;
    end;
  finally
    LSerializer.Free;
  end;
end;

procedure TJSONSerializerCollectionTests.TestObjectListTopLevelStream;
var
  LSerializer: TJSONSerializer;
  LList: TObjectList<TCollItem>;
begin
  LSerializer := TJSONSerializer.Create;
  try
    LList := TObjectList<TCollItem>.Create(True);
    try
      LList.Add(NewItem('Ana', 30));
      LList.Add(NewItem('Bia', 25));
      Assert.AreEqual('[{"Name":"Ana","Age":30},{"Name":"Bia","Age":25}]',
        LSerializer.SerializeToString(LList));
    finally
      LList.Free;
    end;
  finally
    LSerializer.Free;
  end;
end;

procedure TJSONSerializerCollectionTests.TestObjectListPropertyBothPaths;
var
  LSerializer: TJSONSerializer;
  LOwner: TCollOwner;
  LExpected: String;
begin
  LSerializer := TJSONSerializer.Create;
  try
    LOwner := TCollOwner.Create;
    try
      LOwner.Title := 'Time';
      LOwner.Items.Add(NewItem('Ana', 30));
      LOwner.Tags.Add('a');
      LOwner.Tags.Add('b');
      LExpected := '{"Title":"Time","Items":[{"Name":"Ana","Age":30}],"Tags":["a","b"]}';
      Assert.AreEqual(LExpected, LSerializer.FromObject(LOwner).AsJSON, 'caminho DOM');
      Assert.AreEqual(LExpected, LSerializer.SerializeToString(LOwner), 'caminho stream');
    finally
      LOwner.Free;
    end;
  finally
    LSerializer.Free;
  end;
end;

procedure TJSONSerializerCollectionTests.TestStringListProperty;
var
  LSerializer: TJSONSerializer;
  LStrings: TStringList;
begin
  LSerializer := TJSONSerializer.Create;
  try
    LStrings := TStringList.Create;
    try
      LStrings.Add('um');
      LStrings.Add('com "aspas"');
      Assert.AreEqual('["um","com \"aspas\""]', LSerializer.SerializeToString(LStrings));
      Assert.AreEqual('["um","com \"aspas\""]', LSerializer.FromObject(LStrings).AsJSON);
    finally
      LStrings.Free;
    end;
  finally
    LSerializer.Free;
  end;
end;

procedure TJSONSerializerCollectionTests.TestGenericListOfInteger;
var
  LSerializer: TJSONSerializer;
  LList: TList<Integer>;
begin
  LSerializer := TJSONSerializer.Create;
  try
    LList := TList<Integer>.Create;
    try
      LList.AddRange([1, 2, 3]);
      Assert.AreEqual('[1,2,3]', LSerializer.SerializeToString(LList));
      Assert.AreEqual('[1,2,3]', LSerializer.FromObject(LList).AsJSON);
    finally
      LList.Free;
    end;
  finally
    LSerializer.Free;
  end;
end;

procedure TJSONSerializerCollectionTests.TestClassicTList;
var
  LSerializer: TJSONSerializer;
  LList: TList;
  LItem: TCollItem;
begin
  LSerializer := TJSONSerializer.Create;
  try
    LList := TList.Create;
    LItem := NewItem('Ana', 30);
    try
      LList.Add(LItem);
      Assert.AreEqual('[{"Name":"Ana","Age":30}]', LSerializer.SerializeToString(LList));
    finally
      LItem.Free;
      LList.Free;
    end;
  finally
    LSerializer.Free;
  end;
end;

procedure TJSONSerializerCollectionTests.TestTCollection;
var
  LSerializer: TJSONSerializer;
  LColl: TCollection;
begin
  LSerializer := TJSONSerializer.Create;
  try
    LColl := TCollection.Create(TPersonItem);
    try
      TPersonItem(LColl.Add).Name := 'Ana';
      TPersonItem(LColl.Add).Name := 'Bia';
      Assert.AreEqual('[{"Name":"Ana"},{"Name":"Bia"}]',
        LSerializer.SerializeToString(LColl));
    finally
      LColl.Free;
    end;
  finally
    LSerializer.Free;
  end;
end;

procedure TJSONSerializerCollectionTests.TestEmptyCollections;
var
  LSerializer: TJSONSerializer;
  LList: TObjectList<TCollItem>;
  LStrings: TStringList;
begin
  LSerializer := TJSONSerializer.Create;
  try
    LList := TObjectList<TCollItem>.Create(True);
    LStrings := TStringList.Create;
    try
      Assert.AreEqual('[]', LSerializer.SerializeToString(LList));
      Assert.AreEqual('[]', LSerializer.FromObject(LStrings).AsJSON);
    finally
      LStrings.Free;
      LList.Free;
    end;
  finally
    LSerializer.Free;
  end;
end;

procedure TJSONSerializerCollectionTests.TestRoundtripObjectListProperty;
var
  LSerializer: TJSONSerializer;
  LReader: TJSONReader;
  LSource, LTarget: TCollOwner;
  LJson: String;
begin
  LSerializer := TJSONSerializer.Create;
  LReader := TJSONReader.Create;
  try
    LSource := TCollOwner.Create;
    LTarget := TCollOwner.Create;
    try
      LSource.Title := 'Time';
      LSource.Items.Add(NewItem('Ana', 30));
      LSource.Items.Add(NewItem('Bia', 25));
      LSource.Tags.Add('x');
      LJson := LSerializer.SerializeToString(LSource);
      Assert.IsTrue(LSerializer.ToObject(LReader.Read(LJson), LTarget));
      Assert.AreEqual('Time', LTarget.Title);
      Assert.AreEqual(2, LTarget.Items.Count);
      Assert.AreEqual('Ana', LTarget.Items[0].Name);
      Assert.AreEqual(30, LTarget.Items[0].Age);
      Assert.AreEqual('Bia', LTarget.Items[1].Name);
      Assert.AreEqual(1, LTarget.Tags.Count);
      Assert.AreEqual('x', LTarget.Tags[0]);
    finally
      LTarget.Free;
      LSource.Free;
    end;
  finally
    LReader.Free;
    LSerializer.Free;
  end;
end;

procedure TJSONSerializerCollectionTests.TestRoundtripTopLevelObjectList;
var
  LSerializer: TJSONSerializer;
  LSource, LTarget: TObjectList<TCollItem>;
begin
  LSerializer := TJSONSerializer.Create;
  try
    LSource := TObjectList<TCollItem>.Create(True);
    LTarget := TObjectList<TCollItem>.Create(True);
    try
      LSource.Add(NewItem('Ana', 30));
      LTarget.Add(NewItem('Velho', 99)); // deve ser limpo pelo roundtrip
      Assert.IsTrue(LSerializer.ToObject(LSerializer.FromObject(LSource), LTarget));
      Assert.AreEqual(1, LTarget.Count);
      Assert.AreEqual('Ana', LTarget[0].Name);
      Assert.AreEqual(30, LTarget[0].Age);
    finally
      LTarget.Free;
      LSource.Free;
    end;
  finally
    LSerializer.Free;
  end;
end;

procedure TJSONSerializerCollectionTests.TestDeserializeClassicTListRaises;
var
  LSerializer: TJSONSerializer;
  LList: TList;
  LArr: IJSONArray;
begin
  LSerializer := TJSONSerializer.Create;
  try
    LList := TList.Create;
    try
      LArr := TJSONArray.Create;
      Assert.WillRaise(
        procedure
        begin
          LSerializer.ToObject(LArr, LList);
        end, EArgumentException);
    finally
      LList.Free;
    end;
  finally
    LSerializer.Free;
  end;
end;

procedure TJSONSerializerCollectionTests.TestStreamHonorsGetMiddleware;
var
  LSerializer: TJSONSerializer;
  LItem: TCollItem;
begin
  LSerializer := TJSONSerializer.Create;
  try
    LSerializer.AddMiddleware(TMaskNameMiddleware.Create);
    LItem := NewItem('Ana', 30);
    try
      // Antes o caminho stream ignorava middlewares — só o DOM interceptava.
      Assert.AreEqual('{"Name":"***","Age":30}', LSerializer.SerializeToString(LItem), 'stream');
      Assert.AreEqual('{"Name":"***","Age":30}', LSerializer.FromObject(LItem).AsJSON, 'DOM');
    finally
      LItem.Free;
    end;
  finally
    LSerializer.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TJSONSerializerCollectionTests);

end.

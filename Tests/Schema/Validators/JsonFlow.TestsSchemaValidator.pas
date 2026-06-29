unit JsonFlow.TestsSchemaValidator;

interface

uses
  DUnitX.TestFramework,
  JsonFlow.Interfaces,
  JsonFlow.SchemaReader;

type
  [TestFixture]
  TJSONSchemaValidatorTests = class
  private
    FReader: TJSONSchemaReader;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure TestValidate_SimpleType;
    [Test]
    procedure TestValidate_RequiredField;
    [Test]
    procedure TestValidate_StringType;
    [Test]
    procedure TestValidate_NumberType;
    [Test]
    procedure TestValidate_ObjectType;
    [Test]
    procedure TestValidate_ArrayType;
    [Test]
    procedure TestValidate_LocalDefs;
    [Test]
    procedure TestValidate_LocalAnchor;
    [Test]
    procedure TestValidate_DeepNestedProperties;
    [Test]
    procedure TestValidate_LocalDefs_Permissive_AllowsUnknownAndMissing;
    // Testes para Combinadores
    [Test]
    procedure TestValidate_AllOf;
    [Test]
    procedure TestValidate_AnyOf;
    [Test]
    procedure TestValidate_OneOf;
    [Test]
    procedure TestValidate_Not;
    // Testes para Arrays
    [Test]
    procedure TestValidate_MinItems;
    [Test]
    procedure TestValidate_MaxItems;
    [Test]
    procedure TestValidate_Contains;
    [Test]
    procedure TestValidate_UniqueItems;
    // Testes para Strings
    [Test]
    procedure TestValidate_Format;
    [Test]
    procedure TestValidate_Pattern;
    // Testes para Estruturais
    [Test]
    procedure TestValidate_PatternProperties;
    [Test]
    procedure TestValidate_PropertyNames;
    [Test]
    procedure TestValidate_AdditionalProperties;
    // Testes para Propriedades de Objetos
    [Test]
    procedure TestValidate_MinProperties;
    [Test]
    procedure TestValidate_MaxProperties;
    // Testes para Números
    [Test]
    procedure TestValidate_ExclusiveMinimum;
    [Test]
    procedure TestValidate_ExclusiveMaximum;
    [Test]
    procedure TestValidate_MultipleOf;
    // Testes para Condicionais
    [Test]
    procedure TestValidate_IfThenElse;
    [Test]
    procedure TestValidate_Dependencies;
    [Test]
    procedure TestValidate_DefinitionsAlias;
    [Test]
    procedure TestValidate_SchemaPathDiagnostics;
    [Test]
    procedure TestValidate_OfficialSuiteDraft07;
    [Test]
    procedure TestValidate_ContentEncoding;
    [Test]
    procedure TestValidate_ContentMediaType;
    [Test]
    procedure TestValidate_MinMaxContains;
  end;

implementation

uses
  System.SysUtils, System.IOUtils, JsonFlow.TestsSchemaSuiteHelper;

procedure TJSONSchemaValidatorTests.Setup;
begin
  FReader := TJSONSchemaReader.Create;
end;

procedure TJSONSchemaValidatorTests.TearDown;
begin
  FreeAndNil(FReader);
end;

procedure TJSONSchemaValidatorTests.TestValidate_SimpleType;
var
  LSchema: String;
  LJson: String;
begin
  LSchema := '{"type": "string"}';
  FReader.LoadFromString(LSchema);
  LJson := '"hello"';
  Assert.IsTrue(FReader.Validate(LJson), 'Should validate string type correctly');
end;

procedure TJSONSchemaValidatorTests.TestValidate_RequiredField;
var
  LSchema: String;
  LJson: String;
begin
  LSchema := '{"type": "object", "properties": {"name": {"type": "string"}}, "required": ["name"]}';
  FReader.LoadFromString(LSchema);
  LJson := '{"name": "test"}';
  Assert.IsTrue(FReader.Validate(LJson), 'Should validate object with required field');
  
  LJson := '{}';
  Assert.IsFalse(FReader.Validate(LJson), 'Should fail validation when required field is missing');
end;

procedure TJSONSchemaValidatorTests.TestValidate_StringType;
var
  LSchema: String;
  LJson: String;
begin
  LSchema := '{"type": "string", "minLength": 3, "maxLength": 10}';
  FReader.LoadFromString(LSchema);
  LJson := '"hello"';
  Assert.IsTrue(FReader.Validate(LJson), 'Should validate string within length constraints');
  
  LJson := '"hi"';
  Assert.IsFalse(FReader.Validate(LJson), 'Should fail validation for string too short');
end;

procedure TJSONSchemaValidatorTests.TestValidate_NumberType;
var
  LSchema: String;
  LJson: String;
begin
  LSchema := '{"type": "number", "minimum": 0, "maximum": 100}';
  FReader.LoadFromString(LSchema);
  LJson := '50';
  Assert.IsTrue(FReader.Validate(LJson), 'Should validate number within range');
  
  LJson := '150';
  Assert.IsFalse(FReader.Validate(LJson), 'Should fail validation for number out of range');
end;

procedure TJSONSchemaValidatorTests.TestValidate_ObjectType;
var
  LSchema: String;
  LJson: String;
begin
  LSchema := '{"type": "object", "properties": {"name": {"type": "string"}, "age": {"type": "number"}}}';
  FReader.LoadFromString(LSchema);
  LJson := '{"name": "John", "age": 30}';
  Assert.IsTrue(FReader.Validate(LJson), 'Should validate object with correct properties');
end;

procedure TJSONSchemaValidatorTests.TestValidate_ArrayType;
var
  LSchema: String;
  LJson: String;
begin
  LSchema := '{"type": "array", "items": {"type": "string"}, "minItems": 1}';
  FReader.LoadFromString(LSchema);
  LJson := '["item1", "item2"]';
  Assert.IsTrue(FReader.Validate(LJson), 'Should validate array with string items');
  
  LJson := '[]';
  Assert.IsFalse(FReader.Validate(LJson), 'Should fail validation for empty array when minItems is 1');
end;

procedure TJSONSchemaValidatorTests.TestValidate_LocalDefs;
var
  LSchema: String;
  LJson: String;
begin
  LSchema := '{"$defs": {"person": {"type": "object", "properties": {"name": {"type": "string"}}}}, "$ref": "#/$defs/person"}';
  FReader.LoadFromString(LSchema);
  LJson := '{"name": "Alice"}';
  Assert.IsTrue(FReader.Validate(LJson), 'Should validate using local definitions');
end;

procedure TJSONSchemaValidatorTests.TestValidate_LocalAnchor;
var
  LSchema: String;
  LJson: String;
begin
  LSchema := '{"$anchor": "person", "type": "object", "properties": {"name": {"type": "string"}}}';
  FReader.LoadFromString(LSchema);
  LJson := '{"name": "Bob"}';
  Assert.IsTrue(FReader.Validate(LJson), 'Should validate using local anchor');
end;

procedure TJSONSchemaValidatorTests.TestValidate_DeepNestedProperties;
var
  LSchema: String;
  LJson: String;
begin
  LSchema := '{"type": "object", "properties": {"user": {"type": "object", "properties": {"profile": {"type": "object", "properties": {"name": {"type": "string"}}}}}}}';
  FReader.LoadFromString(LSchema);
  LJson := '{"user": {"profile": {"name": "Charlie"}}}';
  Assert.IsTrue(FReader.Validate(LJson), 'Should validate deep nested properties');
end;

procedure TJSONSchemaValidatorTests.TestValidate_LocalDefs_Permissive_AllowsUnknownAndMissing;
var
  LSchema, LJson: String;
begin
  LSchema := '{"$defs":{"stringType":{"type":"string"}},"properties":{"nome":{"$ref":"#/$defs/stringType"}}}';
  FReader.LoadFromString(LSchema);

  LJson := '{"nome":123}';
  Assert.IsFalse(FReader.Validate(LJson), 'Deveria falhar: "nome" deve ser string');
end;

// Testes para Combinadores
procedure TJSONSchemaValidatorTests.TestValidate_AllOf;
var
  LSchema, LJson: String;
begin
  LSchema := '{"allOf": [{"type": "string"}, {"minLength": 3}]}';
  FReader.LoadFromString(LSchema);
  
  LJson := '"hello"';
  Assert.IsTrue(FReader.Validate(LJson), 'Should validate when all schemas match');
  
  LJson := '"hi"';
  Assert.IsFalse(FReader.Validate(LJson), 'Should fail when one schema does not match');
end;

procedure TJSONSchemaValidatorTests.TestValidate_AnyOf;
var
  LSchema, LJson: String;
begin
  LSchema := '{"anyOf": [{"type": "string"}, {"type": "number"}]}';
  FReader.LoadFromString(LSchema);
  
  LJson := '"hello"';
  Assert.IsTrue(FReader.Validate(LJson), 'Should validate when at least one schema matches');
  
  LJson := '42';
  Assert.IsTrue(FReader.Validate(LJson), 'Should validate when at least one schema matches');
  
  LJson := 'true';
  Assert.IsFalse(FReader.Validate(LJson), 'Should fail when no schema matches');
end;

procedure TJSONSchemaValidatorTests.TestValidate_OneOf;
var
  LSchema, LJson: String;
begin
  LSchema := '{"oneOf": [{"type": "string", "maxLength": 5}, {"type": "string", "minLength": 10}]}';
  FReader.LoadFromString(LSchema);
  
  LJson := '"hi"';
  Assert.IsTrue(FReader.Validate(LJson), 'Should validate when exactly one schema matches');
  
  LJson := '"verylongstring"';
  Assert.IsTrue(FReader.Validate(LJson), 'Should validate when exactly one schema matches');
  
  LJson := '"medium"';
  Assert.IsFalse(FReader.Validate(LJson), 'Should fail when multiple schemas match');
end;

procedure TJSONSchemaValidatorTests.TestValidate_Not;
var
  LSchema, LJson: String;
begin
  LSchema := '{"not": {"type": "string"}}';
  FReader.LoadFromString(LSchema);
  
  LJson := '42';
  Assert.IsTrue(FReader.Validate(LJson), 'Should validate when schema does not match');
  
  LJson := '"hello"';
  Assert.IsFalse(FReader.Validate(LJson), 'Should fail when schema matches');
end;

// Testes para Arrays
procedure TJSONSchemaValidatorTests.TestValidate_Contains;
var
  LSchema, LJson: String;
begin
  LSchema := '{"type": "array", "contains": {"type": "string"}}';
  FReader.LoadFromString(LSchema);
  
  LJson := '[1, "hello", 3]';
  Assert.IsTrue(FReader.Validate(LJson), 'Should validate when array contains matching item');
  
  LJson := '[1, 2, 3]';
  Assert.IsFalse(FReader.Validate(LJson), 'Should fail when array does not contain matching item');
end;

procedure TJSONSchemaValidatorTests.TestValidate_UniqueItems;
var
  LSchema, LJson: String;
begin
  LSchema := '{"type": "array", "uniqueItems": true}';
  FReader.LoadFromString(LSchema);
  
  LJson := '[1, 2, 3]';
  Assert.IsTrue(FReader.Validate(LJson), 'Should validate when all items are unique');
  
  LJson := '[1, 2, 2]';
  Assert.IsFalse(FReader.Validate(LJson), 'Should fail when items are not unique');
end;

// Testes para Strings
procedure TJSONSchemaValidatorTests.TestValidate_Format;
var
  LSchema, LJson: String;
begin
  LSchema := '{"type": "string", "format": "email"}';
  FReader.LoadFromString(LSchema);
  
  LJson := '"test@example.com"';
  Assert.IsTrue(FReader.Validate(LJson), 'Should validate valid email format');
  
  LJson := '"invalid-email"';
  Assert.IsFalse(FReader.Validate(LJson), 'Should fail for invalid email format');
end;

procedure TJSONSchemaValidatorTests.TestValidate_Pattern;
var
  LSchema, LJson: String;
begin
  LSchema := '{"type": "string", "pattern": "^[A-Z][a-z]+$"}';
  FReader.LoadFromString(LSchema);
  
  LJson := '"Hello"';
  Assert.IsTrue(FReader.Validate(LJson), 'Should validate string matching pattern');
  
  LJson := '"hello"';
  Assert.IsFalse(FReader.Validate(LJson), 'Should fail for string not matching pattern');
end;

// Testes para Estruturais
procedure TJSONSchemaValidatorTests.TestValidate_PatternProperties;
var
  LSchema, LJson: String;
begin
  LSchema := '{"type": "object", "patternProperties": {"^S_": {"type": "string"}, "^I_": {"type": "number"}}}';
  FReader.LoadFromString(LSchema);
  
  LJson := '{"S_name": "John", "I_age": 30}';
  Assert.IsTrue(FReader.Validate(LJson), 'Should validate properties matching patterns');
  
  LJson := '{"S_name": 123}';
  Assert.IsFalse(FReader.Validate(LJson), 'Should fail when property does not match pattern schema');
end;

procedure TJSONSchemaValidatorTests.TestValidate_PropertyNames;
var
  LSchema, LJson: String;
begin
  LSchema := '{"type": "object", "propertyNames": {"pattern": "^[a-z]+$"}}';
  FReader.LoadFromString(LSchema);
  
  LJson := '{"name": "John", "age": 30}';
  Assert.IsTrue(FReader.Validate(LJson), 'Should validate when all property names match schema');
  
  LJson := '{"Name": "John"}';
  Assert.IsFalse(FReader.Validate(LJson), 'Should fail when property name does not match schema');
end;

procedure TJSONSchemaValidatorTests.TestValidate_AdditionalProperties;
var
  LSchema, LJson: String;
begin
  LSchema := '{"type": "object", "properties": {"name": {"type": "string"}}, "additionalProperties": false}';
  FReader.LoadFromString(LSchema);
  
  LJson := '{"name": "John"}';
  Assert.IsTrue(FReader.Validate(LJson), 'Should validate when no additional properties');
  
  LJson := '{"name": "John", "age": 30}';
  Assert.IsFalse(FReader.Validate(LJson), 'Should fail when additional properties are not allowed');
end;

// Testes para Condicionais
procedure TJSONSchemaValidatorTests.TestValidate_IfThenElse;
var
  LSchema, LJson: String;
begin
  LSchema := '{"type": "object", "if": {"properties": {"type": {"const": "premium"}}}, "then": {"required": ["premium_feature"]}, "else": {"required": ["basic_feature"]}}';
  FReader.LoadFromString(LSchema);
  
  LJson := '{"type": "premium", "premium_feature": true}';
  Assert.IsTrue(FReader.Validate(LJson), 'Should validate when if condition is true and then schema matches');
  
  LJson := '{"type": "basic", "basic_feature": true}';
  Assert.IsTrue(FReader.Validate(LJson), 'Should validate when if condition is false and else schema matches');
  
  LJson := '{"type": "premium"}';  Assert.IsFalse(FReader.Validate(LJson), 'Should fail when if condition is true but then schema does not match');
end;

// Testes para Arrays - MinItems/MaxItems
procedure TJSONSchemaValidatorTests.TestValidate_MinItems;
var
  LSchema, LJson: String;
begin
  LSchema := '{"type": "array", "minItems": 2}';
  FReader.LoadFromString(LSchema);
  
  LJson := '[1, 2, 3]';
  Assert.IsTrue(FReader.Validate(LJson), 'Should validate when array has minimum items');
  
  LJson := '[1]';
  Assert.IsFalse(FReader.Validate(LJson), 'Should fail when array has fewer than minimum items');
end;

procedure TJSONSchemaValidatorTests.TestValidate_MaxItems;
var
  LSchema, LJson: String;
begin
  LSchema := '{"type": "array", "maxItems": 3}';
  FReader.LoadFromString(LSchema);
  
  LJson := '[1, 2]';
  Assert.IsTrue(FReader.Validate(LJson), 'Should validate when array has maximum items or fewer');
  
  LJson := '[1, 2, 3, 4]';
  Assert.IsFalse(FReader.Validate(LJson), 'Should fail when array has more than maximum items');
end;

// Testes para Propriedades de Objetos
procedure TJSONSchemaValidatorTests.TestValidate_MinProperties;
var
  LSchema, LJson: String;
begin
  LSchema := '{"type": "object", "minProperties": 2}';
  FReader.LoadFromString(LSchema);
  
  LJson := '{"name": "John", "age": 30}';
  Assert.IsTrue(FReader.Validate(LJson), 'Should validate when object has minimum properties');
  
  LJson := '{"name": "John"}';
  Assert.IsFalse(FReader.Validate(LJson), 'Should fail when object has fewer than minimum properties');
end;

procedure TJSONSchemaValidatorTests.TestValidate_MaxProperties;
var
  LSchema, LJson: String;
begin
  LSchema := '{"type": "object", "maxProperties": 2}';
  FReader.LoadFromString(LSchema);
  
  LJson := '{"name": "John"}';
  Assert.IsTrue(FReader.Validate(LJson), 'Should validate when object has maximum properties or fewer');
  
  LJson := '{"name": "John", "age": 30, "city": "NYC"}';
  Assert.IsFalse(FReader.Validate(LJson), 'Should fail when object has more than maximum properties');
end;

// Testes para Números - Exclusive Min/Max e MultipleOf
procedure TJSONSchemaValidatorTests.TestValidate_ExclusiveMinimum;
var
  LSchema, LJson: String;
begin
  LSchema := '{"type": "number", "exclusiveMinimum": 10}';
  FReader.LoadFromString(LSchema);
  
  LJson := '15';
  Assert.IsTrue(FReader.Validate(LJson), 'Should validate when number is greater than exclusive minimum');
  
  LJson := '10';
  Assert.IsFalse(FReader.Validate(LJson), 'Should fail when number equals exclusive minimum');
  
  LJson := '5';
  Assert.IsFalse(FReader.Validate(LJson), 'Should fail when number is less than exclusive minimum');
end;

procedure TJSONSchemaValidatorTests.TestValidate_ExclusiveMaximum;
var
  LSchema, LJson: String;
begin
  LSchema := '{"type": "number", "exclusiveMaximum": 100}';
  FReader.LoadFromString(LSchema);
  
  LJson := '50';
  Assert.IsTrue(FReader.Validate(LJson), 'Should validate when number is less than exclusive maximum');
  
  LJson := '100';
  Assert.IsFalse(FReader.Validate(LJson), 'Should fail when number equals exclusive maximum');
  
  LJson := '150';
  Assert.IsFalse(FReader.Validate(LJson), 'Should fail when number is greater than exclusive maximum');
end;

procedure TJSONSchemaValidatorTests.TestValidate_MultipleOf;
var
  LSchema, LJson: String;
begin
  LSchema := '{"type": "number", "multipleOf": 5}';
  FReader.LoadFromString(LSchema);
  
  LJson := '15';
  Assert.IsTrue(FReader.Validate(LJson), 'Should validate when number is multiple of specified value');
  
  LJson := '7';
  Assert.IsFalse(FReader.Validate(LJson), 'Should fail when number is not multiple of specified value');
end;
procedure TJSONSchemaValidatorTests.TestValidate_Dependencies;
var
  LSchema, LJson: string;
begin
  // Dependências de Propriedade
  LSchema := '{"type": "object", "dependencies": {"credit_card": ["billing_address"]}}';
  FReader.LoadFromString(LSchema);
  
  LJson := '{"credit_card": "1234", "billing_address": "Main St"}';
  Assert.IsTrue(FReader.Validate(LJson), 'Property dependency satisfied');
  
  LJson := '{"credit_card": "1234"}';
  Assert.IsFalse(FReader.Validate(LJson), 'Property dependency missing dependent field');

  // Dependências de Esquema
  LSchema := '{"type": "object", "dependencies": {"billing_address": {"properties": {"billing_address": {"type": "string"}}}}}';
  FReader.LoadFromString(LSchema);
  
  LJson := '{"billing_address": "Main St"}';
  Assert.IsTrue(FReader.Validate(LJson), 'Schema dependency matches string');
  
  LJson := '{"billing_address": 123}';
  Assert.IsFalse(FReader.Validate(LJson), 'Schema dependency fails on invalid type');
end;

procedure TJSONSchemaValidatorTests.TestValidate_DefinitionsAlias;
var
  LSchema, LJson: string;
begin
  // Caso 1: Schema tem '$defs', mas o ref chama 'definitions'
  LSchema := '{"$defs": {"user": {"type": "string"}}, "properties": {"name": {"$ref": "#/definitions/user"}}}';
  FReader.LoadFromString(LSchema);
  LJson := '{"name": "Alice"}';
  Assert.IsTrue(FReader.Validate(LJson), 'Should resolve definitions alias inside $defs');

  // Caso 2: Schema tem 'definitions', mas o ref chama '$defs'
  LSchema := '{"definitions": {"user": {"type": "string"}}, "properties": {"name": {"$ref": "#/$defs/user"}}}';
  FReader.LoadFromString(LSchema);
  LJson := '{"name": "Alice"}';
  Assert.IsTrue(FReader.Validate(LJson), 'Should resolve $defs alias inside definitions');
end;

procedure TJSONSchemaValidatorTests.TestValidate_SchemaPathDiagnostics;
var
  LSchema, LJson: string;
  LErrors: TArray<TValidationError>;
begin
  LSchema := '{"type": "object", "properties": {"age": {"type": "integer", "minimum": 18}}}';
  FReader.LoadFromString(LSchema);
  LJson := '{"age": 15}';
  
  Assert.IsFalse(FReader.Validate(LJson));
  
  LErrors := FReader.GetErrors;
  Assert.IsTrue(Length(LErrors) > 0, 'Should return validation errors');
  
  Assert.AreEqual('/properties/age/minimum', LErrors[0].SchemaPath, 'SchemaPath should be complete');
end;

procedure TJSONSchemaValidatorTests.TestValidate_OfficialSuiteDraft07;
var
  LFixturePath: string;
begin
  LFixturePath := TPath.Combine(TPath.Combine(TPath.Combine(ExtractFilePath(ParamStr(0)), 'Fixtures'), 'Draft7'), 'dependencies.json');
  TJSONSchemaTestSuiteRunner.RunSuite(LFixturePath);
end;

procedure TJSONSchemaValidatorTests.TestValidate_ContentEncoding;
var
  LSchema, LJson: string;
begin
  // Base64
  LSchema := '{"type": "string", "contentEncoding": "base64"}';
  FReader.LoadFromString(LSchema);
  
  LJson := '"SGVsbG8gV29ybGQ="'; // "Hello World"
  Assert.IsTrue(FReader.Validate(LJson), 'Valid base64 string');
  
  LJson := '"invalid_base64_chars!@"';
  Assert.IsFalse(FReader.Validate(LJson), 'Invalid base64 string');

  // Hex
  LSchema := '{"type": "string", "contentEncoding": "hex"}';
  FReader.LoadFromString(LSchema);
  
  LJson := '"48656c6c6f"'; // "Hello" em hex
  Assert.IsTrue(FReader.Validate(LJson), 'Valid hex string');
  
  LJson := '"not_hex"';
  Assert.IsFalse(FReader.Validate(LJson), 'Invalid hex string');
end;

procedure TJSONSchemaValidatorTests.TestValidate_ContentMediaType;
var
  LSchema, LJson: string;
begin
  // application/json pura
  LSchema := '{"type": "string", "contentMediaType": "application/json"}';
  FReader.LoadFromString(LSchema);
  
  LJson := '"{\"name\": \"Alice\"}"'; // JSON stringificado
  Assert.IsTrue(FReader.Validate(LJson), 'Valid embedded JSON string');
  
  LJson := '"not a json string"';
  Assert.IsFalse(FReader.Validate(LJson), 'Invalid embedded JSON string');

  // application/json codificado em base64
  LSchema := '{"type": "string", "contentEncoding": "base64", "contentMediaType": "application/json"}';
  FReader.LoadFromString(LSchema);
  
  LJson := '"eyJuYW1lIjogIkFsaWNlIn0="'; // '{"name": "Alice"}' em base64
  Assert.IsTrue(FReader.Validate(LJson), 'Valid base64 JSON string');
  
  LJson := '"SGVsbG8="'; // 'Hello' em base64 (não é JSON)
  Assert.IsFalse(FReader.Validate(LJson), 'Invalid base64 JSON string (not JSON structure)');
end;

procedure TJSONSchemaValidatorTests.TestValidate_MinMaxContains;
var
  LSchema, LJson: string;
begin
  // minContains = 2
  LSchema := '{"type": "array", "contains": {"type": "number"}, "minContains": 2}';
  FReader.LoadFromString(LSchema);
  
  LJson := '[1, 2, "three"]';
  Assert.IsTrue(FReader.Validate(LJson), 'Valid minContains (2 matching numbers)');
  
  LJson := '[1, "two", "three"]';
  Assert.IsFalse(FReader.Validate(LJson), 'Invalid minContains (only 1 matching number)');

  // maxContains = 2
  LSchema := '{"type": "array", "contains": {"type": "number"}, "maxContains": 2}';
  FReader.LoadFromString(LSchema);
  
  LJson := '[1, 2, "three"]';
  Assert.IsTrue(FReader.Validate(LJson), 'Valid maxContains (2 matching numbers)');
  
  LJson := '[1, 2, 3]';
  Assert.IsFalse(FReader.Validate(LJson), 'Invalid maxContains (3 matching numbers)');
end;

initialization
  TDUnitX.RegisterTestFixture(TJSONSchemaValidatorTests);

end.


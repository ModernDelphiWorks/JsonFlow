{
  ------------------------------------------------------------------------------
  JsonFlow
  High-performance JSON serialization, dynamic manipulation, and Draft 7 Schema validation framework for Delphi and Lazarus.

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro

  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.
  ------------------------------------------------------------------------------
}

{$include ../../JsonFlow.inc}

unit JsonFlow.Interfaces;

interface

uses
  System.Rtti,
  SysUtils,
  Classes,
  TypInfo,
  TimeSpan,
  Generics.Collections;

const
  JSON_TRUE = 'true';
  JSON_FALSE = 'false';
  JSON_NULL = 'null';

type
  TJsonSchemaVersion = (
    jsvUnknown,          // Versão não especificada ou desconhecida
    jsvDraft3,           // Draft 3
    jsvDraft4,           // Draft 4
    jsvDraft6,           // Draft 6
    jsvDraft7,           // Draft 7
    jsvDraft201909,      // Draft 2019-09
    jsvDraft202012       // Draft 2020-12
  );

  // Tipos de regras de validação
  TRuleType = (rtPrimitive, rtComposite, rtStructural);

  // Status de validação
  TValidationStatus = (vsValid, vsInvalid, vsSkipped, vsCached);

  TValidationError = record
    Path: string;        // dataPath (JSON Pointer format)
    SchemaPath: string;  // schemaPath (JSON Pointer format) - localização no schema
    Message: string;
    FoundValue: string;
    ExpectedValue: string;
    Keyword: string;
    LineNumber: Integer;
    ColumnNumber: Integer;
    Context: string;
    function ToString: string;
  end;

  // Resultado de validação
  TValidationResult = record
    IsValid: Boolean;
    Errors: TArray<TValidationError>;
    Path: string;
    ExecutionTime: Int64;
    CacheHit: Boolean;

    class function Success(const APath: string = ''): TValidationResult; static;
    class function Failure(const APath: string; const AErrors: TArray<TValidationError>): TValidationResult; static;
  end;

  IJSONElement = interface
    ['{0056FF41-A87A-4C99-87E0-81A850C7160C}']
    function AsJSON(const AIdent: Boolean = False): String;
    procedure SaveToStream(AStream: TStream; const AIdent: Boolean = False);
    function Clone: IJSONElement;
    function TypeName: string;
  end;

  IJSONValue = interface(IJSONElement)
    ['{116CEFDB-D0C4-434D-B67D-1FA2960D925D}']
    function _GetAsBoolean: Boolean;
    procedure _SetAsBoolean(const AValue: Boolean);
    function _GetAsInteger: Int64;
    procedure _SetAsInteger(const AValue: Int64);
    function _GetAsFloat: Double;
    procedure _SetAsFloat(const AValue: Double);
    function _GetAsString: String;
    procedure _SetAsString(const AValue: String);
    function IsString: Boolean;
    function IsInteger: Boolean;
    function IsFloat: Boolean;
    function IsBoolean: Boolean;
    function IsNull: Boolean;
    function IsDate: Boolean;
    property AsBoolean: Boolean read _GetAsBoolean write _SetAsBoolean;
    property AsInteger: Int64 read _GetAsInteger write _SetAsInteger;
    property AsFloat: Double read _GetAsFloat write _SetAsFloat;
    property AsString: String read _GetAsString write _SetAsString;
  end;

  IJSONPair = interface
    ['{6ECC9DEE-0ED3-4549-8BB6-E9661D196819}']
    function _GetKey: String;
    procedure _SetKey(const AValue: String);
    function _GetValue: IJSONElement;
    procedure _SetValue(const AValue: IJSONElement);
    function AsJSON(const AIdent: Boolean = False): String;
    property Key: String read _GetKey write _SetKey;
    property Value: IJSONElement read _GetValue write _SetValue;
  end;

  IJSONObject = interface(IJSONElement)
    ['{E34C8F5A-CB24-4773-A7BB-97EC2FF27E5C}']
    function Add(const AKey: String; const AValue: IJSONElement): IJSONPair;
    function GetValue(const AKey: String): IJSONElement;
    function ContainsKey(const AKey: String): Boolean;
    function Count: Integer;
    procedure Remove(const AKey: String);
    procedure Clear;
    procedure ForEach(const ACallback: TProc<String, IJSONElement>);
    function Filter(const APredicate: TFunc<String, IJSONElement, Boolean>): IJSONObject;
    function Map(const ATransform: TFunc<String, IJSONElement, IJSONPair>): IJSONObject;
    function Pairs: TArray<IJSONPair>;
  end;

  IJSONArray = interface(IJSONElement)
    ['{39099A2A-817C-4A28-8CF6-33FA1B9993E4}']
    procedure Add(const AValue: IJSONElement);
    function GetItem(const AIndex: Integer): IJSONElement;
    function Count: Integer;
    procedure Remove(const AIndex: Integer);
    procedure Clear;
    procedure ForEach(const ACallback: TProc<IJSONElement>);
    function Filter(const APredicate: TFunc<IJSONElement, Boolean>): IJSONArray;
    function Map(const ATransform: TFunc<IJSONElement, IJSONElement>): IJSONArray;
    function Items: TArray<IJSONElement>;
    function Value(AIndex: Integer): IJSONElement;
  end;

  IJSONWriter = interface
    ['{89F0EE05-38B8-44EA-BA7D-81623545D5E4}']
    function Write(const AElement: IJSONElement; const AIdent: Boolean = False): String;
    procedure WriteToStream(const AElement: IJSONElement; AStream: TStream; const AIdent: Boolean = False);
    procedure OnLog(const ALogProc: TProc<String>);
  end;

  IJSONReader = interface
    ['{37250701-4F11-4A9A-A496-74DCD256C4D4}']
    function Read(const AJson: String): IJSONElement;
    function ReadFromStream(AStream: TStream): IJSONElement;
    procedure OnLog(const ALogProc: TProc<String>);
    procedure OnProgress(const AProgress: TProc<TObject, Single>);
  end;

  IEventMiddleware = interface
    ['{96402F5C-2C57-45AA-AD31-36900C5EA7DA}']
  end;

  IGetValueMiddleware = interface(IEventMiddleware)
    ['{C109A7D0-72BA-42F3-9596-F12556746B6E}']
    procedure GetValue(const AInstance: TObject; const AProperty: TRttiProperty;
      var AValue: Variant; var ABreak: Boolean);
  end;

  ISetValueMiddleware = interface(IEventMiddleware)
    ['{CE2F0793-959A-4747-861E-EC111DDBF01B}']
    procedure SetValue(const AInstance: TObject; const AProperty: TRttiProperty;
      var AValue: Variant; var ABreak: Boolean);
  end;

  IJSONSchemaReader = interface
    ['{A6E46C50-C61D-40E0-8468-5C73E06BA7ED}']
    function LoadFromFile(const AFileName: string): Boolean;
    function LoadFromString(const AJsonString: string): Boolean;
    function Validate(const AJson: string): Boolean; overload;
    function Validate(const AElement: IJSONElement): Boolean; overload;
    function GetErrors: TArray<TValidationError>;
    function GetVersion: TJsonSchemaVersion;
    function GetSchema: IJSONElement;
  end;

  IJSONSchemaValidator = interface
    ['{15151CFC-EFA6-4871-B372-30A8C8191617}']
    function GetErrors: TArray<TValidationError>;
    function GetVersion: TJsonSchemaVersion;
    function GetLastError: string;
    function Validate(const AJson: string; const AJsonSchema: string = ''): Boolean; overload;
    function Validate(const AElement: IJSONElement; const APath: string = ''): Boolean; overload;
    procedure ParseSchema(const ASchema: IJSONElement);
    procedure AddLog(const AMessage: string);
    procedure AddError(const APath, AMessage, AFound, AExpected, AKeyword: string;
      ALineNumber: Integer = -1; AColumnNumber: Integer = -1; AContext: string = '');
    procedure OnLog(const ALogProc: TProc<String>);
  end;

  IJSONSchemaRef = interface
    ['{788ABD14-5B00-4826-9A2A-02681D7C48A5}']
    function FetchReference(const ARef: string): IJSONElement;
  end;

  TSchemaNode = class;

  IJSONSchemaTrait = interface
    ['{6D56A900-BBB3-4876-99E5-8D55BCE86F8B}']
    procedure Parse(const ANode: IJSONObject);
    procedure SetNode(const ANode: TSchemaNode);
    function Validate(const ANode: IJSONElement; const APath: String;
      var AErrors: TList<TValidationError>): Boolean;
  end;

  TSchemaNode = class
  private
    FKeyword: String;
    FValue: IJSONElement;
    FChildren: TList<TSchemaNode>;
    FTrait: IJsonSchemaTrait;
    FDefs: TObjectDictionary<String, TSchemaNode>;
    FParent: TSchemaNode;
    FIsValidated: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    procedure ResetValidationState;
    property Keyword: String read FKeyword write FKeyword;
    property Value: IJSONElement read FValue write FValue;
    property Children: TList<TSchemaNode> read FChildren write FChildren;
    property Trait: IJsonSchemaTrait read FTrait write FTrait;
    property Defs: TObjectDictionary<String, TSchemaNode> read FDefs write FDefs;
    property Parent: TSchemaNode read FParent write FParent;
    property IsValidated: Boolean read FIsValidated write FIsValidated;
  end;

  TArrayHelper = class helper for TArray
    class function ToString<T>(const AArray: TArray<T>; const ASeparator: string = ', '): string; static;
  end;

  // Forward declaration
  IJSONComposer = interface;
  
  // Tipos para sintaxe fluente avançada
  TJSONObjectCallback = reference to procedure(const ABuilder: IJSONComposer);
  TJSONArrayCallback = reference to procedure(const ABuilder: IJSONComposer);
  
  // Context-aware types
  TContextInfo = record
    CurrentPath: String;
    ContextType: String; // 'object', 'array', 'root'
    Depth: Integer;
    ParentKey: String;
  end;
  
  // Smart suggestions types
  TJSONSuggestion = record
    SuggestionType: String; // 'key', 'value', 'method'
    Value: String;
    Description: String;
    Context: String;
  end;
  
  // Performance types
  TPerformanceInfo = record
    CreationTime: TDateTime;
    LastModified: TDateTime;
    OperationCount: Integer;
    MemoryUsage: Int64;
    BuildTime: TTimeSpan;
  end;

  // Interface para quebrar dependência circular entre Composer, Enhanced e Pool
  IJSONComposer = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    // Métodos básicos de construção
    function BeginObject(const AName: String = ''): IJSONComposer;
    function BeginArray(const AName: String = ''): IJSONComposer;
    function EndObject: IJSONComposer;
    function EndArray: IJSONComposer;
    
    // Métodos de adição de valores
    function Add(const AName: String; const AValue: String): IJSONComposer; overload;
    function Add(const AName: String; const AValue: Integer): IJSONComposer; overload;
    function Add(const AName: String; const AValue: Double): IJSONComposer; overload;
    function Add(const AName: String; const AValue: Boolean): IJSONComposer; overload;
    function Add(const AName: String; const AValue: TDateTime): IJSONComposer; overload;
    function Add(const AName: String; const AValue: IJSONElement): IJSONComposer; overload;
    function Add(const AName: String; const AValue: Char): IJSONComposer; overload;
    function Add(const AName: String; const AValue: Variant): IJSONComposer; overload;
    function AddNull(const AName: String): IJSONComposer;
    function AddArray(const AName: String; const AValues: array of TValue): IJSONComposer;
    function AddJSON(const AName: String; const AJson: String): IJSONComposer;
    function Add(const AName: String; const AValues: TArray<Integer>): IJSONComposer; overload;
    function Add(const AName: String; const AValues: TArray<String>): IJSONComposer; overload;
    function Add(const AName: String; const AValues: TArray<Double>): IJSONComposer; overload;
    function Add(const AName: String; const AValues: TArray<Boolean>): IJSONComposer; overload;
    function Add(const AName: String; const AValues: TArray<TDateTime>): IJSONComposer; overload;
    function Add(const AName: String; const AValues: TArray<Char>): IJSONComposer; overload;
    function Add(const AName: String; const AValues: TArray<Variant>): IJSONComposer; overload;
    function Merge(const AElement: IJSONElement): IJSONComposer;
    function LoadJSON(const AJson: String): IJSONComposer;
    
    // Métodos de manipulação
    function SetValue(const APath: String; const AValue: Variant): IJSONComposer;
    function RemoveKey(const APath: String): IJSONComposer;
    function AddToArray(const APath: String; const AValue: Variant): IJSONComposer; overload;
    function AddToArray(const APath: String; const AElement: IJSONElement): IJSONComposer; overload;
    function AddToArray(const APath: String; const AValues: TArray<Variant>): IJSONComposer; overload;
    function MergeArray(const APath: String; const AValues: TArray<Variant>): IJSONComposer;
    function RemoveFromArray(const APath: String; const AIndex: Integer): IJSONComposer;
    function ReplaceArray(const APath: String; const AValues: TArray<Variant>): IJSONComposer;
    function AddObject(const APath: String; const AName: String): IJSONComposer;
    
    // Métodos de saída
    function AsJSON(const AIdent: Boolean = False): String;
    function ToJSON(const AIdent: Boolean = False): String;
    function ToElement: IJSONElement;
    function GetRoot: IJSONElement;
    
    // Métodos de controle
    function Clone: IJSONComposer;
    function Clear: IJSONComposer;
    function ForEach(const ACallback: TProc<String, IJSONElement>): IJSONComposer;
    procedure OnLog(const ALogProc: TProc<String>);
    procedure AddLog(const AMessage: String);
    
    // Métodos de conveniência
    function StringValue(const AName, AValue: String): IJSONComposer;
    function NumberValue(const AName: String; AValue: Double): IJSONComposer;
    function IntegerValue(const AName: String; AValue: Integer): IJSONComposer;
    function BooleanValue(const AName: String; AValue: Boolean): IJSONComposer;
    function NullValue(const AName: String): IJSONComposer;
    function DateTimeValue(const AName: String; AValue: TDateTime): IJSONComposer;
    
    // Sintaxe com callbacks
    function ObjectValue(const AName: String; const ACallback: TJSONObjectCallback): IJSONComposer;
    function ArrayValue(const AName: String; const ACallback: TJSONArrayCallback): IJSONComposer;
    
    // Context-aware features
    function NavigateTo(const APath: String): IJSONComposer;
    function GetCurrentPath: String;
    function GetContextInfo: TContextInfo;
    function EnableDebugMode(AEnabled: Boolean): IJSONComposer;
    function GetCompositionTrace: TArray<String>;
    
    // Smart suggestions
    function GetSuggestions(const AContext: String = ''): TArray<TJSONSuggestion>;
    function SuggestKeys: TArray<String>;
    function SuggestValues(const AKey: String): TArray<Variant>;
    function EnableRealTimeValidation(AEnabled: Boolean): IJSONComposer;
    function QuickValidate: Boolean;
    function ValidateStructure: TArray<String>;
    function IsValidJSON: Boolean;
    function GetValidationErrors: TArray<String>;
    
    // Performance e recursos avançados
    function GetPerformanceMetrics: TPerformanceInfo;
    function OptimizeMemory: IJSONComposer;
    function EnableLazyLoading(AEnabled: Boolean): IJSONComposer;
    function Benchmark(const AOperation: TProc): TTimeSpan;
  end;

implementation

function TValidationError.ToString: string;
begin
  Result := Format('Erro em "%s" (linha %d, coluna %d): %s. Encontrado: "%s", Esperado: "%s", Keyword: "%s". Schema: "%s", Contexto: "%s"',
    [Path, LineNumber, ColumnNumber, Message, FoundValue, ExpectedValue, Keyword, SchemaPath, Context]);
end;

{ TValidationResult }

class function TValidationResult.Success(const APath: string): TValidationResult;
begin
  Result.IsValid := True;
  SetLength(Result.Errors, 0);
  Result.Path := APath;
  Result.ExecutionTime := 0;
  Result.CacheHit := False;
end;

class function TValidationResult.Failure(const APath: string; const AErrors: TArray<TValidationError>): TValidationResult;
begin
  Result.IsValid := False;
  Result.Errors := AErrors;
  Result.Path := APath;
  Result.ExecutionTime := 0;
  Result.CacheHit := False;
end;

{ TArrayHelper }

class function TArrayHelper.ToString<T>(const AArray: TArray<T>; const ASeparator: string): string;
var
  LFor: Integer;
  LValue: TValue;
begin
  Result := '';
  for LFor := 0 to High(AArray) do
  begin
    if LFor > 0 then
      Result := Result + ASeparator;
    LValue := TValue.From<T>(AArray[LFor]);
    if LValue.TypeInfo = TypeInfo(TValue) then
      Result := Result + LValue.AsType<TValue>.AsString
    else
      Result := Result + LValue.ToString;
  end;
end;

{ TSchemaNode }

constructor TSchemaNode.Create;
begin
  FIsValidated := False;
  FChildren := TList<TSchemaNode>.Create;
  FDefs := TObjectDictionary<String, TSchemaNode>.Create([doOwnsValues]);
  FParent := nil;
end;

destructor TSchemaNode.Destroy;
var
  LChild: TSchemaNode;
begin
  // Liberar o trait antes de quebrar a referência
  if Assigned(FTrait) then
    FTrait := nil;
  
  // Liberar filhos
  for LChild in FChildren do
    LChild.Free;
  
  FChildren.Free;
  FDefs.Free;
  inherited;
end;

procedure TSchemaNode.ResetValidationState;
begin
  FIsValidated := False;
  for var LChild in Children do
    LChild.ResetValidationState;
end;

end.


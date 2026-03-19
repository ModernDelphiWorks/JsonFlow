{
  ------------------------------------------------------------------------------
  JsonFlow
  Fluent and expressive JSON manipulation API for Delphi.

  SPDX-License-Identifier: Apache-2.0
  Copyright (c) 2025-2026 Isaque Pinheiro

  Licensed under the Apache License, Version 2.0.
  See the LICENSE file in the project root for full license information.
  ------------------------------------------------------------------------------
}

{$include ../../JsonFlow.inc}

unit JsonFlow.SchemaComposer;

interface

uses
  System.Classes,
  System.SysUtils,
  System.Variants,
  System.IOUtils,
  System.Generics.Collections,
  JsonFlow.Interfaces,
  JsonFlow.Composer,
  JsonFlow.Objects,
  JsonFlow.Arrays;

type
  // Estrutura para sugestões fluentes
  TSmartSuggestion = record
    Keyword: string;
    Description: string;
    Priority: Integer;
    Category: string;
    DefaultValue: string;
    AllowedValues: TArray<string>;
  end;

  // Interface fluente para sugestões
  ISmartSuggestionBuilder = interface
    ['{B8E5F2A1-9C3D-4E6F-8A7B-1234567890AB}']
    function AddValidation(const AKeyword: string; APriority: Integer = 5; const ADefaultValue: string = ''): ISmartSuggestionBuilder;
    function AddStructure(const AKeyword: string; APriority: Integer = 5; const ADefaultValue: string = ''): ISmartSuggestionBuilder;
    function AddDocumentation(const AKeyword: string; APriority: Integer = 5; const ADefaultValue: string = ''): ISmartSuggestionBuilder;
    function AddMeta(const AKeyword: string; APriority: Integer = 5; const ADefaultValue: string = ''): ISmartSuggestionBuilder;
    function AddFormat(const AFormat: string; APriority: Integer = 7): ISmartSuggestionBuilder;
    function ForString: ISmartSuggestionBuilder;
    function ForNumber: ISmartSuggestionBuilder;
    function ForArray: ISmartSuggestionBuilder;
    function ForObject: ISmartSuggestionBuilder;
    function ForRoot: ISmartSuggestionBuilder;
    function WithPriority(APriority: Integer): ISmartSuggestionBuilder;
    function WithDefault(const AValue: string): ISmartSuggestionBuilder;
    function WithOptions(const AOptions: array of string): ISmartSuggestionBuilder;
    function Build: TArray<TSmartSuggestion>;
    function Count: Integer;
  end;

  // Implementação do builder fluente
  TSmartSuggestionBuilder = class(TInterfacedObject, ISmartSuggestionBuilder)
  private
    FSuggestions: TList<TSmartSuggestion>;
    FCurrentPriority: Integer;
    FCurrentDefault: string;
    FCurrentOptions: TArray<string>;
    procedure AddSuggestion(const AKeyword, ACategory: string; APriority: Integer; const ADefaultValue: string = '');
    procedure ResetCurrent;
  public
    constructor Create;
    destructor Destroy; override;
    function AddValidation(const AKeyword: string; APriority: Integer = 5; const ADefaultValue: string = ''): ISmartSuggestionBuilder;
    function AddStructure(const AKeyword: string; APriority: Integer = 5; const ADefaultValue: string = ''): ISmartSuggestionBuilder;
    function AddDocumentation(const AKeyword: string; APriority: Integer = 5; const ADefaultValue: string = ''): ISmartSuggestionBuilder;
    function AddMeta(const AKeyword: string; APriority: Integer = 5; const ADefaultValue: string = ''): ISmartSuggestionBuilder;
    function AddFormat(const AFormat: string; APriority: Integer = 7): ISmartSuggestionBuilder;
    function ForString: ISmartSuggestionBuilder;
    function ForNumber: ISmartSuggestionBuilder;
    function ForArray: ISmartSuggestionBuilder;
    function ForObject: ISmartSuggestionBuilder;
    function ForRoot: ISmartSuggestionBuilder;
    function WithPriority(APriority: Integer): ISmartSuggestionBuilder;
    function WithDefault(const AValue: string): ISmartSuggestionBuilder;
    function WithOptions(const AOptions: array of string): ISmartSuggestionBuilder;
    function Build: TArray<TSmartSuggestion>;
    function Count: Integer;
  end;

  // Factory para criação de builders
  TSuggestionFactory = class
  public
    class function NewBuilder: ISmartSuggestionBuilder;
    class function ForContext(const AContextType: string): ISmartSuggestionBuilder;
  end;

  TJSONSchemaComposer = class
  private
    FRoot: IJSONElement;
    FCurrent: IJSONElement;
    FRootSchema: IJSONElement;
    FLogProc: TProc<String>;
    FStack: TStack<IJSONElement>;
    FNameStack: TStack<String>;
    FCurrentContext: String;
    FContextStack: TStack<String>;
    FMetaSchema: IJSONElement;
    FKeywords: TList<String>;
    FContextRules: TObjectDictionary<String, TList<String>>;
    FSmartMode: Boolean;
    procedure _Pop;
    procedure _Log(const AMessage: String);
    procedure _Push(const AElement: IJSONElement; const AName: String);
    procedure _AddToJSONArray(AArray: IJSONArray; ASchema: IJSONElement; const AContext: String);
//    function _CloneCurrent: IJSONElement;
    function _ExtractRootSchema(const ASchema: IJSONElement): IJSONElement;
    function _EnsureObject: IJSONObject;
    function _EnsureArray(const AKey: String): IJSONArray;
    procedure _UpdateContext(const AKey: String);
    procedure _ValidateContext(const AMethod: String);
    procedure _BuildContextRules(const AMetaSchema: IJSONElement);
    procedure _ExtractKeywords(const AMetaSchema: IJSONElement);
  public
    constructor Create;
    destructor Destroy; override;
    procedure LoadMetaSchema(const AFilePath: String = 'json-schema.json');
    procedure EnableSmartMode(AEnabled: Boolean);
    procedure SaveToFile(const AFilePath: String; AIndent: Boolean = True);
    function SuggestNext: String;
    function Obj: TJSONSchemaComposer;
    function Arr: TJSONSchemaComposer;
    function EndObj: TJSONSchemaComposer;
    function EndArr: TJSONSchemaComposer;
    function Schema(const ACallback: TProc<TJSONSchemaComposer>): TJSONSchemaComposer;
    function Prop(const AName: String; const ACallback: TProc<TJSONSchemaComposer> = nil): TJSONSchemaComposer;
    function PatternProp(const APattern: String; const ACallback: TProc<TJSONSchemaComposer>): TJSONSchemaComposer;
    function Def(const AName: String; const ACallback: TProc<TJSONSchemaComposer>): TJSONSchemaComposer;
    function Add(const AKey: String; const AValue: Variant): TJSONSchemaComposer; overload;
    function Add(const AName: String; const AValues: TArray<Variant>): TJSONSchemaComposer; overload;
    function Add(const AName: String; const AValue: IJSONElement): TJSONSchemaComposer; overload;
    function Add(const AKey, AValue: String): TJSONSchemaComposer; overload;
    function RequiredFields(const AFields: array of String): TJSONSchemaComposer;
    function Typ(const AType: String): TJSONSchemaComposer;
    function PropType(const AName, AType: String; ARequired: Boolean = False): TJSONSchemaComposer;
    function DefSchema(const AName: String; const ASchema: IJSONElement): TJSONSchemaComposer;
    function Req(const AField: String): TJSONSchemaComposer;
    function PropRef(const APropertyName, ARefPath: String): TJSONSchemaComposer;
    function RefProp(const APropertyName, ADefinitionName: String): TJSONSchemaComposer;
    function Min(const AMinimum: Double): TJSONSchemaComposer;
    function Max(const AMaximum: Double): TJSONSchemaComposer;
    function Enum(const AValues: array of Variant): TJSONSchemaComposer;
    function Cst(const AValue: Variant): TJSONSchemaComposer;
    function Default(const AValue: Variant): TJSONSchemaComposer;
    function Title(const ATitle: String): TJSONSchemaComposer;
    function Desc(const ADescription: String): TJSONSchemaComposer;
    function MinLen(const AMinLength: Integer): TJSONSchemaComposer;
    function MaxLen(const AMaxLength: Integer): TJSONSchemaComposer;
    function Pattern(const APattern: String): TJSONSchemaComposer;
    function MultOf(const AMultipleOf: Double): TJSONSchemaComposer;
    function Format(const AFormat: String): TJSONSchemaComposer;
    function ExclMin(const AExclusiveMinimum: Double): TJSONSchemaComposer;
    function ExclMax(const AExclusiveMaximum: Double): TJSONSchemaComposer;
    function Items(const AItemSchema: IJSONElement): TJSONSchemaComposer;
    function MinItems(const AMinItems: Integer): TJSONSchemaComposer;
    function MaxItems(const AMaxItems: Integer): TJSONSchemaComposer;
    function Unique(const AUniqueItems: Boolean): TJSONSchemaComposer;
    function MinProps(const AMinProperties: Integer): TJSONSchemaComposer;
    function MaxProps(const AMaxProperties: Integer): TJSONSchemaComposer;
    function AddProps(const AAllow: Boolean; const ASchema: IJSONElement = nil): TJSONSchemaComposer;
    function IfThen(const AIfSchema: IJSONElement): TJSONSchemaComposer;
    function Thn(const AThenSchema: IJSONElement): TJSONSchemaComposer;
    function Els(const AElseSchema: IJSONElement): TJSONSchemaComposer;
    function AllOf(const ASchemas: array of IJSONElement): TJSONSchemaComposer;
    function AnyOf(const ASchemas: array of IJSONElement): TJSONSchemaComposer;
    function OneOf(const ASchemas: array of IJSONElement): TJSONSchemaComposer;
    function Neg(const ANotSchema: IJSONElement): TJSONSchemaComposer;
    function Comment(const AComment: String): TJSONSchemaComposer;
    function Examples(const AExamples: array of Variant): TJSONSchemaComposer;
    function Ref(const ARefPath: String): TJSONSchemaComposer;
    function SubSchema(AProc: TProc<TJSONSchemaComposer>): IJSONElement;
    function Validate(const AJSON: String; out AErrors: TArray<String>): Boolean;
    function Merge(const AElement: IJSONElement): TJSONSchemaComposer; reintroduce;
    function ToJSON(const AIndent: Boolean = False; const AClearAfter: Boolean = True): String;
    function ToElement: IJSONElement;
    function LoadJSON(const AJson: String): TJSONSchemaComposer;
    function Clear: TJSONSchemaComposer;
    procedure OnLog(const ALogProc: TProc<String>);
    
    // Métodos fluentes para sugestões
    function Suggestions: ISmartSuggestionBuilder;
    function SuggestionsFor(const AContextType: string): ISmartSuggestionBuilder;
    function GetSmartSuggestions(const AContext: string = ''): TArray<TSmartSuggestion>;
    function QuickValidate(const APartialJSON: string): Boolean;
  end;

implementation

uses
  JsonFlow.Writer,
  JsonFlow.Value,
  JsonFlow.Reader,
  JsonFlow.SchemaValidator;

constructor TJSONSchemaComposer.Create;
begin
  FStack := TStack<IJSONElement>.Create;
  FNameStack := TStack<String>.Create;
  FContextStack := TStack<String>.Create;
  FKeywords := TList<String>.Create;
  FContextRules := TObjectDictionary<String, TList<String>>.Create([doOwnsValues]);
  FCurrent := TJSONObject.Create;
  FRoot := FCurrent;
  FRootSchema := FCurrent;
  FCurrentContext := 'root';
  FSmartMode := False;
  LoadMetaSchema;
end;

destructor TJSONSchemaComposer.Destroy;
begin
  Clear;
  FContextRules.Free;
  FContextStack.Free;
  FNameStack.Free;
  FStack.Free;
  FKeywords.Free;
  inherited;
end;

procedure TJSONSchemaComposer._Log(const AMessage: String);
begin
  if Assigned(FLogProc) then
    FLogProc(AMessage);
end;

procedure TJSONSchemaComposer._Pop;
var
  LParent: IJSONElement;
  LObject: IJSONObject;
  LArray: IJSONArray;
  LName: String;
begin
  if FStack.Count > 0 then
  begin
    LParent := FStack.Pop;
    LName := FNameStack.Pop;
    if Supports(LParent, IJSONObject, LObject) then
    begin
      if LName <> '' then
        LObject.Add(LName, FCurrent)
      else
      if FStack.Count = 0 then
        FRoot := FCurrent;
      FCurrent := LParent;
    end
    else if Supports(LParent, IJSONArray, LArray) then
      LArray.Add(FCurrent);
    FCurrent := LParent;
    if FSmartMode and (FContextStack.Count > 0) then
      FCurrentContext := FContextStack.Pop;
  end
  else
  begin
    if FNameStack.Count > 0 then
      FNameStack.Pop;
    FCurrent := nil;
  end;
end;

procedure TJSONSchemaComposer._Push(const AElement: IJSONElement; const AName: String);
begin
  if Assigned(FCurrent) then
  begin
    FStack.Push(FCurrent);
    FNameStack.Push(AName);
  end;
  FCurrent := AElement;
  if not Assigned(FRoot) then
  begin
    FRoot := AElement;
    if AName <> '' then
      FNameStack.Push(AName);
  end;
end;

//function TJSONSchemaComposer._CloneCurrent: IJSONElement;
//begin
//  if Supports(FCurrent, IJSONObject, IJSONObject(Result)) then
//    Result := (FCurrent as IJSONObject).Clone
//  else
//    Result := TJSONObject.Create;
//end;

function TJSONSchemaComposer._ExtractRootSchema(const ASchema: IJSONElement): IJSONElement;
var
  LObject: IJSONObject;
begin
  if not Assigned(ASchema) then
    raise EInvalidOperation.Create('Schema cannot be nil');
  if Supports(ASchema, IJSONObject, LObject) and LObject.ContainsKey('root') then
  begin
    Result := LObject.GetValue('root');
    if Result = nil then
      raise EInvalidOperation.Create('Root element is nil in schema');
  end
  else
    Result := ASchema;
end;

function TJSONSchemaComposer._EnsureObject: IJSONObject;
begin
  if not Supports(FCurrent, IJSONObject, Result) then
    raise EInvalidOperation.Create('Current context must be an object');
end;

function TJSONSchemaComposer._EnsureArray(const AKey: String): IJSONArray;
var
  LValue: IJSONElement;
begin
  LValue := _EnsureObject.GetValue(AKey);
  if not Supports(LValue, IJSONArray, Result) then
  begin
    Result := TJSONArray.Create;
    _EnsureObject.Add(AKey, Result);
  end;
end;

procedure TJSONSchemaComposer.LoadMetaSchema(const AFilePath: String);
var
  LReader: TJSONReader;
begin
  if not TFile.Exists(AFilePath) then
  begin
    _Log('Aviso: Meta-schema n?o encontrado em ' + AFilePath + '. Usando regras b?sicas.');
    _BuildContextRules(nil);
    Exit;
  end;

  LReader := TJSONReader.Create;
  try
    FMetaSchema := LReader.Read(TFile.ReadAllText(AFilePath));
    _BuildContextRules(FMetaSchema);
    _ExtractKeywords(FMetaSchema);
  finally
    LReader.Free;
  end;
end;

procedure TJSONSchemaComposer.EnableSmartMode(AEnabled: Boolean);
begin
  FSmartMode := AEnabled;
  if FSmartMode and not Assigned(FMetaSchema) then
    LoadMetaSchema;
end;

procedure TJSONSchemaComposer.SaveToFile(const AFilePath: String; AIndent: Boolean);
begin
  TFile.WriteAllText(AFilePath, ToJSON(AIndent, False));
  _Log('Schema salvo em: ' + AFilePath);
end;

procedure TJSONSchemaComposer._ExtractKeywords(const AMetaSchema: IJSONElement);
var
  LObject: IJSONObject;
  LPair: IJSONPair;
  LProperties: IJSONObject;
  LDefs: IJSONObject;
begin
  FKeywords.Clear;
  if not Assigned(AMetaSchema) or not Supports(AMetaSchema, IJSONObject, LObject) then
  begin
    FKeywords.AddRange(['type', 'properties', 'items']);
    _Log('Meta-schema inv?lido. Usando keywords de fallback.');
    Exit;
  end;

  LProperties := LObject.GetValue('properties') as IJSONObject;
  if Assigned(LProperties) then
  begin
    for LPair in LProperties.Pairs do
    begin
      if FKeywords.Contains(LPair.Key) then
        _Log('Duplicidade detectada em properties: ' + LPair.Key)
      else
        FKeywords.Add(LPair.Key);
    end;
    _Log('Keywords extra?dos de "properties": ' + IntToStr(LProperties.Count));
  end;

  LDefs := LObject.GetValue('definitions') as IJSONObject;
  if Assigned(LDefs) then
  begin
    for LPair in LDefs.Pairs do
    begin
      if FKeywords.Contains(LPair.Key) then
        _Log('Duplicidade detectada em definitions: ' + LPair.Key)
      else
        FKeywords.Add(LPair.Key);
    end;
    _Log('Keywords extra?dos de "definitions": ' + IntToStr(LDefs.Count));
  end;

  if not FKeywords.Contains('type') then
    FKeywords.Add('type');

  _Log('Total de keywords extra?dos: ' + IntToStr(FKeywords.Count));
end;

procedure TJSONSchemaComposer._BuildContextRules(const AMetaSchema: IJSONElement);
var
  LList: TList<String>;
  LItem: String;
begin
  FContextRules.Clear;

  // Root
  LList := TList<String>.Create;
  LList.AddRange(['Obj', 'Arr', 'Typ', 'Def', 'Title', 'Desc', 'Comment', 'Add', 'DefSchema']);
  for LItem in LList do
    if LList.IndexOf(LItem) <> LList.LastIndexOf(LItem) then
      _Log('Duplicidade em root: ' + LItem);
  FContextRules.Add('root', LList);

  LList := TList<String>.Create;
  LList.AddRange(['Prop', 'Def', 'MinProps', 'MaxProps', 'AddProps', 'RequiredFields',
                  'IfThen', 'Thn', 'Els', 'AllOf', 'AnyOf', 'OneOf', 'Neg', 'Typ', 'Add', 'PropType', 'Req', 'DefSchema', 'PatternProp']);
  for LItem in LList do
    if LList.IndexOf(LItem) <> LList.LastIndexOf(LItem) then
      _Log('Duplicidade em object: ' + LItem);
  FContextRules.Add('object', LList);

  // Array
  LList := TList<String>.Create;
  LList.AddRange(['Items', 'MinItems', 'MaxItems', 'Unique', 'Typ', 'Add']);
  for LItem in LList do
    if LList.IndexOf(LItem) <> LList.LastIndexOf(LItem) then
      _Log('Duplicidade em array: ' + LItem);
  FContextRules.Add('array', LList);

  // Items
  LList := TList<String>.Create;
  LList.AddRange(['Typ', 'MinLen', 'MaxLen', 'Pattern', 'Enum', 'Cst', 'Default', 'Format',
                  'Min', 'Max', 'ExclMin', 'ExclMax', 'MultOf', 'Add', 'MinItems', 'MaxItems', 'Unique']);
  for LItem in LList do
    if LList.IndexOf(LItem) <> LList.LastIndexOf(LItem) then
      _Log('Duplicidade em items: ' + LItem);
  FContextRules.Add('items', LList);

  // String
  LList := TList<String>.Create;
  LList.AddRange(['MinLen', 'MaxLen', 'Pattern', 'Enum', 'Cst', 'Default', 'Format', 'Add']);
  for LItem in LList do
    if LList.IndexOf(LItem) <> LList.LastIndexOf(LItem) then
      _Log('Duplicidade em string: ' + LItem);
  FContextRules.Add('string', LList);

  // Number
  LList := TList<String>.Create;
  LList.AddRange(['Min', 'Max', 'ExclMin', 'ExclMax', 'MultOf', 'Cst', 'Default', 'Add']);
  for LItem in LList do
    if LList.IndexOf(LItem) <> LList.LastIndexOf(LItem) then
      _Log('Duplicidade em number: ' + LItem);
  FContextRules.Add('number', LList);
end;

procedure TJSONSchemaComposer._UpdateContext(const AKey: String);
begin
  if FSmartMode and (AKey <> '') then
  begin
    FContextStack.Push(FCurrentContext);
    FCurrentContext := AKey;
    _Log('Contexto atualizado para: ' + AKey);
  end;
end;

procedure TJSONSchemaComposer._ValidateContext(const AMethod: String);
var
  LAllowed: TList<String>;
begin
  if not FSmartMode then
    Exit;
  if FContextRules.TryGetValue(FCurrentContext, LAllowed) then
  begin
    if not LAllowed.Contains(AMethod) then
      raise EInvalidOperation.CreateFmt('M?todo "%s" n?o ? permitido no contexto "%s". Sugest?o: %s',
        [AMethod, FCurrentContext, TArray.ToString<string>(LAllowed.ToArray)]);
  end;
end;

function TJSONSchemaComposer.SuggestNext: String;
var
  LSuggestions: TArray<TSmartSuggestion>;
  LKeywords: TArray<String>;
  I: Integer;
  LRootObj: IJSONObject;
  LPair: IJSONPair;
  LAvailableKeywords: TList<String>;
begin
  if not FSmartMode or not Assigned(FMetaSchema) then
    Exit('Nenhuma sugest?o dispon?vel (modo inteligente desativado ou meta-schema ausente)');

  // Usa a nova sintaxe fluente para obter sugest?es
  LSuggestions := GetSmartSuggestions(FCurrentContext);
  
  if Length(LSuggestions) = 0 then
    Exit('Nenhuma sugest?o dispon?vel para o contexto atual');
  
  // Extrai apenas as palavras-chave das sugest?es
  SetLength(LKeywords, Length(LSuggestions));
  for I := 0 to High(LSuggestions) do
    LKeywords[I] := LSuggestions[I].Keyword;
  
  // Remove palavras-chave j? existentes no schema atual
  LAvailableKeywords := TList<String>.Create;
  try
    LAvailableKeywords.AddRange(LKeywords);
    
    if Supports(FRoot, IJSONObject, LRootObj) then
      for LPair in LRootObj.Pairs do
        LAvailableKeywords.Remove(LPair.Key);

    Result := TArray.ToString<String>(LAvailableKeywords.ToArray, ', ');
    _Log('Sugest?es para "' + FCurrentContext + '": ' + Result);
  finally
    LAvailableKeywords.Free;
  end;

  if Result = '' then
    Result := 'Nenhuma sugest?o dispon?vel para o contexto atual';
end;

function TJSONSchemaComposer.Obj: TJSONSchemaComposer;
begin
  _ValidateContext('Obj');
  _Push(TJSONObject.Create, '');
  if FRootSchema = nil then
    FRootSchema := FCurrent;
  Result := Self;
end;

function TJSONSchemaComposer.Arr: TJSONSchemaComposer;
begin
  _ValidateContext('Arr');
  _Push(TJSONArray.Create, '');
  if FRootSchema = nil then
    FRootSchema := FCurrent;
  Result := Self;
end;

function TJSONSchemaComposer.EndObj: TJSONSchemaComposer;
begin
  _Pop;
  Result := Self;
end;

function TJSONSchemaComposer.EndArr: TJSONSchemaComposer;
begin
  _Pop;
  Result := Self;
end;

function TJSONSchemaComposer.Schema(const ACallback: TProc<TJSONSchemaComposer>): TJSONSchemaComposer;
var
  LSubComposer: TJSONSchemaComposer;
begin
  _ValidateContext('Schema');
  LSubComposer := TJSONSchemaComposer.Create;
  try
    LSubComposer.Obj;
    ACallback(LSubComposer);
    LSubComposer.EndObj;
    FRoot := LSubComposer.ToElement;
    FCurrent := FRoot;
    if FSmartMode then
      _UpdateContext('root');
  finally
    LSubComposer.Free;
  end;
  Result := Self;
end;

function TJSONSchemaComposer.Prop(const AName: String; const ACallback: TProc<TJSONSchemaComposer> = nil): TJSONSchemaComposer;
var
  LSubComposer: TJSONSchemaComposer;
  LProps: IJSONObject;
begin
  _ValidateContext('Prop');
  LProps := _EnsureObject.GetValue('properties') as IJSONObject;
  if not Assigned(LProps) then
  begin
    LProps := TJSONObject.Create;
    _EnsureObject.Add('properties', LProps);
  end;

  if Assigned(ACallback) then
  begin
    LSubComposer := TJSONSchemaComposer.Create;
    try
      LSubComposer.Obj;
      ACallback(LSubComposer);
      LSubComposer.EndObj;
      LProps.Add(AName, LSubComposer.ToElement);
    finally
      LSubComposer.Free;
    end;
  end
  else
    PropType(AName, 'string');

  Result := Self;
end;

function TJSONSchemaComposer.Def(const AName: String; const ACallback: TProc<TJSONSchemaComposer>): TJSONSchemaComposer;
var
  LSubComposer: TJSONSchemaComposer;
begin
  _ValidateContext('Def');
  LSubComposer := TJSONSchemaComposer.Create;
  try
    LSubComposer.Obj;
    ACallback(LSubComposer);
    LSubComposer.EndObj;
    DefSchema(AName, LSubComposer.ToElement);
  finally
    LSubComposer.Free;
  end;
  Result := Self;
end;

function TJSONSchemaComposer.Add(const AKey: String; const AValue: Variant): TJSONSchemaComposer;
var
  LObject: IJSONObject;
begin
  _ValidateContext('Add');
  LObject := _EnsureObject;
  case VarType(AValue) and varTypeMask of
    varInteger: LObject.Add(AKey, TJSONValueInteger.Create(AValue));
    varSingle, varDouble: LObject.Add(AKey, TJSONValueFloat.Create(AValue));
    varBoolean: LObject.Add(AKey, TJSONValueBoolean.Create(AValue));
    varDate: LObject.Add(AKey, TJSONValueDateTime.Create(VarToStr(AValue), True));
    varEmpty, varNull: LObject.Add(AKey, TJSONValueNull.Create);
    else LObject.Add(AKey, TJSONValueString.Create(VarToStr(AValue)));
  end;
  Result := Self;
end;

function TJSONSchemaComposer.RequiredFields(const AFields: array of String): TJSONSchemaComposer;
var
  LField: String;
begin
  _ValidateContext('RequiredFields');
  for LField in AFields do
    Req(LField);
  Result := Self;
end;

function TJSONSchemaComposer.Typ(const AType: String): TJSONSchemaComposer;
var
  LDefs: IJSONObject;
  LSimpleTypes: IJSONObject;
  LEnum: IJSONArray;
  LValue: IJSONElement;
  LFor: Integer;
  LValidType: Boolean;
begin
  _ValidateContext('Typ');
  if FSmartMode and Assigned(FMetaSchema) then
  begin
    LDefs := (FMetaSchema as IJSONObject).GetValue('definitions') as IJSONObject;
    if Assigned(LDefs) then
    begin
      LSimpleTypes := LDefs.GetValue('simpleTypes') as IJSONObject;
      if Assigned(LSimpleTypes) then
      begin
        LEnum := LSimpleTypes.GetValue('enum') as IJSONArray;
        if Assigned(LEnum) then
        begin
          LValidType := False;
          for LFor := 0 to LEnum.Count - 1 do
          begin
            LValue := LEnum.Value(LFor);
            if Supports(LValue, IJSONValue) and ((LValue as IJSONValue).AsString = AType) then
            begin
              LValidType := True;
              Break;
            end;
          end;
          if not LValidType then
            _Log('Aviso: "' + AType + '" n?o ? um tipo v?lido no JSON Schema');
        end;
      end;
    end;
  end;
  Add('type', AType);
  _UpdateContext(AType);
  Result := Self;
end;

function TJSONSchemaComposer.PropType(const AName, AType: String; ARequired: Boolean = False): TJSONSchemaComposer;
var
  LProps: IJSONObject;
  LPropObj: IJSONObject;
begin
  _ValidateContext('PropType');
  LProps := _EnsureObject.GetValue('properties') as IJSONObject;
  if not Assigned(LProps) then
  begin
    LProps := TJSONObject.Create;
    _EnsureObject.Add('properties', LProps);
  end;
  LPropObj := TJSONObject.Create;
  LPropObj.Add('type', TJSONValueString.Create(AType));
  LProps.Add(AName, LPropObj);
  if ARequired then
    Req(AName);
  Result := Self;
end;

function TJSONSchemaComposer.DefSchema(const AName: String; const ASchema: IJSONElement): TJSONSchemaComposer;
var
  LDefs: IJSONObject;
begin
  _ValidateContext('DefSchema');
  if not Assigned(ASchema) then
    raise EInvalidOperation.Create('Definition schema cannot be nil');
  if AName.Trim.IsEmpty then
    raise EInvalidOperation.Create('Definition name cannot be empty');
  LDefs := _EnsureObject.GetValue('$defs') as IJSONObject;
  if not Assigned(LDefs) then
  begin
    LDefs := TJSONObject.Create;
    _EnsureObject.Add('$defs', LDefs);
  end;
  LDefs.Add(AName, ASchema);
  _Log('Added definition for: ' + AName);
  Result := Self;
end;

function TJSONSchemaComposer.Req(const AField: String): TJSONSchemaComposer;
var
  LArray: IJSONArray;
  LItem: IJSONValue;
  LFor: Integer;
  LExists: Boolean;
begin
  _ValidateContext('Req');
  if AField.Trim.IsEmpty then
    raise EInvalidOperation.Create('Required field name cannot be empty');
  LArray := _EnsureArray('required');
  LExists := False;
  for LFor := 0 to LArray.Count - 1 do
  begin
    if Supports(LArray.Value(LFor), IJSONValue, LItem) and (LItem.AsString = AField) then
    begin
      LExists := True;
      Break;
    end;
  end;
  if not LExists then
    LArray.Add(TJSONValueString.Create(AField));
  _Log('Added required field: ' + AField);
  Result := Self;
end;

function TJSONSchemaComposer.PropRef(const APropertyName, ARefPath: String): TJSONSchemaComposer;
var
  LProps: IJSONObject;
  LPropObj: IJSONObject;
begin
  _ValidateContext('PropRef');
  LProps := _EnsureObject.GetValue('properties') as IJSONObject;
  if not Assigned(LProps) then
  begin
    LProps := TJSONObject.Create;
    _EnsureObject.Add('properties', LProps);
  end;
  LPropObj := TJSONObject.Create;
  LPropObj.Add('$ref', TJSONValueString.Create(ARefPath));
  LProps.Add(APropertyName, LPropObj);
  Result := Self;
end;

function TJSONSchemaComposer.RefProp(const APropertyName, ADefinitionName: String): TJSONSchemaComposer;
begin
  _ValidateContext('RefProp');
  Result := PropRef(APropertyName, '#/$defs/' + ADefinitionName);
end;

function TJSONSchemaComposer.Min(const AMinimum: Double): TJSONSchemaComposer;
begin
  _ValidateContext('Min');
  Add('minimum', AMinimum);
  Result := Self;
end;

function TJSONSchemaComposer.Max(const AMaximum: Double): TJSONSchemaComposer;
begin
  _ValidateContext('Max');
  Add('maximum', AMaximum);
  Result := Self;
end;

function TJSONSchemaComposer.Enum(const AValues: array of Variant): TJSONSchemaComposer;
var
  LArray: TJSONArray;
  LFor: Integer;
begin
  _ValidateContext('Enum');
  LArray := TJSONArray.Create;
  for LFor := Low(AValues) to High(AValues) do
  begin
    case VarType(AValues[LFor]) and varTypeMask of
      varInteger: LArray.Add(TJSONValueInteger.Create(AValues[LFor]));
      varSingle, varDouble: LArray.Add(TJSONValueFloat.Create(AValues[LFor]));
      varBoolean: LArray.Add(TJSONValueBoolean.Create(AValues[LFor]));
      varDate: LArray.Add(TJSONValueDateTime.Create(VarToStr(AValues[LFor]), True));
      varEmpty, varNull: LArray.Add(TJSONValueNull.Create);
      else LArray.Add(TJSONValueString.Create(VarToStr(AValues[LFor])));
    end;
  end;
  Add('enum', LArray);
  Result := Self;
end;

function TJSONSchemaComposer.Cst(const AValue: Variant): TJSONSchemaComposer;
var
  LObject: IJSONObject;
begin
  _ValidateContext('Cst');
  LObject := _EnsureObject;
  case VarType(AValue) and varTypeMask of
    varInteger, varShortInt, varByte, varWord, varLongWord, varInt64:
      LObject.Add('const', TJSONValueInteger.Create(AValue));
    varSingle, varDouble:
      LObject.Add('const', TJSONValueFloat.Create(AValue));
    varBoolean:
      LObject.Add('const', TJSONValueBoolean.Create(AValue));
    varDate:
      LObject.Add('const', TJSONValueDateTime.Create(VarToStr(AValue), True));
    varEmpty, varNull:
      LObject.Add('const', TJSONValueNull.Create);
    else
      LObject.Add('const', TJSONValueString.Create(VarToStr(AValue)));
  end;
  Result := Self;
end;

function TJSONSchemaComposer.Default(const AValue: Variant): TJSONSchemaComposer;
begin
  _ValidateContext('Default');
  Add('default', AValue);
  Result := Self;
end;

function TJSONSchemaComposer.Title(const ATitle: String): TJSONSchemaComposer;
begin
  _ValidateContext('Title');
  Add('title', ATitle);
  Result := Self;
end;

function TJSONSchemaComposer.Desc(const ADescription: String): TJSONSchemaComposer;
begin
  _ValidateContext('Desc');
  Add('description', ADescription);
  Result := Self;
end;

function TJSONSchemaComposer.MinLen(const AMinLength: Integer): TJSONSchemaComposer;
begin
  _ValidateContext('MinLen');
  if AMinLength < 0 then
    raise EInvalidOperation.Create('MinLength cannot be negative');
  Add('minLength', AMinLength);
  Result := Self;
end;

function TJSONSchemaComposer.MaxLen(const AMaxLength: Integer): TJSONSchemaComposer;
begin
  _ValidateContext('MaxLen');
  if AMaxLength < 0 then
    raise EInvalidOperation.Create('MaxLength cannot be negative');
  Add('maxLength', AMaxLength);
  Result := Self;
end;

function TJSONSchemaComposer.Pattern(const APattern: String): TJSONSchemaComposer;
begin
  _ValidateContext('Pattern');
  if APattern.Trim.IsEmpty then
    raise EInvalidOperation.Create('Pattern cannot be empty');
  Add('pattern', APattern);
  Result := Self;
end;

function TJSONSchemaComposer.PatternProp(const APattern: String; const ACallback: TProc<TJSONSchemaComposer>): TJSONSchemaComposer;
var
  LSubComposer: TJSONSchemaComposer;
  LPatterns: IJSONObject;
begin
  _ValidateContext('PatternProp');
  if APattern.Trim.IsEmpty then
    raise EInvalidOperation.Create('Pattern cannot be empty');

  LPatterns := _EnsureObject.GetValue('patternProperties') as IJSONObject;
  if not Assigned(LPatterns) then
  begin
    LPatterns := TJSONObject.Create;
    _EnsureObject.Add('patternProperties', LPatterns);
  end;

  LSubComposer := TJSONSchemaComposer.Create;
  try
    LSubComposer.Obj;
    ACallback(LSubComposer);
    LSubComposer.EndObj;
    LPatterns.Add(APattern, LSubComposer.ToElement);
  finally
    LSubComposer.Free;
  end;

  Result := Self;
end;

function TJSONSchemaComposer.MultOf(const AMultipleOf: Double): TJSONSchemaComposer;
begin
  _ValidateContext('MultOf');
  if AMultipleOf <= 0 then
    raise EInvalidOperation.Create('MultipleOf must be greater than 0');
  Add('multipleOf', AMultipleOf);
  Result := Self;
end;

function TJSONSchemaComposer.Format(const AFormat: String): TJSONSchemaComposer;
begin
  _ValidateContext('Format');
  if AFormat.Trim.IsEmpty then
    raise EInvalidOperation.Create('Format cannot be empty');
  Add('format', AFormat);
  Result := Self;
end;

function TJSONSchemaComposer.ExclMin(const AExclusiveMinimum: Double): TJSONSchemaComposer;
begin
  _ValidateContext('ExclMin');
  Add('exclusiveMinimum', AExclusiveMinimum);
  Result := Self;
end;

function TJSONSchemaComposer.ExclMax(const AExclusiveMaximum: Double): TJSONSchemaComposer;
begin
  _ValidateContext('ExclMax');
  Add('exclusiveMaximum', AExclusiveMaximum);
  Result := Self;
end;

function TJSONSchemaComposer.Items(const AItemSchema: IJSONElement): TJSONSchemaComposer;
begin
  _ValidateContext('Items');
  if FSmartMode and (FCurrentContext <> 'array') then
    Typ('array');
  if not Assigned(AItemSchema) then
    raise EInvalidOperation.Create('Item schema cannot be nil');
  _EnsureObject.Add('items', _ExtractRootSchema(AItemSchema));
  _UpdateContext('items');
  Result := Self;
end;

function TJSONSchemaComposer.MinItems(const AMinItems: Integer): TJSONSchemaComposer;
begin
  _ValidateContext('MinItems');
  if AMinItems < 0 then
    raise EInvalidOperation.Create('MinItems cannot be negative');
  Add('minItems', AMinItems);
  Result := Self;
end;

function TJSONSchemaComposer.MaxItems(const AMaxItems: Integer): TJSONSchemaComposer;
begin
  _ValidateContext('MaxItems');
  if AMaxItems < 0 then
    raise EInvalidOperation.Create('MaxItems cannot be negative');
  Add('maxItems', AMaxItems);
  Result := Self;
end;

function TJSONSchemaComposer.Unique(const AUniqueItems: Boolean): TJSONSchemaComposer;
begin
  _ValidateContext('Unique');
  Add('uniqueItems', AUniqueItems);
  Result := Self;
end;

function TJSONSchemaComposer.MinProps(const AMinProperties: Integer): TJSONSchemaComposer;
begin
  _ValidateContext('MinProps');
  if AMinProperties < 0 then
    raise EInvalidOperation.Create('MinProperties cannot be negative');
  Add('minProperties', AMinProperties);
  Result := Self;
end;

function TJSONSchemaComposer.MaxProps(const AMaxProperties: Integer): TJSONSchemaComposer;
begin
  _ValidateContext('MaxProps');
  if AMaxProperties < 0 then
    raise EInvalidOperation.Create('MaxProperties cannot be negative');
  Add('maxProperties', AMaxProperties);
  Result := Self;
end;

function TJSONSchemaComposer.AddProps(const AAllow: Boolean; const ASchema: IJSONElement = nil): TJSONSchemaComposer;
begin
  _ValidateContext('AddProps');
  if AAllow and Assigned(ASchema) then
    _EnsureObject.Add('additionalProperties', _ExtractRootSchema(ASchema))
  else
    Add('additionalProperties', AAllow);
  Result := Self;
end;

function TJSONSchemaComposer.IfThen(const AIfSchema: IJSONElement): TJSONSchemaComposer;
begin
  _ValidateContext('IfThen');
  if not Assigned(AIfSchema) then
    raise EInvalidOperation.Create('If schema cannot be nil');
  _EnsureObject.Add('if', _ExtractRootSchema(AIfSchema));
  Result := Self;
end;

function TJSONSchemaComposer.Thn(const AThenSchema: IJSONElement): TJSONSchemaComposer;
begin
  _ValidateContext('Thn');
  if not Assigned(AThenSchema) then
    raise EInvalidOperation.Create('Then schema cannot be nil');
  _EnsureObject.Add('then', _ExtractRootSchema(AThenSchema));
  Result := Self;
end;

function TJSONSchemaComposer.Els(const AElseSchema: IJSONElement): TJSONSchemaComposer;
begin
  _ValidateContext('Els');
  if not Assigned(AElseSchema) then
    raise EInvalidOperation.Create('Else schema cannot be nil');
  _EnsureObject.Add('else', _ExtractRootSchema(AElseSchema));
  Result := Self;
end;

function TJSONSchemaComposer.AllOf(const ASchemas: array of IJSONElement): TJSONSchemaComposer;
var
  LArray: IJSONArray;
  LSchema: IJSONElement;
begin
  _ValidateContext('AllOf');
  LArray := TJSONArray.Create;
  for LSchema in ASchemas do
    _AddToJSONArray(LArray, LSchema, 'allOf');
  _EnsureObject.Add('allOf', LArray);
  Result := Self;
end;

function TJSONSchemaComposer.AnyOf(const ASchemas: array of IJSONElement): TJSONSchemaComposer;
var
  LArray: IJSONArray;
  LSchema: IJSONElement;
begin
  _ValidateContext('AnyOf');
  LArray := TJSONArray.Create;
  for LSchema in ASchemas do
    _AddToJSONArray(LArray, LSchema, 'anyOf');
  _EnsureObject.Add('anyOf', LArray);
  Result := Self;
end;

function TJSONSchemaComposer.OneOf(const ASchemas: array of IJSONElement): TJSONSchemaComposer;
var
  LArray: IJSONArray;
  LSchema: IJSONElement;
begin
  _ValidateContext('OneOf');
  LArray := TJSONArray.Create;
  for LSchema in ASchemas do
    _AddToJSONArray(LArray, LSchema, 'oneOf');
  _EnsureObject.Add('oneOf', LArray);
  Result := Self;
end;

function TJSONSchemaComposer.Neg(const ANotSchema: IJSONElement): TJSONSchemaComposer;
var
  LNotObject: IJSONObject;
begin
  _ValidateContext('Neg');
  if not Assigned(ANotSchema) then
    raise EInvalidOperation.Create('Not schema cannot be nil');
  if Supports(_ExtractRootSchema(ANotSchema), IJSONObject, LNotObject) then
    _EnsureObject.Add('not', LNotObject)
  else
    raise EInvalidOperation.Create('Not schema must resolve to an object');
  Result := Self;
end;

function TJSONSchemaComposer.Clear: TJSONSchemaComposer;
begin
  FRoot := nil;
  FCurrent := nil;
  FStack.Clear;
  FNameStack.Clear;
  if FSmartMode then
  begin
    FContextStack.Clear;
    FCurrentContext := 'root';
  end;
  Result := Self;
end;

function TJSONSchemaComposer.Comment(const AComment: String): TJSONSchemaComposer;
begin
  _ValidateContext('Comment');
  Add('$comment', AComment);
  Result := Self;
end;

function TJSONSchemaComposer.Examples(const AExamples: array of Variant): TJSONSchemaComposer;
var
  LArray: TJSONArray;
  LFor: Integer;
begin
  _ValidateContext('Examples');
  LArray := TJSONArray.Create;
  for LFor := Low(AExamples) to High(AExamples) do
    LArray.Add(TJSONValueString.Create(VarToStr(AExamples[LFor])));
  _EnsureObject.Add('examples', LArray);
  Result := Self;
end;

function TJSONSchemaComposer.Ref(const ARefPath: String): TJSONSchemaComposer;
begin
  _ValidateContext('Ref');
  if ARefPath.Trim.IsEmpty then
    raise EInvalidOperation.Create('Reference path cannot be empty');
  _EnsureObject.Remove('type');
  Add('$ref', ARefPath);
  _Log('Set reference to: ' + ARefPath);
  Result := Self;
end;

function TJSONSchemaComposer.Validate(const AJSON: String; out AErrors: TArray<String>): Boolean;
var
  LValidator: TJSONSchemaValidator;
  LReader: TJSONReader;
  LJSONElement: IJSONElement;
  LValidationErrors: TArray<TValidationError>;
  LFor: Integer;
begin
  SetLength(AErrors, 0);
  LReader := TJSONReader.Create;
  try
    LJSONElement := LReader.Read(AJSON);
    LValidator := TJSONSchemaValidator.Create(jsvDraft7);
    try
      LValidator.ParseSchema(FMetaSchema);
      Result := LValidator.Validate(ToElement, '');
      if not Result then
      begin
        LValidationErrors := LValidator.GetErrors;
        SetLength(AErrors, Length(LValidationErrors));
        for LFor := 0 to High(LValidationErrors) do
          AErrors[LFor] := LValidationErrors[LFor].Message + ' em ' + LValidationErrors[LFor].Path;
      end;
    finally
      LValidator.Free;
    end;
  finally
    LReader.Free;
  end;
end;

function TJSONSchemaComposer.ToJSON(const AIndent: Boolean; const AClearAfter: Boolean): String;
var
  LWriter: IJSONWriter;
  LRootObj: IJSONObject;
begin
  if Assigned(FCurrent) and (FStack.Count > 0) then
    raise EInvalidOperation.Create('JSON incomplete: unclosed object or array');

//  if FSmartMode and Assigned(FMetaSchema) then
//  begin
//    if not Validate(ToElement.AsJSON, LErrors) then
//      _Log('Valida??o contra meta-schema falhou: ' + TArray.ToString<String>(LErrors));
//  end;

  LWriter := TJSONWriter.Create;
  if Supports(FRoot, IJSONObject, LRootObj) then
    Result := LWriter.Write(LRootObj, AIndent)
  else
    Result := LWriter.Write(FRoot, AIndent);
  if AClearAfter then
    Clear;
end;

function TJSONSchemaComposer.ToElement: IJSONElement;
var
  LRootObject: IJSONObject;
  LRootSchemaObj: IJSONObject;
  LDefs: IJSONElement;
begin
  if not Assigned(FRoot) then
  begin
    _Log('FRoot is nil, initializing default root');
    FRoot := TJSONObject.Create;
  end;

  if Supports(FRoot, IJSONObject, LRootObject) then
  begin
    if Supports(FRootSchema, IJSONObject, LRootSchemaObj) then
    begin
      LDefs := LRootSchemaObj.GetValue('$defs');
      if Assigned(LDefs) and not LRootObject.ContainsKey('$defs') then
      begin
        LRootObject.Add('$defs', LDefs);
        _Log('Propagated $defs to FRoot: ' + LDefs.AsJSON);
      end;
    end;
  end;
  if Assigned(FCurrent) and (FStack.Count > 0) then
    raise EInvalidOperation.Create('JSON incomplete: unclosed object or array');
  Result := FRoot;
end;

function TJSONSchemaComposer.LoadJSON(const AJson: String): TJSONSchemaComposer;
var
  LReader: TJSONReader;
begin
  LReader := TJSONReader.Create;
  try
    Clear;
    FRoot := LReader.Read(AJson);
    FCurrent := FRoot;
  finally
    LReader.Free;
  end;
  Result := Self;
end;

procedure TJSONSchemaComposer._AddToJSONArray(AArray: IJSONArray; ASchema: IJSONElement; const AContext: String);
var
  LSubObject: IJSONObject;
begin
  if ASchema = nil then
    raise EInvalidOperation.Create('Schema cannot be nil for ' + AContext);
  _Log('Adding schema to ' + AContext + ' array');
  if Supports(_ExtractRootSchema(ASchema), IJSONObject, LSubObject) then
  begin
    _Log('Successfully added schema to ' + AContext + ' array');
    AArray.Add(LSubObject);
  end
  else
    raise EInvalidOperation.Create('Schema must resolve to an object for ' + AContext);
end;

function TJSONSchemaComposer.SubSchema(AProc: TProc<TJSONSchemaComposer>): IJSONElement;
var
  LSubSchema: TJSONSchemaComposer;
begin
  LSubSchema := TJSONSchemaComposer.Create;
  try
    LSubSchema.Obj;
    AProc(LSubSchema);
    LSubSchema.EndObj;
    Result := LSubSchema.ToElement;
  finally
    LSubSchema.Free;
  end;
end;

procedure TJSONSchemaComposer.OnLog(const ALogProc: TProc<String>);
begin
  FLogProc := ALogProc;
end;

function TJSONSchemaComposer.Add(const AName: String; const AValues: TArray<Variant>): TJSONSchemaComposer;
var
  LArray: TJSONArray;
  LFor: Integer;
begin
  _ValidateContext('Add');
  LArray := TJSONArray.Create;
  for LFor := 0 to Length(AValues) - 1 do
  begin
    case VarType(AValues[LFor]) and varTypeMask of
      varInteger, varShortInt, varByte, varWord, varLongWord: LArray.Add(TJSONValueInteger.Create(AValues[LFor]));
      varSingle, varDouble, varCurrency: LArray.Add(TJSONValueFloat.Create(AValues[LFor]));
      varBoolean: LArray.Add(TJSONValueBoolean.Create(AValues[LFor]));
      varDate: LArray.Add(TJSONValueDateTime.Create(VarToStr(AValues[LFor]), True));
      varEmpty, varNull: LArray.Add(TJSONValueNull.Create);
      else LArray.Add(TJSONValueString.Create(VarToStr(AValues[LFor])));
    end;
  end;
  Add(AName, LArray);
  Result := Self;
end;

function TJSONSchemaComposer.Add(const AName: String; const AValue: IJSONElement): TJSONSchemaComposer;
var
  LObject: IJSONObject;
  LArray: IJSONArray;
begin
  _ValidateContext('Add');
  if Supports(FCurrent, IJSONObject, LObject) then
    LObject.Add(AName, AValue)
  else if Supports(FCurrent, IJSONArray, LArray) then
    LArray.Add(AValue);
  Result := Self;
end;

function TJSONSchemaComposer.Add(const AKey: String; const AValue: String): TJSONSchemaComposer;
var
  LObject: IJSONObject;
begin
  _ValidateContext('Add');
  LObject := _EnsureObject;
  LObject.Add(AKey, TJSONValueString.Create(AValue));
  Result := Self;
end;

function TJSONSchemaComposer.Merge(const AElement: IJSONElement): TJSONSchemaComposer;
var
  LObject: IJSONObject;
  LArray: IJSONArray;
  LPairs: TArray<IJSONPair>;
  LItems: TArray<IJSONElement>;
  LFor: Integer;
begin
  _ValidateContext('Merge');
  if not Assigned(AElement) then
    Exit(Self);
  if Supports(FCurrent, IJSONObject, LObject) then
  begin
    if Supports(AElement, IJSONObject) then
    begin
      LPairs := (AElement as IJSONObject).Pairs;
      for LFor := 0 to Length(LPairs) - 1 do
        LObject.Add(LPairs[LFor].Key, LPairs[LFor].Value);
    end;
  end
  else if Supports(FCurrent, IJSONArray, LArray) then
  begin
    if Supports(AElement, IJSONArray) then
    begin
      LItems := (AElement as IJSONArray).Items;
      for LFor := 0 to Length(LItems) - 1 do
        LArray.Add(LItems[LFor]);
    end
    else
      LArray.Add(AElement);
  end;
  Result := Self;
end;

{ TSmartSuggestionBuilder }

constructor TSmartSuggestionBuilder.Create;
begin
  inherited;
  FSuggestions := TList<TSmartSuggestion>.Create;
  ResetCurrent;
end;

destructor TSmartSuggestionBuilder.Destroy;
begin
  FSuggestions.Free;
  inherited;
end;

procedure TSmartSuggestionBuilder.AddSuggestion(const AKeyword, ACategory: string; APriority: Integer; const ADefaultValue: string);
var
  LSuggestion: TSmartSuggestion;
begin
  LSuggestion.Keyword := AKeyword;
  LSuggestion.Category := ACategory;
  LSuggestion.Priority := APriority;
  LSuggestion.DefaultValue := ADefaultValue;
  LSuggestion.AllowedValues := FCurrentOptions;
  LSuggestion.Description := Format('%s: %s', [ACategory, AKeyword]);
  FSuggestions.Add(LSuggestion);
  ResetCurrent;
end;

procedure TSmartSuggestionBuilder.ResetCurrent;
begin
  FCurrentPriority := 5;
  FCurrentDefault := '';
  SetLength(FCurrentOptions, 0);
end;

function TSmartSuggestionBuilder.AddValidation(const AKeyword: string; APriority: Integer; const ADefaultValue: string): ISmartSuggestionBuilder;
begin
  AddSuggestion(AKeyword, 'validation', APriority, ADefaultValue);
  Result := Self;
end;

function TSmartSuggestionBuilder.AddStructure(const AKeyword: string; APriority: Integer; const ADefaultValue: string): ISmartSuggestionBuilder;
begin
  AddSuggestion(AKeyword, 'structure', APriority, ADefaultValue);
  Result := Self;
end;

function TSmartSuggestionBuilder.AddDocumentation(const AKeyword: string; APriority: Integer; const ADefaultValue: string): ISmartSuggestionBuilder;
begin
  AddSuggestion(AKeyword, 'documentation', APriority, ADefaultValue);
  Result := Self;
end;

function TSmartSuggestionBuilder.AddMeta(const AKeyword: string; APriority: Integer; const ADefaultValue: string): ISmartSuggestionBuilder;
begin
  AddSuggestion(AKeyword, 'meta', APriority, ADefaultValue);
  Result := Self;
end;

function TSmartSuggestionBuilder.AddFormat(const AFormat: string; APriority: Integer): ISmartSuggestionBuilder;
begin
  AddSuggestion('format', 'validation', APriority, AFormat);
  Result := Self;
end;

function TSmartSuggestionBuilder.ForString: ISmartSuggestionBuilder;
begin
  AddValidation('type', 10, 'string')
    .AddValidation('minLength')
    .AddValidation('maxLength')
    .AddValidation('pattern')
    .AddFormat('email')
    .AddFormat('date-time')
    .AddFormat('uri');
  Result := Self;
end;

function TSmartSuggestionBuilder.ForNumber: ISmartSuggestionBuilder;
begin
  AddValidation('type', 10, 'number')
    .AddValidation('minimum')
    .AddValidation('maximum')
    .AddValidation('multipleOf');
  Result := Self;
end;

function TSmartSuggestionBuilder.ForArray: ISmartSuggestionBuilder;
begin
  AddValidation('type', 10, 'array')
    .AddStructure('items')
    .AddValidation('minItems')
    .AddValidation('maxItems')
    .AddValidation('uniqueItems');
  Result := Self;
end;

function TSmartSuggestionBuilder.ForObject: ISmartSuggestionBuilder;
begin
  AddValidation('type', 10, 'object')
    .AddStructure('properties')
    .AddStructure('required')
    .AddValidation('additionalProperties')
    .AddValidation('minProperties')
    .AddValidation('maxProperties');
  Result := Self;
end;

function TSmartSuggestionBuilder.ForRoot: ISmartSuggestionBuilder;
begin
  AddMeta('$schema', 10, 'https://json-schema.org/draft/2020-12/schema')
    .AddMeta('$id')
    .AddDocumentation('title')
    .AddDocumentation('description')
    .AddValidation('type');
  Result := Self;
end;

function TSmartSuggestionBuilder.WithPriority(APriority: Integer): ISmartSuggestionBuilder;
begin
  FCurrentPriority := APriority;
  Result := Self;
end;

function TSmartSuggestionBuilder.WithDefault(const AValue: string): ISmartSuggestionBuilder;
begin
  FCurrentDefault := AValue;
  Result := Self;
end;

function TSmartSuggestionBuilder.WithOptions(const AOptions: array of string): ISmartSuggestionBuilder;
var
  I: Integer;
begin
  SetLength(FCurrentOptions, Length(AOptions));
  for I := 0 to High(AOptions) do
    FCurrentOptions[I] := AOptions[I];
  Result := Self;
end;

function TSmartSuggestionBuilder.Build: TArray<TSmartSuggestion>;
begin
  Result := FSuggestions.ToArray;
end;

function TSmartSuggestionBuilder.Count: Integer;
begin
  Result := FSuggestions.Count;
end;

{ TSuggestionFactory }

class function TSuggestionFactory.NewBuilder: ISmartSuggestionBuilder;
begin
  Result := TSmartSuggestionBuilder.Create;
end;

class function TSuggestionFactory.ForContext(const AContextType: string): ISmartSuggestionBuilder;
var
  LBuilder: ISmartSuggestionBuilder;
begin
  LBuilder := NewBuilder;
  
  if SameText(AContextType, 'string') then
    Result := LBuilder.ForString
  else if SameText(AContextType, 'number') then
    Result := LBuilder.ForNumber
  else if SameText(AContextType, 'array') then
    Result := LBuilder.ForArray
  else if SameText(AContextType, 'object') then
    Result := LBuilder.ForObject
  else if SameText(AContextType, 'root') then
    Result := LBuilder.ForRoot
  else
    Result := LBuilder;
end;

{ TJSONSchemaComposer - Métodos Fluentes }

function TJSONSchemaComposer.Suggestions: ISmartSuggestionBuilder;
begin
  Result := TSuggestionFactory.NewBuilder;
end;

function TJSONSchemaComposer.SuggestionsFor(const AContextType: string): ISmartSuggestionBuilder;
begin
  Result := TSuggestionFactory.ForContext(AContextType);
end;

function TJSONSchemaComposer.GetSmartSuggestions(const AContext: string): TArray<TSmartSuggestion>;
var
  LContextType: string;
begin
  if AContext.IsEmpty then
    LContextType := FCurrentContext
  else
    LContextType := AContext;
    
  Result := SuggestionsFor(LContextType).Build;
end;

function TJSONSchemaComposer.QuickValidate(const APartialJSON: string): Boolean;
var
  LErrors: TArray<String>;
begin
  try
    // Validação básica - verifica se o JSON parcial é válido
    Result := Validate(APartialJSON, LErrors) and (Length(LErrors) = 0);
  except
    Result := False;
  end;
end;

end.


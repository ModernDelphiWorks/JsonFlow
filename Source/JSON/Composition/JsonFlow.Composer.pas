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

unit JsonFlow.Composer;

interface

uses
  System.Rtti,
  System.SysUtils,
  System.Classes,
  System.Variants,
  System.TypInfo,
  System.Generics.Collections,
  System.DateUtils,
  System.TimeSpan,
  JsonFlow.Utils,
  JsonFlow.Value,
  JsonFlow.Interfaces,
  JsonFlow.Navigator;

type
  TJSONComposer = class(TInterfacedObject, IJSONComposer)
  private
    function _FindElement(const APath: String): IJSONElement;
    function _FindParentAndKey(const APath: String; out AKey: String): IJSONElement;
    function _CloneElement(const AElement: IJSONElement): IJSONElement;
    function _ExtractArrayIndex(const APart: String; out AIndex: Integer): Boolean;
    procedure _UpdateContext(const AKey: String);
    procedure _ValidateContext(const AMethod: String);
    function _GetCurrentPath: String;
    function _BuildContextInfo: TContextInfo;
    function _GetContextSuggestions: TArray<TJSONSuggestion>;
    function _ValidateStructure: TArray<String>;
    procedure _UpdatePerformanceMetrics;
    procedure _StartOperation;
    procedure _EndOperation;
  protected
    FRoot: IJSONElement;
    FCurrent: IJSONElement;
    FLogProc: TProc<String>;
    FStack: TStack<IJSONElement>;
    FNameStack: TStack<String>;
    FCurrentContext: String;
    FContextStack: TStack<String>;
    FContextRules: TDictionary<String, TArray<String>>;
    FDebugMode: Boolean;
    FRealTimeValidation: Boolean;
    FValidationErrors: TList<String>;
    FSuggestionCache: TDictionary<String, TArray<TJSONSuggestion>>;
    FPerformanceInfo: TPerformanceInfo;
    FOperationStartTime: TDateTime;
    FOperationCount: Integer;
    procedure _Pop;
    procedure _Push(const AElement: IJSONElement; const AName: String);
  public
    constructor Create;
    destructor Destroy; override;
    function BeginObject(const AName: String = ''): IJSONComposer;
    function BeginArray(const AName: String = ''): IJSONComposer;
    function EndObject: IJSONComposer;
    function EndArray: IJSONComposer;
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
    function AddToArray(const APath: String; const AValue: Variant): IJSONComposer; overload;
    function AddToArray(const APath: String; const AElement: IJSONElement): IJSONComposer; overload;
    function AddToArray(const APath: String; const AValues: TArray<Variant>): IJSONComposer; overload;
    function MergeArray(const APath: String; const AValues: TArray<Variant>): IJSONComposer;
    function RemoveFromArray(const APath: String; const AIndex: Integer): IJSONComposer;
    function ReplaceArray(const APath: String; const AValues: TArray<Variant>): IJSONComposer;
    function AddObject(const APath: String; const AName: String): IJSONComposer;
    function SetValue(const APath: String; const AValue: Variant): IJSONComposer;
    function RemoveKey(const APath: String): IJSONComposer;
    function Clone: IJSONComposer;
    function GetRoot: IJSONElement;
    function AsJSON(const AIdent: Boolean = False): String;
    function ToJSON(const AIdent: Boolean = False): String; overload; virtual;
    function ToElement: IJSONElement;
    function ForEach(const ACallback: TProc<String, IJSONElement>): IJSONComposer;
    function Clear: IJSONComposer;
    procedure OnLog(const ALogProc: TProc<String>);
    procedure AddLog(const AMessage: String);

    function StringValue(const AName, AValue: String): IJSONComposer;
    function NumberValue(const AName: String; AValue: Double): IJSONComposer;
    function IntegerValue(const AName: String; AValue: Integer): IJSONComposer;
    function BooleanValue(const AName: String; AValue: Boolean): IJSONComposer;
    function NullValue(const AName: String): IJSONComposer;
    function DateTimeValue(const AName: String; AValue: TDateTime): IJSONComposer;
    function ObjectValue(const AName: String; const ACallback: TJSONObjectCallback): IJSONComposer;
    function ArrayValue(const AName: String; const ACallback: TJSONArrayCallback): IJSONComposer;

    function NavigateTo(const APath: String): IJSONComposer;
    function GetCurrentPath: String;
    function GetContextInfo: TContextInfo;
    function EnableDebugMode(AEnabled: Boolean): IJSONComposer;
    function GetCompositionTrace: TArray<String>;

    function GetSuggestions(const AContext: String = ''): TArray<TJSONSuggestion>;
    function SuggestKeys: TArray<String>;
    function SuggestValues(const AKey: String): TArray<Variant>;
    function EnableRealTimeValidation(AEnabled: Boolean): IJSONComposer;
    function QuickValidate: Boolean;
    function ValidateStructure: TArray<String>;
    function IsValidJSON: Boolean;
    function GetValidationErrors: TArray<String>;

    function GetPerformanceMetrics: TPerformanceInfo;
    function OptimizeMemory: IJSONComposer;
    function EnableLazyLoading(AEnabled: Boolean): IJSONComposer;
    function Benchmark(const AOperation: TProc): TTimeSpan;

    // Factory methods
    class function CreateForObject: TJSONComposer;
    class function CreateForArray: TJSONComposer;
    class function CreateFromJSON(const AJson: String): TJSONComposer;
  end;

implementation

uses
  JsonFlow.Objects,
  JsonFlow.Arrays,
  JsonFlow.Writer,
  JsonFlow.Reader;

{ TJSONComposer }

constructor TJSONComposer.Create;
begin
  FStack := TStack<IJSONElement>.Create;
  FNameStack := TStack<String>.Create;
  FContextStack := TStack<String>.Create;
  FContextRules := TDictionary<String, TArray<String>>.Create;
  FCurrentContext := 'root';
  FDebugMode := False;
  FRealTimeValidation := False;
  FValidationErrors := TList<String>.Create;
  FSuggestionCache := TDictionary<String, TArray<TJSONSuggestion>>.Create;
  FPerformanceInfo.CreationTime := Now;
  FPerformanceInfo.LastModified := Now;
  FPerformanceInfo.OperationCount := 0;
  FPerformanceInfo.MemoryUsage := 0;
  FOperationCount := 0;
  //
  _UpdatePerformanceMetrics;
end;

destructor TJSONComposer.Destroy;
begin
  Clear;
  //
  FNameStack.Free;
  FStack.Free;
  FContextStack.Free;
  FContextRules.Free;
  FValidationErrors.Free;
  FSuggestionCache.Free;
  inherited;
end;

procedure TJSONComposer._Push(const AElement: IJSONElement; const AName: String);
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

procedure TJSONComposer._Pop;
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
      LObject.Add(LName, FCurrent)
    else if Supports(LParent, IJSONArray, LArray) then
      LArray.Add(FCurrent);
    FCurrent := LParent;
  end
  else
  begin
    if FNameStack.Count > 0 then
      FNameStack.Pop;
    FCurrent := nil;
  end;
end;

procedure TJSONComposer._UpdateContext(const AKey: String);
begin
  if AKey <> '' then
  begin
    FCurrentContext := AKey;
    if FDebugMode then
      AddLog('Context updated to: ' + AKey);
  end;
  _UpdatePerformanceMetrics;
end;

procedure TJSONComposer._ValidateContext(const AMethod: String);
begin
  if FRealTimeValidation then
  begin
    if not IsValidJSON then
      FValidationErrors.Add('Invalid context for method: ' + AMethod);
  end;
end;

function TJSONComposer._GetCurrentPath: String;
var
  LPaths: TArray<String>;
  LPath: String;
begin
  Result := '';
  if FContextStack.Count > 0 then
  begin
    SetLength(LPaths, FContextStack.Count);
    for var I := 0 to FContextStack.Count - 1 do
      LPaths[I] := FContextStack.ToArray[I];
    Result := String.Join('.', LPaths);
  end;
end;

function TJSONComposer._BuildContextInfo: TContextInfo;
begin
  Result.CurrentPath := _GetCurrentPath;
  Result.Depth := FStack.Count;
  Result.ParentKey := FCurrentContext;
  
  if Assigned(FCurrent) then
  begin
    if Supports(FCurrent, IJSONObject) then
      Result.ContextType := 'object'
    else if Supports(FCurrent, IJSONArray) then
      Result.ContextType := 'array'
    else
      Result.ContextType := 'value';
  end
  else
    Result.ContextType := 'root';
end;

function TJSONComposer._GetContextSuggestions: TArray<TJSONSuggestion>;
var
  LSuggestions: TList<TJSONSuggestion>;
  LSuggestion: TJSONSuggestion;
begin
  LSuggestions := TList<TJSONSuggestion>.Create;
  try
    if Supports(FCurrent, IJSONObject) then
    begin
      LSuggestion.SuggestionType := 'method';
      LSuggestion.Value := 'StringValue';
      LSuggestion.Description := 'Add a string property';
      LSuggestion.Context := 'object';
      LSuggestions.Add(LSuggestion);
      
      LSuggestion.Value := 'NumberValue';
      LSuggestion.Description := 'Add a number property';
      LSuggestions.Add(LSuggestion);
      
      LSuggestion.Value := 'ObjectValue';
      LSuggestion.Description := 'Add a nested object';
      LSuggestions.Add(LSuggestion);
    end
    else if Supports(FCurrent, IJSONArray) then
    begin
      LSuggestion.SuggestionType := 'method';
      LSuggestion.Value := 'Add';
      LSuggestion.Description := 'Add an element to array';
      LSuggestion.Context := 'array';
      LSuggestions.Add(LSuggestion);
    end;
    
    Result := LSuggestions.ToArray;
  finally
    LSuggestions.Free;
  end;
end;

function TJSONComposer._ValidateStructure: TArray<String>;
var
  LErrors: TList<String>;
begin
  LErrors := TList<String>.Create;
  try
    // Validações básicas
    if not Assigned(FRoot) then
      LErrors.Add('No root element defined');
      
    if FStack.Count > 0 then
      LErrors.Add('Unclosed objects or arrays detected');
      
    if FNameStack.Count <> FStack.Count then
      LErrors.Add('Name stack and element stack mismatch');
      
    Result := LErrors.ToArray;
  finally
    LErrors.Free;
  end;
end;

// FASE 4: Performance methods
procedure TJSONComposer._UpdatePerformanceMetrics;
begin
  FPerformanceInfo.LastModified := Now;
  FPerformanceInfo.OperationCount := FOperationCount;
  // Estimativa simples de uso de memória
  FPerformanceInfo.MemoryUsage := FStack.Count * SizeOf(IJSONElement) + 
                                  FNameStack.Count * SizeOf(String);
end;

procedure TJSONComposer._StartOperation;
begin
  FOperationStartTime := Now;
end;

procedure TJSONComposer._EndOperation;
begin
  Inc(FOperationCount);
  FPerformanceInfo.BuildTime := TTimeSpan.FromMilliseconds(
    MilliSecondsBetween(Now, FOperationStartTime));
  _UpdatePerformanceMetrics;
end;

function TJSONComposer._FindElement(const APath: String): IJSONElement;
var
  LNavigator: TJSONNavigator;
begin
  if not Assigned(FRoot) then
    raise EInvalidOperation.Create('No JSON loaded');

  LNavigator := TJSONNavigator.Create(FRoot);
  try
    Result := LNavigator.GetValue(APath);
    if not Assigned(Result) then
      raise EInvalidOperation.Create('Path not found: ' + APath);
  finally
    LNavigator.Free;
  end;
end;

function TJSONComposer._FindParentAndKey(const APath: String; out AKey: String): IJSONElement;
var
  LNavigator: TJSONNavigator;
  LParts: TArray<String>;
  LParentPath: String;
begin
  if not Assigned(FRoot) then
    raise EInvalidOperation.Create('No JSON loaded');

  LParts := APath.Split(['.']);
  AKey := LParts[Length(LParts) - 1];
  LParentPath := Copy(APath, 1, Length(APath) - Length(AKey) - 1);

  LNavigator := TJSONNavigator.Create(FRoot);
  try
    if LParentPath = '' then
      Result := FRoot
    else
    begin
      Result := LNavigator.GetValue(LParentPath);
      if not Assigned(Result) then
        raise EInvalidOperation.Create('Parent path not found: ' + LParentPath);
    end;
  finally
    LNavigator.Free;
  end;
end;

function TJSONComposer._ExtractArrayIndex(const APart: String; out AIndex: Integer): Boolean;
var
  LStart, LEnd: Integer;
  LIndexStr: String;
begin
  Result := False;
  LStart := Pos('[', APart);
  LEnd := Pos(']', APart);
  if (LStart > 0) and (LEnd > LStart) then
  begin
    LIndexStr := Copy(APart, LStart + 1, LEnd - LStart - 1);
    Result := TryStrToInt(LIndexStr, AIndex) and (AIndex >= 0);
  end;
end;

function TJSONComposer._CloneElement(const AElement: IJSONElement): IJSONElement;
var
  LObject: IJSONObject;
  LArray: IJSONArray;
  LValue: IJSONValue;
  LPairs: TArray<IJSONPair>;
  LItems: TArray<IJSONElement>;
  LNewObj: TJSONObject;
  LNewArr: TJSONArray;
  LFor: Integer;
begin
  if not Assigned(AElement) then
    Exit(nil);

  if Supports(AElement, IJSONObject, LObject) then
  begin
    LNewObj := TJSONObject.Create;
    LPairs := LObject.Pairs;
    for LFor := 0 to Length(LPairs) - 1 do
      LNewObj.Add(LPairs[LFor].Key, _CloneElement(LPairs[LFor].Value));
    Result := LNewObj;
  end
  else if Supports(AElement, IJSONArray, LArray) then
  begin
    LNewArr := TJSONArray.Create;
    LItems := LArray.Items;
    for LFor := 0 to Length(LItems) - 1 do
      LNewArr.Add(_CloneElement(LItems[LFor]));
    Result := LNewArr;
  end
  else if Supports(AElement, IJSONValue, LValue) then
  begin
    if LValue is TJSONValueString then
      Result := TJSONValueString.Create(LValue.AsString)
    else if LValue is TJSONValueInteger then
      Result := TJSONValueInteger.Create(LValue.AsInteger)
    else if LValue is TJSONValueFloat then
      Result := TJSONValueFloat.Create(LValue.AsFloat)
    else if LValue is TJSONValueBoolean then
      Result := TJSONValueBoolean.Create(LValue.AsBoolean)
    else if LValue is TJSONValueDateTime then
      Result := TJSONValueDateTime.Create(LValue.AsString, True)
    else if LValue is TJSONValueNull then
      Result := TJSONValueNull.Create
    else
      raise EInvalidOperation.Create('Unknown JSON value type');
  end
  else
    raise EInvalidOperation.Create('Unsupported JSON element type');
end;

function TJSONComposer.BeginObject(const AName: String): IJSONComposer;
begin
  _Push(TJSONObject.Create, AName);
  Result := Self;
end;

function TJSONComposer.BeginArray(const AName: String): IJSONComposer;
begin
  _Push(TJSONArray.Create, AName);
  Result := Self;
end;

function TJSONComposer.EndObject: IJSONComposer;
begin
  _Pop;
  Result := Self;
end;

function TJSONComposer.EndArray: IJSONComposer;
begin
  _Pop;
  Result := Self;
end;

function TJSONComposer.Add(const AName: String; const AValue: String): IJSONComposer;
var
  LObject: IJSONObject;
  LArray: IJSONArray;
begin
  if Supports(FCurrent, IJSONObject, LObject) then
    LObject.Add(AName, TJSONValueString.Create(AValue))
  else if Supports(FCurrent, IJSONArray, LArray) then
    LArray.Add(TJSONValueString.Create(AValue));
  Result := Self;
end;

function TJSONComposer.Add(const AName: String; const AValue: Integer): IJSONComposer;
var
  LObject: IJSONObject;
  LArray: IJSONArray;
begin
  if Supports(FCurrent, IJSONObject, LObject) then
    LObject.Add(AName, TJSONValueInteger.Create(AValue))
  else if Supports(FCurrent, IJSONArray, LArray) then
    LArray.Add(TJSONValueInteger.Create(AValue));
  Result := Self;
end;

function TJSONComposer.Add(const AName: String; const AValue: Double): IJSONComposer;
var
  LObject: IJSONObject;
  LArray: IJSONArray;
begin
  if Supports(FCurrent, IJSONObject, LObject) then
    LObject.Add(AName, TJSONValueFloat.Create(AValue))
  else if Supports(FCurrent, IJSONArray, LArray) then
    LArray.Add(TJSONValueFloat.Create(AValue));
  Result := Self;
end;

function TJSONComposer.Add(const AName: String; const AValue: Boolean): IJSONComposer;
var
  LObject: IJSONObject;
  LArray: IJSONArray;
begin
  if Supports(FCurrent, IJSONObject, LObject) then
    LObject.Add(AName, TJSONValueBoolean.Create(AValue))
  else if Supports(FCurrent, IJSONArray, LArray) then
    LArray.Add(TJSONValueBoolean.Create(AValue));
  Result := Self;
end;

function TJSONComposer.Add(const AName: String; const AValue: TDateTime): IJSONComposer;
var
  LObject: IJSONObject;
  LArray: IJSONArray;
begin
  if Supports(FCurrent, IJSONObject, LObject) then
    LObject.Add(AName, TJSONValueDateTime.Create(AValue))
  else if Supports(FCurrent, IJSONArray, LArray) then
    LArray.Add(TJSONValueDateTime.Create(AValue));
  Result := Self;
end;

function TJSONComposer.Add(const AName: String; const AValue: IJSONElement): IJSONComposer;
var
  LObject: IJSONObject;
  LArray: IJSONArray;
begin
  if Supports(FCurrent, IJSONObject, LObject) then
    LObject.Add(AName, AValue)
  else if Supports(FCurrent, IJSONArray, LArray) then
    LArray.Add(AValue);
  Result := Self;
end;

function TJSONComposer.Add(const AName: String; const AValue: Char): IJSONComposer;
var
  LObject: IJSONObject;
  LArray: IJSONArray;
begin
  if Supports(FCurrent, IJSONObject, LObject) then
    LObject.Add(AName, TJSONValueString.Create(AValue))
  else if Supports(FCurrent, IJSONArray, LArray) then
    LArray.Add(TJSONValueString.Create(AValue));
  Result := Self;
end;

function TJSONComposer.Add(const AName: String; const AValue: Variant): IJSONComposer;
var
  LObject: IJSONObject;
  LArray: IJSONArray;
begin
  if Supports(FCurrent, IJSONObject, LObject) then
  begin
    case VarType(AValue) and varTypeMask of
      varInteger, varShortInt, varByte, varWord, varLongWord: LObject.Add(AName, TJSONValueInteger.Create(AValue));
      varSingle, varDouble, varCurrency: LObject.Add(AName, TJSONValueFloat.Create(AValue));
      varBoolean: LObject.Add(AName, TJSONValueBoolean.Create(AValue));
      varDate: LObject.Add(AName, TJSONValueDateTime.Create(VarToStr(AValue), True));
      varEmpty, varNull: LObject.Add(AName, TJSONValueNull.Create);
    else
      LObject.Add(AName, TJSONValueString.Create(VarToStr(AValue)));
    end;
  end
  else if Supports(FCurrent, IJSONArray, LArray) then
  begin
    case VarType(AValue) and varTypeMask of
      varInteger, varShortInt, varByte, varWord, varLongWord: LArray.Add(TJSONValueInteger.Create(AValue));
      varSingle, varDouble, varCurrency: LArray.Add(TJSONValueFloat.Create(AValue));
      varBoolean: LArray.Add(TJSONValueBoolean.Create(AValue));
      varDate: LArray.Add(TJSONValueDateTime.Create(VarToStr(AValue), True));
      varEmpty, varNull: LArray.Add(TJSONValueNull.Create);
    else
      LArray.Add(TJSONValueString.Create(VarToStr(AValue)));
    end;
  end;
  Result := Self;
end;

function TJSONComposer.AddNull(const AName: String): IJSONComposer;
var
  LObject: IJSONObject;
  LArray: IJSONArray;
begin
  if Supports(FCurrent, IJSONObject, LObject) then
    LObject.Add(AName, TJSONValueNull.Create)
  else if Supports(FCurrent, IJSONArray, LArray) then
    LArray.Add(TJSONValueNull.Create);
  Result := Self;
end;

function TJSONComposer.AddArray(const AName: String; const AValues: array of TValue): IJSONComposer;
var
  LArray: TJSONArray;
  LFor: Integer;
begin
  LArray := TJSONArray.Create;
  for LFor := Low(AValues) to High(AValues) do
    case AValues[LFor].Kind of
      tkInteger: LArray.Add(TJSONValueInteger.Create(AValues[LFor].AsInteger));
      tkFloat: LArray.Add(TJSONValueFloat.Create(AValues[LFor].AsExtended));
      tkString, tkLString, tkWString, tkUString: LArray.Add(TJSONValueString.Create(AValues[LFor].AsString));
      tkEnumeration: if AValues[LFor].TypeInfo = TypeInfo(Boolean) then
                       LArray.Add(TJSONValueBoolean.Create(AValues[LFor].AsBoolean))
                     else
                       LArray.Add(TJSONValueInteger.Create(AValues[LFor].AsInteger));
      else
        LArray.Add(TJSONValueNull.Create);
    end;
  Add(AName, LArray);
  Result := Self;
end;

function TJSONComposer.AddJSON(const AName: String; const AJson: String): IJSONComposer;
var
  LReader: TJSONReader;
  LObject: IJSONObject;
  LArray: IJSONArray;
begin
  LReader := TJSONReader.Create;
  try
    if Supports(FCurrent, IJSONObject, LObject) then
      LObject.Add(AName, LReader.Read(AJson))
    else if Supports(FCurrent, IJSONArray, LArray) then
      LArray.Add(LReader.Read(AJson));
  finally
    LReader.Free;
  end;
  Result := Self;
end;

procedure TJSONComposer.AddLog(const AMessage: String);
begin
  if Assigned(FLogProc) then
    FLogProc(AMessage);
end;

function TJSONComposer.Add(const AName: String; const AValues: TArray<Integer>): IJSONComposer;
var
  LArray: TJSONArray;
  LFor: Integer;
begin
  LArray := TJSONArray.Create;
  for LFor := 0 to Length(AValues) - 1 do
    LArray.Add(TJSONValueInteger.Create(AValues[LFor]));
  Add(AName, LArray);
  Result := Self;
end;

function TJSONComposer.Add(const AName: String; const AValues: TArray<String>): IJSONComposer;
var
  LArray: TJSONArray;
  LFor: Integer;
begin
  LArray := TJSONArray.Create;
  for LFor := 0 to Length(AValues) - 1 do
    LArray.Add(TJSONValueString.Create(AValues[LFor]));
  Add(AName, LArray);
  Result := Self;
end;

function TJSONComposer.Add(const AName: String; const AValues: TArray<Double>): IJSONComposer;
var
  LArray: TJSONArray;
  LFor: Integer;
begin
  LArray := TJSONArray.Create;
  for LFor := 0 to Length(AValues) - 1 do
    LArray.Add(TJSONValueFloat.Create(AValues[LFor]));
  Add(AName, LArray);
  Result := Self;
end;

function TJSONComposer.Add(const AName: String; const AValues: TArray<Boolean>): IJSONComposer;
var
  LArray: TJSONArray;
  LFor: Integer;
begin
  LArray := TJSONArray.Create;
  for LFor := 0 to Length(AValues) - 1 do
    LArray.Add(TJSONValueBoolean.Create(AValues[LFor]));
  Add(AName, LArray);
  Result := Self;
end;

function TJSONComposer.Add(const AName: String; const AValues: TArray<TDateTime>): IJSONComposer;
var
  LArray: TJSONArray;
  LFor: Integer;
begin
  LArray := TJSONArray.Create;
  for LFor := 0 to Length(AValues) - 1 do
    LArray.Add(TJSONValueDateTime.Create(AValues[LFor]));
  Add(AName, LArray);
  Result := Self;
end;

function TJSONComposer.Add(const AName: String; const AValues: TArray<Char>): IJSONComposer;
var
  LArray: TJSONArray;
  LFor: Integer;
begin
  LArray := TJSONArray.Create;
  for LFor := 0 to Length(AValues) - 1 do
    LArray.Add(TJSONValueString.Create(AValues[LFor]));
  Add(AName, LArray);
  Result := Self;
end;

function TJSONComposer.Add(const AName: String; const AValues: TArray<Variant>): IJSONComposer;
var
  LArray: TJSONArray;
  LFor: Integer;
begin
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

function TJSONComposer.Merge(const AElement: IJSONElement): IJSONComposer;
var
  LObject: IJSONObject;
  LArray: IJSONArray;
  LPairs: TArray<IJSONPair>;
  LItems: TArray<IJSONElement>;
  LFor: Integer;
begin
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

function TJSONComposer.LoadJSON(const AJson: String): IJSONComposer;
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

function TJSONComposer.AddToArray(const APath: String; const AValue: Variant): IJSONComposer;
var
  LArray: IJSONArray;
  LParts: TArray<String>;
  LLastPart: String;
  LIndex: Integer;
  LItems: TArray<IJSONElement>;
  LNewArray: IJSONArray;
  LFor: Integer;
  LArrayPath: String;
  LElement: IJSONElement;
begin
  LParts := APath.Split(['.']);
  LLastPart := LParts[High(LParts)];
  if _ExtractArrayIndex(LLastPart, LIndex) then
  begin
    LArrayPath := Copy(APath, 1, Length(APath) - (Length(LLastPart) - Pos('[', LLastPart) + 1));
    if LArrayPath = '' then LArrayPath := Copy(LLastPart, 1, Pos('[', LLastPart) - 1);
    LElement := _FindElement(LArrayPath);
    if not Assigned(LElement) then
      raise EInvalidOperation.Create('Path not found: ' + LArrayPath);
    if not Supports(LElement, IJSONArray, LArray) then
      raise EInvalidOperation.Create('Path does not point to an array: ' + LArrayPath);
    if (LIndex < 0) or (LIndex > LArray.Count) then
      raise EInvalidOperation.Create('Index out of bounds: ' + IntToStr(LIndex));
    LItems := LArray.Items;
    LNewArray := TJSONArray.Create;
    for LFor := 0 to Length(LItems) - 1 do
    begin
      if LFor = LIndex then
      begin
        case VarType(AValue) and varTypeMask of
          varInteger, varShortInt, varByte, varWord, varLongWord: LNewArray.Add(TJSONValueInteger.Create(AValue));
          varSingle, varDouble, varCurrency: LNewArray.Add(TJSONValueFloat.Create(AValue));
          varBoolean: LNewArray.Add(TJSONValueBoolean.Create(AValue));
          varDate: LNewArray.Add(TJSONValueDateTime.Create(VarToStr(AValue), True));
          varEmpty, varNull: LNewArray.Add(TJSONValueNull.Create);
          else LNewArray.Add(TJSONValueString.Create(VarToStr(AValue)));
        end;
      end;
      LNewArray.Add(LItems[LFor]);
    end;
    if LIndex = LArray.Count then
    begin
      case VarType(AValue) and varTypeMask of
        varInteger, varShortInt, varByte, varWord, varLongWord: LNewArray.Add(TJSONValueInteger.Create(AValue));
        varSingle, varDouble, varCurrency: LNewArray.Add(TJSONValueFloat.Create(AValue));
        varBoolean: LNewArray.Add(TJSONValueBoolean.Create(AValue));
        varDate: LNewArray.Add(TJSONValueDateTime.Create(VarToStr(AValue), True));
        varEmpty, varNull: LNewArray.Add(TJSONValueNull.Create);
        else LNewArray.Add(TJSONValueString.Create(VarToStr(AValue)));
      end;
    end;
    LArray.Clear;
    for LFor := 0 to LNewArray.Count - 1 do
      LArray.Add(LNewArray.Value(LFor));
  end
  else
  begin
    LElement := _FindElement(APath);
    if not Assigned(LElement) then
      raise EInvalidOperation.Create('Path not found: ' + APath);
    if not Supports(LElement, IJSONArray, LArray) then
      raise EInvalidOperation.Create('Path does not point to an array: ' + APath);
    case VarType(AValue) and varTypeMask of
      varInteger, varShortInt, varByte, varWord, varLongWord: LArray.Add(TJSONValueInteger.Create(AValue));
      varSingle, varDouble, varCurrency: LArray.Add(TJSONValueFloat.Create(AValue));
      varBoolean: LArray.Add(TJSONValueBoolean.Create(AValue));
      varDate: LArray.Add(TJSONValueDateTime.Create(VarToStr(AValue), True));
      varEmpty, varNull: LArray.Add(TJSONValueNull.Create);
      else LArray.Add(TJSONValueString.Create(VarToStr(AValue)));
    end;
  end;
  Result := Self;
end;

function TJSONComposer.AddToArray(const APath: String; const AElement: IJSONElement): IJSONComposer;
var
  LArray: IJSONArray;
begin
  if not Supports(_FindElement(APath), IJSONArray, LArray) then
    raise EInvalidOperation.Create('Path does not point to an array: ' + APath);

  LArray.Add(AElement);
  Result := Self;
end;

function TJSONComposer.AddToArray(const APath: String; const AValues: TArray<Variant>): IJSONComposer;
var
  LArray: IJSONArray;
  LNewArray: TJSONArray;
  LFor: Integer;
begin
  if not Supports(_FindElement(APath), IJSONArray, LArray) then
    raise EInvalidOperation.Create('Path does not point to an array: ' + APath);

  LNewArray := TJSONArray.Create;
  for LFor := 0 to Length(AValues) - 1 do
  begin
    case VarType(AValues[LFor]) and varTypeMask of
      varInteger, varShortInt, varByte, varWord, varLongWord: LNewArray.Add(TJSONValueInteger.Create(AValues[LFor]));
      varSingle, varDouble, varCurrency: LNewArray.Add(TJSONValueFloat.Create(AValues[LFor]));
      varBoolean: LNewArray.Add(TJSONValueBoolean.Create(AValues[LFor]));
      varDate: LNewArray.Add(TJSONValueDateTime.Create(VarToStr(AValues[LFor]), True));
      varEmpty, varNull: LNewArray.Add(TJSONValueNull.Create);
    else
      LNewArray.Add(TJSONValueString.Create(VarToStr(AValues[LFor])));
    end;
  end;
  LArray.Add(LNewArray);
  Result := Self;
end;

function TJSONComposer.MergeArray(const APath: String; const AValues: TArray<Variant>): IJSONComposer;
var
  LArray: IJSONArray;
  LFor: Integer;
begin
  if not Supports(_FindElement(APath), IJSONArray, LArray) then
    raise EInvalidOperation.Create('Path does not point to an array: ' + APath);

  for LFor := 0 to Length(AValues) - 1 do
  begin
    case VarType(AValues[LFor]) and varTypeMask of
      varInteger, varShortInt, varByte, varWord, varLongWord: LArray.Add(TJSONValueInteger.Create(AValues[LFor]));
      varSingle, varDouble, varCurrency: LArray.Add(TJSONValueFloat.Create(AValues[LFor]));
      varBoolean: LArray.Add(TJSONValueBoolean.Create(AValues[LFor]));
      varDate: LArray.Add(TJSONValueDateTime.Create(VarToStr(AValues[LFor]), True));
      varEmpty, varNull: LArray.Add(TJSONValueNull.Create);
    else
      LArray.Add(TJSONValueString.Create(VarToStr(AValues[LFor])));
    end;
  end;
  Result := Self;
end;

procedure TJSONComposer.OnLog(const ALogProc: TProc<String>);
begin
  FLogProc := ALogProc;
end;

function TJSONComposer.RemoveFromArray(const APath: String; const AIndex: Integer): IJSONComposer;
var
  LArray: IJSONArray;
begin
  if not Supports(_FindElement(APath), IJSONArray, LArray) then
    raise EInvalidOperation.Create('Path does not point to an array: ' + APath);
  if (AIndex < 0) or (AIndex >= LArray.Count) then
    raise EInvalidOperation.Create('Index out of bounds: ' + IntToStr(AIndex));

  LArray.Remove(AIndex);
  Result := Self;
end;

function TJSONComposer.ReplaceArray(const APath: String; const AValues: TArray<Variant>): IJSONComposer;
var
  LParent: IJSONElement;
  LKey: String;
  LNewArray: TJSONArray;
  LFor: Integer;
  LObject: IJSONObject;
begin
  LParent := _FindParentAndKey(APath, LKey);
  if not Supports(LParent, IJSONObject, LObject) then
    raise EInvalidOperation.Create('Parent path is not an object: ' + APath);

  LNewArray := TJSONArray.Create;
  for LFor := 0 to Length(AValues) - 1 do
  begin
    case VarType(AValues[LFor]) and varTypeMask of
      varInteger, varShortInt, varByte, varWord, varLongWord: LNewArray.Add(TJSONValueInteger.Create(AValues[LFor]));
      varSingle, varDouble, varCurrency: LNewArray.Add(TJSONValueFloat.Create(AValues[LFor]));
      varBoolean: LNewArray.Add(TJSONValueBoolean.Create(AValues[LFor]));
      varDate: LNewArray.Add(TJSONValueDateTime.Create(VarToStr(AValues[LFor]), True));
      varEmpty, varNull: LNewArray.Add(TJSONValueNull.Create);
    else
      LNewArray.Add(TJSONValueString.Create(VarToStr(AValues[LFor])));
    end;
  end;

  LObject.Add(LKey, LNewArray);
  Result := Self;
end;

function TJSONComposer.AddObject(const APath: String; const AName: String): IJSONComposer;
var
  LParent: IJSONElement;
  LNewObject: TJSONObject;
  LObject: IJSONObject;
  LArray: IJSONArray;
begin
  LParent := _FindElement(APath);
  LNewObject := TJSONObject.Create;

  if Supports(LParent, IJSONObject, LObject) then
    LObject.Add(AName, LNewObject)
  else if Supports(LParent, IJSONArray, LArray) then
    LArray.Add(LNewObject)
  else
    raise EInvalidOperation.Create('Path does not point to an object or array: ' + APath);

  FCurrent := LNewObject;
  Result := Self;
end;

function TJSONComposer.SetValue(const APath: String; const AValue: Variant): IJSONComposer;
var
  LElement: IJSONElement;
  LValue: IJSONValue;
  LParts: TArray<String>;
  LLastPart: String;
  LArray: IJSONArray;
  LIndex: Integer;
  LArrayPath: String;
begin
  LParts := APath.Split(['.']);
  LLastPart := LParts[High(LParts)];
  if _ExtractArrayIndex(LLastPart, LIndex) then
  begin
    LArrayPath := Copy(APath, 1, Length(APath) - (Length(LLastPart) - Pos('[', LLastPart) + 1));
    if LArrayPath = '' then LArrayPath := Copy(LLastPart, 1, Pos('[', LLastPart) - 1);
    LElement := _FindElement(LArrayPath);
    if not Assigned(LElement) then
      raise EInvalidOperation.Create('Path not found: ' + LArrayPath);
    if not Supports(LElement, IJSONArray, LArray) then
      raise EInvalidOperation.Create('Path does not point to an array: ' + LArrayPath);
    if (LIndex < 0) or (LIndex >= LArray.Count) then
      raise EInvalidOperation.Create('Index out of bounds: ' + IntToStr(LIndex));
    LElement := LArray.Value(LIndex);
    if not Supports(LElement, IJSONValue, LValue) then
      raise EInvalidOperation.Create('Path does not point to a value: ' + APath);
  end
  else
  begin
    LElement := _FindElement(APath);
    if not Assigned(LElement) then
      raise EInvalidOperation.Create('Path not found: ' + APath);
    if not Supports(LElement, IJSONValue, LValue) then
      raise EInvalidOperation.Create('Path does not point to a value: ' + APath);
  end;
  case VarType(AValue) and varTypeMask of
    varInteger, varShortInt, varByte, varWord, varLongWord: LValue.AsInteger := AValue;
    varSingle, varDouble, varCurrency: LValue.AsFloat := AValue;
    varBoolean: LValue.AsBoolean := AValue;
    varDate: LValue.AsString := VarToStr(AValue); // Assume ISO 8601
    varEmpty, varNull: raise EInvalidOperation.Create('Cannot set value to null');
    else LValue.AsString := VarToStr(AValue);
  end;
  Result := Self;
end;

function TJSONComposer.RemoveKey(const APath: String): IJSONComposer;
var
  LParent: IJSONElement;
  LKey: String;
  LObject: IJSONObject;
begin
  LParent := _FindParentAndKey(APath, LKey);
  if not Supports(LParent, IJSONObject, LObject) then
    raise EInvalidOperation.Create('Parent path is not an object: ' + APath);

  LObject.Remove(LKey);
  Result := Self;
end;

function TJSONComposer.Clone: IJSONComposer;
var
  LNewComposer: TJSONComposer;
begin
  LNewComposer := TJSONComposer.Create;
  LNewComposer.FRoot := _CloneElement(FRoot);
  LNewComposer.FCurrent := LNewComposer.FRoot;
  Result := LNewComposer;
end;

function TJSONComposer.GetRoot: IJSONElement;
begin
  Result := FRoot;
end;

function TJSONComposer.AsJSON(const AIdent: Boolean): String;
begin
  Result := ToJSON(AIdent);
end;

function TJSONComposer.ToJSON(const AIdent: Boolean): String;
var
  LWriter: IJSONWriter;
begin
  if Assigned(FCurrent) and (FStack.Count > 0) then
    raise EInvalidOperation.Create('JSON incomplete: unclosed object or array');
  LWriter := TJSONWriter.Create;
  Result := LWriter.Write(FRoot, AIdent);
end;

function TJSONComposer.ToElement: IJSONElement;
begin
  if Assigned(FCurrent) and (FStack.Count > 0) then
    raise EInvalidOperation.Create('JSON incomplete: unclosed object or array');
  Result := FRoot;
end;

function TJSONComposer.ForEach(const ACallback: TProc<String, IJSONElement>): IJSONComposer;
var
  LObject: IJSONObject;
  LArray: IJSONArray;
  LPairs: TArray<IJSONPair>;
  LItems: TArray<IJSONElement>;
  LFor: Integer;
begin
  if Assigned(ACallback) then
  begin
    if Supports(FCurrent, IJSONObject, LObject) then
    begin
      LPairs := LObject.Pairs;
      for LFor := 0 to Length(LPairs) - 1 do
        ACallback(LPairs[LFor].Key, LPairs[LFor].Value);
    end
    else if Supports(FCurrent, IJSONArray, LArray) then
    begin
      LItems := LArray.Items;
      for LFor := 0 to Length(LItems) - 1 do
        ACallback('', LItems[LFor]);
    end;
  end;
  Result := Self;
end;

function TJSONComposer.Clear: IJSONComposer;
begin
  FRoot := nil;
  FCurrent := nil;
  FStack.Clear;
  FNameStack.Clear;
  Result := Self;
end;

// === IMPLEMENTAÇÃO DOS MÉTODOS PÚBLICOS DAS FASES 1-4 ===

// FASE 1: Sintaxe fluente moderna
function TJSONComposer.StringValue(const AName, AValue: String): IJSONComposer;
begin
  _StartOperation;
  _ValidateContext('StringValue');
  Add(AName, AValue);
  _UpdateContext(AName);
  _EndOperation;
  Result := Self;
end;

function TJSONComposer.NumberValue(const AName: String; AValue: Double): IJSONComposer;
begin
  _StartOperation;
  _ValidateContext('NumberValue');
  Add(AName, AValue);
  _UpdateContext(AName);
  _EndOperation;
  Result := Self;
end;

function TJSONComposer.IntegerValue(const AName: String; AValue: Integer): IJSONComposer;
begin
  _StartOperation;
  _ValidateContext('IntegerValue');
  Add(AName, AValue);
  _UpdateContext(AName);
  _EndOperation;
  Result := Self;
end;

function TJSONComposer.BooleanValue(const AName: String; AValue: Boolean): IJSONComposer;
begin
  _StartOperation;
  _ValidateContext('BooleanValue');
  Add(AName, AValue);
  _UpdateContext(AName);
  _EndOperation;
  Result := Self;
end;

function TJSONComposer.NullValue(const AName: String): IJSONComposer;
begin
  _StartOperation;
  _ValidateContext('NullValue');
  AddNull(AName);
  _UpdateContext(AName);
  _EndOperation;
  Result := Self;
end;

function TJSONComposer.DateTimeValue(const AName: String; AValue: TDateTime): IJSONComposer;
begin
  _StartOperation;
  _ValidateContext('DateTimeValue');
  Add(AName, AValue);
  _UpdateContext(AName);
  _EndOperation;
  Result := Self;
end;

function TJSONComposer.ObjectValue(const AName: String; const ACallback: TJSONObjectCallback): IJSONComposer;
begin
  _StartOperation;
  _ValidateContext('ObjectValue');
  
  BeginObject(AName);
  FContextStack.Push(AName);
  
  if Assigned(ACallback) then
    ACallback(Self);
    
  FContextStack.Pop;
  EndObject;
  
  _UpdateContext(AName);
  _EndOperation;
  Result := Self;
end;

function TJSONComposer.ArrayValue(const AName: String; const ACallback: TJSONArrayCallback): IJSONComposer;
begin
  _StartOperation;
  _ValidateContext('ArrayValue');
  
  BeginArray(AName);
  FContextStack.Push(AName);
  
  if Assigned(ACallback) then
    ACallback(Self);
    
  FContextStack.Pop;
  EndArray;
  
  _UpdateContext(AName);
  _EndOperation;
  Result := Self;
end;

// FASE 2: Context-aware features
function TJSONComposer.NavigateTo(const APath: String): IJSONComposer;
var
  LElement: IJSONElement;
begin
  _StartOperation;
  LElement := _FindElement(APath);
  if Assigned(LElement) then
  begin
    FCurrent := LElement;
    FCurrentContext := APath;
    if FDebugMode then
      AddLog('Navigated to: ' + APath);
  end;
  _EndOperation;
  Result := Self;
end;

function TJSONComposer.GetCurrentPath: String;
begin
  Result := _GetCurrentPath;
end;

function TJSONComposer.GetContextInfo: TContextInfo;
begin
  Result := _BuildContextInfo;
end;

function TJSONComposer.EnableDebugMode(AEnabled: Boolean): IJSONComposer;
begin
  FDebugMode := AEnabled;
  if FDebugMode then
    AddLog('Debug mode enabled')
  else
    AddLog('Debug mode disabled');
  Result := Self;
end;

function TJSONComposer.GetCompositionTrace: TArray<String>;
var
  LTrace: TList<String>;
  LInfo: TContextInfo;
begin
  LTrace := TList<String>.Create;
  try
    LInfo := GetContextInfo;
    LTrace.Add('Current Path: ' + LInfo.CurrentPath);
    LTrace.Add('Context Type: ' + LInfo.ContextType);
    LTrace.Add('Depth: ' + IntToStr(LInfo.Depth));
    LTrace.Add('Parent Key: ' + LInfo.ParentKey);
    LTrace.Add('Operations: ' + IntToStr(FOperationCount));
    Result := LTrace.ToArray;
  finally
    LTrace.Free;
  end;
end;

// FASE 3: Smart suggestions
function TJSONComposer.GetSuggestions(const AContext: String): TArray<TJSONSuggestion>;
var
  LCacheKey: String;
begin
  LCacheKey := AContext + '_' + FCurrentContext;
  
  if not FSuggestionCache.ContainsKey(LCacheKey) then
    FSuggestionCache.Add(LCacheKey, _GetContextSuggestions);
    
  Result := FSuggestionCache[LCacheKey];
end;

function TJSONComposer.SuggestKeys: TArray<String>;
var
  LSuggestions: TArray<TJSONSuggestion>;
  LKeys: TList<String>;
  I: Integer;
begin
  LSuggestions := GetSuggestions;
  LKeys := TList<String>.Create;
  try
    for I := 0 to Length(LSuggestions) - 1 do
      if LSuggestions[I].SuggestionType = 'key' then
        LKeys.Add(LSuggestions[I].Value);
    Result := LKeys.ToArray;
  finally
    LKeys.Free;
  end;
end;

function TJSONComposer.SuggestValues(const AKey: String): TArray<Variant>;
var
  LValues: TList<Variant>;
begin
  LValues := TList<Variant>.Create;
  try
    // Sugestões básicas baseadas no nome da chave
    if AKey.Contains('name') or AKey.Contains('title') then
      LValues.Add('Sample Text')
    else if AKey.Contains('count') or AKey.Contains('age') or AKey.Contains('id') then
      LValues.Add(0)
    else if AKey.Contains('active') or AKey.Contains('enabled') then
      LValues.Add(True)
    else if AKey.Contains('date') or AKey.Contains('time') then
      LValues.Add(Now);
      
    Result := LValues.ToArray;
  finally
    LValues.Free;
  end;
end;

function TJSONComposer.EnableRealTimeValidation(AEnabled: Boolean): IJSONComposer;
begin
  FRealTimeValidation := AEnabled;
  if AEnabled then
    AddLog('Real-time validation enabled')
  else
    AddLog('Real-time validation disabled');
  Result := Self;
end;

function TJSONComposer.QuickValidate: Boolean;
var
  LErrors: TArray<String>;
begin
  LErrors := _ValidateStructure;
  Result := Length(LErrors) = 0;
end;

function TJSONComposer.ValidateStructure: TArray<String>;
begin
  Result := _ValidateStructure;
end;

function TJSONComposer.IsValidJSON: Boolean;
begin
  try
    Result := Assigned(FRoot) and (FStack.Count = 0);
  except
    Result := False;
  end;
end;

function TJSONComposer.GetValidationErrors: TArray<String>;
begin
  Result := FValidationErrors.ToArray;
end;

// FASE 4: Performance e recursos avançados
function TJSONComposer.GetPerformanceMetrics: TPerformanceInfo;
begin
  _UpdatePerformanceMetrics;
  Result := FPerformanceInfo;
end;

function TJSONComposer.OptimizeMemory: IJSONComposer;
begin
  // Limpa caches desnecessários
  FSuggestionCache.Clear;
  FValidationErrors.Clear;
  
  // Force garbage collection (se necessário)
  if FDebugMode then
    AddLog('Memory optimization performed');
    
  _UpdatePerformanceMetrics;
  Result := Self;
end;

function TJSONComposer.EnableLazyLoading(AEnabled: Boolean): IJSONComposer;
begin
  // Implementação futura para lazy loading
  if FDebugMode then
  begin
    if AEnabled then
      AddLog('Lazy loading enabled')
    else
      AddLog('Lazy loading disabled');
  end;
  Result := Self;
end;

function TJSONComposer.Benchmark(const AOperation: TProc): TTimeSpan;
var
  LStartTime: TDateTime;
begin
  LStartTime := Now;
  if Assigned(AOperation) then
    AOperation();
  Result := TTimeSpan.FromMilliseconds(MilliSecondsBetween(Now, LStartTime));
end;

// Factory methods
class function TJSONComposer.CreateForObject: TJSONComposer;
begin
  Result := TJSONComposer.Create;
  Result.BeginObject;
end;

class function TJSONComposer.CreateForArray: TJSONComposer;
begin
  Result := TJSONComposer.Create;
  Result.BeginArray;
end;

class function TJSONComposer.CreateFromJSON(const AJson: String): TJSONComposer;
begin
  Result := TJSONComposer.Create;
  Result.LoadJSON(AJson);
end;

// All method implementations moved to appropriate Enhanced/Pool modules

end.

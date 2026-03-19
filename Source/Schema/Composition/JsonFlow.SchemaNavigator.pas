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

unit JsonFlow.SchemaNavigator;

interface

uses
  System.Classes,
  System.IOUtils,
  System.SysUtils,
  System.StrUtils,
  System.Generics.Collections,
  JsonFlow.Interfaces,
  JsonFlow.Reader;

type
  TJSONSchemaNavigator = class
  private
    FRoot: IJSONElement;
    FLogProc: TProc<String>;
    FExternalSchemas: TDictionary<String, IJSONElement>;
    FMaxDepth: Integer;
    FVisitedRefs: TStringList;
    FCurrentDepth: Integer;
    function _NavigatePointer(const APointer: String; const AElement: IJSONElement): IJSONElement;
    function _ResolveRef(const ARef: String; const ABasePath: String = ''): IJSONElement;
    function _LoadExternalSchema(const AUri: String; const ABasePath: String): IJSONElement;
    function _FindAnchor(const AAnchor: String; const AElement: IJSONElement): IJSONElement;
    function _FindAnchorSafe(const AAnchor: String; const AElement: IJSONElement; ADepth: Integer): IJSONElement;
    function _ResolveRefSafe(const ARef: String; const ABasePath: String = ''): IJSONElement;
    function _IsCircularReference(const ARef: String): Boolean;
    procedure _ResetCircularDetection;
  protected
    procedure _Log(const AMessage: string);
  public
    constructor Create(const ARoot: IJSONElement);
    destructor Destroy; override;
    function GetValue(const APointer: String): IJSONElement;
    function GetObject(const APointer: String): IJSONObject;
    function GetArray(const APointer: String): IJSONArray;
    function ResolveReference(const ARef: String; const ABasePath: String = ''): IJSONElement;
    function ResolveReferenceSafe(const ARef: String; const ABasePath: String = ''): IJSONElement;
    procedure OnLog(const ALogProc: TProc<String>);
    procedure ResetCircularDetection;
    property Root: IJSONElement read FRoot;
    property MaxDepth: Integer read FMaxDepth write FMaxDepth;
    property CurrentDepth: Integer read FCurrentDepth;
  end;

implementation

constructor TJSONSchemaNavigator.Create(const ARoot: IJSONElement);
begin
  if not Assigned(ARoot) then
    raise EArgumentNilException.Create('Root schema element cannot be nil');
  FRoot := ARoot;
  FExternalSchemas := TDictionary<String, IJSONElement>.Create;
  FVisitedRefs := TStringList.Create;
  FMaxDepth := 100; // Limite padrão de 100 níveis
  FCurrentDepth := 0;
end;

destructor TJSONSchemaNavigator.Destroy;
begin
  FExternalSchemas.Free;
  FVisitedRefs.Free;
  FRoot := nil;
  inherited;
end;

function TJSONSchemaNavigator._NavigatePointer(const APointer: String; const AElement: IJSONElement): IJSONElement;
var
  LParts: TArray<String>;
  LCurrent: IJSONElement;
  LObject: IJSONObject;
  LArray: IJSONArray;
  LPart: String;
  LIndex: Integer;
  LFor: Integer;
begin
  if not Assigned(AElement) then
    Exit(nil);

  if (APointer = '') or (APointer = '/') then
    Exit(AElement);

  if not APointer.StartsWith('/') then
    Exit(nil);
  LParts := APointer.Substring(1).Split(['/']);
  LCurrent := AElement;

  for LFor := 0 to Length(LParts) - 1 do
  begin
    LPart := LParts[LFor];
    LPart := LPart.Replace('~1', '/', [rfReplaceAll]).Replace('~0', '~', [rfReplaceAll]);

    if Supports(LCurrent, IJSONObject, LObject) then
    begin
      LCurrent := LObject.GetValue(LPart);
      if not Assigned(LCurrent) then
        Exit(nil);
    end
    else if Supports(LCurrent, IJSONArray, LArray) then
    begin
      if not TryStrToInt(LPart, LIndex) or (LIndex < 0) or (LIndex >= LArray.Count) then
        Exit(nil);
      LCurrent := LArray.Value(LIndex);
      if not Assigned(LCurrent) then
        Exit(nil);
    end
    else
      Exit(nil);
  end;
  Result := LCurrent;
end;

function TJSONSchemaNavigator._FindAnchor(const AAnchor: String;
  const AElement: IJSONElement): IJSONElement;
var
  LObject: IJSONObject;
  LArray: IJSONArray;
  LPair: IJSONPair;
  LValue: IJSONValue;
  LFor: Integer;
begin
  Result := nil;
  if not Assigned(AElement) then
    Exit;

  if Supports(AElement, IJSONObject, LObject) then
  begin
    LValue := LObject.GetValue('$anchor') as IJSONValue;
    if Assigned(LValue) and (LValue.AsString = AAnchor) then
      Exit(AElement);

    for LPair in LObject.Pairs do
    begin
      Result := _FindAnchor(AAnchor, LPair.Value);
      if Assigned(Result) then
        Exit;
    end;
  end
  else if Supports(AElement, IJSONArray, LArray) then
  begin
    for LFor := 0 to LArray.Count - 1 do
    begin
      Result := _FindAnchor(AAnchor, LArray.Value(LFor));
      if Assigned(Result) then
        Exit;
    end;
  end;
end;

function TJSONSchemaNavigator._LoadExternalSchema(const AUri: String; const ABasePath: String): IJSONElement;
var
  LReader: TJSONReader;
  LFullPath: String;
  LJsonContent: String;
begin
  if FExternalSchemas.TryGetValue(AUri, Result) then
    Exit;

  if AUri.StartsWith('http://') or AUri.StartsWith('https://') then
    raise Exception.Create('External schema loading via HTTP not implemented yet: ' + AUri);

  if (ABasePath <> '') and TFile.Exists(ABasePath) then
    LFullPath := ABasePath
  else
    LFullPath := TPath.Combine(TPath.GetDirectoryName(ABasePath), AUri);

  if not TFile.Exists(LFullPath) then
    Exit(nil);

  LJsonContent := TFile.ReadAllText(LFullPath);
  LReader := TJSONReader.Create;
  try
    try
      Result := LReader.Read(LJsonContent);
      FExternalSchemas.Add(AUri, Result);
    except
      on E: Exception do
      begin
        Result := nil;
      end;
    end;
  finally
    LReader.Free;
  end;
end;

procedure TJSONSchemaNavigator._Log(const AMessage: string);
begin
  if Assigned(FLogProc) then
    FLogProc(AMessage);
end;

function TJSONSchemaNavigator._ResolveRef(const ARef: String; const ABasePath: String): IJSONElement;
var
  LUri, LPointer: String;
  LHashPos: Integer;
  LSchema: IJSONElement;
begin
  if ARef = '' then
    Exit(nil);

  LHashPos := Pos('#', ARef);
  if LHashPos > 0 then
  begin
    LUri := Copy(ARef, 1, LHashPos - 1);
    LPointer := Copy(ARef, LHashPos + 1);
  end
  else
  begin
    LUri := ARef;
    LPointer := '';
  end;

  if LUri <> '' then
  begin
    LSchema := _LoadExternalSchema(LUri, ABasePath);
    if not Assigned(LSchema) then
      Exit(nil);
  end
  else
    LSchema := FRoot;

  if (LPointer <> '') and not LPointer.StartsWith('/') then
  begin
    Result := _FindAnchor(LPointer, LSchema);
    if Assigned(Result) then
      Exit;
    Exit(nil);
  end;

  if LPointer.StartsWith('/') then
    Result := _NavigatePointer(LPointer, LSchema)
  else
    Result := _NavigatePointer('/' + LPointer, LSchema);
end;

function TJSONSchemaNavigator.GetValue(const APointer: String): IJSONElement;
begin
  if Trim(APointer) = '' then
    Result := FRoot
  else
    Result := _NavigatePointer(APointer, FRoot);
end;

procedure TJSONSchemaNavigator.OnLog(const ALogProc: TProc<String>);
begin
  FLogProc := ALogProc;
end;

function TJSONSchemaNavigator.GetObject(const APointer: String): IJSONObject;
var
  LElement: IJSONElement;
begin
  LElement := GetValue(APointer);
  if Supports(LElement, IJSONObject, Result) then
    Exit;
  Result := nil;
end;

function TJSONSchemaNavigator.GetArray(const APointer: String): IJSONArray;
var
  LElement: IJSONElement;
begin
  LElement := GetValue(APointer);
  if Supports(LElement, IJSONArray, Result) then
    Exit;
  Result := nil;
end;

function TJSONSchemaNavigator.ResolveReference(const ARef: String; const ABasePath: String): IJSONElement;
begin
  Result := _ResolveRef(ARef, ABasePath);
end;

function TJSONSchemaNavigator._IsCircularReference(const ARef: String): Boolean;
begin
  Result := FVisitedRefs.IndexOf(ARef) >= 0;
end;

procedure TJSONSchemaNavigator._ResetCircularDetection;
begin
  FVisitedRefs.Clear;
  FCurrentDepth := 0;
end;

function TJSONSchemaNavigator._FindAnchorSafe(const AAnchor: String; const AElement: IJSONElement; ADepth: Integer): IJSONElement;
var
  LObject: IJSONObject;
  LArray: IJSONArray;
  LPair: IJSONPair;
  LValue: IJSONValue;
  LFor: Integer;
begin
  Result := nil;
  if not Assigned(AElement) or (ADepth >= FMaxDepth) then
    Exit;

  if Supports(AElement, IJSONObject, LObject) then
  begin
    LValue := LObject.GetValue('$anchor') as IJSONValue;
    if Assigned(LValue) and (LValue.AsString = AAnchor) then
      Exit(AElement);

    for LPair in LObject.Pairs do
    begin
      Result := _FindAnchorSafe(AAnchor, LPair.Value, ADepth + 1);
      if Assigned(Result) then
        Exit;
    end;
  end
  else if Supports(AElement, IJSONArray, LArray) then
  begin
    for LFor := 0 to LArray.Count - 1 do
    begin
      Result := _FindAnchorSafe(AAnchor, LArray.Value(LFor), ADepth + 1);
      if Assigned(Result) then
        Exit;
    end;
  end;
end;

function TJSONSchemaNavigator._ResolveRefSafe(const ARef: String; const ABasePath: String): IJSONElement;
begin
  Result := nil;
  
  // Verificar referência circular
  if _IsCircularReference(ARef) then
  begin
    _Log('Circular reference detected: ' + ARef);
    Exit;
  end;
  
  // Verificar limite de profundidade
  if FCurrentDepth >= FMaxDepth then
  begin
    _Log('Maximum depth reached: ' + IntToStr(FMaxDepth));
    Exit;
  end;
  
  // Adicionar à lista de visitados e incrementar profundidade
  FVisitedRefs.Add(ARef);
  Inc(FCurrentDepth);
  
  try
    // Resolver a referência usando o método original
    Result := _ResolveRef(ARef, ABasePath);
  finally
    // Remover da lista de visitados e decrementar profundidade
    FVisitedRefs.Delete(FVisitedRefs.IndexOf(ARef));
    Dec(FCurrentDepth);
  end;
end;

function TJSONSchemaNavigator.ResolveReferenceSafe(const ARef: String; const ABasePath: String): IJSONElement;
begin
  Result := _ResolveRefSafe(ARef, ABasePath);
end;

procedure TJSONSchemaNavigator.ResetCircularDetection;
begin
  _ResetCircularDetection;
end;

end.


{
  ------------------------------------------------------------------------------
  JsonFlow
  High-performance JSON serialization, dynamic manipulation, and Draft 7 Schema validation framework for Delphi.

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro

  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.
  ------------------------------------------------------------------------------
}

{$include ../../JsonFlow.inc}

unit JsonFlow.Objects;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Defaults,
  System.Generics.Collections,
  JsonFlow.Interfaces,
  JsonFlow.Pair;

type
  TJSONObject = class(TInterfacedObject, IJSONElement, IJSONObject, IJSONCompactWriter)
  private const
    // Abaixo disso a varredura linear é mais barata que manter o dicionário
    // (objetos JSON típicos têm poucas chaves e não pagam alocação extra).
    INDEX_THRESHOLD = 8;
  private
    FPairs: TList<IJSONPair>;
    FIndex: TDictionary<String, Integer>;
    procedure _BuildIndex;
    function _FindPair(const AKey: String; out AIndex: Integer): IJSONPair;
  public
    constructor Create;
    destructor Destroy; override;
    function Add(const AKey: String; const AValue: IJSONElement): IJSONPair;
    function GetValue(const AKey: String): IJSONElement;
    function TryGetValue(const AKey: String; out AValue: IJSONElement): Boolean;
    function ContainsKey(const AKey: String): Boolean;
    function Count: Integer;
    procedure Remove(const AKey: String);
    procedure Clear;
    procedure ForEach(const ACallback: TProc<String, IJSONElement>);
    function Filter(const APredicate: TFunc<String, IJSONElement, Boolean>): IJSONObject;
    function Map(const ATransform: TFunc<String, IJSONElement, IJSONPair>): IJSONObject;
    function Pairs: TArray<IJSONPair>;
    procedure AppendCompactJSON(ABuilder: TStringBuilder);
    function AsJSON(const AIdent: Boolean = False): String;
    procedure SaveToStream(AStream: TStream; const AIdent: Boolean = False);
    function Clone: IJSONElement;
    function TypeName: string;
  end;

implementation

type
  // Igualdade idêntica à do SameText (folding apenas de a-z, como CompareText)
  // para o índice reproduzir exatamente a semântica do lookup linear anterior.
  TSameTextEqualityComparer = class(TEqualityComparer<String>)
  public
    function Equals(const Left, Right: String): Boolean; override;
    function GetHashCode(const Value: String): Integer; override;
  end;

var
  GSameTextComparer: IEqualityComparer<String>;

function TSameTextEqualityComparer.Equals(const Left, Right: String): Boolean;
begin
  Result := SameText(Left, Right);
end;

function TSameTextEqualityComparer.GetHashCode(const Value: String): Integer;
var
  LFor: Integer;
  LChar: Word;
  LHash: Cardinal;
begin
  // FNV-1a com o mesmo folding a-z -> A-Z do CompareText/SameText,
  // garantindo hash consistente com Equals.
  LHash := 2166136261;
  for LFor := 1 to Length(Value) do
  begin
    LChar := Word(Value[LFor]);
    if (LChar >= Word('a')) and (LChar <= Word('z')) then
      Dec(LChar, 32);
    LHash := (LHash xor LChar) * 16777619;
  end;
  Result := Integer(LHash);
end;

{ TJSONObject }

constructor TJSONObject.Create;
begin
  inherited Create;
  FPairs := TList<IJSONPair>.Create;
end;

destructor TJSONObject.Destroy;
begin
  FIndex.Free;
  FPairs.Clear;
  FPairs.Free;
  inherited;
end;

procedure TJSONObject._BuildIndex;
var
  LFor: Integer;
begin
  FIndex := TDictionary<String, Integer>.Create(FPairs.Count * 2, GSameTextComparer);
  for LFor := 0 to FPairs.Count - 1 do
    FIndex.AddOrSetValue(FPairs[LFor].Key, LFor);
end;

function TJSONObject._FindPair(const AKey: String; out AIndex: Integer): IJSONPair;
var
  LFor: Integer;
begin
  Result := nil;
  AIndex := -1;
  if Assigned(FIndex) then
  begin
    if FIndex.TryGetValue(AKey, LFor) then
    begin
      AIndex := LFor;
      Result := FPairs[LFor];
    end;
    Exit;
  end;
  for LFor := 0 to FPairs.Count - 1 do
    if SameText(FPairs[LFor].Key, AKey) then
    begin
      Result := FPairs[LFor];
      AIndex := LFor;
      Break;
    end;
end;

function TJSONObject.Add(const AKey: String; const AValue: IJSONElement): IJSONPair;
var
  LPair: IJSONPair;
  LIndex: Integer;
begin
  LPair := _FindPair(AKey, LIndex);
  if Assigned(LPair) then
  begin
    LPair.Value := AValue;
    Result := LPair;
  end
  else
  begin
    LPair := TJSONPair.Create(AKey, AValue);
    FPairs.Add(LPair);
    Result := LPair;
    if Assigned(FIndex) then
      FIndex.AddOrSetValue(AKey, FPairs.Count - 1)
    else if FPairs.Count > INDEX_THRESHOLD then
      _BuildIndex;
  end;
end;

function TJSONObject.GetValue(const AKey: String): IJSONElement;
var
  LPair: IJSONPair;
  LIndex: Integer;
begin
  LPair := _FindPair(AKey, LIndex);
  if Assigned(LPair) then
    Result := LPair.Value
  else
    Result := nil;
end;

function TJSONObject.TryGetValue(const AKey: String; out AValue: IJSONElement): Boolean;
var
  LPair: IJSONPair;
  LIndex: Integer;
begin
  LPair := _FindPair(AKey, LIndex);
  Result := Assigned(LPair);
  if Result then
    AValue := LPair.Value
  else
    AValue := nil;
end;

function TJSONObject.ContainsKey(const AKey: String): Boolean;
var
  LIndex: Integer;
begin
  Result := Assigned(_FindPair(AKey, LIndex));
end;

function TJSONObject.Count: Integer;
begin
  Result := FPairs.Count;
end;

procedure TJSONObject.Remove(const AKey: String);
var
  LIndex: Integer;
begin
  if _FindPair(AKey, LIndex) <> nil then
  begin
    FPairs.Delete(LIndex);
    // Delete desloca os índices seguintes; reconstrução é O(k) e Remove é raro.
    if Assigned(FIndex) then
    begin
      FreeAndNil(FIndex);
      if FPairs.Count > INDEX_THRESHOLD then
        _BuildIndex;
    end;
  end;
end;

procedure TJSONObject.Clear;
begin
  FreeAndNil(FIndex);
  FPairs.Clear;
end;

procedure TJSONObject.ForEach(const ACallback: TProc<String, IJSONElement>);
var
  LFor: Integer;
begin
  if Assigned(ACallback) then
    for LFor := 0 to FPairs.Count - 1 do
      ACallback(FPairs[LFor].Key, FPairs[LFor].Value);
end;

function TJSONObject.Filter(const APredicate: TFunc<String, IJSONElement, Boolean>): IJSONObject;
var
  LFor: Integer;
  LPair: IJSONPair;
begin
  Result := TJSONObject.Create;
  if Assigned(APredicate) then
    for LFor := 0 to FPairs.Count - 1 do
    begin
      LPair := FPairs[LFor];
      if APredicate(LPair.Key, LPair.Value) then
        Result.Add(LPair.Key, LPair.Value);
    end;
end;

function TJSONObject.Map(const ATransform: TFunc<String, IJSONElement, IJSONPair>): IJSONObject;
var
  LFor: Integer;
  LNewPair: IJSONPair;
begin
  Result := TJSONObject.Create;
  if Assigned(ATransform) then
    for LFor := 0 to FPairs.Count - 1 do
    begin
      LNewPair := ATransform(FPairs[LFor].Key, FPairs[LFor].Value);
      if Assigned(LNewPair) then
        Result.Add(LNewPair.Key, LNewPair.Value);
    end;
end;

function TJSONObject.Pairs: TArray<IJSONPair>;
begin
  Result := FPairs.ToArray;
end;

procedure TJSONObject.AppendCompactJSON(ABuilder: TStringBuilder);
var
  LFor: Integer;
  LValue: IJSONElement;
  LCompact: IJSONCompactWriter;
begin
  ABuilder.Append('{');
  for LFor := 0 to FPairs.Count - 1 do
  begin
    if LFor > 0 then
      ABuilder.Append(',');
    ABuilder.Append('"');
    ABuilder.Append(StringReplace(FPairs[LFor].Key, '"', '\"', [rfReplaceAll]));
    ABuilder.Append('":');
    LValue := FPairs[LFor].Value;
    if not Assigned(LValue) then
      ABuilder.Append(JSON_NULL)
    else if Supports(LValue, IJSONCompactWriter, LCompact) then
      LCompact.AppendCompactJSON(ABuilder)
    else
      ABuilder.Append(LValue.AsJSON(False));
  end;
  ABuilder.Append('}');
end;

function TJSONObject.AsJSON(const AIdent: Boolean): String;
var
  LBuilder: TStringBuilder;
  LFor: Integer;
  LIndent: String;
begin
  // Compacto: recursão num único builder — antes cada nível materializava a
  // subárvore inteira como String (Pair.AsJSON -> Value.AsJSON -> ...).
  if not AIdent then
  begin
    LBuilder := TStringBuilder.Create(1024);
    try
      AppendCompactJSON(LBuilder);
      Result := LBuilder.ToString;
    finally
      LBuilder.Free;
    end;
    Exit;
  end;

  LBuilder := TStringBuilder.Create;
  try
    if AIdent then
      LIndent := StringOfChar(' ', 2)
    else
      LIndent := '';

    LBuilder.Append('{');
    if FPairs.Count > 0 then
    begin
      if AIdent then
        LBuilder.AppendLine;
      for LFor := 0 to FPairs.Count - 1 do
      begin
        if AIdent then
          LBuilder.Append(LIndent);
        LBuilder.Append(FPairs[LFor].AsJSON(AIdent));
        if LFor < FPairs.Count - 1 then
          LBuilder.Append(',');
        if AIdent then
          LBuilder.AppendLine;
      end;
      if AIdent then
        LBuilder.Append(LIndent);
    end;
    LBuilder.Append('}');
    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

procedure TJSONObject.SaveToStream(AStream: TStream; const AIdent: Boolean);
var
  LJson: String;
  LBytes: TBytes;
begin
  LJson := AsJSON(AIdent);
  LBytes := TEncoding.UTF8.GetBytes(LJson);
  AStream.WriteBuffer(LBytes, Length(LBytes));
end;

function TJSONObject.TypeName: string;
begin
  Result := 'object';
end;

function TJSONObject.Clone: IJSONElement;
var
  LClone: TJSONObject;
  LFor: Integer;
begin
  LClone := TJSONObject.Create;
  for LFor := 0 to FPairs.Count - 1 do
    LClone.Add(FPairs[LFor].Key, FPairs[LFor].Value.Clone);
  Result := LClone;
end;

initialization
  GSameTextComparer := TSameTextEqualityComparer.Create;

end.

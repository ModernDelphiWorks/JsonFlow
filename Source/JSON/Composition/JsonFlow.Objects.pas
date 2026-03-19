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

unit JsonFlow.Objects;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  JsonFlow.Interfaces,
  JsonFlow.Pair;

type
  TJSONObject = class(TInterfacedObject, IJSONElement, IJSONObject)
  private
    FPairs: TList<IJSONPair>;
    function _FindPair(const AKey: String; out AIndex: Integer): IJSONPair;
  public
    constructor Create;
    destructor Destroy; override;
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
    function AsJSON(const AIdent: Boolean = False): String;
    procedure SaveToStream(AStream: TStream; const AIdent: Boolean = False);
    function Clone: IJSONElement;
    function TypeName: string;
  end;

implementation

{ TJSONObject }

constructor TJSONObject.Create;
begin
  inherited Create;
  FPairs := TList<IJSONPair>.Create;
end;

destructor TJSONObject.Destroy;
begin
  FPairs.Clear;
  FPairs.Free;
  inherited;
end;

function TJSONObject._FindPair(const AKey: String; out AIndex: Integer): IJSONPair;
var
  LFor: Integer;
begin
  Result := nil;
  AIndex := -1;
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
    FPairs.Delete(LIndex);
end;

procedure TJSONObject.Clear;
begin
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

function TJSONObject.AsJSON(const AIdent: Boolean): String;
var
  LBuilder: TStringBuilder;
  LFor: Integer;
  LIndent: String;
begin
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

end.

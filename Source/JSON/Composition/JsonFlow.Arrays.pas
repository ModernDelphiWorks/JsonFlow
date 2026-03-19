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

unit JsonFlow.Arrays;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  JsonFlow.Interfaces;

type
  TJSONArray = class(TInterfacedObject, IJSONElement, IJSONArray)
  private
    FItems: TList<IJSONElement>;
    function _GetElement(AIndex: Integer; ARaiseOnError: Boolean): IJSONElement;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(const AValue: IJSONElement);
    function GetItem(const AIndex: Integer): IJSONElement;
    function Count: Integer;
    procedure Remove(const AIndex: Integer);
    procedure Clear;
    procedure ForEach(const ACallback: TProc<IJSONElement>);
    function Filter(const APredicate: TFunc<IJSONElement, Boolean>): IJSONArray;
    function Map(const ATransform: TFunc<IJSONElement, IJSONElement>): IJSONArray;
    function Items: TArray<IJSONElement>;
    function AsJSON(const AIdent: Boolean = False): String;
    procedure SaveToStream(AStream: TStream; const AIdent: Boolean = False);
    function Clone: IJSONElement;
    function Value(AIndex: Integer): IJSONElement;
    function TypeName: string;
  end;

implementation

{ TJSONArray }

constructor TJSONArray.Create;
begin
  inherited Create;
  FItems := TList<IJSONElement>.Create;
end;

destructor TJSONArray.Destroy;
begin
  FItems.Free;
  inherited;
end;

procedure TJSONArray.Add(const AValue: IJSONElement);
begin
  if AValue = nil then
    raise EArgumentNilException.Create('Cannot add nil element to JSONArray');
  FItems.Add(AValue);
end;

function TJSONArray.GetItem(const AIndex: Integer): IJSONElement;
begin
  Result := _GetElement(AIndex, True);
end;

function TJSONArray.Count: Integer;
begin
  Result := FItems.Count;
end;

procedure TJSONArray.Remove(const AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex >= FItems.Count) then
    raise EArgumentOutOfRangeException.CreateFmt('Index %d out of bounds [0..%d]', [AIndex, FItems.Count - 1]);
  FItems.Delete(AIndex);
end;

procedure TJSONArray.Clear;
begin
  FItems.Clear;
end;

procedure TJSONArray.ForEach(const ACallback: TProc<IJSONElement>);
var
  LFor: Integer;
begin
  if not Assigned(ACallback) then
    raise EArgumentNilException.Create('Callback cannot be nil');
  for LFor := 0 to FItems.Count - 1 do
    ACallback(FItems[LFor]);
end;

function TJSONArray.Filter(const APredicate: TFunc<IJSONElement, Boolean>): IJSONArray;
var
  LFor: Integer;
begin
  if not Assigned(APredicate) then
    raise EArgumentNilException.Create('Predicate cannot be nil');
  Result := TJSONArray.Create;
  for LFor := 0 to FItems.Count - 1 do
    if APredicate(FItems[LFor]) then
      Result.Add(FItems[LFor].Clone);
end;

function TJSONArray.Map(const ATransform: TFunc<IJSONElement, IJSONElement>): IJSONArray;
var
  LFor: Integer;
  LNewItem: IJSONElement;
begin
  if not Assigned(ATransform) then
    raise EArgumentNilException.Create('Transform function cannot be nil');
  Result := TJSONArray.Create;
  for LFor := 0 to FItems.Count - 1 do
  begin
    LNewItem := ATransform(FItems[LFor]);
    if not Assigned(LNewItem) then
      raise EInvalidOperation.Create('Transform function returned nil');
    Result.Add(LNewItem);
  end;
end;

function TJSONArray.Items: TArray<IJSONElement>;
begin
  Result := FItems.ToArray;
end;

function TJSONArray.AsJSON(const AIdent: Boolean): String;
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

    LBuilder.Append('[');
    if FItems.Count > 0 then
    begin
      if AIdent then
        LBuilder.AppendLine;
      for LFor := 0 to FItems.Count - 1 do
      begin
        if AIdent then
          LBuilder.Append(LIndent);
        LBuilder.Append(FItems[LFor].AsJSON(AIdent));
        if LFor < FItems.Count - 1 then
          LBuilder.Append(',');
        if AIdent then
          LBuilder.AppendLine;
      end;
      if AIdent then
        LBuilder.Append(LIndent);
    end;
    LBuilder.Append(']');
    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

procedure TJSONArray.SaveToStream(AStream: TStream; const AIdent: Boolean);
var
  LJson: String;
  LBytes: TBytes;
begin
  LJson := AsJSON(AIdent);
  LBytes := TEncoding.UTF8.GetBytes(LJson);
  AStream.WriteBuffer(LBytes, Length(LBytes));
end;

function TJSONArray.TypeName: string;
begin
  Result := 'array';
end;

function TJSONArray.Value(AIndex: Integer): IJSONElement;
begin
  Result := _GetElement(AIndex, False);
end;

function TJSONArray._GetElement(AIndex: Integer; ARaiseOnError: Boolean): IJSONElement;
begin
  if (AIndex >= 0) and (AIndex < FItems.Count) then
    Result := FItems[AIndex]
  else if ARaiseOnError then
    raise EArgumentOutOfRangeException.CreateFmt('Index %d out of bounds [0..%d]', [AIndex, FItems.Count - 1])
  else
    Result := nil;
end;

function TJSONArray.Clone: IJSONElement;
var
  LClone: TJSONArray;
  LFor: Integer;
begin
  LClone := TJSONArray.Create;
  for LFor := 0 to FItems.Count - 1 do
    LClone.Add(FItems[LFor].Clone);
  Result := LClone;
end;

end.

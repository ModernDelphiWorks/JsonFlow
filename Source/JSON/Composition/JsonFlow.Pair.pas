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

unit JsonFlow.Pair;

interface

uses
  System.SysUtils,
  JsonFlow.Interfaces;

type
  TJSONPair = class(TInterfacedObject, IJSONPair)
  private
    FKey: String;
    FValue: IJSONElement;
    function _GetKey: String;
    procedure _SetKey(const AValue: String);
    function _GetValue: IJSONElement;
    procedure _SetValue(const AValue: IJSONElement);
  public
    constructor Create(const AKey: String; const AValue: IJSONElement);
    destructor Destroy; override;
    function AsJSON(const AIdent: Boolean = False): String;
    property Key: String read _GetKey write _SetKey;
    property Value: IJSONElement read _GetValue write _SetValue;
  end;

implementation

{ TJSONPair }

constructor TJSONPair.Create(const AKey: String; const AValue: IJSONElement);
begin
  inherited Create;
  if Trim(AKey) = '' then
    raise EArgumentException.Create('Key cannot be empty');
  FKey := AKey;
  FValue := AValue;
end;

destructor TJSONPair.Destroy;
begin
  FValue := nil;
  inherited;
end;

function TJSONPair._GetKey: String;
begin
  Result := FKey;
end;

procedure TJSONPair._SetKey(const AValue: String);
begin
  if Trim(AValue) = '' then
    raise EArgumentException.Create('Key cannot be empty');
  FKey := AValue;
end;

function TJSONPair._GetValue: IJSONElement;
begin
  Result := FValue;
end;

procedure TJSONPair._SetValue(const AValue: IJSONElement);
begin
  FValue := AValue;
end;

function TJSONPair.AsJSON(const AIdent: Boolean): String;
var
  LKeyStr, LValueStr: String;
begin
  LKeyStr := '"' + StringReplace(FKey, '"', '\"', [rfReplaceAll]) + '"';
  if Assigned(FValue) then
    LValueStr := FValue.AsJSON(AIdent)
  else
    LValueStr := JSON_NULL;

  if AIdent then
    Result := LKeyStr + ': ' + LValueStr
  else
    Result := LKeyStr + ':' + LValueStr;
end;

end.

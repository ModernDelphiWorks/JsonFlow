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

unit JsonFlow.Navigator;

interface

uses
  System.SysUtils,
  System.StrUtils,
  JsonFlow.Value,
  JsonFlow.Interfaces;

type
  TJSONNavigator = class
  private
    FRoot: IJSONElement;
    function _NavigatePath(const APath: String; const AElement: IJSONElement): IJSONElement;
    function _ExtractArrayIndex(const APart: String; out AIndex: Integer): Boolean;
  public
    constructor Create(const ARoot: IJSONElement);
    destructor Destroy; override;
    function GetValue(const APath: String): IJSONElement;
    function GetObject(const APath: String): IJSONObject;
    function GetArray(const APath: String): IJSONArray;
    function GetString(const APath: String): String;
    function GetInteger(const APath: String): Int64;
    function GetFloat(const APath: String): Double;
    function GetBoolean(const APath: String): Boolean;
    function IsNull(const APath: String): Boolean;
    property Root: IJSONElement read FRoot;
  end;

implementation

constructor TJSONNavigator.Create(const ARoot: IJSONElement);
begin
  if not Assigned(ARoot) then
    raise EArgumentNilException.Create('Root JSON element cannot be nil');
  FRoot := ARoot;
end;

destructor TJSONNavigator.Destroy;
begin
  FRoot := nil;
  inherited;
end;

function TJSONNavigator._ExtractArrayIndex(const APart: String; out AIndex: Integer): Boolean;
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

function TJSONNavigator._NavigatePath(const APath: String; const AElement: IJSONElement): IJSONElement;
var
  LParts: TArray<String>;
  LCurrent: IJSONElement;
  LObject: IJSONObject;
  LArray: IJSONArray;
  LPart, LKey: String;
  LIndex: Integer;
  LFor: Integer;
begin
  if not Assigned(AElement) then
    Exit(nil);

  LParts := APath.Split(['.']);
  LCurrent := AElement;

  for LFor := 0 to Length(LParts) - 1 do
  begin
    LPart := LParts[LFor];
    if LPart = '' then
      Continue;

    if Supports(LCurrent, IJSONObject, LObject) then
    begin
      if _ExtractArrayIndex(LPart, LIndex) then
      begin
        LKey := Copy(LPart, 1, Pos('[', LPart) - 1);
        if LKey = '' then
          Exit(nil);
        LCurrent := LObject.GetValue(LKey);
        if not Assigned(LCurrent) then
          Exit(nil);
        if not Supports(LCurrent, IJSONArray, LArray) then
          Exit(nil);
        if (LIndex < 0) or (LIndex >= LArray.Count) then
          Exit(nil);
        LCurrent := LArray.Value(LIndex);
        if not Assigned(LCurrent) then
          Exit(nil);
      end
      else
      begin
        LKey := LPart;
        LCurrent := LObject.GetValue(LKey);
        if not Assigned(LCurrent) then
          Exit(nil);
      end;
    end
    else if Supports(LCurrent, IJSONArray, LArray) then
    begin
      if not _ExtractArrayIndex(LPart, LIndex) then
        Exit(nil);
      if (LIndex < 0) or (LIndex >= LArray.Count) then
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

function TJSONNavigator.GetValue(const APath: String): IJSONElement;
begin
  if Trim(APath) = '' then
    Result := FRoot
  else
    Result := _NavigatePath(APath, FRoot);
end;

function TJSONNavigator.GetObject(const APath: String): IJSONObject;
var
  LElement: IJSONElement;
begin
  LElement := GetValue(APath);
  if Supports(LElement, IJSONObject, Result) then
    Exit;
  Result := nil;
end;

function TJSONNavigator.GetArray(const APath: String): IJSONArray;
var
  LElement: IJSONElement;
begin
  LElement := GetValue(APath);
  if Supports(LElement, IJSONArray, Result) then
    Exit;
  Result := nil;
end;

function TJSONNavigator.GetString(const APath: String): String;
var
  LValue: IJSONValue;
begin
  if Supports(GetValue(APath), IJSONValue, LValue) then
    Result := LValue.AsString
  else
    Result := '';
end;

function TJSONNavigator.GetInteger(const APath: String): Int64;
var
  LElement: IJSONElement;
  LValue: IJSONValue;
begin
  LElement := GetValue(APath);
  if Assigned(LElement) then
  begin
    if Supports(LElement, IJSONValue, LValue) then
      Result := LValue.AsInteger
    else
      raise Exception.Create('Not a numeric value in "' + APath + '"');
  end
  else
    Result := 0;
end;

function TJSONNavigator.GetFloat(const APath: String): Double;
var
  LValue: IJSONValue;
begin
  if Supports(GetValue(APath), IJSONValue, LValue) then
    Result := LValue.AsFloat
  else
    Result := 0.0;
end;

function TJSONNavigator.GetBoolean(const APath: String): Boolean;
var
  LValue: IJSONValue;
begin
  if Supports(GetValue(APath), IJSONValue, LValue) then
    Result := LValue.AsBoolean
  else
    Result := False;
end;

function TJSONNavigator.IsNull(const APath: String): Boolean;
var
  LValue: IJSONValue;
begin
  Result := Supports(GetValue(APath), IJSONValue, LValue) and (LValue is TJSONValueNull);
end;

end.

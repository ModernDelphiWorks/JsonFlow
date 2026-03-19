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

unit JsonFlow.Writer;

interface

uses
  System.SysUtils,
  System.Classes,
  JsonFlow.Interfaces;

type
  TJSONWriter = class(TInterfacedObject, IJSONWriter)
  private
    FLogProc: TProc<String>;
    FFormatSettings: TFormatSettings;
    procedure _WriteElement(const AElement: IJSONElement; ABuilder: TStringBuilder; const AIdent: Boolean; ALevel: Integer);
  protected
    procedure _Log(const AMessage: string);
  public
    constructor Create; overload;
    constructor Create(const AFormatSettings: TFormatSettings); overload;
    function Write(const AElement: IJSONElement; const AIdent: Boolean = False): String;
    procedure WriteToStream(const AElement: IJSONElement; AStream: TStream; const AIdent: Boolean = False);
    procedure OnLog(const ALogProc: TProc<String>);
  end;

implementation

uses
  JsonFlow.Objects,
  JsonFlow.Arrays;

{ TJSONWriter }

constructor TJSONWriter.Create;
begin
  FFormatSettings := TFormatSettings.Create('en-US');
  FFormatSettings.ShortDateFormat := 'yyyy-mm-dd';
  FFormatSettings.DateSeparator := '-';
  FFormatSettings.TimeSeparator := ':';
  FFormatSettings.DecimalSeparator := '.';
end;

constructor TJSONWriter.Create(const AFormatSettings: TFormatSettings);
begin
  Create;
  FFormatSettings := AFormatSettings;
end;

procedure TJSONWriter.OnLog(const ALogProc: TProc<String>);
begin
  FLogProc := ALogProc;
end;

procedure TJSONWriter._Log(const AMessage: string);
begin
  if Assigned(FLogProc) then
    FLogProc(AMessage);
end;

procedure TJSONWriter._WriteElement(const AElement: IJSONElement; ABuilder: TStringBuilder; const AIdent: Boolean; ALevel: Integer);
var
  LFor: Integer;
  LIndent: String;
  LObj: IJSONObject;
  LPairs: TArray<IJSONPair>;
  LArr: IJSONArray;
  LItems: TArray<IJSONElement>;
begin
  if not Assigned(AElement) then
  begin
    ABuilder.Append(JSON_NULL);
    Exit;
  end;

  if AIdent then
    LIndent := StringOfChar(' ', ALevel * 2)
  else
    LIndent := '';

  if Supports(AElement, IJSONObject, LObj) then
  begin
    LPairs := LObj.Pairs;
    ABuilder.Append('{');
    if Length(LPairs) > 0 then
    begin
      if AIdent then
        ABuilder.AppendLine;
      for LFor := 0 to Length(LPairs) - 1 do
      begin
        if AIdent then
          ABuilder.Append(LIndent + '  ');
        ABuilder.Append(LPairs[LFor].AsJSON(AIdent));
        if LFor < Length(LPairs) - 1 then
          ABuilder.Append(',');
        if AIdent then
          ABuilder.AppendLine;
      end;
      if AIdent then
        ABuilder.Append(LIndent);
    end;
    ABuilder.Append('}');
  end
  else
  if Supports(AElement, IJSONArray, LArr) then
  begin
    LItems := LArr.Items;
    ABuilder.Append('[');
    if Length(LItems) > 0 then
    begin
      if AIdent then
        ABuilder.AppendLine;
      for LFor := 0 to Length(LItems) - 1 do
      begin
        if AIdent then
          ABuilder.Append(LIndent + '  ');
        _WriteElement(LItems[LFor], ABuilder, AIdent, ALevel + 1);
        if LFor < Length(LItems) - 1 then
          ABuilder.Append(',');
        if AIdent then
          ABuilder.AppendLine;
      end;
      if AIdent then
        ABuilder.Append(LIndent);
    end;
    ABuilder.Append(']');
  end
  else
  begin
    ABuilder.Append(AElement.AsJSON(AIdent));
  end;
end;

function TJSONWriter.Write(const AElement: IJSONElement; const AIdent: Boolean): String;
var
  LBuilder: TStringBuilder;
begin
  LBuilder := TStringBuilder.Create;
  try
    _WriteElement(AElement, LBuilder, AIdent, 0);
    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

procedure TJSONWriter.WriteToStream(const AElement: IJSONElement; AStream: TStream; const AIdent: Boolean);
var
  LJson: String;
  LBytes: TBytes;
begin
  LJson := Write(AElement, AIdent);
  LBytes := TEncoding.UTF8.GetBytes(LJson);
  AStream.WriteBuffer(LBytes, Length(LBytes));
end;

end.

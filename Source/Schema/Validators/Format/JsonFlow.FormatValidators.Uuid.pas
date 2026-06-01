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

{$include ../../../JsonFlow.inc}
unit JsonFlow.FormatValidators.Uuid;

interface

uses
  System.SysUtils,
  System.RegularExpressions,
  JsonFlow.FormatValidators.Base;

type
  TUuidFormatValidator = class(TBaseFormatValidatorPlugin)
  protected
    function DoValidate(const AValue: string): Boolean; override;
    function GetCustomErrorMessage(const AValue: string): string; override;
  public
    constructor Create;
  end;

  // Função para registrar o validador
  procedure RegisterUuidValidator;

implementation

uses
  JsonFlow.FormatRegistry;

{ TUuidFormatValidator }

constructor TUuidFormatValidator.Create;
begin
  inherited Create('uuid', 'String does not match UUID format');
end;

function TUuidFormatValidator.DoValidate(const AValue: string): Boolean;
var
  LRegex: TRegEx;
begin
  if AValue.IsEmpty then
  begin
    Result := False;
    Exit;
  end;
  
  // Formato UUID: 8-4-4-4-12 caracteres hexadecimais
  // Exemplo: 550e8400-e29b-41d4-a716-446655440000
  LRegex := TRegEx.Create('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
  Result := LRegex.IsMatch(AValue);
end;

function TUuidFormatValidator.GetCustomErrorMessage(const AValue: string): string;
var
  LParts: TArray<string>;
begin
  if AValue.IsEmpty then
    Result := 'UUID cannot be empty'
  else if Length(AValue) <> 36 then
    Result := Format('UUID "%s" must be exactly 36 characters long', [AValue])
  else if (AValue.CountChar('-') <> 4) then
    Result := Format('UUID "%s" must contain exactly 4 hyphens', [AValue])
  else
  begin
    LParts := AValue.Split(['-']);
    if Length(LParts) <> 5 then
      Result := Format('UUID "%s" must have 5 parts separated by hyphens', [AValue])
    else if (Length(LParts[0]) <> 8) or (Length(LParts[1]) <> 4) or 
            (Length(LParts[2]) <> 4) or (Length(LParts[3]) <> 4) or 
            (Length(LParts[4]) <> 12) then
      Result := Format('UUID "%s" parts must follow pattern 8-4-4-4-12', [AValue])
    else
      Result := Format('UUID "%s" contains invalid hexadecimal characters', [AValue]);
  end;
end;

// Função para registrar o validador
procedure RegisterUuidValidator;
begin
  TFormatRegistry.RegisterValidator('uuid', TUuidFormatValidator.Create);
end;

end.

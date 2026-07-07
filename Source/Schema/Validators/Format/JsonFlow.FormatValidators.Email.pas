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

{$include ../../../JsonFlow.inc}
unit JsonFlow.FormatValidators.Email;

interface

uses
  System.SysUtils,
  System.RegularExpressions,
  JsonFlow.FormatValidators.Base;

type
  TEmailFormatValidator = class(TBaseFormatValidatorPlugin)
  protected
    function DoValidate(const AValue: string): Boolean; override;
    function GetCustomErrorMessage(const AValue: string): string; override;
  public
    constructor Create;
  end;

  // Função para registrar o validador
  procedure RegisterEmailValidator;

implementation

uses
  JsonFlow.FormatRegistry;

var
  // Regexes compiladas UMA vez no load da unit (antes: TRegEx.Create
  // por valor validado dentro do DoValidate)
  GRegex1: TRegEx;

{ TEmailFormatValidator }

constructor TEmailFormatValidator.Create;
begin
  inherited Create('email', 'String does not match email format');
end;

function TEmailFormatValidator.DoValidate(const AValue: string): Boolean;
var
  LRegex: TRegEx;
begin
  if AValue.IsEmpty then
  begin
    Result := False;
    Exit;
  end;
  
  // Regex mais robusta para validação de email
  LRegex := GRegex1;
  Result := LRegex.IsMatch(AValue);
end;

function TEmailFormatValidator.GetCustomErrorMessage(const AValue: string): string;
begin
  if AValue.IsEmpty then
    Result := 'Email cannot be empty'
  else if not AValue.Contains('@') then
    Result := 'Email must contain @ symbol'
  else if not AValue.Contains('.') then
    Result := 'Email must contain a domain with extension'
  else
    Result := Format('String "%s" is not a valid email format', [AValue]);
end;

// Função para registrar o validador
procedure RegisterEmailValidator;
begin
  TFormatRegistry.RegisterValidator('email', TEmailFormatValidator.Create);
end;

initialization
  GRegex1 := TRegEx.Create('^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

end.

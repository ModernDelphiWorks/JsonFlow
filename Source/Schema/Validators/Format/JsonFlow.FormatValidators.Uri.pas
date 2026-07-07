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
unit JsonFlow.FormatValidators.Uri;

interface

uses
  System.SysUtils,
  System.RegularExpressions,
  JsonFlow.FormatValidators.Base;

type
  TUriFormatValidator = class(TBaseFormatValidatorPlugin)
  protected
    function DoValidate(const AValue: string): Boolean; override;
    function GetCustomErrorMessage(const AValue: string): string; override;
  public
    constructor Create;
  end;

  // Função para registrar o validador
  procedure RegisterUriValidator;

implementation

uses
  JsonFlow.FormatRegistry;

var
  // Regexes compiladas UMA vez no load da unit (antes: TRegEx.Create
  // por valor validado dentro do DoValidate)
  GRegex1: TRegEx;

{ TUriFormatValidator }

constructor TUriFormatValidator.Create;
begin
  inherited Create('uri', 'String does not match URI format');
end;

function TUriFormatValidator.DoValidate(const AValue: string): Boolean;
var
  LRegex: TRegEx;
begin
  if AValue.IsEmpty then
  begin
    Result := False;
    Exit;
  end;
  
  // Regex mais abrangente para URIs (http, https, ftp, etc.)
  LRegex := GRegex1;
  Result := LRegex.IsMatch(AValue);
end;

function TUriFormatValidator.GetCustomErrorMessage(const AValue: string): string;
begin
  if AValue.IsEmpty then
    Result := 'URI cannot be empty'
  else if not (AValue.StartsWith('http://') or AValue.StartsWith('https://') or AValue.StartsWith('ftp://')) then
    Result := 'URI must start with a valid scheme (http://, https://, ftp://)'
  else
    Result := Format('String "%s" is not a valid URI format', [AValue]);
end;

// Função para registrar o validador
procedure RegisterUriValidator;
begin
  TFormatRegistry.RegisterValidator('uri', TUriFormatValidator.Create);
end;

initialization
  GRegex1 := TRegEx.Create('^(https?|ftp)://[^\s/$.?#].[^\s]*$', [roIgnoreCase]);

end.

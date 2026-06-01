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

{$include ../../../../JsonFlow.inc}
unit JsonFlow.FormatValidators.BrazilianPhone;

{*******************************************************************************
  Validador de formato para telefone brasileiro
  
  Este validador verifica se uma string está no formato de telefone brasileiro válido.
  
  Formatos aceitos:
  - (11) 99999-9999 (celular com formatação)
  - (11) 3333-4444 (fixo com formatação)
  - 11999999999 (celular sem formatação)
  - 1133334444 (fixo sem formatação)
  - +55 11 99999-9999 (internacional)
  - +5511999999999 (internacional sem espaços)
  
  Autor: JsonFlow4D
  Data: 2024
*******************************************************************************}

interface

uses
  System.SysUtils,
  System.Classes,
  System.RegularExpressions,
  JsonFlow.FormatValidators.Base,
  JsonFlow.FormatRegistry;

type
  // Validador de telefone brasileiro
  TBrazilianPhoneFormatValidator = class(TBaseFormatValidatorPlugin)
  protected
    function DoValidate(const AValue: string): Boolean; override;
  end;

// Procedimento para registrar o validador
procedure RegisterBrazilianPhoneValidator;

implementation

{ TBrazilianPhoneFormatValidator }

function TBrazilianPhoneFormatValidator.DoValidate(const AValue: string): Boolean;
var
  LPatterns: TArray<string>;
  LPattern: string;
begin
  Result := False;
  
  // Padrões para telefones brasileiros
  LPatterns := [
    // Celular com formatação: (11) 99999-9999
    '^\(\d{2}\)\s9\d{4}-\d{4}$',
    // Fixo com formatação: (11) 3333-4444
    '^\(\d{2}\)\s[2-5]\d{3}-\d{4}$',
    // Celular sem formatação: 11999999999
    '^\d{2}9\d{8}$',
    // Fixo sem formatação: 1133334444
    '^\d{2}[2-5]\d{7}$',
    // Internacional com espaços: +55 11 99999-9999
    '^\+55\s\d{2}\s9\d{4}-\d{4}$',
    // Internacional fixo com espaços: +55 11 3333-4444
    '^\+55\s\d{2}\s[2-5]\d{3}-\d{4}$',
    // Internacional sem espaços celular: +5511999999999
    '^\+55\d{2}9\d{8}$',
    // Internacional sem espaços fixo: +55113333444
    '^\+55\d{2}[2-5]\d{7}$'
  ];
  
  // Testa cada padrão
  for LPattern in LPatterns do
  begin
    if TRegEx.IsMatch(AValue, LPattern) then
    begin
      Result := True;
      Break;
    end;
  end;
end;

procedure RegisterBrazilianPhoneValidator;
begin
  TFormatRegistry.RegisterValidator('brazilian-phone', TBrazilianPhoneFormatValidator.Create('brazilian-phone', 'Telefone brasileiro inválido'));
end;

end.

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

var
  GPhoneRegexes: array[0..7] of TRegEx;


{ TBrazilianPhoneFormatValidator }

function TBrazilianPhoneFormatValidator.DoValidate(const AValue: string): Boolean;
begin
  // Regexes pre-compiladas no load da unit (antes: TRegEx.IsMatch estatico
  // compilava cada um dos 8 padroes por valor validado)
  Result := GPhoneRegexes[0].IsMatch(AValue) or GPhoneRegexes[1].IsMatch(AValue) or
            GPhoneRegexes[2].IsMatch(AValue) or GPhoneRegexes[3].IsMatch(AValue) or
            GPhoneRegexes[4].IsMatch(AValue) or GPhoneRegexes[5].IsMatch(AValue) or
            GPhoneRegexes[6].IsMatch(AValue) or GPhoneRegexes[7].IsMatch(AValue);
end;

procedure RegisterBrazilianPhoneValidator;
begin
  TFormatRegistry.RegisterValidator('brazilian-phone', TBrazilianPhoneFormatValidator.Create('brazilian-phone', 'Telefone brasileiro inválido'));
end;

initialization
  GPhoneRegexes[0] := TRegEx.Create('^\(\d{2}\)\s9\d{4}-\d{4}$');       // (11) 99999-9999
  GPhoneRegexes[1] := TRegEx.Create('^\(\d{2}\)\s[2-5]\d{3}-\d{4}$');   // (11) 3333-4444
  GPhoneRegexes[2] := TRegEx.Create('^\d{2}9\d{8}$');                       // 11999999999
  GPhoneRegexes[3] := TRegEx.Create('^\d{2}[2-5]\d{7}$');                   // 1133334444
  GPhoneRegexes[4] := TRegEx.Create('^\+55\s\d{2}\s9\d{4}-\d{4}$');     // +55 11 99999-9999
  GPhoneRegexes[5] := TRegEx.Create('^\+55\s\d{2}\s[2-5]\d{3}-\d{4}$'); // +55 11 3333-4444
  GPhoneRegexes[6] := TRegEx.Create('^\+55\d{2}9\d{8}$');                  // +5511999999999
  GPhoneRegexes[7] := TRegEx.Create('^\+55\d{2}[2-5]\d{7}$');              // +55113333444

end.

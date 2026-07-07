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
unit JsonFlow.FormatValidators.CEP;

{*******************************************************************************
  Validador de formato para CEP brasileiro
  
  Este validador verifica se uma string está no formato de CEP válido.
  
  Formatos aceitos:
  - 01234-567
  - 01234567
  
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
  // Validador de CEP brasileiro
  TCEPFormatValidator = class(TBaseFormatValidatorPlugin)
  protected
    function DoValidate(const AValue: string): Boolean; override;
  end;

// Procedimento para registrar o validador
procedure RegisterCEPValidator;

implementation

var
  GCEPRegex: TRegEx;


{ TCEPFormatValidator }

function TCEPFormatValidator.DoValidate(const AValue: string): Boolean;
begin
  // Padrão para CEP: 8 dígitos com ou sem hífen (12345-678 ou 12345678),
  // regex pré-compilada no load da unit
  Result := GCEPRegex.IsMatch(AValue);
end;

procedure RegisterCEPValidator;
begin
  TFormatRegistry.RegisterValidator('cep', TCEPFormatValidator.Create('cep', 'CEP inválido'));
end;

initialization
  GCEPRegex := TRegEx.Create('^\d{5}-?\d{3}$');

end.

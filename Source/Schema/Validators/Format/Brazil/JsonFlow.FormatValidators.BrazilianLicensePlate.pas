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
unit JsonFlow.FormatValidators.BrazilianLicensePlate;

{*******************************************************************************
  Validador de formato para placa de veículo brasileira
  
  Este validador verifica se uma string está no formato de placa brasileira válida.
  
  Formatos aceitos:
  - ABC-1234 (formato antigo com hífen)
  - ABC1234 (formato antigo sem hífen)
  - ABC1D23 (formato Mercosul sem hífen)
  - ABC-1D23 (formato Mercosul com hífen)
  
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
  // Validador de placa brasileira
  TBrazilianLicensePlateValidator = class(TBaseFormatValidatorPlugin)
  protected
    function DoValidate(const AValue: string): Boolean; override;
  end;

// Procedimento para registrar o validador
procedure RegisterBrazilianLicensePlateValidator;

implementation

var
  GPlateRegexes: array[0..3] of TRegEx;


{ TBrazilianLicensePlateValidator }

function TBrazilianLicensePlateValidator.DoValidate(const AValue: string): Boolean;
var
  LUpper: string;
begin
  // Regexes pre-compiladas no load da unit; ToUpper aplicado UMA vez
  LUpper := AValue.ToUpper;
  Result := GPlateRegexes[0].IsMatch(LUpper) or GPlateRegexes[1].IsMatch(LUpper) or
            GPlateRegexes[2].IsMatch(LUpper) or GPlateRegexes[3].IsMatch(LUpper);
end;

procedure RegisterBrazilianLicensePlateValidator;
begin
  TFormatRegistry.RegisterValidator('brazilian-license-plate', TBrazilianLicensePlateValidator.Create('brazilian-license-plate', 'Placa brasileira inválida'));
end;

initialization
  GPlateRegexes[0] := TRegEx.Create('^[A-Z]{3}-\d{4}$');        // ABC-1234
  GPlateRegexes[1] := TRegEx.Create('^[A-Z]{3}\d{4}$');         // ABC1234
  GPlateRegexes[2] := TRegEx.Create('^[A-Z]{3}\d[A-Z]\d{2}$'); // ABC1D23 (Mercosul)
  GPlateRegexes[3] := TRegEx.Create('^[A-Z]{3}-\d[A-Z]\d{2}$');// ABC-1D23 (Mercosul)

end.

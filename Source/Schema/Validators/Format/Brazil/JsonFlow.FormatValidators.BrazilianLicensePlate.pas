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

{ TBrazilianLicensePlateValidator }

function TBrazilianLicensePlateValidator.DoValidate(const AValue: string): Boolean;
var
  LPatterns: TArray<string>;
  LPattern: string;
begin
  Result := False;
  
  // Padrões para placas brasileiras
  LPatterns := [
    // Formato antigo com hífen: ABC-1234
    '^[A-Z]{3}-\d{4}$',
    // Formato antigo sem hífen: ABC1234
    '^[A-Z]{3}\d{4}$',
    // Formato Mercosul sem hífen: ABC1D23
    '^[A-Z]{3}\d[A-Z]\d{2}$',
    // Formato Mercosul com hífen: ABC-1D23
    '^[A-Z]{3}-\d[A-Z]\d{2}$'
  ];
  
  // Testa cada padrão
  for LPattern in LPatterns do
  begin
    if TRegEx.IsMatch(AValue.ToUpper, LPattern) then
    begin
      Result := True;
      Break;
    end;
  end;
end;

procedure RegisterBrazilianLicensePlateValidator;
begin
  TFormatRegistry.RegisterValidator('brazilian-license-plate', TBrazilianLicensePlateValidator.Create('brazilian-license-plate', 'Placa brasileira inválida'));
end;

end.

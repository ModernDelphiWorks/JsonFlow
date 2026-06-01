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
unit JsonFlow.FormatValidators.CNPJ;

{*******************************************************************************
  Validador de formato para CNPJ brasileiro
  
  Este validador verifica se uma string está no formato de CNPJ válido,
  incluindo validação do dígito verificador.
  
  Formatos aceitos:
  - 11.222.333/0001-81
  - 11222333000181
  
  Autor: JsonFlow4D
  Data: 2024
*******************************************************************************}

interface

uses
  System.SysUtils,
  System.Classes,
  JsonFlow.FormatValidators.Base,
  JsonFlow.FormatRegistry;

type
  // Validador de CNPJ brasileiro
  TCNPJFormatValidator = class(TBaseFormatValidatorPlugin)
  private
    function IsValidCNPJ(const ACNPJ: string): Boolean;
    function CalculateDigit(const ANumbers: string; const AWeights: array of Integer): Integer;
    function CleanCNPJ(const ACNPJ: string): string;
  protected
    function DoValidate(const AValue: string): Boolean; override;
  end;

// Procedimento para registrar o validador
procedure RegisterCNPJValidator;

implementation

{ TCNPJFormatValidator }

function TCNPJFormatValidator.DoValidate(const AValue: string): Boolean;
begin
  Result := IsValidCNPJ(AValue);
end;

function TCNPJFormatValidator.CleanCNPJ(const ACNPJ: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(ACNPJ) do
  begin
    if CharInSet(ACNPJ[I], ['0'..'9']) then
      Result := Result + ACNPJ[I];
  end;
end;

function TCNPJFormatValidator.IsValidCNPJ(const ACNPJ: string): Boolean;
var
  LCleanCNPJ: string;
  LDigit1, LDigit2: Integer;
  I: Integer;
  LAllSame: Boolean;
begin
  Result := False;
  
  // Limpa o CNPJ (remove pontos, barras e hífens)
  LCleanCNPJ := CleanCNPJ(ACNPJ);
  
  // Verifica se tem 14 dígitos
  if Length(LCleanCNPJ) <> 14 then
    Exit;
  
  // Verifica se todos os dígitos são iguais (CNPJ inválido)
  LAllSame := True;
  for I := 2 to 14 do
  begin
    if LCleanCNPJ[I] <> LCleanCNPJ[1] then
    begin
      LAllSame := False;
      Break;
    end;
  end;
  
  if LAllSame then
    Exit;
  
  // Calcula o primeiro dígito verificador
  LDigit1 := CalculateDigit(Copy(LCleanCNPJ, 1, 12), [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]);
  
  // Calcula o segundo dígito verificador
  LDigit2 := CalculateDigit(Copy(LCleanCNPJ, 1, 12) + IntToStr(LDigit1), [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]);
  
  // Verifica se os dígitos calculados conferem
  Result := (LDigit1 = StrToInt(LCleanCNPJ[13])) and (LDigit2 = StrToInt(LCleanCNPJ[14]));
end;

function TCNPJFormatValidator.CalculateDigit(const ANumbers: string; const AWeights: array of Integer): Integer;
var
  I, LSum: Integer;
begin
  LSum := 0;
  for I := 1 to Length(ANumbers) do
  begin
    LSum := LSum + (StrToInt(ANumbers[I]) * AWeights[I - 1]);
  end;
  
  Result := LSum mod 11;
  if Result < 2 then
    Result := 0
  else
    Result := 11 - Result;
end;

procedure RegisterCNPJValidator;
begin
  TFormatRegistry.RegisterValidator('cnpj', TCNPJFormatValidator.Create('cnpj', 'CNPJ inválido'));
end;

end.

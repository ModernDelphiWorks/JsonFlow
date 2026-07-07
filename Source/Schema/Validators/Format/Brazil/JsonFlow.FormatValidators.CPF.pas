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
unit JsonFlow.FormatValidators.CPF;

{*******************************************************************************
  Validador de formato para CPF brasileiro
  
  Este validador verifica se uma string está no formato de CPF válido,
  incluindo validação do dígito verificador.
  
  Formatos aceitos:
  - 123.456.789-09
  - 12345678909
  
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
  // Validador de CPF brasileiro
  TCPFFormatValidator = class(TBaseFormatValidatorPlugin)
  private
    function IsValidCPF(const ACPF: string): Boolean;
    function CalculateDigit(const ANumbers: string; AWeight: Integer): Integer;
    function CleanCPF(const ACPF: string): string;
  protected
    function DoValidate(const AValue: string): Boolean; override;
  end;

// Procedimento para registrar o validador
procedure RegisterCPFValidator;

implementation

{ TCPFFormatValidator }

function TCPFFormatValidator.DoValidate(const AValue: string): Boolean;
begin
  Result := IsValidCPF(AValue);
end;

function TCPFFormatValidator.CleanCPF(const ACPF: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(ACPF) do
  begin
    if CharInSet(ACPF[I], ['0'..'9']) then
      Result := Result + ACPF[I];
  end;
end;

function TCPFFormatValidator.IsValidCPF(const ACPF: string): Boolean;
var
  LCleanCPF: string;
  LDigit1, LDigit2: Integer;
  I: Integer;
  LAllSame: Boolean;
begin
  Result := False;
  
  // Limpa o CPF (remove pontos e hífens)
  LCleanCPF := CleanCPF(ACPF);
  
  // Verifica se tem 11 dígitos
  if Length(LCleanCPF) <> 11 then
    Exit;
  
  // Verifica se todos os dígitos são iguais (CPF inválido)
  LAllSame := True;
  for I := 2 to 11 do
  begin
    if LCleanCPF[I] <> LCleanCPF[1] then
    begin
      LAllSame := False;
      Break;
    end;
  end;
  
  if LAllSame then
    Exit;
  
  // Calcula o primeiro dígito verificador
  LDigit1 := CalculateDigit(Copy(LCleanCPF, 1, 9), 10);
  
  // Calcula o segundo dígito verificador
  LDigit2 := CalculateDigit(Copy(LCleanCPF, 1, 9) + IntToStr(LDigit1), 11);
  
  // Verifica se os dígitos calculados conferem
  Result := (LDigit1 = StrToInt(LCleanCPF[10])) and (LDigit2 = StrToInt(LCleanCPF[11]));
end;

function TCPFFormatValidator.CalculateDigit(const ANumbers: string; AWeight: Integer): Integer;
var
  I, LSum: Integer;
begin
  LSum := 0;
  for I := 1 to Length(ANumbers) do
  begin
    LSum := LSum + (StrToInt(ANumbers[I]) * AWeight);
    Dec(AWeight);
  end;
  
  Result := LSum mod 11;
  if Result < 2 then
    Result := 0
  else
    Result := 11 - Result;
end;

procedure RegisterCPFValidator;
begin
  TFormatRegistry.RegisterValidator('cpf', TCPFFormatValidator.Create('cpf', 'CPF inválido'));
end;

end.

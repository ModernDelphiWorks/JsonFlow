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
unit JsonFlow.FormatValidators.Brazil;

{
  JsonFlow4D - Validadores de Formato Brasileiros
  
  Arquivo centralizador para registro de todos os validadores de formato
  específicos do Brasil.
  
  Validadores incluídos:
  - CPF (Cadastro de Pessoas Físicas)
  - CNPJ (Cadastro Nacional da Pessoa Jurídica)
  - CEP (Código de Endereçamento Postal)
  - Telefone brasileiro
  - Placa de carro brasileira (antigo e Mercosul)
  
  Autor: JsonFlow4D Framework
  Data: 2024
}

interface

uses
  JsonFlow.FormatValidators.CPF,
  JsonFlow.FormatValidators.CNPJ,
  JsonFlow.FormatValidators.CEP,
  JsonFlow.FormatValidators.BrazilianPhone,
  JsonFlow.FormatValidators.BrazilianLicensePlate;

// Registra todos os validadores brasileiros
procedure RegisterAllBrazilianFormatValidators;

// Registra validadores individuais
procedure RegisterBuiltInCPFValidator;
procedure RegisterBuiltInCNPJValidator;
procedure RegisterBuiltInCEPValidator;
procedure RegisterBuiltInBrazilianPhoneValidator;
procedure RegisterBuiltInBrazilianLicensePlateValidator;

implementation

procedure RegisterBuiltInCPFValidator;
begin
  RegisterCPFValidator;
end;

procedure RegisterBuiltInCNPJValidator;
begin
  RegisterCNPJValidator;
end;

procedure RegisterBuiltInCEPValidator;
begin
  RegisterCEPValidator;
end;

procedure RegisterBuiltInBrazilianPhoneValidator;
begin
  RegisterBrazilianPhoneValidator;
end;

procedure RegisterBuiltInBrazilianLicensePlateValidator;
begin
  RegisterBrazilianLicensePlateValidator;
end;

procedure RegisterAllBrazilianFormatValidators;
begin
  RegisterBuiltInCPFValidator;
  RegisterBuiltInCNPJValidator;
  RegisterBuiltInCEPValidator;
  RegisterBuiltInBrazilianPhoneValidator;
  RegisterBuiltInBrazilianLicensePlateValidator;
end;

end.

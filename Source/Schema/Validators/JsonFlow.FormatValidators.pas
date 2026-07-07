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

{$include ../../JsonFlow.inc}
unit JsonFlow.FormatValidators;

// Unidade centralizada para registro de todos os validadores de formato
// Esta unidade substitui o registro manual no JsonFlow.FormatRegistry.pas

interface

// Procedimento principal para registrar todos os validadores built-in
procedure RegisterAllFormatValidators;

// Procedimentos individuais para registro seletivo
procedure RegisterBuiltInEmailValidator;
procedure RegisterBuiltInUriValidator;
procedure RegisterBuiltInDateValidator;
procedure RegisterBuiltInTimeValidator;
procedure RegisterBuiltInDateTimeValidator;
procedure RegisterBuiltInUuidValidator;
procedure RegisterBuiltInIpv4Validator;
procedure RegisterBuiltInIpv6Validator;

implementation

uses
  JsonFlow.FormatValidators.Email,
  JsonFlow.FormatValidators.Uri,
  JsonFlow.FormatValidators.Date,
  JsonFlow.FormatValidators.Time,
  JsonFlow.FormatValidators.DateTime,
  JsonFlow.FormatValidators.Uuid,
  JsonFlow.FormatValidators.Ipv4,
  JsonFlow.FormatValidators.Ipv6;

// Registra todos os validadores built-in
procedure RegisterAllFormatValidators;
begin
  RegisterBuiltInEmailValidator;
  RegisterBuiltInUriValidator;
  RegisterBuiltInDateValidator;
  RegisterBuiltInTimeValidator;
  RegisterBuiltInDateTimeValidator;
  RegisterBuiltInUuidValidator;
  RegisterBuiltInIpv4Validator;
  RegisterBuiltInIpv6Validator;
end;

// Procedimentos individuais para registro seletivo
procedure RegisterBuiltInEmailValidator;
begin
  JsonFlow.FormatValidators.Email.RegisterEmailValidator;
end;

procedure RegisterBuiltInUriValidator;
begin
  JsonFlow.FormatValidators.Uri.RegisterUriValidator;
end;

procedure RegisterBuiltInDateValidator;
begin
  JsonFlow.FormatValidators.Date.RegisterDateValidator;
end;

procedure RegisterBuiltInTimeValidator;
begin
  JsonFlow.FormatValidators.Time.RegisterTimeValidator;
end;

procedure RegisterBuiltInDateTimeValidator;
begin
  JsonFlow.FormatValidators.DateTime.RegisterDateTimeValidator;
end;

procedure RegisterBuiltInUuidValidator;
begin
  JsonFlow.FormatValidators.Uuid.RegisterUuidValidator;
end;

procedure RegisterBuiltInIpv4Validator;
begin
  JsonFlow.FormatValidators.Ipv4.RegisterIpv4Validator;
end;

procedure RegisterBuiltInIpv6Validator;
begin
  JsonFlow.FormatValidators.Ipv6.RegisterIpv6Validator;
end;

end.

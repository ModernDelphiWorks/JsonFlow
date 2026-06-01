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

{$include ../../JsonFlow.inc}
unit JsonFlow.ValidationRules.Format;

interface

uses
  System.SysUtils,
  JsonFlow.Interfaces, JsonFlow.ValidationEngine,
  JsonFlow.ValidationRules.Base, JsonFlow.FormatRegistry;

type
  // Regra de validação de formato usando apenas validadores plugáveis
  TFormatRule = class(TBaseValidationRule)
  private
    FFormat: string;
    function ValidateUsingRegistry(const AValue: string): Boolean;
    function GetErrorMessageFromRegistry(const AValue: string): string;
  public
    constructor Create(const AFormat: string);
    function Validate(const AValue: IJSONElement; const AContext: TObject): TValidationResult; override;
  end;

implementation

{ TFormatRule }

constructor TFormatRule.Create(const AFormat: string);
begin
  inherited Create('format');
  FFormat := AFormat;
end;

function TFormatRule.ValidateUsingRegistry(const AValue: string): Boolean;
var
  LValidator: IFormatValidator;
  LFormatLower: string;
begin
  // Usa apenas o registry de validadores plugáveis
  LFormatLower := AnsiLowerCase(FFormat);
  LValidator := TFormatRegistry.GetValidator(LFormatLower);
  if Assigned(LValidator) then
    Result := LValidator.Validate(AValue)
  else
    Result := True; // Formatos não registrados são considerados válidos
end;

function TFormatRule.GetErrorMessageFromRegistry(const AValue: string): string;
var
  LValidator: IFormatValidator;
  LFormatLower: string;
begin
  LFormatLower := AnsiLowerCase(FFormat);
  LValidator := TFormatRegistry.GetValidator(LFormatLower);
  if Assigned(LValidator) then
    Result := LValidator.GetErrorMessage(AValue)
  else
    Result := Format('String "%s" does not match format "%s"', [AValue, FFormat]);
end;



function TFormatRule.Validate(const AValue: IJSONElement; const AContext: TObject): TValidationResult;
var
  LValue: IJSONValue;
  LError: TValidationError;
  LValidationContext: TValidationContext;
  LIsValid: Boolean;
  LFormatLower: string;
begin
  LValidationContext := TValidationContext(AContext);
  
  if not Supports(AValue, IJSONValue, LValue) then
  begin
    LError := CreateValidationError(
      LValidationContext.GetFullPath,
      'Value must be a string for format validation',
      'non-string',
      'string',
      'format',
      LValidationContext.GetFullSchemaPath + '/format'
    );
    Result := TValidationResult.Failure(LValidationContext.GetFullPath, [LError]);
    Exit;
  end;

  if not LValue.IsString then
  begin
    LError := CreateValidationError(
      LValidationContext.GetFullPath,
      'Value must be a string for format validation',
      'non-string',
      'string',
      'format',
      LValidationContext.GetFullSchemaPath + '/format'
    );
    Result := TValidationResult.Failure(LValidationContext.GetFullPath, [LError]);
    Exit;
  end;

  // Usa apenas o sistema de registry plugável
  LIsValid := ValidateUsingRegistry(LValue.AsString);

  if LIsValid then
    Result := TValidationResult.Success(LValidationContext.GetFullPath)
  else
  begin
    LError := CreateValidationError(
      LValidationContext.GetFullPath,
      GetErrorMessageFromRegistry(LValue.AsString),
      LValue.AsString,
      FFormat,
      'format',
      LValidationContext.GetFullSchemaPath + '/format'
    );
    Result := TValidationResult.Failure(LValidationContext.GetFullPath, [LError]);
  end;
end;

end.

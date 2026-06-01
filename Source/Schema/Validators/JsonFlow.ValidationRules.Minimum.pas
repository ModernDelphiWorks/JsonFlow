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
unit JsonFlow.ValidationRules.Minimum;

interface

uses
  SysUtils,
  Classes,
  JsonFlow.Interfaces,
  JsonFlow.ValidationEngine,
  JsonFlow.ValidationRules.Base;

type
  // Regra de validação de valor mínimo
  TMinimumRule = class(TBaseValidationRule)
  private
    FMinValue: Double;
  public
    constructor Create(AMinValue: Double);
    function Validate(const AValue: IJSONElement; const AContext: TObject): TValidationResult; override;
  end;

implementation

{ TMinimumRule }

constructor TMinimumRule.Create(AMinValue: Double);
begin
  inherited Create('minimum');
  FMinValue := AMinValue;
end;

function TMinimumRule.Validate(const AValue: IJSONElement; const AContext: TObject): TValidationResult;
var
  LValue: IJSONValue;
  LError: TValidationError;
  LValidationContext: TValidationContext;
begin
  LValidationContext := TValidationContext(AContext);
  
  if not Supports(AValue, IJSONValue, LValue) then
  begin
    LError := CreateValidationError(
      LValidationContext.GetFullPath,
      'Value must be a number for minimum validation',
      'non-number',
      'number',
      'minimum',
      LValidationContext.GetFullSchemaPath + '/minimum'
    );
    Result := TValidationResult.Failure(LValidationContext.GetFullPath, [LError]);
    Exit;
  end;

  if not (LValue.IsInteger or LValue.IsFloat) then
  begin
    LError := CreateValidationError(
      LValidationContext.GetFullPath,
      'Value must be a number for minimum validation',
      'non-number',
      'number',
      'minimum',
      LValidationContext.GetFullSchemaPath + '/minimum'
    );
    Result := TValidationResult.Failure(LValidationContext.GetFullPath, [LError]);
    Exit;
  end;

  if LValue.AsFloat >= FMinValue then
    Result := TValidationResult.Success(LValidationContext.GetFullPath)
  else
  begin
    LError := CreateValidationError(
      LValidationContext.GetFullPath,
      Format('Value %g is less than minimum %g', [LValue.AsFloat, FMinValue]),
      FloatToStr(LValue.AsFloat),
      FloatToStr(FMinValue),
      'minimum',
      LValidationContext.GetFullSchemaPath + '/minimum'
    );
    Result := TValidationResult.Failure(LValidationContext.GetFullPath, [LError]);
  end;
end;

end.

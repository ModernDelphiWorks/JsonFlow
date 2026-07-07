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

unit JsonFlow.ValidationRules.MinLength;

interface

uses
  SysUtils,
  Classes,
  JsonFlow.Interfaces,
  JsonFlow.ValidationEngine,
  JsonFlow.ValidationRules.Base;

type
  // Regra de validação de comprimento mínimo
  TMinLengthRule = class(TBaseValidationRule)
  private
    FMinLength: Integer;
  public
    constructor Create(AMinLength: Integer);
    function Validate(const AValue: IJSONElement; const AContext: TObject): TValidationResult; override;
  end;

implementation

{ TMinLengthRule }

constructor TMinLengthRule.Create(AMinLength: Integer);
begin
  inherited Create('minLength');
  FMinLength := AMinLength;
end;

function TMinLengthRule.Validate(const AValue: IJSONElement; const AContext: TObject): TValidationResult;
var
  LValue: IJSONValue;
  LArray: IJSONArray;
  LLength: Integer;
  LError: TValidationError;
  LValidationContext: TValidationContext;
begin
  LValidationContext := TValidationContext(AContext);

  if Supports(AValue, IJSONValue, LValue) and LValue.IsString then
    LLength := Length(LValue.AsString)
  else if Supports(AValue, IJSONArray, LArray) then
    LLength := LArray.Count
  else
  begin
    LError := CreateValidationError(
      LValidationContext.GetFullPath,
      'Value must be a string or array for minLength validation',
      'invalid type',
      'string or array',
      'minLength',
      LValidationContext.GetFullSchemaPath + '/minLength'
    );
    Result := TValidationResult.Failure(LValidationContext.GetFullPath, [LError]);
    Exit;
  end;

  if LLength >= FMinLength then
    Result := TValidationResult.Success(LValidationContext.GetFullPath)
  else
  begin
    LError := CreateValidationError(
      LValidationContext.GetFullPath,
      Format('Length %d is less than minimum length %d', [LLength, FMinLength]),
      IntToStr(LLength),
      IntToStr(FMinLength),
      'minLength',
      LValidationContext.GetFullSchemaPath + '/minLength'
    );
    Result := TValidationResult.Failure(LValidationContext.GetFullPath, [LError]);
  end;
end;

end.

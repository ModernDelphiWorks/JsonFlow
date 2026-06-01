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
unit JsonFlow.ValidationRules.Consts;

interface

uses
  System.SysUtils, System.Classes,
  JsonFlow.Interfaces, JsonFlow.ValidationEngine,
  JsonFlow.ValidationRules.Base;

type
  // Regra de validação de constante
  TConstRule = class(TBaseValidationRule)
  private
    FConstValue: string;
  public
    constructor Create(const AConstValue: string);
    function Validate(const AValue: IJSONElement; const AContext: TObject): TValidationResult; override;
  end;

implementation

{ TConstRule }

constructor TConstRule.Create(const AConstValue: string);
begin
  inherited Create('const');
  FConstValue := AConstValue;
end;

function TConstRule.Validate(const AValue: IJSONElement; const AContext: TObject): TValidationResult;
var
  LValue: IJSONValue;
  LError: TValidationError;
  LValidationContext: TValidationContext;
  LValueStr: string;
begin
  LValidationContext := TValidationContext(AContext);
  
  if not Supports(AValue, IJSONValue, LValue) then
  begin
    LError := CreateValidationError(
      LValidationContext.GetFullPath,
      'Value must be a primitive for const validation',
      'non-primitive',
      'primitive',
      'const',
      LValidationContext.GetFullSchemaPath + '/const'
    );
    Result := TValidationResult.Failure(LValidationContext.GetFullPath, [LError]);
    Exit;
  end;

  // Converter valor para string para comparação
  if LValue.IsString then
    LValueStr := LValue.AsString
  else if LValue.IsInteger then
    LValueStr := IntToStr(LValue.AsInteger)
  else if LValue.IsFloat then
    LValueStr := FloatToStr(LValue.AsFloat)
  else if LValue.IsBoolean then
    LValueStr := BoolToStr(LValue.AsBoolean, True)
  else if LValue.IsNull then
    LValueStr := 'null'
  else
    LValueStr := 'unknown';

  if LValueStr = FConstValue then
    Result := TValidationResult.Success(LValidationContext.GetFullPath)
  else
  begin
    LError := CreateValidationError(
      LValidationContext.GetFullPath,
      Format('Value "%s" does not match constant "%s"', [LValueStr, FConstValue]),
      LValueStr,
      FConstValue,
      'const',
      LValidationContext.GetFullSchemaPath + '/const'
    );
    Result := TValidationResult.Failure(LValidationContext.GetFullPath, [LError]);
  end;
end;

end.

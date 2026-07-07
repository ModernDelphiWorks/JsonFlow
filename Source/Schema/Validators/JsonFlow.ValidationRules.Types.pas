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

unit JsonFlow.ValidationRules.Types;

interface

uses
  SysUtils,
  Classes,
  JsonFlow.Interfaces,
  JsonFlow.ValidationEngine,
  JsonFlow.ValidationRules.Base;

type
  // Regra de validação de tipo
  TTypeRule = class(TBaseValidationRule)
  private
    FExpectedType: string;
  public
    constructor Create(const AExpectedType: string);
    function Validate(const AValue: IJSONElement; const AContext: TObject): TValidationResult; override;
  end;

implementation

{ TTypeRule }

constructor TTypeRule.Create(const AExpectedType: string);
begin
  inherited Create('type');
  FExpectedType := AExpectedType;
end;

function TTypeRule.Validate(const AValue: IJSONElement; const AContext: TObject): TValidationResult;
var
  LActualType: string;
  LValue: IJSONValue;
  LError: TValidationError;
  LValidationContext: TValidationContext;
  LExpected: string;
begin
  LValidationContext := TValidationContext(AContext);
  
  // Determinar o tipo atual do valor
  if Supports(AValue, IJSONValue) then
  begin
    LValue := AValue as IJSONValue;
    if LValue.IsString then
      LActualType := 'string'
    else if LValue.IsDate then
      // O Reader detecta strings ISO-8601 e cria TJSONValueDateTime; para o
      // JSON Schema o tipo continua sendo "string" (sem isso, qualquer data
      // num documento reprovava type:string como "unknown").
      LActualType := 'string'
    else if LValue.IsInteger then
      LActualType := 'integer'
    else if LValue.IsFloat then
      LActualType := 'number'
    else if LValue.IsBoolean then
      LActualType := 'boolean'
    else if LValue.IsNull then
      LActualType := 'null'
    else
      LActualType := 'unknown';
  end
  else if Supports(AValue, IJSONArray) then
    LActualType := 'array'
  else if Supports(AValue, IJSONObject) then
    LActualType := 'object'
  else
    LActualType := 'unknown';

  LExpected := AnsiLowerCase(FExpectedType);
  if (LActualType = LExpected) or ((LExpected = 'number') and (LActualType = 'integer')) then
    Result := TValidationResult.Success(LValidationContext.GetFullPath)
  else
  begin
    LError := CreateValidationError(
      LValidationContext.GetFullPath,
      Format('Invalid type: expected %s, found %s', [LExpected, LActualType]),
      LActualType,
      LExpected,
      'type',
      LValidationContext.GetFullSchemaPath + '/type'
    );
    Result := TValidationResult.Failure(LValidationContext.GetFullPath, [LError]);
  end;
end;

end.

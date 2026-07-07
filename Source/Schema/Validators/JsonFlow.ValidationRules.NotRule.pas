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
unit JsonFlow.ValidationRules.NotRule;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  JsonFlow.Interfaces, JsonFlow.ValidationEngine,
  JsonFlow.ValidationRules.Base;

type
  // Regra de validação not - o valor não deve ser válido contra o esquema
  TNotRule = class(TBaseValidationRule)
  private
    FSchema: IJSONElement;
    function ValidateAgainstSchema(const AValue: IJSONElement; const ASchema: IJSONElement; const AContext: TValidationContext): TValidationResult;
  public
    constructor Create(const ASchema: IJSONElement);
    function Validate(const AValue: IJSONElement; const AContext: TObject): TValidationResult; override;
  end;

implementation

uses
  JsonFlow.ValidationRules.Types;

{ TNotRule }

constructor TNotRule.Create(const ASchema: IJSONElement);
begin
  inherited Create('not');
  FSchema := ASchema;
end;

function TNotRule.ValidateAgainstSchema(const AValue: IJSONElement; const ASchema: IJSONElement; const AContext: TValidationContext): TValidationResult;
var
  LSchemaObj: IJSONObject;
  LTypeValue: string;
  LTypeRule: IValidationRule;
begin
  if Assigned(AContext.Evaluator) then
  begin
    Result := AContext.Evaluator.Evaluate(AValue, ASchema, AContext);
    Exit;
  end;

  if not Supports(ASchema, IJSONObject, LSchemaObj) then
  begin
    Result := TValidationResult.Success(AContext.GetFullPath);
    Exit;
  end;
  
  // Validação básica de tipo se especificado
  if LSchemaObj.ContainsKey('type') then
  begin
    LTypeValue := (LSchemaObj.GetValue('type') as IJSONValue).AsString;
    LTypeRule := TTypeRule.Create(LTypeValue);
    try
      Result := LTypeRule.Validate(AValue, AContext);
    finally
      LTypeRule := nil;
    end;
  end
  else
  begin
    Result := TValidationResult.Success(AContext.GetFullPath);
  end;
end;

function TNotRule.Validate(const AValue: IJSONElement; const AContext: TObject): TValidationResult;
var
  LValidationContext: TValidationContext;
  LSchemaResult: TValidationResult;
  LError: TValidationError;
begin
  LValidationContext := TValidationContext(AContext);

  LValidationContext.PushSchemaSegment('not');
  try
    // Validar contra o esquema
    LSchemaResult := ValidateAgainstSchema(AValue, FSchema, LValidationContext);
  
    // Se o esquema é válido, então a regra 'not' falha
    if LSchemaResult.IsValid then
    begin
      LError := CreateValidationError(
        LValidationContext.GetFullPath,
        'Value should not be valid against the schema in not',
        'valid',
        'invalid',
        'not',
        LValidationContext.GetFullSchemaPath
      );
      Result := TValidationResult.Failure(LValidationContext.GetFullPath, [LError]);
    end
    else
    begin
      // Se o esquema é inválido, então a regra 'not' é bem-sucedida
      Result := TValidationResult.Success(LValidationContext.GetFullPath);
    end;
  finally
    LValidationContext.PopSchemaSegment;
  end;
end;

end.

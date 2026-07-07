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

unit JsonFlow.ValidationRules.OneOf;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  JsonFlow.Interfaces, JsonFlow.ValidationEngine,
  JsonFlow.ValidationRules.Base,
  JsonFlow.ValidationRules.Required,
  JsonFlow.ValidationRules.Properties,
  JsonFlow.ValidationRules.MinLength,
  JsonFlow.ValidationRules.MaxLength,
  JsonFlow.ValidationRules.Minimum,
  JsonFlow.ValidationRules.Maximum,
  JsonFlow.ValidationRules.Consts;

type
  // Regra de validação oneOf - exatamente uma das subregras deve ser válida
  TOneOfRule = class(TBaseValidationRule)
  private
    FSchemas: TArray<IJSONElement>;
    function ValidateAgainstSchema(const AValue: IJSONElement; const ASchema: IJSONElement; const AContext: TValidationContext): TValidationResult;
  public
    constructor Create(const ASchemas: TArray<IJSONElement>);
    function Validate(const AValue: IJSONElement; const AContext: TObject): TValidationResult; override;
  end;

implementation

uses
  JsonFlow.ValidationRules.Types;

{ TOneOfRule }

constructor TOneOfRule.Create(const ASchemas: TArray<IJSONElement>);
begin
  inherited Create('oneOf');
  FSchemas := ASchemas;
end;

function TOneOfRule.ValidateAgainstSchema(const AValue: IJSONElement; const ASchema: IJSONElement; const AContext: TValidationContext): TValidationResult;
begin
  if Assigned(AContext.Evaluator) then
    Result := AContext.Evaluator.Evaluate(AValue, ASchema, AContext)
  else
    Result := TValidationResult.Success(AContext.GetFullPath);
end;

function TOneOfRule.Validate(const AValue: IJSONElement; const AContext: TObject): TValidationResult;
var
  LValidationContext: TValidationContext;
  LValidSchemaCount: Integer;
  LSchema: IJSONElement;
  LSchemaResult: TValidationResult;
  I: Integer;
  LError: TValidationError;
  LAllErrors: TList<TValidationError>;
begin
  LValidationContext := TValidationContext(AContext);
  LValidSchemaCount := 0;
  LAllErrors := TList<TValidationError>.Create;
  try
    LValidationContext.PushSchemaSegment('oneOf');
    try
  
  // Contar quantos esquemas são válidos
  for I := 0 to Length(FSchemas) - 1 do
  begin
    LSchema := FSchemas[I];
    LValidationContext.PushSchemaSegment(IntToStr(I));
    try
      LSchemaResult := ValidateAgainstSchema(AValue, LSchema, LValidationContext);
    finally
      LValidationContext.PopSchemaSegment;
    end;
    
    if LSchemaResult.IsValid then
      Inc(LValidSchemaCount);
    if not LSchemaResult.IsValid then
      LAllErrors.AddRange(LSchemaResult.Errors);
  end;
    finally
      LValidationContext.PopSchemaSegment;
    end;
  
  if LValidSchemaCount = 1 then
    Result := TValidationResult.Success(LValidationContext.GetFullPath)
  else if LValidSchemaCount = 0 then
  begin
    LError := CreateValidationError(
      LValidationContext.GetFullPath,
      'Value does not match any of the schemas in oneOf',
      'invalid',
      'valid against exactly one schema',
      'oneOf',
      LValidationContext.GetFullSchemaPath + '/oneOf'
    );
    var LErrors := TList<TValidationError>.Create;
    try
      LErrors.Add(LError);
      LErrors.AddRange(LAllErrors);
      Result := TValidationResult.Failure(LValidationContext.GetFullPath, LErrors.ToArray);
    finally
      LErrors.Free;
    end;
  end
  else
  begin
    LError := CreateValidationError(
      LValidationContext.GetFullPath,
      Format('Value matches %d schemas in oneOf, but should match exactly one', [LValidSchemaCount]),
      IntToStr(LValidSchemaCount),
      '1',
      'oneOf',
      LValidationContext.GetFullSchemaPath + '/oneOf'
    );
    Result := TValidationResult.Failure(LValidationContext.GetFullPath, [LError]);
  end;
  finally
    LAllErrors.Free;
  end;
end;

end.

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

unit JsonFlow.ValidationRules.AllOf;

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
  // Regra de validação allOf - todas as subregras devem ser válidas
  TAllOfRule = class(TBaseValidationRule)
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

{ TAllOfRule }

constructor TAllOfRule.Create(const ASchemas: TArray<IJSONElement>);
begin
  inherited Create('allOf');
  FSchemas := ASchemas;
end;

function TAllOfRule.ValidateAgainstSchema(const AValue: IJSONElement; const ASchema: IJSONElement; const AContext: TValidationContext): TValidationResult;
begin
  if Assigned(AContext.Evaluator) then
    Result := AContext.Evaluator.Evaluate(AValue, ASchema, AContext)
  else
    Result := TValidationResult.Success(AContext.GetFullPath);
end;

function TAllOfRule.Validate(const AValue: IJSONElement; const AContext: TObject): TValidationResult;
var
  LValidationContext: TValidationContext;
  LAllErrors: TList<TValidationError>;
  LHasErrors: Boolean;
  LSchema: IJSONElement;
  LSchemaResult: TValidationResult;
  I: Integer;
begin
  LValidationContext := TValidationContext(AContext);
  LAllErrors := TList<TValidationError>.Create;
  try
    LHasErrors := False;
    
    LValidationContext.PushSchemaSegment('allOf');
    try
      // Todos os esquemas devem ser válidos
      for I := 0 to Length(FSchemas) - 1 do
      begin
        LSchema := FSchemas[I];
        LValidationContext.PushSchemaSegment(IntToStr(I));
        try
          LSchemaResult := ValidateAgainstSchema(AValue, LSchema, LValidationContext);
        finally
          LValidationContext.PopSchemaSegment;
        end;

        if not LSchemaResult.IsValid then
        begin
          LHasErrors := True;
          LAllErrors.AddRange(LSchemaResult.Errors);
        end;
      end;
    finally
      LValidationContext.PopSchemaSegment;
    end;
    
    if LHasErrors then
      Result := TValidationResult.Failure(LValidationContext.GetFullPath, LAllErrors.ToArray)
    else
      Result := TValidationResult.Success(LValidationContext.GetFullPath);
  finally
    LAllErrors.Free;
  end;
end;

end.

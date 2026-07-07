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

unit JsonFlow.ValidationRules.AnyOf;

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
  // Regra de validação anyOf - pelo menos uma das subregras deve ser válida
  TAnyOfRule = class(TBaseValidationRule)
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

{ TAnyOfRule }

constructor TAnyOfRule.Create(const ASchemas: TArray<IJSONElement>);
begin
  inherited Create('anyOf');
  FSchemas := ASchemas;
end;

function TAnyOfRule.ValidateAgainstSchema(const AValue: IJSONElement; const ASchema: IJSONElement; const AContext: TValidationContext): TValidationResult;
begin
  if Assigned(AContext.Evaluator) then
    Result := AContext.Evaluator.Evaluate(AValue, ASchema, AContext)
  else
    Result := TValidationResult.Success(AContext.GetFullPath);
end;

function TAnyOfRule.Validate(const AValue: IJSONElement; const AContext: TObject): TValidationResult;
var
  LValidationContext: TValidationContext;
  LAllErrors: TList<TValidationError>;
  LHasValidSchema: Boolean;
  LSchema: IJSONElement;
  LSchemaResult: TValidationResult;
  I: Integer;
begin
  LValidationContext := TValidationContext(AContext);
  LAllErrors := TList<TValidationError>.Create;
  try
    LHasValidSchema := False;

    LValidationContext.PushSchemaSegment('anyOf');
    try
      // Pelo menos um esquema deve ser válido
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
        begin
          LHasValidSchema := True;
          Break; // Encontrou um esquema válido, pode parar
        end
        else
        begin
          LAllErrors.AddRange(LSchemaResult.Errors);
        end;
      end;
    finally
      LValidationContext.PopSchemaSegment;
    end;
    
    if LHasValidSchema then
      Result := TValidationResult.Success(LValidationContext.GetFullPath)
    else
    begin
      var LError := CreateValidationError(
        LValidationContext.GetFullPath,
        'Value does not match any of the schemas in anyOf',
        'invalid',
        'valid against at least one schema',
        'anyOf',
        LValidationContext.GetFullSchemaPath + '/anyOf'
      );
      var LErrors := TList<TValidationError>.Create;
      try
        LErrors.Add(LError);
        LErrors.AddRange(LAllErrors);
        Result := TValidationResult.Failure(LValidationContext.GetFullPath, LErrors.ToArray);
      finally
        LErrors.Free;
      end;
    end;
  finally
    LAllErrors.Free;
  end;
end;

end.

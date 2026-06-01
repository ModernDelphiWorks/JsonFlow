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

unit JsonFlow.ValidationRules.PropertyNames;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.RegularExpressions,
  JsonFlow.Interfaces, JsonFlow.ValidationEngine, JsonFlow.Value,
  JsonFlow.ValidationRules.Base;

type
  // Regra de validação dos nomes das propriedades
  TPropertyNamesRule = class(TBaseValidationRule)
  private
    FSchema: IJSONElement;
    function ValidatePropertyName(const APropertyName: string; const ASchema: IJSONElement; const AContext: TValidationContext): TValidationResult;
  public
    constructor Create(const ASchema: IJSONElement);
    function Validate(const AValue: IJSONElement; const AContext: TObject): TValidationResult; override;
  end;

implementation

uses
  JsonFlow.ValidationRules.Types, JsonFlow.ValidationRules.Pattern, JsonFlow.ValidationRules.MinLength, JsonFlow.ValidationRules.MaxLength;

{ TPropertyNamesRule }

constructor TPropertyNamesRule.Create(const ASchema: IJSONElement);
begin
  inherited Create('propertyNames');
  FSchema := ASchema;
end;

function TPropertyNamesRule.ValidatePropertyName(const APropertyName: string; const ASchema: IJSONElement; const AContext: TValidationContext): TValidationResult;
var
  LSchemaObj: IJSONObject;
  LTypeValue: string;
  LPatternValue: string;
  LMinLengthValue: Integer;
  LMaxLengthValue: Integer;
  LPatternRule: IValidationRule;
  LMinLengthRule: IValidationRule;
  LMaxLengthRule: IValidationRule;
  LPropertyNameValue: IJSONValue;
  LResult: TValidationResult;
begin
  if not Supports(ASchema, IJSONObject, LSchemaObj) then
  begin
    Result := TValidationResult.Success(AContext.GetFullPath);
    Exit;
  end;

  if Assigned(AContext.Evaluator) then
  begin
    LPropertyNameValue := TJSONValueString.Create(APropertyName);
    try
      Result := AContext.Evaluator.Evaluate(LPropertyNameValue, ASchema, AContext);
    finally
      LPropertyNameValue := nil;
    end;
    Exit;
  end;
  
  // Criar um IJSONValue temporário para o nome da propriedade
  LPropertyNameValue := TJSONValueString.Create(APropertyName);
  try
    // Validar tipo (deve ser string)
    if LSchemaObj.ContainsKey('type') then
    begin
      LTypeValue := (LSchemaObj.GetValue('type') as IJSONValue).AsString;
      if LTypeValue <> 'string' then
      begin
        var LError := CreateValidationError(
          AContext.GetFullPath,
          Format('Property name "%s" type validation failed: expected string', [APropertyName]),
          'property name',
          'string',
          'propertyNames',
          AContext.GetFullSchemaPath + '/propertyNames'
        );
        Result := TValidationResult.Failure(AContext.GetFullPath, [LError]);
        Exit;
      end;
    end;
    
    // Validar padrão se especificado
    if LSchemaObj.ContainsKey('pattern') then
    begin
      LPatternValue := (LSchemaObj.GetValue('pattern') as IJSONValue).AsString;
      LPatternRule := TPatternRule.Create(LPatternValue);
      try
        LResult := LPatternRule.Validate(LPropertyNameValue, AContext);
        if not LResult.IsValid then
        begin
          Result := LResult;
          Exit;
        end;
      finally
        LPatternRule := nil;
      end;
    end;
    
    // Validar comprimento mínimo se especificado
    if LSchemaObj.ContainsKey('minLength') then
    begin
      LMinLengthValue := (LSchemaObj.GetValue('minLength') as IJSONValue).AsInteger;
      LMinLengthRule := TMinLengthRule.Create(LMinLengthValue);
      try
        LResult := LMinLengthRule.Validate(LPropertyNameValue, AContext);
        if not LResult.IsValid then
        begin
          Result := LResult;
          Exit;
        end;
      finally
        LMinLengthRule := nil;
      end;
    end;
    
    // Validar comprimento máximo se especificado
    if LSchemaObj.ContainsKey('maxLength') then
    begin
      LMaxLengthValue := (LSchemaObj.GetValue('maxLength') as IJSONValue).AsInteger;
      LMaxLengthRule := TMaxLengthRule.Create(LMaxLengthValue);
      try
        LResult := LMaxLengthRule.Validate(LPropertyNameValue, AContext);
        if not LResult.IsValid then
        begin
          Result := LResult;
          Exit;
        end;
      finally
        LMaxLengthRule := nil;
      end;
    end;
    
    Result := TValidationResult.Success(AContext.GetFullPath);
  finally
    LPropertyNameValue := nil;
  end;
end;

function TPropertyNamesRule.Validate(const AValue: IJSONElement; const AContext: TObject): TValidationResult;
var
  LObject: IJSONObject;
  LError: TValidationError;
  LValidationContext: TValidationContext;
  LPropertyName: string;
  LPropertyResult: TValidationResult;
  LAllErrors: TList<TValidationError>;
  LHasErrors: Boolean;
  LPairs: TArray<IJSONPair>;
  I: Integer;
begin
  LValidationContext := TValidationContext(AContext);
  
  if not Supports(AValue, IJSONObject, LObject) then
  begin
    LError := CreateValidationError(
      LValidationContext.GetFullPath,
      'Value must be an object for propertyNames validation',
      'non-object',
      'object',
      'propertyNames',
      LValidationContext.GetFullSchemaPath + '/propertyNames'
    );
    Result := TValidationResult.Failure(LValidationContext.GetFullPath, [LError]);
    Exit;
  end;

  LAllErrors := TList<TValidationError>.Create;
  try
    LHasErrors := False;
    LPairs := LObject.Pairs;
    
    LValidationContext.PushSchemaSegment('propertyNames');
    try
      // Validar cada nome de propriedade
      for I := 0 to Length(LPairs) - 1 do
      begin
        LPropertyName := LPairs[I].Key;

        LPropertyResult := ValidatePropertyName(LPropertyName, FSchema, LValidationContext);

        if not LPropertyResult.IsValid then
        begin
          LHasErrors := True;
          LAllErrors.AddRange(LPropertyResult.Errors);
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

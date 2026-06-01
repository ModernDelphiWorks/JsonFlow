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
var
  LSchemaObj: IJSONObject;
  LTypeValue: string;
  LRule: IValidationRule;
  LResult: TValidationResult;
  LErrors: TList<TValidationError>;
  LPropertiesObj: IJSONObject;
  LPropertySchemas: TDictionary<string, IJSONElement>;
  LPair: IJSONPair;
  LRequiredArray: IJSONArray;
  LConstValue: IJSONValue;
  LMinValue, LMaxValue: Double;
  LMinLength, LMaxLength: Integer;
  I: Integer;
  LRequiredFields: TArray<string>;
begin
  if Assigned(AContext.Evaluator) then
  begin
    Result := AContext.Evaluator.Evaluate(AValue, ASchema, AContext);
    Exit;
  end;

  if not Assigned(ASchema) then
  begin
    Result := TValidationResult.Success(AContext.GetFullPath);
    Exit;
  end;
  
  if not Supports(ASchema, IJSONObject, LSchemaObj) then
  begin
    Result := TValidationResult.Success(AContext.GetFullPath);
    Exit;
  end;
  
  LErrors := TList<TValidationError>.Create;
  try
    // Validate type
    if LSchemaObj.ContainsKey('type') then
    begin
      LTypeValue := (LSchemaObj.GetValue('type') as IJSONValue).AsString;
      LRule := TTypeRule.Create(LTypeValue);
      try
        LResult := LRule.Validate(AValue, AContext);
        if not LResult.IsValid then
          LErrors.AddRange(LResult.Errors);
      finally
        LRule := nil;
      end;
    end;
    
    // Validate const
    if LSchemaObj.ContainsKey('const') then
    begin
      LConstValue := LSchemaObj.GetValue('const') as IJSONValue;
      LRule := TConstRule.Create(LConstValue.AsString);
      try
        LResult := LRule.Validate(AValue, AContext);
        if not LResult.IsValid then
          LErrors.AddRange(LResult.Errors);
      finally
        LRule := nil;
      end;
    end;
    
    // Validate required (for objects)
    if LSchemaObj.ContainsKey('required') and Supports(AValue, IJSONObject) then
    begin
      LRequiredArray := LSchemaObj.GetValue('required') as IJSONArray;
      SetLength(LRequiredFields, LRequiredArray.Count);
      for I := 0 to LRequiredArray.Count - 1 do
        LRequiredFields[I] := (LRequiredArray.GetItem(I) as IJSONValue).AsString;
      
      LRule := TRequiredRule.Create(LRequiredFields);
      try
        LResult := LRule.Validate(AValue, AContext);
        if not LResult.IsValid then
          LErrors.AddRange(LResult.Errors);
      finally
        LRule := nil;
      end;
    end;
    
    // Validate properties (for objects)
    if LSchemaObj.ContainsKey('properties') and Supports(AValue, IJSONObject) then
    begin
      LPropertiesObj := LSchemaObj.GetValue('properties') as IJSONObject;
      LPropertySchemas := TDictionary<string, IJSONElement>.Create;
      try
        for LPair in LPropertiesObj.Pairs do
          LPropertySchemas.Add(LPair.Key, LPair.Value);
        
        LRule := TPropertiesRule.Create(LPropertySchemas);
        try
          LResult := LRule.Validate(AValue, AContext);
          if not LResult.IsValid then
            LErrors.AddRange(LResult.Errors);
        finally
          LRule := nil;
        end;
      finally
        LPropertySchemas.Free;
      end;
    end;
    
    // Validate minLength/maxLength (for strings)
    if Supports(AValue, IJSONValue) and (AValue as IJSONValue).IsString then
    begin
      if LSchemaObj.ContainsKey('minLength') then
      begin
        LMinLength := Trunc((LSchemaObj.GetValue('minLength') as IJSONValue).AsFloat);
        LRule := TMinLengthRule.Create(LMinLength);
        try
          LResult := LRule.Validate(AValue, AContext);
          if not LResult.IsValid then
            LErrors.AddRange(LResult.Errors);
        finally
          LRule := nil;
        end;
      end;
      
      if LSchemaObj.ContainsKey('maxLength') then
      begin
        LMaxLength := Trunc((LSchemaObj.GetValue('maxLength') as IJSONValue).AsFloat);
        LRule := TMaxLengthRule.Create(LMaxLength);
        try
          LResult := LRule.Validate(AValue, AContext);
          if not LResult.IsValid then
            LErrors.AddRange(LResult.Errors);
        finally
          LRule := nil;
        end;
      end;
    end;
    
    // Validate minimum/maximum (for numbers)
    if Supports(AValue, IJSONValue) and ((AValue as IJSONValue).IsFloat or (AValue as IJSONValue).IsInteger) then
    begin
      if LSchemaObj.ContainsKey('minimum') then
      begin
        LMinValue := (LSchemaObj.GetValue('minimum') as IJSONValue).AsFloat;
        LRule := TMinimumRule.Create(LMinValue);
        try
          LResult := LRule.Validate(AValue, AContext);
          if not LResult.IsValid then
            LErrors.AddRange(LResult.Errors);
        finally
          LRule := nil;
        end;
      end;
      
      if LSchemaObj.ContainsKey('maximum') then
      begin
        LMaxValue := (LSchemaObj.GetValue('maximum') as IJSONValue).AsFloat;
        LRule := TMaximumRule.Create(LMaxValue);
        try
          LResult := LRule.Validate(AValue, AContext);
          if not LResult.IsValid then
            LErrors.AddRange(LResult.Errors);
        finally
          LRule := nil;
        end;
      end;
    end;
    
    // Return result
    if LErrors.Count = 0 then
      Result := TValidationResult.Success(AContext.GetFullPath)
    else
      Result := TValidationResult.Failure(AContext.GetFullPath, LErrors.ToArray);
      
  finally
    LErrors.Free;
  end;
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

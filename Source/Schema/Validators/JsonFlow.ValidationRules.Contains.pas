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

unit JsonFlow.ValidationRules.Contains;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  JsonFlow.Interfaces, JsonFlow.ValidationEngine,
  JsonFlow.ValidationRules.Base;

type
  // Regra de validação contains - pelo menos um item do array deve ser válido contra o esquema
  TContainsRule = class(TBaseValidationRule)
  private
    FSchema: IJSONElement;
    FMinContains: Integer;
    FMaxContains: Integer;
    function ValidateItemAgainstSchema(const AItem: IJSONElement; const ASchema: IJSONElement; const AContext: TValidationContext): TValidationResult;
  public
    constructor Create(const ASchema: IJSONElement; AMinContains: Integer = 1; AMaxContains: Integer = -1);
    function Validate(const AValue: IJSONElement; const AContext: TObject): TValidationResult; override;
  end;

implementation

uses
  JsonFlow.ValidationRules.Types;

{ TContainsRule }

constructor TContainsRule.Create(const ASchema: IJSONElement; AMinContains: Integer; AMaxContains: Integer);
begin
  inherited Create('contains');
  FSchema := ASchema;
  FMinContains := AMinContains;
  FMaxContains := AMaxContains;
end;

function TContainsRule.ValidateItemAgainstSchema(const AItem: IJSONElement; const ASchema: IJSONElement; const AContext: TValidationContext): TValidationResult;
var
  LSchemaObj: IJSONObject;
  LTypeValue: string;
  LTypeRule: IValidationRule;
begin
  if Assigned(AContext.Evaluator) then
  begin
    Result := AContext.Evaluator.Evaluate(AItem, ASchema, AContext);
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
      Result := LTypeRule.Validate(AItem, AContext);
    finally
      LTypeRule := nil;
    end;
  end
  else
  begin
    Result := TValidationResult.Success(AContext.GetFullPath);
  end;
end;

function TContainsRule.Validate(const AValue: IJSONElement; const AContext: TObject): TValidationResult;
var
  LArray: IJSONArray;
  LValidationContext: TValidationContext;
  LError: TValidationError;
  LItem: IJSONElement;
  LItemResult: TValidationResult;
  LValidItemCount: Integer;
  LIsValid: Boolean;
  I: Integer;
begin
  LValidationContext := TValidationContext(AContext);
  
  if not Supports(AValue, IJSONArray, LArray) then
  begin
    LError := CreateValidationError(
      LValidationContext.GetFullPath,
      'Value must be an array for contains validation',
      'non-array',
      'array',
      'contains',
      LValidationContext.GetFullSchemaPath + '/contains'
    );
    Result := TValidationResult.Failure(LValidationContext.GetFullPath, [LError]);
    Exit;
  end;
  
  LValidItemCount := 0;
  
  LValidationContext.PushSchemaSegment('contains');
  try
    for I := 0 to LArray.Count - 1 do
    begin
      LItem := LArray.GetItem(I);

      LValidationContext.PushArrayIndex(I);
      try
        LItemResult := ValidateItemAgainstSchema(LItem, FSchema, LValidationContext);

        if LItemResult.IsValid then
        begin
          Inc(LValidItemCount);
        end;
      finally
        LValidationContext.PopArrayIndex;
      end;
    end;
  finally
    LValidationContext.PopSchemaSegment;
  end;
  
  LIsValid := LValidItemCount >= FMinContains;
  if LIsValid and (FMaxContains >= 0) then
    LIsValid := LValidItemCount <= FMaxContains;
    
  if LIsValid then
    Result := TValidationResult.Success(LValidationContext.GetFullPath)
  else
  begin
    if LValidItemCount < FMinContains then
    begin
      LError := CreateValidationError(
        LValidationContext.GetFullPath,
        Format('Array contains %d matching items, but at least %d were expected', [LValidItemCount, FMinContains]),
        IntToStr(LValidItemCount),
        'at least ' + IntToStr(FMinContains) + ' matching items',
        'minContains',
        LValidationContext.GetFullSchemaPath + '/minContains'
      );
    end
    else
    begin
      LError := CreateValidationError(
        LValidationContext.GetFullPath,
        Format('Array contains %d matching items, but at most %d were expected', [LValidItemCount, FMaxContains]),
        IntToStr(LValidItemCount),
        'at most ' + IntToStr(FMaxContains) + ' matching items',
        'maxContains',
        LValidationContext.GetFullSchemaPath + '/maxContains'
      );
    end;
    Result := TValidationResult.Failure(LValidationContext.GetFullPath, [LError]);
  end;
end;

end.

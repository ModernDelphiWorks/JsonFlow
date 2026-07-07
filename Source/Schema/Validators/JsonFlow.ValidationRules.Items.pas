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

unit JsonFlow.ValidationRules.Items;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  JsonFlow.Interfaces, JsonFlow.ValidationEngine,
  JsonFlow.ValidationRules.Base;

type
  // Regra de validação de itens de array
  TItemsRule = class(TBaseValidationRule)
  private
    FItemSchema: IJSONElement;
    FItemSchemas: TArray<IJSONElement>; // Para arrays com esquemas específicos por posição
    FUsePositionalSchemas: Boolean;
    FAllowAdditionalItems: Boolean;
    FAdditionalItemsSchema: IJSONElement;
  private
    function ValidateItemAgainstSchema(const AItem: IJSONElement; const ASchema: IJSONElement; const AContext: TValidationContext): TValidationResult;
  public
    constructor Create(const AItemSchema: IJSONElement); overload;
    constructor Create(const AItemSchemas: TArray<IJSONElement>; const AAllowAdditionalItems: Boolean = True; const AAdditionalItemsSchema: IJSONElement = nil); overload;
    function Validate(const AValue: IJSONElement; const AContext: TObject): TValidationResult; override;
  end;

implementation

{ TItemsRule }

constructor TItemsRule.Create(const AItemSchema: IJSONElement);
begin
  inherited Create('items');
  FItemSchema := AItemSchema;
  FUsePositionalSchemas := False;
  FAllowAdditionalItems := True;
  FAdditionalItemsSchema := nil;
end;

constructor TItemsRule.Create(const AItemSchemas: TArray<IJSONElement>; const AAllowAdditionalItems: Boolean; const AAdditionalItemsSchema: IJSONElement);
begin
  inherited Create('items');
  FItemSchemas := AItemSchemas;
  FUsePositionalSchemas := True;
  FAllowAdditionalItems := AAllowAdditionalItems;
  FAdditionalItemsSchema := AAdditionalItemsSchema;
end;

function TItemsRule.Validate(const AValue: IJSONElement; const AContext: TObject): TValidationResult;
var
  LArray: IJSONArray;
  LError: TValidationError;
  LValidationContext: TValidationContext;
  LItem: IJSONElement;
  LItemSchema: IJSONElement;
  LItemResult: TValidationResult;
  LAllErrors: TList<TValidationError>;
  LHasErrors: Boolean;
  LFor: Integer;
begin
  LValidationContext := TValidationContext(AContext);
  
  if not Supports(AValue, IJSONArray, LArray) then
  begin
    LError := CreateValidationError(
      LValidationContext.GetFullPath,
      'Value must be an array for items validation',
      'non-array',
      'array',
      'items',
      LValidationContext.GetFullSchemaPath + '/items'
    );
    Result := TValidationResult.Failure(LValidationContext.GetFullPath, [LError]);
    Exit;
  end;

  LAllErrors := TList<TValidationError>.Create;
  try
    LHasErrors := False;
    
    // Validar cada item do array
    for LFor := 0 to LArray.Count - 1 do
    begin
      LItem := LArray.GetItem(LFor);
      
      // Determinar qual esquema usar
      if FUsePositionalSchemas then
      begin
        if LFor < Length(FItemSchemas) then
          LItemSchema := FItemSchemas[LFor]
        else
        begin
          if not FAllowAdditionalItems then
          begin
            LHasErrors := True;
            LError := CreateValidationError(
              LValidationContext.GetFullPath,
              Format('Additional item at index %d is not allowed', [LFor]),
              IntToStr(LFor),
              'no additional items',
              'additionalItems',
              LValidationContext.GetFullSchemaPath + '/additionalItems'
            );
            LAllErrors.Add(LError);
            Continue;
          end;

          if Assigned(FAdditionalItemsSchema) then
            LItemSchema := FAdditionalItemsSchema
          else
            LItemSchema := nil;
        end;
      end
      else
        LItemSchema := FItemSchema;
      
      if Assigned(LItemSchema) then
      begin
        // Criar contexto para o item
        LValidationContext.PushArrayIndex(LFor);
        try
          if FUsePositionalSchemas then
          begin
            if LFor < Length(FItemSchemas) then
            begin
              LValidationContext.PushSchemaSegment('items');
              LValidationContext.PushSchemaSegment(IntToStr(LFor));
            end
            else
              LValidationContext.PushSchemaSegment('additionalItems');
          end
          else
            LValidationContext.PushSchemaSegment('items');
          try
          // Validar o item usando o esquema
          LItemResult := ValidateItemAgainstSchema(LItem, LItemSchema, LValidationContext);
          
          if not LItemResult.IsValid then
          begin
            LHasErrors := True;
            LAllErrors.AddRange(LItemResult.Errors);
          end;
          finally
            if FUsePositionalSchemas then
            begin
              if LFor < Length(FItemSchemas) then
              begin
                LValidationContext.PopSchemaSegment;
                LValidationContext.PopSchemaSegment;
              end
              else
                LValidationContext.PopSchemaSegment;
            end
            else
              LValidationContext.PopSchemaSegment;
          end;
        finally
          LValidationContext.PopArrayIndex;
        end;
      end;
    end;

    if LHasErrors then
      Result := TValidationResult.Failure(LValidationContext.GetFullPath, LAllErrors.ToArray)
    else
      Result := TValidationResult.Success(LValidationContext.GetFullPath);
  finally
    LAllErrors.Free;
  end;
end;

function TItemsRule.ValidateItemAgainstSchema(const AItem: IJSONElement; const ASchema: IJSONElement; const AContext: TValidationContext): TValidationResult;
begin
  if Assigned(AContext.Evaluator) then
    Result := AContext.Evaluator.Evaluate(AItem, ASchema, AContext)
  else
    Result := TValidationResult.Success(AContext.GetFullPath);
end;

end.

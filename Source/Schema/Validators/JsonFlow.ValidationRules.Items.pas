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
var
  LSchemaObj: IJSONObject;
  LTypeValue: IJSONValue;
  LExpectedType: string;
  LActualType: string;
  LItemValue: IJSONValue;
  LError: TValidationError;
  LPropertiesObj: IJSONObject;
  LPropertySchemas: TDictionary<string, IJSONElement>;
  LPairs: TArray<IJSONPair>;
  LFor: Integer;
  LItemObj: IJSONObject;
  LPropertyName: string;
  LPropertyValue: IJSONElement;
  LPropertySchema: IJSONElement;
  LPropertyResult: TValidationResult;
  LAllErrors: TList<TValidationError>;
  LHasErrors: Boolean;
  LArray: IJSONArray;
  LItemSchema: IJSONElement;
  LItem: IJSONElement;
  LItemErrors: TList<TValidationError>;
  LPropertyErrors: TList<TValidationError>;
  LNewContext: TValidationContext;
begin
  if Assigned(AContext.Evaluator) then
  begin
    Result := AContext.Evaluator.Evaluate(AItem, ASchema, AContext);
    Exit;
  end;

  // Implementação básica de validação de tipo e propriedades
  if not Supports(ASchema, IJSONObject, LSchemaObj) then
  begin
    Result := TValidationResult.Success(AContext.GetFullPath);
    Exit;
  end;

  LAllErrors := TList<TValidationError>.Create;
  try
    LHasErrors := False;
    
    // Verificar se o esquema tem uma propriedade 'type'
    if LSchemaObj.ContainsKey('type') then
    begin
      LTypeValue := LSchemaObj.GetValue('type') as IJSONValue;
      LExpectedType := LTypeValue.AsString;
      
      // Determinar o tipo atual do item
       if Supports(AItem, IJSONValue, LItemValue) then
       begin
         if LItemValue.IsString then
           LActualType := 'string'
         else if LItemValue.IsInteger then
           LActualType := 'integer'
         else if LItemValue.IsFloat then
           LActualType := 'number'
         else if LItemValue.IsBoolean then
           LActualType := 'boolean'
         else if LItemValue.IsNull then
           LActualType := 'null'
         else
           LActualType := 'unknown';
       end
      else if Supports(AItem, IJSONArray) then
        LActualType := 'array'
      else if Supports(AItem, IJSONObject) then
        LActualType := 'object'
      else
        LActualType := 'unknown';
      
      // Verificar se os tipos correspondem
        // Nota: integer é um subtipo de number em JSON Schema
        if not ((LExpectedType = LActualType) or 
                ((LExpectedType = 'number') and (LActualType = 'integer'))) then
       begin
         LError := CreateValidationError(
           AContext.GetFullPath,
           Format('Expected type %s but got %s', [LExpectedType, LActualType]),
           LActualType,
           LExpectedType,
           'type',
           AContext.GetFullSchemaPath + '/type'
         );
         LAllErrors.Add(LError);
         LHasErrors := True;
       end;
    end;
    
    // Validar propriedades se for um objeto
    if (LExpectedType = 'object') and Supports(AItem, IJSONObject, LItemObj) and LSchemaObj.ContainsKey('properties') then
    begin
      LPropertiesObj := LSchemaObj.GetValue('properties') as IJSONObject;
      LPairs := LPropertiesObj.Pairs;

      AContext.PushSchemaSegment('properties');
      try
        for LFor := 0 to Length(LPairs) - 1 do
        begin
          LPropertyName := LPairs[LFor].Key;
          LPropertySchema := LPairs[LFor].Value;

          if LItemObj.ContainsKey(LPropertyName) then
          begin
            LPropertyValue := LItemObj.GetValue(LPropertyName);

            // Criar contexto para a propriedade
            AContext.PushProperty(LPropertyName);
            AContext.PushSchemaSegment(LPropertyName);
            try
              // Validar recursivamente a propriedade
              LPropertyResult := ValidateItemAgainstSchema(LPropertyValue, LPropertySchema, AContext);
              if not LPropertyResult.IsValid then
              begin
                LHasErrors := True;
                LAllErrors.AddRange(LPropertyResult.Errors);
              end;
            finally
              AContext.PopSchemaSegment;
              AContext.PopProperty;
            end;
          end;
        end;
      finally
        AContext.PopSchemaSegment;
      end;
    end;
    
    // Validar itens se for um array
    if (LExpectedType = 'array') and Supports(AItem, IJSONArray, LArray) and LSchemaObj.ContainsKey('items') then
    begin
      LItemSchema := LSchemaObj.GetValue('items');
      
      for LFor := 0 to LArray.Count - 1 do
      begin
        LItem := LArray.GetItem(LFor);
        
        // Criar contexto para o item do array
        AContext.PushArrayIndex(LFor);
        try
          // Validar recursivamente o item
          LPropertyResult := ValidateItemAgainstSchema(LItem, LItemSchema, AContext);
           if not LPropertyResult.IsValid then
           begin
             LHasErrors := True;
             for LError in LPropertyResult.Errors do
               LAllErrors.Add(LError);
           end;
        finally
          AContext.PopArrayIndex;
        end;
      end;
    end;
    
    if LHasErrors then
      Result := TValidationResult.Failure(AContext.GetFullPath, LAllErrors.ToArray)
    else
      Result := TValidationResult.Success(AContext.GetFullPath);
  finally
    LAllErrors.Free;
  end;
end;

end.

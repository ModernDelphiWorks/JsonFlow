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

unit JsonFlow.ValidationRules.Properties;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  JsonFlow.Interfaces, JsonFlow.ValidationEngine,
  JsonFlow.ValidationRules.Base, JsonFlow.ValidationRules.Types;

type
  // Regra de validação de propriedades de objeto
  TPropertiesRule = class(TBaseValidationRule)
  private
    FPropertySchemas: TDictionary<string, IJSONElement>;
    function ValidatePropertySchema(const AValue: IJSONElement; const ASchema: IJSONElement; const AContext: TValidationContext): TValidationResult;
  public
    constructor Create(const APropertySchemas: TDictionary<string, IJSONElement>);
    destructor Destroy; override;
    function Validate(const AValue: IJSONElement; const AContext: TObject): TValidationResult; override;
  end;

implementation

// Função auxiliar para resolver referências locais sem depender do resolver
function ResolveLocalReference(const ARefPath: string; const ARootSchema: IJSONElement): IJSONElement;
var
  LRootObj: IJSONObject;
  LDefsObj: IJSONObject;
  LDefName: string;
begin
  Result := nil;
  
  // Suporte básico para referências locais (#/$defs/...)
  if ARefPath.StartsWith('#/$defs/') then
  begin
    LDefName := ARefPath.Substring(8); // Remove '#/$defs/'
    
    if Supports(ARootSchema, IJSONObject, LRootObj) then
    begin
      if LRootObj.ContainsKey('$defs') then
      begin
        LDefsObj := LRootObj.GetValue('$defs') as IJSONObject;
        if LDefsObj.ContainsKey(LDefName) then
        begin
          Result := LDefsObj.GetValue(LDefName);
        end;
      end;
    end;
  end;
end;

{ TPropertiesRule }

constructor TPropertiesRule.Create(const APropertySchemas: TDictionary<string, IJSONElement>);
begin
  inherited Create('properties');
  FPropertySchemas := APropertySchemas;
end;

destructor TPropertiesRule.Destroy;
begin
  FPropertySchemas.Free;
  inherited;
end;

function TPropertiesRule.Validate(const AValue: IJSONElement; const AContext: TObject): TValidationResult;
var
  LObject: IJSONObject;
  LError: TValidationError;
  LValidationContext: TValidationContext;
  LPropertyName: string;
  LPropertyValue: IJSONElement;
  LPropertySchema: IJSONElement;
  LPropertyResult: TValidationResult;
  LAllErrors: TList<TValidationError>;
  LHasErrors: Boolean;
begin
  LValidationContext := TValidationContext(AContext);
  
  if not Supports(AValue, IJSONObject, LObject) then
  begin
    LError := CreateValidationError(
      LValidationContext.GetFullPath,
      'Value must be an object for properties validation',
      'non-object',
      'object',
      'properties',
      LValidationContext.GetFullSchemaPath + '/properties'
    );
    Result := TValidationResult.Failure(LValidationContext.GetFullPath, [LError]);
    Exit;
  end;

  LAllErrors := TList<TValidationError>.Create;
  try
    LHasErrors := False;
    
    // Validar cada propriedade que tem esquema definido
    for LPropertyName in FPropertySchemas.Keys do
    begin
      if LObject.ContainsKey(LPropertyName) then
      begin
        LPropertyValue := LObject.GetValue(LPropertyName);
        LPropertySchema := FPropertySchemas[LPropertyName];
        
        // Criar contexto para a propriedade
        LValidationContext.PushProperty(LPropertyName);
        try
          LValidationContext.PushSchemaSegment('properties');
          LValidationContext.PushSchemaSegment(LPropertyName);
          try
          // Validar usando o esquema da propriedade
          LPropertyResult := ValidatePropertySchema(LPropertyValue, LPropertySchema, LValidationContext);
          
          if not LPropertyResult.IsValid then
          begin
            LHasErrors := True;
            LAllErrors.AddRange(LPropertyResult.Errors);
          end;
          finally
            LValidationContext.PopSchemaSegment;
            LValidationContext.PopSchemaSegment;
          end;
        finally
          LValidationContext.PopProperty;
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

function TPropertiesRule.ValidatePropertySchema(const AValue: IJSONElement; const ASchema: IJSONElement; const AContext: TValidationContext): TValidationResult;
var
  LSchemaObj: IJSONObject;
  LTypeValue: string;
  LTypeRule: IValidationRule;
  LError: TValidationError;
begin
  if Assigned(AContext.Evaluator) then
  begin
    Result := AContext.Evaluator.Evaluate(AValue, ASchema, AContext);
    Exit;
  end;

  // Verificar se o esquema é um objeto
  if not Supports(ASchema, IJSONObject, LSchemaObj) then
  begin
    Result := TValidationResult.Success(AContext.GetFullPath);
    Exit;
  end;
  
  // Se há uma referência $ref, resolver e validar
  if LSchemaObj.ContainsKey('$ref') then
  begin
    var LRefValue := (LSchemaObj.GetValue('$ref') as IJSONValue).AsString;
    var LResolvedSchema := ResolveLocalReference(LRefValue, AContext.Schema);
    if Assigned(LResolvedSchema) then
    begin
      // Validar recursivamente com o esquema resolvido
      Result := ValidatePropertySchema(AValue, LResolvedSchema, AContext);
      Exit;
    end;
    // Se não conseguiu resolver, considera válido por compatibilidade
    Result := TValidationResult.Success(AContext.GetFullPath);
    Exit;
  end;
  
  // Verificar se há uma regra de tipo
  if LSchemaObj.ContainsKey('type') then
  begin
    LTypeValue := (LSchemaObj.GetValue('type') as IJSONValue).AsString;
    
    // Criar e aplicar a regra de tipo
    LTypeRule := TTypeRule.Create(LTypeValue);
    try
      Result := LTypeRule.Validate(AValue, AContext);
    finally
      LTypeRule := nil; // Interface será liberada automaticamente
    end;
  end
  else
  begin
    // Se não há regra de tipo, considera válido
    Result := TValidationResult.Success(AContext.GetFullPath);
  end;
end;

end.

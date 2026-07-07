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

unit JsonFlow.ValidationRules.AdditionalProperties;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  System.RegularExpressions,
  JsonFlow.Interfaces,
  JsonFlow.ValidationEngine,
  JsonFlow.ValidationRules.Base;

type
  // Regra de validação de propriedades adicionais
  TAdditionalPropertiesRule = class(TBaseValidationRule)
  private
    FAllowAdditional: Boolean;
    FAdditionalSchema: IJSONElement;
    FDefinedProperties: TArray<string>;
    FPatternProperties: TArray<string>;
    FDefinedSet: TDictionary<string, Byte>;
    FCompiledPatterns: TArray<TRegEx>;
    function IsDefinedProperty(const APropertyName: string): Boolean;
  public
    constructor Create(AAllowAdditional: Boolean;
      const AAdditionalSchema: IJSONElement = nil;
      const ADefinedProperties: TArray<string> = nil;
      const APatternProperties: TArray<string> = nil);
    destructor Destroy; override;
    function Validate(const AValue: IJSONElement; const AContext: TObject): TValidationResult; override;
  end;

implementation

{ TAdditionalPropertiesRule }

constructor TAdditionalPropertiesRule.Create(AAllowAdditional: Boolean;
  const AAdditionalSchema: IJSONElement;
  const ADefinedProperties: TArray<string>;
  const APatternProperties: TArray<string>);
var
  LProp, LPattern: string;
  LRegex: TRegEx;
begin
  inherited Create('additionalProperties');
  FAllowAdditional := AAllowAdditional;
  FAdditionalSchema := AAdditionalSchema;
  FDefinedProperties := ADefinedProperties;
  FPatternProperties := APatternProperties;

  // Preparado UMA vez no compile: hash set das propriedades definidas (antes
  // busca linear por propriedade validada) e regexes pré-compiladas (antes
  // TRegEx.IsMatch estático compilava a cada chamada).
  FDefinedSet := TDictionary<string, Byte>.Create;
  for LProp in ADefinedProperties do
    FDefinedSet.AddOrSetValue(LProp, 0);

  for LPattern in APatternProperties do
  begin
    try
      LRegex := TRegEx.Create(LPattern, [roCompiled]);
      if LRegex.IsMatch('') then; // força a compilação lazy fora do hot path
      FCompiledPatterns := FCompiledPatterns + [LRegex];
    except
      // padrão inválido: ignora (comportamento anterior: Exit(False) na 1ª falha)
    end;
  end;
end;

destructor TAdditionalPropertiesRule.Destroy;
begin
  FDefinedSet.Free;
  inherited;
end;

function TAdditionalPropertiesRule.IsDefinedProperty(const APropertyName: string): Boolean;
var
  LFor: Integer;
begin
  if FDefinedSet.ContainsKey(APropertyName) then
    Exit(True);

  for LFor := 0 to High(FCompiledPatterns) do
    if FCompiledPatterns[LFor].IsMatch(APropertyName) then
      Exit(True);

  Result := False;
end;

function TAdditionalPropertiesRule.Validate(const AValue: IJSONElement; const AContext: TObject): TValidationResult;
var
  LObject: IJSONObject;
  LError: TValidationError;
  LValidationContext: TValidationContext;
  LPropertyName: string;
  LPropertyValue: IJSONElement;
  LIsDefinedProperty: Boolean;
  LAllErrors: TList<TValidationError>;
  LHasErrors: Boolean;
  LPairs: TArray<IJSONPair>;
  LFor: Integer;
begin
  LValidationContext := TValidationContext(AContext);

  if not Supports(AValue, IJSONObject, LObject) then
  begin
    LError := CreateValidationError(
      LValidationContext.GetFullPath,
      'Value must be an object for additionalProperties validation',
      'non-object',
      'object',
      'additionalProperties',
      LValidationContext.GetFullSchemaPath + '/additionalProperties'
    );
    Result := TValidationResult.Failure(LValidationContext.GetFullPath, [LError]);
    Exit;
  end;

  LAllErrors := TList<TValidationError>.Create;
  try
    LHasErrors := False;
    LPairs := LObject.Pairs;

    // Verificar cada propriedade do objeto
    for LFor := 0 to Length(LPairs) - 1 do
    begin
      LPropertyName := LPairs[LFor].Key;
      
      // Verificar se é uma propriedade definida no esquema
      LIsDefinedProperty := IsDefinedProperty(LPropertyName);
      
      // Se não é uma propriedade definida, é uma propriedade adicional
      if not LIsDefinedProperty then
      begin
        if not FAllowAdditional then
        begin
          // Propriedades adicionais não são permitidas
          LHasErrors := True;
          LError := CreateValidationError(
            LValidationContext.GetFullPath + '.' + LPropertyName,
            Format('Additional property "%s" is not allowed', [LPropertyName]),
            'present',
            'not allowed',
            'additionalProperties',
            LValidationContext.GetFullSchemaPath + '/additionalProperties'
          );
          LAllErrors.Add(LError);
        end
        else if Assigned(FAdditionalSchema) then
        begin
          // Validar propriedade adicional contra o esquema
          LPropertyValue := LObject.GetValue(LPropertyName);
          LValidationContext.PushProperty(LPropertyName);
          try
            if Assigned(LValidationContext.Evaluator) then
            begin
              LValidationContext.PushSchemaSegment('additionalProperties');
              try
                var LSubResult := LValidationContext.Evaluator.Evaluate(LPropertyValue, FAdditionalSchema, LValidationContext);
                if not LSubResult.IsValid then
                begin
                  LHasErrors := True;
                  LAllErrors.AddRange(LSubResult.Errors);
                end;
              finally
                LValidationContext.PopSchemaSegment;
              end;
            end;
          finally
            LValidationContext.PopProperty;
          end;
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

end.

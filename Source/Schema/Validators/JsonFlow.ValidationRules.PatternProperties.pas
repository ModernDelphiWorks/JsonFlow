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

unit JsonFlow.ValidationRules.PatternProperties;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.RegularExpressions,
  JsonFlow.Interfaces, JsonFlow.ValidationEngine,
  JsonFlow.ValidationRules.Base;

type
  // Regra de validação de propriedades baseada em padrões
  TPatternPropertiesRule = class(TBaseValidationRule)
  private
    FPatternSchemas: TDictionary<string, IJSONElement>;
    FCompiledPatterns: TDictionary<string, TRegEx>;
    function ValidatePropertySchema(const AValue: IJSONElement; const ASchema: IJSONElement; const AContext: TValidationContext): TValidationResult;
  public
    constructor Create(const APatternSchemas: TDictionary<string, IJSONElement>);
    destructor Destroy; override;
    function Validate(const AValue: IJSONElement; const AContext: TObject): TValidationResult; override;
  end;

implementation

uses
  JsonFlow.ValidationRules.Types;

{ TPatternPropertiesRule }

constructor TPatternPropertiesRule.Create(const APatternSchemas: TDictionary<string, IJSONElement>);
var
  LPattern: string;
  LRegex: TRegEx;
begin
  inherited Create('patternProperties');
  FPatternSchemas := APatternSchemas;
  // Compila cada padrão UMA vez — antes era TRegEx.Create dentro do loop
  // propriedade × padrão a cada objeto validado. Padrão inválido fica de
  // fora e é reportado no Validate (mesmo comportamento do try/except antigo).
  FCompiledPatterns := TDictionary<string, TRegEx>.Create;
  for LPattern in APatternSchemas.Keys do
  begin
    try
      LRegex := TRegEx.Create(LPattern, [roCompiled]);
      if LRegex.IsMatch('') then; // força a compilação lazy fora do hot path
      FCompiledPatterns.Add(LPattern, LRegex);
    except
      // padrão inválido: sem entrada no dicionário
    end;
  end;
end;

destructor TPatternPropertiesRule.Destroy;
begin
  FCompiledPatterns.Free;
  FPatternSchemas.Free;
  inherited;
end;

function TPatternPropertiesRule.ValidatePropertySchema(const AValue: IJSONElement; const ASchema: IJSONElement; const AContext: TValidationContext): TValidationResult;
var
  LSchemaObj: IJSONObject;
  LTypeValue: string;
  LTypeRule: IValidationRule;
begin
  if Assigned(AContext.Evaluator) then
  begin
    Result := AContext.Evaluator.Evaluate(AValue, ASchema, AContext);
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
      Result := LTypeRule.Validate(AValue, AContext);
    finally
      LTypeRule := nil;
    end;
  end
  else
  begin
    Result := TValidationResult.Success(AContext.GetFullPath);
  end;
end;

function TPatternPropertiesRule.Validate(const AValue: IJSONElement; const AContext: TObject): TValidationResult;
var
  LObject: IJSONObject;
  LError: TValidationError;
  LValidationContext: TValidationContext;
  LPropertyName: string;
  LPropertyValue: IJSONElement;
  LPattern: string;
  LPatternSchema: IJSONElement;
  LPropertyResult: TValidationResult;
  LAllErrors: TList<TValidationError>;
  LHasErrors: Boolean;
  LRegex: TRegEx;
  LPairs: TArray<IJSONPair>;
  I: Integer;
begin
  LValidationContext := TValidationContext(AContext);
  
  if not Supports(AValue, IJSONObject, LObject) then
  begin
    LError := CreateValidationError(
      LValidationContext.GetFullPath,
      'Value must be an object for patternProperties validation',
      'non-object',
      'object',
      'patternProperties',
      LValidationContext.GetFullSchemaPath + '/patternProperties'
    );
    Result := TValidationResult.Failure(LValidationContext.GetFullPath, [LError]);
    Exit;
  end;

  LAllErrors := TList<TValidationError>.Create;
  try
    LHasErrors := False;
    LPairs := LObject.Pairs;
    
    LValidationContext.PushSchemaSegment('patternProperties');
    try
      // Verificar cada propriedade do objeto
      for I := 0 to Length(LPairs) - 1 do
      begin
        LPropertyName := LPairs[I].Key;
        LPropertyValue := LPairs[I].Value;

        // Verificar se a propriedade corresponde a algum padrão
        for LPattern in FPatternSchemas.Keys do
        begin
          try
            // Regex pré-compilada no constructor; padrão inválido não entra
            // no dicionário e cai no caminho de erro abaixo.
            if not FCompiledPatterns.TryGetValue(LPattern, LRegex) then
              raise Exception.CreateFmt('Pattern "%s" failed to compile', [LPattern]);
            if LRegex.IsMatch(LPropertyName) then
            begin
              LPatternSchema := FPatternSchemas[LPattern];

              // Criar contexto para a propriedade
              LValidationContext.PushProperty(LPropertyName);
              LValidationContext.PushSchemaSegment(LPattern);
              try
                // Validar usando o esquema do padrão
                LPropertyResult := ValidatePropertySchema(LPropertyValue, LPatternSchema, LValidationContext);

                if not LPropertyResult.IsValid then
                begin
                  LHasErrors := True;
                  LAllErrors.AddRange(LPropertyResult.Errors);
                end;
              finally
                LValidationContext.PopSchemaSegment;
                LValidationContext.PopProperty;
              end;
            end;
          except
            on E: Exception do
            begin
              LError := CreateValidationError(
                LValidationContext.GetFullPath,
                Format('Invalid regex pattern "%s": %s', [LPattern, E.Message]),
                LPattern,
                'valid regex',
                'patternProperties',
                LValidationContext.GetFullSchemaPath + '/patternProperties'
              );
              LAllErrors.Add(LError);
              LHasErrors := True;
            end;
          end;
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

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
unit JsonFlow.ValidationRules.Dependencies;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  JsonFlow.Interfaces, JsonFlow.ValidationEngine,
  JsonFlow.ValidationRules.Base;

type
  // Regra de validação para a keyword 'dependencies' (Draft-07)
  TDependenciesRule = class(TBaseValidationRule)
  private
    FPropertyDeps: TDictionary<string, TArray<string>>;
    FSchemaDeps: TDictionary<string, IValidationRule>;
  public
    constructor Create(const APropertyDeps: TDictionary<string, TArray<string>>;
      const ASchemaDeps: TDictionary<string, IValidationRule>);
    destructor Destroy; override;
    function Validate(const AValue: IJSONElement; const AContext: TObject): TValidationResult; override;
  end;

implementation

{ TDependenciesRule }

constructor TDependenciesRule.Create(const APropertyDeps: TDictionary<string, TArray<string>>;
  const ASchemaDeps: TDictionary<string, IValidationRule>);
begin
  inherited Create('dependencies');
  FPropertyDeps := APropertyDeps;
  FSchemaDeps := ASchemaDeps;
end;

destructor TDependenciesRule.Destroy;
begin
  FPropertyDeps.Free;
  FSchemaDeps.Free;
  inherited;
end;

function TDependenciesRule.Validate(const AValue: IJSONElement; const AContext: TObject): TValidationResult;
var
  LObject: IJSONObject;
  LValidationContext: TValidationContext;
  LError: TValidationError;
  LErrors: TList<TValidationError>;
  LTriggerProp: string;
  LDepProp: string;
  LDeps: TArray<string>;
  LSchemaRule: IValidationRule;
  LSubResult: TValidationResult;
  LSubError: TValidationError;
begin
  LValidationContext := TValidationContext(AContext);

  if not Supports(AValue, IJSONObject, LObject) then
  begin
    // 'dependencies' só se aplica a objetos
    Result := TValidationResult.Success(LValidationContext.GetFullPath);
    Exit;
  end;

  LErrors := TList<TValidationError>.Create;
  try
    // 1. Processar dependências de propriedades
    if Assigned(FPropertyDeps) then
    begin
      for LTriggerProp in FPropertyDeps.Keys do
      begin
        // Se a propriedade disparadora existe no objeto
        if LObject.ContainsKey(LTriggerProp) then
        begin
          LDeps := FPropertyDeps[LTriggerProp];
          for LDepProp in LDeps do
          begin
            // Se a propriedade dependente está ausente
            if not LObject.ContainsKey(LDepProp) then
            begin
              LError := CreateValidationError(
                LValidationContext.GetFullPath + '/' + LDepProp,
                Format('Dependency property "%s" is required when "%s" is present', [LDepProp, LTriggerProp]),
                'missing',
                'present',
                'dependencies',
                LValidationContext.GetFullSchemaPath + '/dependencies/' + LTriggerProp
              );
              LErrors.Add(LError);
            end;
          end;
        end;
      end;
    end;

    // 2. Processar dependências de esquemas
    if Assigned(FSchemaDeps) then
    begin
      for LTriggerProp in FSchemaDeps.Keys do
      begin
        // Se a propriedade disparadora existe no objeto
        if LObject.ContainsKey(LTriggerProp) then
        begin
          LSchemaRule := FSchemaDeps[LTriggerProp];
          
          // Entrar no subcaminho para a validação do esquema condicional
          LValidationContext.PushProperty(LTriggerProp);
          LValidationContext.PushSchemaSegment('dependencies');
          LValidationContext.PushSchemaSegment(LTriggerProp);
          try
            LSubResult := LSchemaRule.Validate(AValue, LValidationContext);
            if not LSubResult.IsValid then
            begin
              for LSubError in LSubResult.Errors do
                LErrors.Add(LSubError);
            end;
          finally
            LValidationContext.PopSchemaSegment;
            LValidationContext.PopSchemaSegment;
            LValidationContext.PopProperty;
          end;
        end;
      end;
    end;

    if LErrors.Count = 0 then
      Result := TValidationResult.Success(LValidationContext.GetFullPath)
    else
      Result := TValidationResult.Failure(LValidationContext.GetFullPath, LErrors.ToArray);
  finally
    LErrors.Free;
  end;
end;

end.

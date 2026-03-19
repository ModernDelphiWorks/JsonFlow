{
  ------------------------------------------------------------------------------
  JsonFlow
  Fluent and expressive JSON manipulation API for Delphi.

  SPDX-License-Identifier: Apache-2.0
  Copyright (c) 2025-2026 Isaque Pinheiro

  Licensed under the Apache License, Version 2.0.
  See the LICENSE file in the project root for full license information.
  ------------------------------------------------------------------------------
}

{$include ../../JsonFlow.inc}

unit JsonFlow.ValidationRules;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  JsonFlow.Interfaces,
  JsonFlow.ValidationEngine,
  JsonFlow.ValidationRules.Base,
  JsonFlow.ValidationRules.Types,
  JsonFlow.ValidationRules.Minimum,
  JsonFlow.ValidationRules.Maximum,
  JsonFlow.ValidationRules.MinLength,
  JsonFlow.ValidationRules.MaxLength,
  JsonFlow.ValidationRules.ExclusiveMinimum,
  JsonFlow.ValidationRules.ExclusiveMaximum,
  JsonFlow.ValidationRules.MultipleOf,
  JsonFlow.ValidationRules.Pattern,
  JsonFlow.ValidationRules.Format,
  JsonFlow.ValidationRules.Enum,
  JsonFlow.ValidationRules.Consts,
  JsonFlow.ValidationRules.Required,
  JsonFlow.ValidationRules.Properties,
  JsonFlow.ValidationRules.AdditionalProperties,
  JsonFlow.ValidationRules.Items,
  JsonFlow.ValidationRules.UniqueItems,
  JsonFlow.ValidationRules.MinItems,
  JsonFlow.ValidationRules.MaxItems,
  JsonFlow.ValidationRules.MinProperties,
  JsonFlow.ValidationRules.MaxProperties,
  JsonFlow.ValidationRules.AllOf,
  JsonFlow.ValidationRules.AnyOf,
  JsonFlow.ValidationRules.OneOf,
  JsonFlow.ValidationRules.NotRule,
  JsonFlow.ValidationRules.Contains,
  JsonFlow.ValidationRules.PatternProperties,
  JsonFlow.ValidationRules.PropertyNames,
  JsonFlow.ValidationRules.Conditional;

type
  TBaseValidationRule = JsonFlow.ValidationRules.Base.TBaseValidationRule;
  TTypeRule = JsonFlow.ValidationRules.Types.TTypeRule;
  TMinimumRule = JsonFlow.ValidationRules.Minimum.TMinimumRule;
  TMaximumRule = JsonFlow.ValidationRules.Maximum.TMaximumRule;
  TMinLengthRule = JsonFlow.ValidationRules.MinLength.TMinLengthRule;
  TMaxLengthRule = JsonFlow.ValidationRules.MaxLength.TMaxLengthRule;
  TExclusiveMinimumRule = JsonFlow.ValidationRules.ExclusiveMinimum.TExclusiveMinimumRule;
  TExclusiveMaximumRule = JsonFlow.ValidationRules.ExclusiveMaximum.TExclusiveMaximumRule;
  TMultipleOfRule = JsonFlow.ValidationRules.MultipleOf.TMultipleOfRule;
  TPatternRule = JsonFlow.ValidationRules.Pattern.TPatternRule;
  TFormatRule = JsonFlow.ValidationRules.Format.TFormatRule;
  TEnumRule = JsonFlow.ValidationRules.Enum.TEnumRule;
  TConstRule = JsonFlow.ValidationRules.Consts.TConstRule;
  TRequiredRule = JsonFlow.ValidationRules.Required.TRequiredRule;
  TPropertiesRule = JsonFlow.ValidationRules.Properties.TPropertiesRule;
  TAdditionalPropertiesRule = JsonFlow.ValidationRules.AdditionalProperties.TAdditionalPropertiesRule;
  TItemsRule = JsonFlow.ValidationRules.Items.TItemsRule;
  TUniqueItemsRule = JsonFlow.ValidationRules.UniqueItems.TUniqueItemsRule;
  TMinItemsRule = JsonFlow.ValidationRules.MinItems.TMinItemsRule;
  TMaxItemsRule = JsonFlow.ValidationRules.MaxItems.TMaxItemsRule;
  TMinPropertiesRule = JsonFlow.ValidationRules.MinProperties.TMinPropertiesRule;
  TMaxPropertiesRule = JsonFlow.ValidationRules.MaxProperties.TMaxPropertiesRule;
  TAllOfRule = JsonFlow.ValidationRules.AllOf.TAllOfRule;
  TAnyOfRule = JsonFlow.ValidationRules.AnyOf.TAnyOfRule;
  TOneOfRule = JsonFlow.ValidationRules.OneOf.TOneOfRule;
  TNotRule = JsonFlow.ValidationRules.NotRule.TNotRule;
  TContainsRule = JsonFlow.ValidationRules.Contains.TContainsRule;
  TPatternPropertiesRule = JsonFlow.ValidationRules.PatternProperties.TPatternPropertiesRule;
  TPropertyNamesRule = JsonFlow.ValidationRules.PropertyNames.TPropertyNamesRule;
  TConditionalRule = JsonFlow.ValidationRules.Conditional.TConditionalRule;

  // Factory para cria��o de regras
  TValidationRuleFactory = class
  public
    class function CreateTypeRule(const AExpectedType: string): IValidationRule;
    class function CreateMinimumRule(AMinValue: Double): IValidationRule;
    class function CreateMaximumRule(AMaxValue: Double): IValidationRule;
    class function CreateMinLengthRule(AMinLength: Integer): IValidationRule;
    class function CreateMaxLengthRule(AMaxLength: Integer): IValidationRule;
    class function CreateExclusiveMinimumRule(AMinValue: Double): IValidationRule;
    class function CreateExclusiveMaximumRule(AMaxValue: Double): IValidationRule;
    class function CreateMultipleOfRule(ADivisor: Double): IValidationRule;
    class function CreatePatternRule(const APattern: string): IValidationRule;
    class function CreateFormatRule(const AFormat: string): IValidationRule;
    class function CreateEnumRule(const AAllowedValues: TArray<string>): IValidationRule;
    class function CreateConstRule(const AConstValue: string): IValidationRule;
    class function CreateRequiredRule(const ARequiredProperties: TArray<string>): IValidationRule;
    class function CreatePropertiesRule(const APropertySchemas: TDictionary<string, IJSONElement>): IValidationRule;
    class function CreateAdditionalPropertiesRule(AAllowAdditional: Boolean; const AAdditionalSchema: IJSONElement = nil; const ADefinedProperties: TArray<string> = nil): IValidationRule;
    class function CreateItemsRule(const AItemSchema: IJSONElement): IValidationRule; overload;
    class function CreateItemsRule(const AItemSchemas: TArray<IJSONElement>): IValidationRule; overload;
    class function CreateUniqueItemsRule(ARequireUnique: Boolean): IValidationRule;
    class function CreateMinItemsRule(AMinItems: Integer): IValidationRule;
    class function CreateMaxItemsRule(AMaxItems: Integer): IValidationRule;
    class function CreateMinPropertiesRule(AMinProperties: Integer): IValidationRule;
    class function CreateMaxPropertiesRule(AMaxProperties: Integer): IValidationRule;
    class function CreateAllOfRule(const ASchemas: TArray<IJSONElement>): IValidationRule;
    class function CreateAnyOfRule(const ASchemas: TArray<IJSONElement>): IValidationRule;
    class function CreateOneOfRule(const ASchemas: TArray<IJSONElement>): IValidationRule;
    class function CreateNotRule(const ASchema: IJSONElement): IValidationRule;
    class function CreateContainsRule(const ASchema: IJSONElement): IValidationRule;
    class function CreatePatternPropertiesRule(const APatternSchemas: TDictionary<string, IJSONElement>): IValidationRule;
    class function CreatePropertyNamesRule(const ASchema: IJSONElement): IValidationRule;
    class function CreateConditionalRule(const AIfSchema: IJSONElement; const AThenSchema: IJSONElement = nil; const AElseSchema: IJSONElement = nil): IValidationRule;
  end;

implementation

{ TValidationRuleFactory }

class function TValidationRuleFactory.CreateTypeRule(const AExpectedType: string): IValidationRule;
begin
  Result := TTypeRule.Create(AExpectedType);
end;

class function TValidationRuleFactory.CreateMinimumRule(AMinValue: Double): IValidationRule;
begin
  Result := TMinimumRule.Create(AMinValue);
end;

class function TValidationRuleFactory.CreateMaximumRule(AMaxValue: Double): IValidationRule;
begin
  Result := TMaximumRule.Create(AMaxValue);
end;

class function TValidationRuleFactory.CreateMinLengthRule(AMinLength: Integer): IValidationRule;
begin
  Result := TMinLengthRule.Create(AMinLength);
end;

class function TValidationRuleFactory.CreateMaxLengthRule(AMaxLength: Integer): IValidationRule;
begin
  Result := TMaxLengthRule.Create(AMaxLength);
end;

class function TValidationRuleFactory.CreateExclusiveMinimumRule(AMinValue: Double): IValidationRule;
begin
  Result := TExclusiveMinimumRule.Create(AMinValue);
end;

class function TValidationRuleFactory.CreateExclusiveMaximumRule(AMaxValue: Double): IValidationRule;
begin
  Result := TExclusiveMaximumRule.Create(AMaxValue);
end;

class function TValidationRuleFactory.CreateMultipleOfRule(ADivisor: Double): IValidationRule;
begin
  Result := TMultipleOfRule.Create(ADivisor);
end;

class function TValidationRuleFactory.CreatePatternRule(const APattern: string): IValidationRule;
begin
  Result := TPatternRule.Create(APattern);
end;

class function TValidationRuleFactory.CreateFormatRule(const AFormat: string): IValidationRule;
begin
  Result := TFormatRule.Create(AFormat);
end;

class function TValidationRuleFactory.CreateEnumRule(const AAllowedValues: TArray<string>): IValidationRule;
begin
  Result := TEnumRule.Create(AAllowedValues);
end;

class function TValidationRuleFactory.CreateConstRule(const AConstValue: string): IValidationRule;
begin
  Result := TConstRule.Create(AConstValue);
end;

class function TValidationRuleFactory.CreateRequiredRule(const ARequiredProperties: TArray<string>): IValidationRule;
begin
  Result := TRequiredRule.Create(ARequiredProperties);
end;

class function TValidationRuleFactory.CreatePropertiesRule(const APropertySchemas: TDictionary<string, IJSONElement>): IValidationRule;
begin
  Result := TPropertiesRule.Create(APropertySchemas);
end;

class function TValidationRuleFactory.CreateAdditionalPropertiesRule(AAllowAdditional: Boolean; const AAdditionalSchema: IJSONElement; const ADefinedProperties: TArray<string>): IValidationRule;
begin
  Result := TAdditionalPropertiesRule.Create(AAllowAdditional, AAdditionalSchema, ADefinedProperties);
end;

class function TValidationRuleFactory.CreateItemsRule(const AItemSchema: IJSONElement): IValidationRule;
begin
  Result := TItemsRule.Create(AItemSchema);
end;

class function TValidationRuleFactory.CreateItemsRule(const AItemSchemas: TArray<IJSONElement>): IValidationRule;
begin
  Result := TItemsRule.Create(AItemSchemas);
end;

class function TValidationRuleFactory.CreateUniqueItemsRule(ARequireUnique: Boolean): IValidationRule;
begin
  Result := TUniqueItemsRule.Create(ARequireUnique);
end;

class function TValidationRuleFactory.CreateMinItemsRule(AMinItems: Integer): IValidationRule;
begin
  Result := TMinItemsRule.Create(AMinItems);
end;

class function TValidationRuleFactory.CreateMaxItemsRule(AMaxItems: Integer): IValidationRule;
begin
  Result := TMaxItemsRule.Create(AMaxItems);
end;

class function TValidationRuleFactory.CreateMinPropertiesRule(AMinProperties: Integer): IValidationRule;
begin
  Result := TMinPropertiesRule.Create(AMinProperties);
end;

class function TValidationRuleFactory.CreateMaxPropertiesRule(AMaxProperties: Integer): IValidationRule;
begin
  Result := TMaxPropertiesRule.Create(AMaxProperties);
end;

class function TValidationRuleFactory.CreateAllOfRule(const ASchemas: TArray<IJSONElement>): IValidationRule;
begin
  Result := TAllOfRule.Create(ASchemas);
end;

class function TValidationRuleFactory.CreateAnyOfRule(const ASchemas: TArray<IJSONElement>): IValidationRule;
begin
  Result := TAnyOfRule.Create(ASchemas);
end;

class function TValidationRuleFactory.CreateOneOfRule(const ASchemas: TArray<IJSONElement>): IValidationRule;
begin
  Result := TOneOfRule.Create(ASchemas);
end;

class function TValidationRuleFactory.CreateNotRule(const ASchema: IJSONElement): IValidationRule;
begin
  Result := TNotRule.Create(ASchema);
end;

class function TValidationRuleFactory.CreateContainsRule(const ASchema: IJSONElement): IValidationRule;
begin
  Result := TContainsRule.Create(ASchema);
end;

class function TValidationRuleFactory.CreatePatternPropertiesRule(const APatternSchemas: TDictionary<string, IJSONElement>): IValidationRule;
begin
  Result := TPatternPropertiesRule.Create(APatternSchemas);
end;

class function TValidationRuleFactory.CreatePropertyNamesRule(const ASchema: IJSONElement): IValidationRule;
begin
  Result := TPropertyNamesRule.Create(ASchema);
end;

class function TValidationRuleFactory.CreateConditionalRule(const AIfSchema: IJSONElement; const AThenSchema: IJSONElement; const AElseSchema: IJSONElement): IValidationRule;
begin
  Result := TConditionalRule.Create(AIfSchema, AThenSchema, AElseSchema);
end;

end.

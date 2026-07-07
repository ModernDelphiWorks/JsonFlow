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
unit JsonFlow.ValidationRules.MinProperties;

interface

uses
  System.SysUtils, System.Classes,
  JsonFlow.Interfaces, JsonFlow.ValidationEngine,
  JsonFlow.ValidationRules.Base;

type
  // Regra de validação de número mínimo de propriedades em objeto
  TMinPropertiesRule = class(TBaseValidationRule)
  private
    FMinProperties: Integer;
  public
    constructor Create(AMinProperties: Integer);
    function Validate(const AValue: IJSONElement; const AContext: TObject): TValidationResult; override;
  end;

implementation

{ TMinPropertiesRule }

constructor TMinPropertiesRule.Create(AMinProperties: Integer);
begin
  inherited Create('minProperties');
  FMinProperties := AMinProperties;
end;

function TMinPropertiesRule.Validate(const AValue: IJSONElement; const AContext: TObject): TValidationResult;
var
  LObject: IJSONObject;
  LError: TValidationError;
  LValidationContext: TValidationContext;
  LPropertyCount: Integer;
begin
  LValidationContext := TValidationContext(AContext);
  
  if not Supports(AValue, IJSONObject, LObject) then
  begin
    LError := CreateValidationError(
      LValidationContext.GetFullPath,
      'Value must be an object for minProperties validation',
      'non-object',
      'object',
      'minProperties',
      LValidationContext.GetFullSchemaPath + '/minProperties'
    );
    Result := TValidationResult.Failure(LValidationContext.GetFullPath, [LError]);
    Exit;
  end;

  LPropertyCount := LObject.Count;
  
  if LPropertyCount >= FMinProperties then
    Result := TValidationResult.Success(LValidationContext.GetFullPath)
  else
  begin
    LError := CreateValidationError(
      LValidationContext.GetFullPath,
      Format('Object has %d properties, minimum required is %d', [LPropertyCount, FMinProperties]),
      IntToStr(LPropertyCount),
      IntToStr(FMinProperties),
      'minProperties',
      LValidationContext.GetFullSchemaPath + '/minProperties'
    );
    Result := TValidationResult.Failure(LValidationContext.GetFullPath, [LError]);
  end;
end;

end.

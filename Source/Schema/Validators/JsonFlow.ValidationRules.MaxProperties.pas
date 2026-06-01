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
unit JsonFlow.ValidationRules.MaxProperties;

interface

uses
  System.SysUtils, System.Classes,
  JsonFlow.Interfaces, JsonFlow.ValidationEngine,
  JsonFlow.ValidationRules.Base;

type
  // Regra de validação de número máximo de propriedades em objeto
  TMaxPropertiesRule = class(TBaseValidationRule)
  private
    FMaxProperties: Integer;
  public
    constructor Create(AMaxProperties: Integer);
    function Validate(const AValue: IJSONElement; const AContext: TObject): TValidationResult; override;
  end;

implementation

{ TMaxPropertiesRule }

constructor TMaxPropertiesRule.Create(AMaxProperties: Integer);
begin
  inherited Create('maxProperties');
  FMaxProperties := AMaxProperties;
end;

function TMaxPropertiesRule.Validate(const AValue: IJSONElement; const AContext: TObject): TValidationResult;
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
      'Value must be an object for maxProperties validation',
      'non-object',
      'object',
      'maxProperties',
      LValidationContext.GetFullSchemaPath + '/maxProperties'
    );
    Result := TValidationResult.Failure(LValidationContext.GetFullPath, [LError]);
    Exit;
  end;

  LPropertyCount := LObject.Count;
  
  if LPropertyCount <= FMaxProperties then
    Result := TValidationResult.Success(LValidationContext.GetFullPath)
  else
  begin
    LError := CreateValidationError(
      LValidationContext.GetFullPath,
      Format('Object has %d properties, maximum allowed is %d', [LPropertyCount, FMaxProperties]),
      IntToStr(LPropertyCount),
      IntToStr(FMaxProperties),
      'maxProperties',
      LValidationContext.GetFullSchemaPath + '/maxProperties'
    );
    Result := TValidationResult.Failure(LValidationContext.GetFullPath, [LError]);
  end;
end;

end.

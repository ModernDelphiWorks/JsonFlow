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
unit JsonFlow.ValidationRules.MaxItems;

interface

uses
  System.SysUtils, System.Classes,
  JsonFlow.Interfaces, JsonFlow.ValidationEngine,
  JsonFlow.ValidationRules.Base;

type
  // Regra de validação de número máximo de itens em array
  TMaxItemsRule = class(TBaseValidationRule)
  private
    FMaxItems: Integer;
  public
    constructor Create(AMaxItems: Integer);
    function Validate(const AValue: IJSONElement; const AContext: TObject): TValidationResult; override;
  end;

implementation

{ TMaxItemsRule }

constructor TMaxItemsRule.Create(AMaxItems: Integer);
begin
  inherited Create('maxItems');
  FMaxItems := AMaxItems;
end;

function TMaxItemsRule.Validate(const AValue: IJSONElement; const AContext: TObject): TValidationResult;
var
  LArray: IJSONArray;
  LError: TValidationError;
  LValidationContext: TValidationContext;
  LItemCount: Integer;
begin
  LValidationContext := TValidationContext(AContext);
  
  if not Supports(AValue, IJSONArray, LArray) then
  begin
    LError := CreateValidationError(
      LValidationContext.GetFullPath,
      'Value must be an array for maxItems validation',
      'non-array',
      'array',
      'maxItems',
      LValidationContext.GetFullSchemaPath + '/maxItems'
    );
    Result := TValidationResult.Failure(LValidationContext.GetFullPath, [LError]);
    Exit;
  end;

  LItemCount := LArray.Count;
  
  if LItemCount <= FMaxItems then
    Result := TValidationResult.Success(LValidationContext.GetFullPath)
  else
  begin
    LError := CreateValidationError(
      LValidationContext.GetFullPath,
      Format('Array has %d items, maximum allowed is %d', [LItemCount, FMaxItems]),
      IntToStr(LItemCount),
      IntToStr(FMaxItems),
      'maxItems',
      LValidationContext.GetFullSchemaPath + '/maxItems'
    );
    Result := TValidationResult.Failure(LValidationContext.GetFullPath, [LError]);
  end;
end;

end.

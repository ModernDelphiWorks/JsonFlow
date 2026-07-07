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
unit JsonFlow.ValidationRules.UniqueItems;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  JsonFlow.Interfaces, JsonFlow.ValidationEngine,
  JsonFlow.ValidationRules.Base;

type
  // Regra de validação de itens únicos em array
  TUniqueItemsRule = class(TBaseValidationRule)
  private
    FRequireUnique: Boolean;
    function ElementToString(const AElement: IJSONElement): string;
  public
    constructor Create(ARequireUnique: Boolean);
    function Validate(const AValue: IJSONElement; const AContext: TObject): TValidationResult; override;
  end;

implementation

{ TUniqueItemsRule }

constructor TUniqueItemsRule.Create(ARequireUnique: Boolean);
begin
  inherited Create('uniqueItems');
  FRequireUnique := ARequireUnique;
end;

function TUniqueItemsRule.ElementToString(const AElement: IJSONElement): string;
var
  LValue: IJSONValue;
  LArray: IJSONArray;
  LObject: IJSONObject;
begin
  if Supports(AElement, IJSONValue, LValue) then
  begin
    if LValue.IsString then
      Result := '"' + LValue.AsString + '"'
    else if LValue.IsInteger then
      Result := IntToStr(LValue.AsInteger)
    else if LValue.IsFloat then
      Result := FloatToStr(LValue.AsFloat)
    else if LValue.IsBoolean then
      Result := BoolToStr(LValue.AsBoolean, True)
    else if LValue.IsNull then
      Result := 'null'
    else
      Result := 'unknown';
  end
  // Serialização compacta real: os placeholders '[array]'/'{object}' faziam
  // QUALQUER par de arrays/objetos distintos contar como duplicado.
  else if Supports(AElement, IJSONArray, LArray) then
    Result := LArray.AsJSON(False)
  else if Supports(AElement, IJSONObject, LObject) then
    Result := LObject.AsJSON(False)
  else
    Result := 'unknown';
end;

function TUniqueItemsRule.Validate(const AValue: IJSONElement; const AContext: TObject): TValidationResult;
var
  LArray: IJSONArray;
  LError: TValidationError;
  LValidationContext: TValidationContext;
  LAllErrors: TList<TValidationError>;
  LHasErrors: Boolean;
  I, J: Integer;
begin
  LValidationContext := TValidationContext(AContext);
  
  if not Supports(AValue, IJSONArray, LArray) then
  begin
    LError := CreateValidationError(
      LValidationContext.GetFullPath,
      'Value must be an array for uniqueItems validation',
      'non-array',
      'array',
      'uniqueItems',
      LValidationContext.GetFullSchemaPath + '/uniqueItems'
    );
    Result := TValidationResult.Failure(LValidationContext.GetFullPath, [LError]);
    Exit;
  end;

  // Se uniqueItems é false, não há necessidade de validação
  if not FRequireUnique then
  begin
    Result := TValidationResult.Success(LValidationContext.GetFullPath);
    Exit;
  end;

  LAllErrors := TList<TValidationError>.Create;
  try
    LHasErrors := False;

    // O(n) com hash da forma canônica de cada item — antes era loop duplo
    // O(n²) com 2 serializações por PAR comparado.
    var LSeen := TDictionary<string, Integer>.Create(LArray.Count * 2);
    try
      for J := 0 to LArray.Count - 1 do
      begin
        var LKey := ElementToString(LArray.GetItem(J));
        if LSeen.TryGetValue(LKey, I) then
        begin
          LHasErrors := True;
          LError := CreateValidationError(
            LValidationContext.GetFullPath + '/' + IntToStr(J),
            Format('Duplicate item found at index %d (same as index %d)', [J, I]),
            LKey,
            'unique value',
            'uniqueItems',
            LValidationContext.GetFullSchemaPath + '/uniqueItems'
          );
          LAllErrors.Add(LError);
        end
        else
          LSeen.Add(LKey, J);
      end;
    finally
      LSeen.Free;
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

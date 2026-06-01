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

{$include ../../../JsonFlow.inc}
unit JsonFlow.FormatValidators.Base;

interface

uses
  System.SysUtils,
  JsonFlow.FormatRegistry;

type
  // Classe base para validadores de formato individuais
  TBaseFormatValidatorPlugin = class(TInterfacedObject, IFormatValidator)
  private
    FFormatName: string;
    FDefaultErrorMessage: string;
  protected
    // Método abstrato que deve ser implementado pelas classes filhas
    function DoValidate(const AValue: string): Boolean; virtual; abstract;
    // Método que pode ser sobrescrito para mensagens de erro customizadas
    function GetCustomErrorMessage(const AValue: string): string; virtual;
  public
    constructor Create(const AFormatName, ADefaultErrorMessage: string);
    
    // Implementação da interface IFormatValidator
    function GetFormatName: string;
    function Validate(const AValue: string): Boolean;
    function GetErrorMessage(const AValue: string): string;
    function GetDefaultErrorMessage: string;
  end;

implementation

{ TBaseFormatValidatorPlugin }

constructor TBaseFormatValidatorPlugin.Create(const AFormatName, ADefaultErrorMessage: string);
begin
  inherited Create;
  FFormatName := AFormatName;
  FDefaultErrorMessage := ADefaultErrorMessage;
end;

function TBaseFormatValidatorPlugin.GetFormatName: string;
begin
  Result := FFormatName;
end;

function TBaseFormatValidatorPlugin.Validate(const AValue: string): Boolean;
begin
  Result := DoValidate(AValue);
end;

function TBaseFormatValidatorPlugin.GetErrorMessage(const AValue: string): string;
begin
  Result := GetCustomErrorMessage(AValue);
  if Result.IsEmpty then
    Result := GetDefaultErrorMessage;
end;

function TBaseFormatValidatorPlugin.GetDefaultErrorMessage: string;
begin
  Result := FDefaultErrorMessage;
end;

function TBaseFormatValidatorPlugin.GetCustomErrorMessage(const AValue: string): string;
begin
  // Implementação padrão retorna string vazia
  // Classes filhas podem sobrescrever para mensagens customizadas
  Result := '';
end;

end.

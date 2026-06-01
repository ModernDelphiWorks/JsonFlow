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
unit JsonFlow.FormatValidators.Ipv4;

interface

uses
  System.SysUtils,
  System.RegularExpressions,
  JsonFlow.FormatValidators.Base;

type
  TIpv4FormatValidator = class(TBaseFormatValidatorPlugin)
  protected
    function DoValidate(const AValue: string): Boolean; override;
    function GetCustomErrorMessage(const AValue: string): string; override;
  public
    constructor Create;
  end;

  // Função para registrar o validador
  procedure RegisterIpv4Validator;

implementation

uses
  JsonFlow.FormatRegistry;

{ TIpv4FormatValidator }

constructor TIpv4FormatValidator.Create;
begin
  inherited Create('ipv4', 'String does not match IPv4 format');
end;

function TIpv4FormatValidator.DoValidate(const AValue: string): Boolean;
var
  LParts: TArray<string>;
  LPart: string;
  LValue: Integer;
begin
  if AValue.IsEmpty then
  begin
    Result := False;
    Exit;
  end;
  
  // Divide por pontos
  LParts := AValue.Split(['.']);
  
  // Deve ter exatamente 4 partes
  if Length(LParts) <> 4 then
  begin
    Result := False;
    Exit;
  end;
  
  // Valida cada parte
  for LPart in LParts do
  begin
    // Não pode estar vazio
    if LPart.IsEmpty then
    begin
      Result := False;
      Exit;
    end;
    
    // Não pode ter zeros à esquerda (exceto "0")
    if (Length(LPart) > 1) and (LPart[1] = '0') then
    begin
      Result := False;
      Exit;
    end;
    
    // Deve ser um número válido
    if not TryStrToInt(LPart, LValue) then
    begin
      Result := False;
      Exit;
    end;
    
    // Deve estar no range 0-255
    if (LValue < 0) or (LValue > 255) then
    begin
      Result := False;
      Exit;
    end;
  end;
  
  Result := True;
end;

function TIpv4FormatValidator.GetCustomErrorMessage(const AValue: string): string;
var
  LParts: TArray<string>;
  LPart: string;
  LValue: Integer;
  I: Integer;
begin
  if AValue.IsEmpty then
    Result := 'IPv4 address cannot be empty'
  else
  begin
    LParts := AValue.Split(['.']);
    
    if Length(LParts) <> 4 then
      Result := Format('IPv4 address "%s" must have exactly 4 parts separated by dots', [AValue])
    else
    begin
      for I := 0 to High(LParts) do
      begin
        LPart := LParts[I];
        
        if LPart.IsEmpty then
        begin
          Result := Format('IPv4 address "%s" has empty part at position %d', [AValue, I + 1]);
          Exit;
        end;
        
        if (Length(LPart) > 1) and (LPart[1] = '0') then
        begin
          Result := Format('IPv4 address "%s" has leading zero in part "%s"', [AValue, LPart]);
          Exit;
        end;
        
        if not TryStrToInt(LPart, LValue) then
        begin
          Result := Format('IPv4 address "%s" has non-numeric part "%s"', [AValue, LPart]);
          Exit;
        end;
        
        if (LValue < 0) or (LValue > 255) then
        begin
          Result := Format('IPv4 address "%s" has invalid value %d (must be 0-255)', [AValue, LValue]);
          Exit;
        end;
      end;
      
      Result := Format('IPv4 address "%s" is invalid', [AValue]);
    end;
  end;
end;

// Função para registrar o validador
procedure RegisterIpv4Validator;
begin
  TFormatRegistry.RegisterValidator('ipv4', TIpv4FormatValidator.Create);
end;

end.

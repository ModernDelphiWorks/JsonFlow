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
unit JsonFlow.FormatValidators.Ipv6;

interface

uses
  System.SysUtils,
  System.RegularExpressions,
  JsonFlow.FormatValidators.Base;

type
  TIpv6FormatValidator = class(TBaseFormatValidatorPlugin)
  protected
    function DoValidate(const AValue: string): Boolean; override;
    function GetCustomErrorMessage(const AValue: string): string; override;
  private
    function IsValidIpv6Part(const APart: string): Boolean;
  public
    constructor Create;
  end;

  // Função para registrar o validador
  procedure RegisterIpv6Validator;

implementation

uses
  JsonFlow.FormatRegistry;

{ TIpv6FormatValidator }

constructor TIpv6FormatValidator.Create;
begin
  inherited Create('ipv6', 'String does not match IPv6 format');
end;

function TIpv6FormatValidator.IsValidIpv6Part(const APart: string): Boolean;
var
  LRegex: TRegEx;
begin
  if APart.IsEmpty then
  begin
    Result := True; // Partes vazias são válidas em IPv6 (::)
    Exit;
  end;
  
  // Deve ter 1-4 caracteres hexadecimais
  if (Length(APart) < 1) or (Length(APart) > 4) then
  begin
    Result := False;
    Exit;
  end;
  
  LRegex := TRegEx.Create('^[0-9a-fA-F]+$');
  Result := LRegex.IsMatch(APart);
end;

function TIpv6FormatValidator.DoValidate(const AValue: string): Boolean;
var
  LParts: TArray<string>;
  LPart: string;
  LDoubleColonCount: Integer;
  LNonEmptyParts: Integer;
begin
  if AValue.IsEmpty then
  begin
    Result := False;
    Exit;
  end;
  
  // Conta quantos "::" existem (máximo 1 permitido)
  LDoubleColonCount := 0;
  if AValue.Contains('::') then
  begin
    LDoubleColonCount := AValue.CountChar(':') - AValue.Replace('::', ':').CountChar(':') + 1;
    if LDoubleColonCount > 1 then
    begin
      Result := False;
      Exit;
    end;
  end;
  
  // Divide por dois pontos
  LParts := AValue.Split([':']);
  
  // Valida número de partes
  if AValue.Contains('::') then
  begin
    // Com ::, pode ter menos de 8 partes
    if Length(LParts) > 8 then
    begin
      Result := False;
      Exit;
    end;
  end
  else
  begin
    // Sem ::, deve ter exatamente 8 partes
    if Length(LParts) <> 8 then
    begin
      Result := False;
      Exit;
    end;
  end;
  
  // Conta partes não vazias
  LNonEmptyParts := 0;
  for LPart in LParts do
  begin
    if not LPart.IsEmpty then
      Inc(LNonEmptyParts);
      
    if not IsValidIpv6Part(LPart) then
    begin
      Result := False;
      Exit;
    end;
  end;
  
  // Se tem ::, o total de partes não vazias deve ser menor que 8
  if AValue.Contains('::') and (LNonEmptyParts >= 8) then
  begin
    Result := False;
    Exit;
  end;
  
  Result := True;
end;

function TIpv6FormatValidator.GetCustomErrorMessage(const AValue: string): string;
var
  LParts: TArray<string>;
  LPart: string;
  LDoubleColonCount: Integer;
  I: Integer;
begin
  if AValue.IsEmpty then
    Result := 'IPv6 address cannot be empty'
  else
  begin
    // Verifica múltiplos ::
    LDoubleColonCount := 0;
    if AValue.Contains('::') then
    begin
      LDoubleColonCount := AValue.CountChar(':') - AValue.Replace('::', ':').CountChar(':') + 1;
      if LDoubleColonCount > 1 then
      begin
        Result := Format('IPv6 address "%s" cannot contain multiple "::"', [AValue]);
        Exit;
      end;
    end;
    
    LParts := AValue.Split([':']);
    
    // Verifica número de partes
    if not AValue.Contains('::') and (Length(LParts) <> 8) then
    begin
      Result := Format('IPv6 address "%s" must have exactly 8 parts when not using "::"', [AValue]);
      Exit;
    end;
    
    if Length(LParts) > 8 then
    begin
      Result := Format('IPv6 address "%s" has too many parts', [AValue]);
      Exit;
    end;
    
    // Verifica cada parte
    for I := 0 to High(LParts) do
    begin
      LPart := LParts[I];
      
      if not LPart.IsEmpty then
      begin
        if (Length(LPart) < 1) or (Length(LPart) > 4) then
        begin
          Result := Format('IPv6 address "%s" has invalid part "%s" (must be 1-4 hex digits)', [AValue, LPart]);
          Exit;
        end;
        
        if not IsValidIpv6Part(LPart) then
        begin
          Result := Format('IPv6 address "%s" has invalid hexadecimal part "%s"', [AValue, LPart]);
          Exit;
        end;
      end;
    end;
    
    Result := Format('IPv6 address "%s" is invalid', [AValue]);
  end;
end;

// Função para registrar o validador
procedure RegisterIpv6Validator;
begin
  TFormatRegistry.RegisterValidator('ipv6', TIpv6FormatValidator.Create);
end;

end.

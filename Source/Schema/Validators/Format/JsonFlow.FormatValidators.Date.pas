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

{$include ../../../JsonFlow.inc}
unit JsonFlow.FormatValidators.Date;

interface

uses
  System.SysUtils,
  System.RegularExpressions,
  JsonFlow.FormatValidators.Base;

type
  TDateFormatValidator = class(TBaseFormatValidatorPlugin)
  protected
    function DoValidate(const AValue: string): Boolean; override;
    function GetCustomErrorMessage(const AValue: string): string; override;
  public
    constructor Create;
  end;

  // Função para registrar o validador
  procedure RegisterDateValidator;

implementation

uses
  JsonFlow.FormatRegistry;

var
  // Regexes compiladas UMA vez no load da unit (antes: TRegEx.Create
  // por valor validado dentro do DoValidate)
  GRegex1: TRegEx;

{ TDateFormatValidator }

constructor TDateFormatValidator.Create;
begin
  inherited Create('date', 'String does not match date format (YYYY-MM-DD)');
end;

function TDateFormatValidator.DoValidate(const AValue: string): Boolean;
var
  LRegex: TRegEx;
  LYear, LMonth, LDay: Integer;
  LDate: TDateTime;
begin
  if AValue.IsEmpty then
  begin
    Result := False;
    Exit;
  end;
  
  // Primeiro verifica o formato YYYY-MM-DD
  LRegex := GRegex1;
  if not LRegex.IsMatch(AValue) then
  begin
    Result := False;
    Exit;
  end;
  
  // Extrai e valida os componentes da data
  try
    LYear := StrToInt(Copy(AValue, 1, 4));
    LMonth := StrToInt(Copy(AValue, 6, 2));
    LDay := StrToInt(Copy(AValue, 9, 2));
    
    // Valida os ranges
    if (LMonth < 1) or (LMonth > 12) then
    begin
      Result := False;
      Exit;
    end;
    
    if (LDay < 1) or (LDay > 31) then
    begin
      Result := False;
      Exit;
    end;
    
    // Valida se a data é realmente válida (considera anos bissextos, etc.)
    Result := TryEncodeDate(LYear, LMonth, LDay, LDate);
  except
    Result := False;
  end;
end;

function TDateFormatValidator.GetCustomErrorMessage(const AValue: string): string;
var
  LRegex: TRegEx;
  LYear, LMonth, LDay: Integer;
begin
  if AValue.IsEmpty then
    Result := 'Date cannot be empty'
  else
  begin
    LRegex := GRegex1;
    if not LRegex.IsMatch(AValue) then
      Result := Format('String "%s" does not match date format YYYY-MM-DD', [AValue])
    else
    begin
      try
        LYear := StrToInt(Copy(AValue, 1, 4));
        LMonth := StrToInt(Copy(AValue, 6, 2));
        LDay := StrToInt(Copy(AValue, 9, 2));
        
        if (LMonth < 1) or (LMonth > 12) then
          Result := Format('Invalid month %d in date "%s"', [LMonth, AValue])
        else if (LDay < 1) or (LDay > 31) then
          Result := Format('Invalid day %d in date "%s"', [LDay, AValue])
        else
          Result := Format('Date "%s" is not a valid calendar date', [AValue]);
      except
        Result := Format('String "%s" contains invalid numeric components', [AValue]);
      end;
    end;
  end;
end;

// Função para registrar o validador
procedure RegisterDateValidator;
begin
  TFormatRegistry.RegisterValidator('date', TDateFormatValidator.Create);
end;

initialization
  GRegex1 := TRegEx.Create('^\d{4}-\d{2}-\d{2}$');

end.

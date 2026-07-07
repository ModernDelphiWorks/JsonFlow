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
unit JsonFlow.FormatValidators.Time;

interface

uses
  System.SysUtils,
  System.RegularExpressions,
  JsonFlow.FormatValidators.Base;

type
  TTimeFormatValidator = class(TBaseFormatValidatorPlugin)
  protected
    function DoValidate(const AValue: string): Boolean; override;
    function GetCustomErrorMessage(const AValue: string): string; override;
  public
    constructor Create;
  end;

  // Função para registrar o validador
  procedure RegisterTimeValidator;

implementation

uses
  JsonFlow.FormatRegistry;

var
  // Regexes compiladas UMA vez no load da unit (antes: TRegEx.Create
  // por valor validado dentro do DoValidate)
  GRegex1: TRegEx;

{ TTimeFormatValidator }

constructor TTimeFormatValidator.Create;
begin
  inherited Create('time', 'String does not match time format (HH:MM:SS or HH:MM:SS.sss)');
end;

function TTimeFormatValidator.DoValidate(const AValue: string): Boolean;
var
  LRegex: TRegEx;
  LHour, LMinute, LSecond: Integer;
  LTime: TDateTime;
  LTimePart: string;
begin
  if AValue.IsEmpty then
  begin
    Result := False;
    Exit;
  end;
  
  // Primeiro verifica o formato HH:MM:SS ou HH:MM:SS.sss
  LRegex := GRegex1;
  if not LRegex.IsMatch(AValue) then
  begin
    Result := False;
    Exit;
  end;
  
  // Extrai a parte do tempo (sem os milissegundos)
  if AValue.Contains('.') then
    LTimePart := Copy(AValue, 1, 8) // HH:MM:SS
  else
    LTimePart := AValue;
  
  // Extrai e valida os componentes do tempo
  try
    LHour := StrToInt(Copy(LTimePart, 1, 2));
    LMinute := StrToInt(Copy(LTimePart, 4, 2));
    LSecond := StrToInt(Copy(LTimePart, 7, 2));
    
    // Valida os ranges
    if (LHour < 0) or (LHour > 23) then
    begin
      Result := False;
      Exit;
    end;
    
    if (LMinute < 0) or (LMinute > 59) then
    begin
      Result := False;
      Exit;
    end;
    
    if (LSecond < 0) or (LSecond > 59) then
    begin
      Result := False;
      Exit;
    end;
    
    // Valida se o tempo é realmente válido
    Result := TryEncodeTime(LHour, LMinute, LSecond, 0, LTime);
  except
    Result := False;
  end;
end;

function TTimeFormatValidator.GetCustomErrorMessage(const AValue: string): string;
var
  LRegex: TRegEx;
  LHour, LMinute, LSecond: Integer;
  LTimePart: string;
begin
  if AValue.IsEmpty then
    Result := 'Time cannot be empty'
  else
  begin
    LRegex := GRegex1;
    if not LRegex.IsMatch(AValue) then
      Result := Format('String "%s" does not match time format HH:MM:SS or HH:MM:SS.sss', [AValue])
    else
    begin
      try
        // Extrai a parte do tempo (sem os milissegundos)
        if AValue.Contains('.') then
          LTimePart := Copy(AValue, 1, 8)
        else
          LTimePart := AValue;
          
        LHour := StrToInt(Copy(LTimePart, 1, 2));
        LMinute := StrToInt(Copy(LTimePart, 4, 2));
        LSecond := StrToInt(Copy(LTimePart, 7, 2));
        
        if (LHour < 0) or (LHour > 23) then
          Result := Format('Invalid hour %d in time "%s" (must be 00-23)', [LHour, AValue])
        else if (LMinute < 0) or (LMinute > 59) then
          Result := Format('Invalid minute %d in time "%s" (must be 00-59)', [LMinute, AValue])
        else if (LSecond < 0) or (LSecond > 59) then
          Result := Format('Invalid second %d in time "%s" (must be 00-59)', [LSecond, AValue])
        else
          Result := Format('Time "%s" is not valid', [AValue]);
      except
        Result := Format('String "%s" contains invalid numeric components', [AValue]);
      end;
    end;
  end;
end;

// Função para registrar o validador
procedure RegisterTimeValidator;
begin
  TFormatRegistry.RegisterValidator('time', TTimeFormatValidator.Create);
end;

initialization
  GRegex1 := TRegEx.Create('^\d{2}:\d{2}:\d{2}(\.\d{3})?$');

end.

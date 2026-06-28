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

unit JsonFlow.Utils;

interface

uses
  StrUtils,
  DateUtils,
  SysUtils;

function DateTimeToIso8601(const AValue: TDateTime;
  const AUseISO8601DateFormat: Boolean): String;
function Iso8601ToDateTime(const AValue: String;
  const AUseISO8601DateFormat: Boolean): TDateTime;

var
  GJsonFlowFormatSettings: TFormatSettings;

implementation

function DateTimeToIso8601(const AValue: TDateTime;
  const AUseISO8601DateFormat: Boolean): String;
var
  LDatePart: String;
  LTimePart: String;
begin
  Result := '';
  if AValue = 0 then
    Exit;

  if AUseISO8601DateFormat then
    LDatePart := FormatDateTime('yyyy-mm-dd', AValue)
  else
    LDatePart := DateToStr(AValue, GJsonFlowFormatSettings);

  if Frac(AValue) = 0 then
    Result := ifThen(AUseISO8601DateFormat, LDatePart, DateToStr(AValue, GJsonFlowFormatSettings))
  else
  begin
    LTimePart := FormatDateTime('hh:nn:ss', AValue);
    Result := ifThen(AUseISO8601DateFormat, LDatePart + 'T' + LTimePart, LDatePart + ' ' + LTimePart);
  end;
end;

function Iso8601ToDateTime(const AValue: String;
  const AUseISO8601DateFormat: Boolean): TDateTime;
var
  LYYYY: Integer;
  LMM: Integer;
  LDD: Integer;
  LHH: Integer;
  LMI: Integer;
  LSS: Integer;
  LMS: Integer;
begin
  if not AUseISO8601DateFormat then
  begin
    Result := StrToDateTimeDef(AValue, 0);
    Exit;
  end;
  LYYYY := 0; LMM := 0; LDD := 0; LHH := 0; LMI := 0; LSS := 0; LMS := 0;
  // A DATA (yyyy-mm-dd) e obrigatoria; a parte de HORA e OPCIONAL. Antes a cadeia
  // AND exigia hh:nn:ss e devolvia 0 para uma string so-data, zerando datas de dia
  // inteiro (vencimento/data-cadastro) no round-trip JSON. TryEncodeDateTime guarda
  // valores invalidos (devolve 0 = comportamento anterior). Timestamp completo
  // continua parseando identico (retrocompativel).
  if TryStrToInt(Copy(AValue, 1, 4), LYYYY) and
     TryStrToInt(Copy(AValue, 6, 2), LMM) and
     TryStrToInt(Copy(AValue, 9, 2), LDD) then
  begin
    if Length(AValue) >= 19 then
    begin
      TryStrToInt(Copy(AValue, 12, 2), LHH);
      TryStrToInt(Copy(AValue, 15, 2), LMI);
      TryStrToInt(Copy(AValue, 18, 2), LSS);
    end;
    if not TryEncodeDateTime(LYYYY, LMM, LDD, LHH, LMI, LSS, LMS, Result) then
      Result := 0;
  end
  else
    Result := 0;
end;

initialization
  GJsonFlowFormatSettings := TFormatSettings.Create('en_US');

end.

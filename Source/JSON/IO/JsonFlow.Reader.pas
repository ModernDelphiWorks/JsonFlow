{
  ------------------------------------------------------------------------------
  JsonFlow
  Fluent and expressive JSON manipulation API for Delphi.

  SPDX-License-Identifier: Apache-2.0
  Copyright (c) 2025-2026 Isaque Pinheiro

  Licensed under the Apache License, Version 2.0.
  See the LICENSE file in the project root for full license information.
  ------------------------------------------------------------------------------
}

{$include ../../JsonFlow.inc}

unit JsonFlow.Reader;

interface

uses
  System.Classes,
  System.SysUtils,
  System.DateUtils,
  System.RegularExpressions,
  JsonFlow.Interfaces,
  JsonFlow.Value,
  JsonFlow.Objects,
  JsonFlow.Arrays;

type
  TJSONReader = class(TInterfacedObject, IJSONReader)
  private
    FLogProc: TProc<String>;
    FFormatSettings: TFormatSettings;
    FBuffer: TCharArray;
    FBufferSize: Integer;
    FBufferPos: Integer;
    FBufferEnd: Integer;
    FStream: TStream;
    FProgressProc: TProc<TObject, Single>;
    procedure _Log(const AMessage: string);
    procedure _SkipWhitespace(const AJson: PChar; var AIndex: Integer; ALength: Integer); overload;
    procedure _SkipWhitespace(var AChar: Char; AStream: TStream); overload;
    function _ParseValue(const AJson: PChar; var AIndex: Integer; ALength: Integer): IJSONElement; overload;
    function _ParseValue(var AChar: Char; AStream: TStream): IJSONElement; overload;
    function _ParseObject(const AJson: PChar; var AIndex: Integer; ALength: Integer): IJSONObject; overload;
    function _ParseObject(var AChar: Char; AStream: TStream): IJSONObject; overload;
    function _ParseArray(const AJson: PChar; var AIndex: Integer; ALength: Integer): IJSONArray; overload;
    function _ParseArray(var AChar: Char; AStream: TStream): IJSONArray; overload;
    function _ParseString(const AJson: PChar; var AIndex: Integer; ALength: Integer): String; overload;
    function _ParseString(var AChar: Char; AStream: TStream): String; overload;
    function _ParseNumber(const AJson: PChar; var AIndex: Integer; ALength: Integer): IJSONElement; overload;
    function _ParseNumber(var AChar: Char; AStream: TStream): IJSONElement; overload;
    function _ReadChar(AStream: TStream; var AChar: Char): Boolean;
  public
    constructor Create; overload;
    constructor Create(const ABufferSize: Integer); overload;
    constructor Create(const AFormatSettings: TFormatSettings); overload;
    constructor Create(const AFormatSettings: TFormatSettings; const ABufferSize: Integer); overload;
    function Read(const AJson: String): IJSONElement;
    function ReadFromStream(AStream: TStream): IJSONElement;
    procedure OnLog(const ALogProc: TProc<String>);
    procedure OnProgress(const AProgress: TProc<TObject, Single>);
    property BufferSize: Integer read FBufferSize write FBufferSize;
  end;

implementation

{ TJSONReader }

constructor TJSONReader.Create;
begin
  FFormatSettings := TFormatSettings.Create('en_US');
  FFormatSettings.DecimalSeparator := '.';
  FBufferSize := 65536;
  SetLength(FBuffer, FBufferSize);
end;

constructor TJSONReader.Create(const ABufferSize: Integer);
begin
  Create;
  if ABufferSize <= 0 then
    Exit;
  if ABufferSize < 4096 then
  begin
    FBufferSize := 4096;
    SetLength(FBuffer, FBufferSize);
  end
  else
  begin
    FBufferSize := ABufferSize;
    SetLength(FBuffer, FBufferSize);
  end;
end;

constructor TJSONReader.Create(const AFormatSettings: TFormatSettings);
begin
  Create;
  FFormatSettings := AFormatSettings;
end;

constructor TJSONReader.Create(const AFormatSettings: TFormatSettings; const ABufferSize: Integer);
begin
  Create(AFormatSettings);
  if ABufferSize > 0 then
  begin
    FBufferSize := ABufferSize;
    SetLength(FBuffer, FBufferSize);
  end;
end;

procedure TJSONReader.OnLog(const ALogProc: TProc<String>);
begin
  FLogProc := ALogProc;
end;

procedure TJSONReader.OnProgress(const AProgress: TProc<TObject, Single>);
begin
  FProgressProc := AProgress;
end;

function TJSONReader._ReadChar(AStream: TStream; var AChar: Char): Boolean;
var
  LProgress: Single;
begin
  if FBufferPos >= FBufferEnd then
  begin
    FBufferEnd := AStream.Read(FBuffer[0], FBufferSize * SizeOf(Char));
    FBufferPos := 0;
    if FBufferEnd = 0 then
    begin
      Result := False;
      Exit;
    end;
    _Log('Read ' + IntToStr(FBufferEnd) + ' bytes into buffer (size: ' + IntToStr(FBufferSize) + ')');
    if Assigned(FProgressProc) and (AStream.Size > 0) then
    begin
      LProgress := (AStream.Position / AStream.Size) * 100;
      FProgressProc(Self, LProgress);
    end;
  end;
  AChar := FBuffer[FBufferPos];
  Inc(FBufferPos);
  Result := True;
end;

procedure TJSONReader._SkipWhitespace(const AJson: PChar; var AIndex: Integer; ALength: Integer);
begin
  while (AIndex < ALength) and CharInSet(AJson[AIndex], [#9, #10, #13, #32]) do
    Inc(AIndex);
end;

procedure TJSONReader._SkipWhitespace(var AChar: Char; AStream: TStream);
begin
  while CharInSet(AChar, [#9, #10, #13, #32]) and _ReadChar(AStream, AChar) do;
end;

function TJSONReader._ParseString(const AJson: PChar; var AIndex: Integer; ALength: Integer): String;
var
  LBuilder: TStringBuilder;
  LChar: Char;
begin
  LBuilder := TStringBuilder.Create;
  try
    Inc(AIndex); // Pula a aspa inicial
    while (AIndex < ALength) and (AJson[AIndex] <> '"') do
    begin
      LChar := AJson[AIndex];
      if LChar = '\' then
      begin
        Inc(AIndex);
        if AIndex >= ALength then
          raise EInvalidOperation.Create('Unexpected end of JSON string');
        case AJson[AIndex] of
          '"', '\', '/': LBuilder.Append(AJson[AIndex]);
          'b': LBuilder.Append(#8);
          'f': LBuilder.Append(#12);
          'n': LBuilder.Append(#10);
          'r': LBuilder.Append(#13);
          't': LBuilder.Append(#9);
          'u': begin
                 Inc(AIndex);
                 if AIndex + 3 < ALength then
                   LBuilder.Append(Char(StrToInt('$'+Copy(AJson+AIndex, 0, 4))))
                 else
                   raise EInvalidOperation.Create('Invalid unicode escape');
                 Inc(AIndex, 3);
               end;
          else
            raise EInvalidOperation.Create('Invalid escape sequence');
        end;
      end
      else
        LBuilder.Append(LChar);
      Inc(AIndex);
    end;
    if AIndex >= ALength then
      raise EInvalidOperation.Create('Unterminated string');
    Inc(AIndex); // Pula a aspa final
    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

function TJSONReader._ParseString(var AChar: Char; AStream: TStream): String;
var
  LBuilder: TStringBuilder;
begin
  LBuilder := TStringBuilder.Create;
  try
    while _ReadChar(AStream, AChar) do
    begin
      if AChar = '"' then
      begin
        Result := LBuilder.ToString;
        Exit;
      end;
      if AChar = '\' then
      begin
        if not _ReadChar(AStream, AChar) then
          raise EInvalidOperation.Create('Unexpected end of JSON string');
        case AChar of
          '"', '\', '/': LBuilder.Append(AChar);
          'b': LBuilder.Append(#8);
          'f': LBuilder.Append(#12);
          'n': LBuilder.Append(#10);
          'r': LBuilder.Append(#13);
          't': LBuilder.Append(#9);
          'u': begin
                 var LUnicode: string := '';
                 for var i := 1 to 4 do
                 begin
                   if not _ReadChar(AStream, AChar) then
                     raise EInvalidOperation.Create('Invalid unicode escape');
                   LUnicode := LUnicode + AChar;
                 end;
                 LBuilder.Append(Char(StrToInt('$'+LUnicode)));
               end;
          else
            raise EInvalidOperation.Create('Invalid escape sequence');
        end;
      end
      else
        LBuilder.Append(AChar);
    end;
    raise EInvalidOperation.Create('Unterminated string');
  finally
    LBuilder.Free;
  end;
end;

function TJSONReader._ParseNumber(const AJson: PChar; var AIndex: Integer; ALength: Integer): IJSONElement;
var
  LStart: Integer;
  LStr: String;
  LIsFloat: Boolean;
begin
  LStart := AIndex;
  LIsFloat := False;
  while (AIndex < ALength) and CharInSet(AJson[AIndex], ['0'..'9', '-', '.', 'e', 'E', '+']) do
  begin
    if CharInSet(AJson[AIndex], ['.', 'e', 'E']) then
      LIsFloat := True;
    Inc(AIndex);
  end;
  LStr := Copy(AJson, LStart + 1, AIndex - LStart);
  if LIsFloat then
    Result := TJSONValueFloat.Create(StrToFloatDef(LStr, 0.0, FFormatSettings))
  else
    Result := TJSONValueInteger.Create(StrToInt64Def(LStr, 0));
end;

function TJSONReader._ParseNumber(var AChar: Char; AStream: TStream): IJSONElement;
var
  LStr: string;
  LIsFloat: Boolean;
begin
  LStr := AChar;
  LIsFloat := False;
  while _ReadChar(AStream, AChar) and CharInSet(AChar, ['0'..'9', '-', '.', 'e', 'E', '+']) do
  begin
    LStr := LStr + AChar;
    if CharInSet(AChar, ['.', 'e', 'E']) then
      LIsFloat := True;
  end;
  if LIsFloat then
    Result := TJSONValueFloat.Create(StrToFloatDef(LStr, 0.0, FFormatSettings))
  else
    Result := TJSONValueInteger.Create(StrToInt64Def(LStr, 0));
end;

function TJSONReader._ParseValue(const AJson: PChar; var AIndex: Integer; ALength: Integer): IJSONElement;
var
  LChar: Char;
  LValue: TJSONValue;
  LString: String;

    function _IsISODateTime_(const S: String): Boolean;
    var
      LYear, LMonth, LDay: Integer;
    begin
      // Checa formato básico: "YYYY-MM-DD" ou "YYYY-MM-DDThh:mm:ss"
      Result := (Length(S) >= 10) and (S[5] = '-') and (S[8] = '-') and
                CharInSet(S[1], ['0'..'9']) and CharInSet(S[2], ['0'..'9']) and
                CharInSet(S[3], ['0'..'9']) and CharInSet(S[4], ['0'..'9']) and
                CharInSet(S[6], ['0'..'1']) and CharInSet(S[7], ['0'..'9']) and
                CharInSet(S[9], ['0'..'3']) and CharInSet(S[10], ['0'..'9']);
      if not Result then
        Exit;

      // Valida ano, mês e dia
      LYear := StrToIntDef(Copy(S, 1, 4), -1);
      LMonth := StrToIntDef(Copy(S, 6, 2), -1);
      LDay := StrToIntDef(Copy(S, 9, 2), -1);
      Result := (LYear >= 0) and (LMonth >= 1) and (LMonth <= 12) and
                (LDay >= 1) and (LDay <= DaysInAMonth(LYear, LMonth));

      // Se tem 'T', valida tempo
      if Result and (Pos('T', S) > 0) and (Length(S) >= 19) then
        Result := CharInSet(S[12], ['0'..'2']) and CharInSet(S[13], ['0'..'9']) and
                  (S[14] = ':') and CharInSet(S[15], ['0'..'5']) and CharInSet(S[16], ['0'..'9']) and
                  (S[17] = ':') and CharInSet(S[18], ['0'..'5']) and CharInSet(S[19], ['0'..'9']);
    end;
begin
  _SkipWhitespace(AJson, AIndex, ALength);
  if AIndex >= ALength then
    raise EInvalidOperation.Create('Unexpected end of JSON');

  LChar := AJson[AIndex];
  case LChar of
    '{': Result := _ParseObject(AJson, AIndex, ALength);
    '[': Result := _ParseArray(AJson, AIndex, ALength);
    '"': begin
           LString := _ParseString(AJson, AIndex, ALength);
           if _IsISODateTime_(LString) then
             LValue := TJSONValueDateTime.Create(LString, True)
           else
             LValue := TJSONValueString.Create(LString);
           Result := LValue;
         end;
    't': begin
           if Copy(AJson + AIndex, 1, 4) = 'true' then
           begin
             LValue := TJSONValueBoolean.Create(True);
             Result := LValue;
             Inc(AIndex, 4);
           end
           else
             raise EInvalidOperation.Create('Invalid JSON value');
         end;
    'f': begin
           if Copy(AJson + AIndex, 1, 5) = 'false' then
           begin
             LValue := TJSONValueBoolean.Create(False);
             Result := LValue;
             Inc(AIndex, 5);
           end
           else
             raise EInvalidOperation.Create('Invalid JSON value');
         end;
    'n': begin
           if Copy(AJson + AIndex, 1, 4) = 'null' then
           begin
             LValue := TJSONValueNull.Create;
             Result := LValue;
             Inc(AIndex, 4);
           end
           else
             raise EInvalidOperation.Create('Invalid JSON value');
         end;
    '0'..'9', '-': Result := _ParseNumber(AJson, AIndex, ALength);
    else
      raise EInvalidOperation.Create('Unexpected character: ' + LChar);
  end;
end;

function TJSONReader._ParseValue(var AChar: Char; AStream: TStream): IJSONElement;
var
  LValue: TJSONValue;
  LString: String;

  function _IsISODateTime_(const S: String): Boolean;
  begin
    Result := (Length(S) >= 10) and (S[5] = '-') and (S[8] = '-') and
              CharInSet(S[1], ['0'..'9']) and CharInSet(S[2], ['0'..'9']) and
              CharInSet(S[3], ['0'..'9']) and CharInSet(S[4], ['0'..'9']);
    if Result and (Pos('T', S) > 0) then
      Result := (Length(S) >= 19) and CharInSet(S[12], ['0'..'2']) and CharInSet(S[15], ['0'..'5']);
  end;

begin
  _SkipWhitespace(AChar, AStream);
  case AChar of
    '{': Result := _ParseObject(AChar, AStream);
    '[': Result := _ParseArray(AChar, AStream);
    '"': begin
           LString := _ParseString(AChar, AStream);
           if _IsISODateTime_(LString) then
             LValue := TJSONValueDateTime.Create(LString, True)
           else
             LValue := TJSONValueString.Create(LString);
           Result := LValue;
           if not _ReadChar(AStream, AChar) then AChar := #0;
         end;
    't': begin
           LValue := TJSONValueBoolean.Create(True);
           Result := LValue;
           for var i := 1 to 3 do if not _ReadChar(AStream, AChar) then
             raise EInvalidOperation.Create('Incomplete true value');
         end;
    'f': begin
           LValue := TJSONValueBoolean.Create(False);
           Result := LValue;
           for var i := 1 to 4 do if not _ReadChar(AStream, AChar) then
             raise EInvalidOperation.Create('Incomplete false value');
         end;
    'n': begin
           LValue := TJSONValueNull.Create;
           Result := LValue;
           for var i := 1 to 3 do if not _ReadChar(AStream, AChar) then
             raise EInvalidOperation.Create('Incomplete null value');
         end;
    '0'..'9', '-': Result := _ParseNumber(AChar, AStream);
    else
      raise EInvalidOperation.Create('Unexpected character: ' + AChar);
  end;
end;

function TJSONReader._ParseObject(const AJson: PChar; var AIndex: Integer; ALength: Integer): IJSONObject;
var
  LKey: String;
begin
  Result := TJSONObject.Create;
  Inc(AIndex); // Pula '{'
  _SkipWhitespace(AJson, AIndex, ALength);

  if (AIndex < ALength) and (AJson[AIndex] = '}') then
  begin
    Inc(AIndex);
    Exit;
  end;

  while AIndex < ALength do
  begin
    _SkipWhitespace(AJson, AIndex, ALength);
    if AJson[AIndex] <> '"' then
      raise EInvalidOperation.Create('Expected string key');
    LKey := _ParseString(AJson, AIndex, ALength);

    _SkipWhitespace(AJson, AIndex, ALength);
    if (AIndex >= ALength) or (AJson[AIndex] <> ':') then
      raise EInvalidOperation.Create('Expected ":" after key');
    Inc(AIndex); // Pula ':'

    Result.Add(LKey, _ParseValue(AJson, AIndex, ALength));

    _SkipWhitespace(AJson, AIndex, ALength);
    if AIndex >= ALength then
      raise EInvalidOperation.Create('Unterminated object');
    if AJson[AIndex] = '}' then
    begin
      Inc(AIndex);
      Break;
    end;
    if AJson[AIndex] <> ',' then
      raise EInvalidOperation.Create('Expected "," or "}"');
    Inc(AIndex); // Pula ','
  end;
end;

function TJSONReader._ParseObject(var AChar: Char; AStream: TStream): IJSONObject;
var
  LKey: String;
begin
  Result := TJSONObject.Create;
  if not _ReadChar(AStream, AChar) then
    raise EInvalidOperation.Create('Unterminated object');
  _SkipWhitespace(AChar, AStream);

  if AChar = '}' then Exit;

  while True do
  begin
    if AChar <> '"' then
      raise EInvalidOperation.Create('Expected string key');
    LKey := _ParseString(AChar, AStream);
    if not _ReadChar(AStream, AChar) then
      raise EInvalidOperation.Create('Expected ":" after key');
    _SkipWhitespace(AChar, AStream);
    if AChar <> ':' then
      raise EInvalidOperation.Create('Expected ":" after key');
    if not _ReadChar(AStream, AChar) then
      raise EInvalidOperation.Create('Unexpected end of JSON');
    Result.Add(LKey, _ParseValue(AChar, AStream));
    _SkipWhitespace(AChar, AStream);
    if AChar = '}' then Break;
    if AChar <> ',' then
      raise EInvalidOperation.Create('Expected "," or "}"');
    if not _ReadChar(AStream, AChar) then
      raise EInvalidOperation.Create('Unterminated object');
  end;
  if not _ReadChar(AStream, AChar) then AChar := #0;
end;

function TJSONReader._ParseArray(const AJson: PChar; var AIndex: Integer; ALength: Integer): IJSONArray;
begin
  Result := TJSONArray.Create;
  Inc(AIndex); // Pula '['
  _SkipWhitespace(AJson, AIndex, ALength);

  if (AIndex < ALength) and (AJson[AIndex] = ']') then
  begin
    Inc(AIndex);
    Exit;
  end;

  while AIndex < ALength do
  begin
    Result.Add(_ParseValue(AJson, AIndex, ALength));

    _SkipWhitespace(AJson, AIndex, ALength);
    if AIndex >= ALength then
      raise EInvalidOperation.Create('Unterminated array');
    if AJson[AIndex] = ']' then
    begin
      Inc(AIndex);
      Break;
    end;
    if AJson[AIndex] <> ',' then
      raise EInvalidOperation.Create('Expected "," or "]"');
    Inc(AIndex); // Pula ','
  end;
end;

function TJSONReader._ParseArray(var AChar: Char; AStream: TStream): IJSONArray;
begin
  Result := TJSONArray.Create;
  if not _ReadChar(AStream, AChar) then
    raise EInvalidOperation.Create('Unterminated array');
  _SkipWhitespace(AChar, AStream);

  if AChar = ']' then Exit;

  while True do
  begin
    Result.Add(_ParseValue(AChar, AStream));
    _SkipWhitespace(AChar, AStream);
    if AChar = ']' then Break;
    if AChar <> ',' then
      raise EInvalidOperation.Create('Expected "," or "]"');
    if not _ReadChar(AStream, AChar) then
      raise EInvalidOperation.Create('Unterminated array');
  end;
  if not _ReadChar(AStream, AChar) then AChar := #0;
end;

function TJSONReader.Read(const AJson: String): IJSONElement;
var
  LIndex: Integer;
begin
  Writeln('Parsing JSON: "', AJson, '"');
  Writeln('Length of JSON: ', Length(AJson));
  if AJson = '' then
    raise EInvalidOperation.Create('Empty JSON string');
  LIndex := 0;
  Result := _ParseValue(PChar(AJson), LIndex, Length(AJson));
  _SkipWhitespace(PChar(AJson), LIndex, Length(AJson));
  if LIndex < Length(AJson) then
    raise EInvalidOperation.Create('Extra characters after JSON');
end;

function TJSONReader.ReadFromStream(AStream: TStream): IJSONElement;
var
  LChar: Char;
begin
  FStream := AStream;
  FBufferPos := 0;
  FBufferEnd := 0;
  if not _ReadChar(AStream, LChar) then
    raise EInvalidOperation.Create('Empty stream');
  _SkipWhitespace(LChar, AStream);
  Result := _ParseValue(LChar, AStream);
end;

procedure TJSONReader._Log(const AMessage: string);
begin
  if Assigned(FLogProc) then
    FLogProc(AMessage);
end;

end.


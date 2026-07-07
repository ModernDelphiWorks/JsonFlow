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
  EJsonFlowParseError = class(Exception);

  TJSONReader = class(TInterfacedObject, IJSONReader)
  private
    FLogProc: TProc<String>;
    FFormatSettings: TFormatSettings;
    FBufferSize: Integer;
    FProgressProc: TProc<TObject, Single>;
    procedure _Log(const AMessage: string);
    procedure _SkipWhitespace(const AJson: PChar; var AIndex: Integer; ALength: Integer);
    function _ParseValue(const AJson: PChar; var AIndex: Integer; ALength: Integer): IJSONElement;
    function _ParseObject(const AJson: PChar; var AIndex: Integer; ALength: Integer): IJSONObject;
    function _ParseArray(const AJson: PChar; var AIndex: Integer; ALength: Integer): IJSONArray;
    function _ParseString(const AJson: PChar; var AIndex: Integer; ALength: Integer): String;
    function _ParseNumber(const AJson: PChar; var AIndex: Integer; ALength: Integer): IJSONElement;
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
end;

constructor TJSONReader.Create(const ABufferSize: Integer);
begin
  Create;
  if ABufferSize <= 0 then
    Exit;
  if ABufferSize < 4096 then
    FBufferSize := 4096
  else
    FBufferSize := ABufferSize;
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
    FBufferSize := ABufferSize;
end;

procedure TJSONReader.OnLog(const ALogProc: TProc<String>);
begin
  FLogProc := ALogProc;
end;

procedure TJSONReader.OnProgress(const AProgress: TProc<TObject, Single>);
begin
  FProgressProc := AProgress;
end;

procedure TJSONReader._SkipWhitespace(const AJson: PChar; var AIndex: Integer; ALength: Integer);
begin
  while (AIndex < ALength) and CharInSet(AJson[AIndex], [#9, #10, #13, #32]) do
    Inc(AIndex);
end;

function TJSONReader._ParseString(const AJson: PChar; var AIndex: Integer; ALength: Integer): String;
var
  LBuilder: TStringBuilder;
  LChar: Char;
  LStart: Integer;
  LScan: Integer;
begin
  // Fast-path: a imensa maioria das strings não tem escape — localiza a aspa
  // final e copia o trecho inteiro com SetString, sem TStringBuilder (que era
  // alocado por string parseada, inclusive para cada CHAVE de objeto).
  LStart := AIndex + 1;
  LScan := LStart;
  while (LScan < ALength) and (AJson[LScan] <> '"') and (AJson[LScan] <> '\') do
    Inc(LScan);
  if LScan >= ALength then
    raise EJsonFlowParseError.Create('Unterminated string');
  if AJson[LScan] = '"' then
  begin
    SetString(Result, AJson + LStart, LScan - LStart);
    AIndex := LScan + 1; // Pula a aspa final
    Exit;
  end;

  // Caminho lento (há escapes): builder com capacidade estimada
  LBuilder := TStringBuilder.Create(LScan - LStart + 32);
  try
    Inc(AIndex); // Pula a aspa inicial
    while (AIndex < ALength) and (AJson[AIndex] <> '"') do
    begin
      LChar := AJson[AIndex];
      if LChar = '\' then
      begin
        Inc(AIndex);
        if AIndex >= ALength then
          raise EJsonFlowParseError.Create('Unexpected end of JSON string');
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
                 begin
                   var LHex: string;
                   SetString(LHex, AJson + AIndex, 4);
                   LBuilder.Append(Char(StrToInt('$' + LHex)));
                 end
                 else
                   raise EJsonFlowParseError.Create('Invalid unicode escape');
                 Inc(AIndex, 3);
               end;
          else
            raise EJsonFlowParseError.Create('Invalid escape sequence');
        end;
      end
      else
        LBuilder.Append(LChar);
      Inc(AIndex);
    end;
    if AIndex >= ALength then
      raise EJsonFlowParseError.Create('Unterminated string');
    Inc(AIndex); // Pula a aspa final
    Result := LBuilder.ToString;
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
  // SetString copia só o trecho do número — Copy(AJson, ...) com PChar
  // convertia o restante inteiro do buffer para String a cada número (O(n²)).
  SetString(LStr, AJson + LStart, AIndex - LStart);
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
    raise EJsonFlowParseError.Create('Unexpected end of JSON');

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
    // StrLComp compara in-place — Copy(AJson + AIndex, ...) com PChar convertia
    // o restante inteiro do buffer para String a cada literal (O(n²)).
    't': begin
           if (AIndex + 3 < ALength) and (StrLComp(AJson + AIndex, 'true', 4) = 0) then
           begin
             LValue := TJSONValueBoolean.Create(True);
             Result := LValue;
             Inc(AIndex, 4);
           end
           else
             raise EJsonFlowParseError.Create('Invalid JSON value');
         end;
    'f': begin
           if (AIndex + 4 < ALength) and (StrLComp(AJson + AIndex, 'false', 5) = 0) then
           begin
             LValue := TJSONValueBoolean.Create(False);
             Result := LValue;
             Inc(AIndex, 5);
           end
           else
             raise EJsonFlowParseError.Create('Invalid JSON value');
         end;
    'n': begin
           if (AIndex + 3 < ALength) and (StrLComp(AJson + AIndex, 'null', 4) = 0) then
           begin
             LValue := TJSONValueNull.Create;
             Result := LValue;
             Inc(AIndex, 4);
           end
           else
             raise EJsonFlowParseError.Create('Invalid JSON value');
         end;
    '0'..'9', '-': Result := _ParseNumber(AJson, AIndex, ALength);
    else
      raise EJsonFlowParseError.Create('Unexpected character: ' + LChar);
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
      raise EJsonFlowParseError.Create('Expected string key');
    LKey := _ParseString(AJson, AIndex, ALength);

    _SkipWhitespace(AJson, AIndex, ALength);
    if (AIndex >= ALength) or (AJson[AIndex] <> ':') then
      raise EJsonFlowParseError.Create('Expected ":" after key');
    Inc(AIndex); // Pula ':'

    Result.Add(LKey, _ParseValue(AJson, AIndex, ALength));

    _SkipWhitespace(AJson, AIndex, ALength);
    if AIndex >= ALength then
      raise EJsonFlowParseError.Create('Unterminated object');
    if AJson[AIndex] = '}' then
    begin
      Inc(AIndex);
      Break;
    end;
    if AJson[AIndex] <> ',' then
      raise EJsonFlowParseError.Create('Expected "," or "}"');
    Inc(AIndex); // Pula ','
  end;
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
      raise EJsonFlowParseError.Create('Unterminated array');
    if AJson[AIndex] = ']' then
    begin
      Inc(AIndex);
      Break;
    end;
    if AJson[AIndex] <> ',' then
      raise EJsonFlowParseError.Create('Expected "," or "]"');
    Inc(AIndex); // Pula ','
  end;
end;

function TJSONReader.Read(const AJson: String): IJSONElement;
var
  LIndex: Integer;
begin
  if AJson = '' then
    raise EJsonFlowParseError.Create('Empty JSON string');
  LIndex := 0;
  Result := _ParseValue(PChar(AJson), LIndex, Length(AJson));
  _SkipWhitespace(PChar(AJson), LIndex, Length(AJson));
  if LIndex < Length(AJson) then
    raise EJsonFlowParseError.Create('Extra characters after JSON');
end;

function TJSONReader.ReadFromStream(AStream: TStream): IJSONElement;
var
  LBytes: TBytes;
  LCount: Int64;
  LEncoding: TEncoding;
  LOffset: Integer;
  LJson: string;
begin
  // O parser de stream anterior tinha dois defeitos fatais: usava o retorno de
  // AStream.Read (BYTES) como índice de CHARS (leitura fora do buffer em
  // documentos > buffer) e assumia UTF-16 cru, enquanto todo SaveToStream do
  // framework grava UTF-8. Agora: lê os bytes, detecta BOM (UTF-8/16/32,
  // default UTF-8) e decodifica antes de delegar ao parser PChar otimizado.
  LCount := AStream.Size - AStream.Position;
  if LCount <= 0 then
    raise EJsonFlowParseError.Create('Empty stream');

  SetLength(LBytes, LCount);
  AStream.ReadBuffer(LBytes[0], LCount);

  LEncoding := nil;
  LOffset := TEncoding.GetBufferEncoding(LBytes, LEncoding, TEncoding.UTF8);
  LJson := LEncoding.GetString(LBytes, LOffset, Length(LBytes) - LOffset);

  if Assigned(FProgressProc) then
    FProgressProc(Self, 100);

  Result := Read(LJson);
end;

procedure TJSONReader._Log(const AMessage: string);
begin
  if Assigned(FLogProc) then
    FLogProc(AMessage);
end;

end.


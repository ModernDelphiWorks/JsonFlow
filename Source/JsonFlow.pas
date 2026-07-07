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

{ @abstract(JsonFlow Framework.)
  @created(23 Nov 2020)
  @author(Isaque Pinheiro <isaquepsp@gmail.com>)
  @author(Telegram : @IsaquePinheiro)
}

unit JsonFlow;

interface

uses
  SysUtils,
  Classes,
  Generics.Collections,
  JsonFlow.Utils,
  JsonFlow.Types,
  JsonFlow.Interfaces,
  JsonFlow.Reader,
  JsonFlow.Writer,
  JsonFlow.Serializer,
  JsonFlow.Builders;

type
  TJsonFlow = class
  strict private
    // Instance state
    FReader: TJSONReader;
    FWriter: TJSONWriter;
    FSerializer: TJSONSerializer;
  strict private
    // Class state
    class var FJsonBuilder: TJsonBuilder;
    class procedure _SetNotifyEventGetValue(const Value: TNotifyEventGetValue); static; inline;
    class procedure _SetNotifyEventSetValue(const Value: TNotifyEventSetValue); static; inline;
    class procedure _SetFormatSettings(const Value: TFormatSettings); static; inline;
    class function _GetFormatSettings: TFormatSettings; static; inline;
  public
    // Instance lifecycle
    constructor Create; overload;
    constructor Create(const AFormatSettings: TFormatSettings); overload;
    destructor Destroy; override;

    // Instance methods — parse / emit
    function Parse(const AJson: string): IJSONElement;
    function ToJson(const AElement: IJSONElement; const AIdent: Boolean = False): string;

    // Instance methods — object serialization
    function FromObject(AObject: TObject; const AStoreClass: Boolean = False): IJSONElement;
    function ToObject(const AElement: IJSONElement; AObject: TObject): Boolean;

    // Instance logging
    procedure OnLog(const ALogProc: TProc<string>);

  public
    // Class lifecycle
    class constructor Create;
    class destructor Destroy;

    // Class methods — object <-> JSON string (delegate to FJsonBuilder)
    class function ObjectToJsonString(AObject: TObject;
      AStoreClassName: Boolean = False): string; inline;
    class function ObjectListToJsonString(AObjectList: TObjectList<TObject>;
      AStoreClassName: Boolean = False): string; overload; inline;
    class function ObjectListToJsonString<T: class, constructor>(AObjectList: TObjectList<T>;
      AStoreClassName: Boolean = False): string; overload; inline;

    // Class methods — JSON string -> object (delegate to FJsonBuilder)
    class function JsonToObject<T: class, constructor>(const AJson: string): T; overload; inline;
    class function JsonToObject<T: class>(const AObject: T;
      const AJson: string): Boolean; overload; inline;
    class procedure JsonToObject(const AJson: string; AObject: TObject); overload; inline;
    class function JsonToObjectList<T: class, constructor>(const AJson: string): TObjectList<T>; overload; inline;
    class function JsonToObjectList(const AJson: string; const AType: TClass): TObjectList<TObject>; overload; inline;

    // Middleware management
    class procedure AddMiddleware(const AEventMiddleware: IEventMiddleware);
    class procedure ClearMiddlewares;

    // Deprecated notify events — kept for source compatibility, delegate to FJsonBuilder
    {$MESSAGE WARN 'This property [OnSetValue] has been deprecated. Use middlewares instead.'}
    class property OnSetValue: TNotifyEventSetValue write _SetNotifyEventSetValue;
    {$MESSAGE WARN 'This property [OnGetValue] has been deprecated. Use middlewares instead.'}
    class property OnGetValue: TNotifyEventGetValue write _SetNotifyEventGetValue;

    // Global format settings
    class property FormatSettings: TFormatSettings read _GetFormatSettings write _SetFormatSettings;
  end;

implementation

{ TJsonFlow — instance }

constructor TJsonFlow.Create;
begin
  inherited Create;
  FReader     := TJSONReader.Create;
  FWriter     := TJSONWriter.Create;
  FSerializer := TJSONSerializer.Create;
end;

constructor TJsonFlow.Create(const AFormatSettings: TFormatSettings);
begin
  inherited Create;
  FReader     := TJSONReader.Create(AFormatSettings);
  FWriter     := TJSONWriter.Create(AFormatSettings);
  FSerializer := TJSONSerializer.Create(AFormatSettings);
end;

destructor TJsonFlow.Destroy;
begin
  FSerializer.Free;
  FWriter.Free;
  FReader.Free;
  inherited;
end;

function TJsonFlow.Parse(const AJson: string): IJSONElement;
begin
  // EJsonFlowParseError propagates unmodified — no shim.
  Result := FReader.Read(AJson);
end;

function TJsonFlow.ToJson(const AElement: IJSONElement; const AIdent: Boolean): string;
begin
  Result := FWriter.Write(AElement, AIdent);
end;

function TJsonFlow.FromObject(AObject: TObject; const AStoreClass: Boolean): IJSONElement;
begin
  Result := FSerializer.FromObject(AObject, AStoreClass);
end;

function TJsonFlow.ToObject(const AElement: IJSONElement; AObject: TObject): Boolean;
begin
  Result := FSerializer.ToObject(AElement, AObject);
end;

procedure TJsonFlow.OnLog(const ALogProc: TProc<string>);
begin
  FReader.OnLog(ALogProc);
  FWriter.OnLog(ALogProc);
  FSerializer.OnLog(ALogProc);
end;

{ TJsonFlow — class }

class constructor TJsonFlow.Create;
begin
  FJsonBuilder := TJsonBuilder.Create;
end;

class destructor TJsonFlow.Destroy;
begin
  FJsonBuilder.Free;
end;

class function TJsonFlow._GetFormatSettings: TFormatSettings;
begin
  Result := GJsonFlowFormatSettings;
end;

class procedure TJsonFlow._SetFormatSettings(const Value: TFormatSettings);
begin
  // ATENÇÃO: configuração GLOBAL sem sincronização — defina apenas na
  // inicialização da aplicação, antes de haver serializações concorrentes
  // (o record contém strings; escrita simultânea a leituras é race condition).
  GJsonFlowFormatSettings := Value;
end;

class procedure TJsonFlow._SetNotifyEventGetValue(const Value: TNotifyEventGetValue);
begin
  FJsonBuilder.OnGetValue := Value;
end;

class procedure TJsonFlow._SetNotifyEventSetValue(const Value: TNotifyEventSetValue);
begin
  FJsonBuilder.OnSetValue := Value;
end;

class function TJsonFlow.ObjectToJsonString(AObject: TObject;
  AStoreClassName: Boolean): string;
begin
  Result := FJsonBuilder.ObjectToJSON(AObject, AStoreClassName);
end;

class function TJsonFlow.ObjectListToJsonString(AObjectList: TObjectList<TObject>;
  AStoreClassName: Boolean): string;
var
  LFor: Integer;
  LResultBuilder: TStringBuilder;
begin
  LResultBuilder := TStringBuilder.Create;
  try
    LResultBuilder.Append('[');
    for LFor := 0 to AObjectList.Count - 1 do
    begin
      LResultBuilder.Append(FJsonBuilder.ObjectToJSON(AObjectList.Items[LFor], AStoreClassName));
      if LFor < AObjectList.Count - 1 then
        LResultBuilder.Append(',');
    end;
    // Append em vez de ReplaceLastChar: o replace sobrescrevia o '}' final do
    // último objeto, corrompendo a saída ('[{"a":1]'); lista vazia vira '[]'.
    LResultBuilder.Append(']');
    Result := LResultBuilder.ToString;
  finally
    LResultBuilder.Free;
  end;
end;

class function TJsonFlow.ObjectListToJsonString<T>(AObjectList: TObjectList<T>;
  AStoreClassName: Boolean): string;
var
  LFor: Integer;
  LResultBuilder: TStringBuilder;
begin
  LResultBuilder := TStringBuilder.Create;
  try
    LResultBuilder.Append('[');
    for LFor := 0 to AObjectList.Count - 1 do
    begin
      LResultBuilder.Append(FJsonBuilder.ObjectToJSON(AObjectList.Items[LFor] as T, AStoreClassName));
      if LFor < AObjectList.Count - 1 then
        LResultBuilder.Append(',');
    end;
    // Append em vez de ReplaceLastChar: o replace sobrescrevia o '}' final do
    // último objeto, corrompendo a saída ('[{"a":1]'); lista vazia vira '[]'.
    LResultBuilder.Append(']');
    Result := LResultBuilder.ToString;
  finally
    LResultBuilder.Free;
  end;
end;

class function TJsonFlow.JsonToObject<T>(const AJson: string): T;
begin
  Result := FJsonBuilder.JsonToObject<T>(AJson);
end;

class function TJsonFlow.JsonToObject<T>(const AObject: T; const AJson: string): Boolean;
begin
  Result := FJsonBuilder.JsonToObject(TObject(AObject), AJson);
end;

class procedure TJsonFlow.JsonToObject(const AJson: string; AObject: TObject);
begin
  FJsonBuilder.JsonToObject(AObject, AJson);
end;

class function TJsonFlow.JsonToObjectList<T>(const AJson: string): TObjectList<T>;
begin
  Result := FJsonBuilder.JsonToObjectList<T>(AJson);
end;

class function TJsonFlow.JsonToObjectList(const AJson: string;
  const AType: TClass): TObjectList<TObject>;
begin
  Result := FJsonBuilder.JsonToObjectList(AJson, AType);
end;

class procedure TJsonFlow.AddMiddleware(const AEventMiddleware: IEventMiddleware);
begin
  FJsonBuilder.AddMiddleware(AEventMiddleware);
end;

class procedure TJsonFlow.ClearMiddlewares;
begin
  TJsonBuilder.ClearMiddlewares;
end;

end.

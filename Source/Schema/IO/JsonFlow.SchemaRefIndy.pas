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

{$include ../../JsonFlow.inc}
unit JsonFlow.SchemaRefIndy;

// Optional HTTP $ref backend — requires the third-party Indy library.
// Define JSONFLOW_HTTP_INDY (and have Indy) to compile it in (PLANO Fase 5: HTTP is opt-in).
{$IFDEF JSONFLOW_HTTP_INDY}

interface

uses
  System.SysUtils,
  System.Classes,
  IdHTTP,
  JsonFlow.Interfaces,
  JsonFlow.Reader;

type
  TJSONSchemaRefIndy = class(TInterfacedObject, IJSONSchemaRef)
  private
    FHTTP: TIdHTTP;
    FReader: TJSONReader;
  public
    constructor Create;
    destructor Destroy; override;
    function FetchReference(const ARef: string): IJSONElement;
  end;

implementation

constructor TJSONSchemaRefIndy.Create;
begin
  FHTTP := TIdHTTP.Create(nil);
  FReader := TJSONReader.Create;
end;

destructor TJSONSchemaRefIndy.Destroy;
begin
  FReader.Free;
  FHTTP.Free;
  inherited;
end;

function TJSONSchemaRefIndy.FetchReference(const ARef: string): IJSONElement;
var
  LStream: TStringStream;
  LResponse: string;
begin
  LStream := TStringStream.Create;
  try
    LResponse := FHTTP.Get(ARef);
    LStream.WriteString(LResponse);
    LStream.Position := 0;
    Result := FReader.ReadFromStream(LStream);
  except
    on E: Exception do
    begin
      raise EInvalidOperation.CreateFmt('Failed to fetch reference "%s": %s', [ARef, E.Message]);
    end;
  end;
  LStream.Free;
end;

{$ELSE}
interface
implementation
{$ENDIF}

end.

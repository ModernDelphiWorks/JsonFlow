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

unit Horse.JsonFlow;

interface

uses
  Web.HTTPApp,
  System.Classes,
  System.SysUtils,
  Horse;

type
  THorseRequestHelper = class helper for THorseRequest
  private
    class var Res: THorseResponse;
  public
    function Body<T: class, constructor>: T; overload;
  end;

function HorseJsonFlow: THorseCallback; overload;
function HorseJsonFlow(const ACharset: String): THorseCallback; overload;
procedure Middleware(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);

implementation

uses JsonFlow;

var
  Charset: String;

function HorseJsonFlow: THorseCallback;
var
  LFormatSettings: TFormatSettings;
begin
  Result := HorseJsonFlow('UTF-8');
  LFormatSettings := TFormatSettings.Create('en_US');
  TJsonFlow.FormatSettings := LFormatSettings;
end;

function HorseJsonFlow(const ACharset: String): THorseCallback;
begin
  Charset := ACharset;
  Result := Middleware;
end;

procedure Middleware(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  if (Req.MethodType in [mtPost, mtPut, mtPatch]) and
     (Req.RawWebRequest.ContentType.Contains('application/json')) then
  begin
    THorseRequest.Res := Res;
  end;

  try
    Next;
  finally
    if (Res.Content <> nil) and
       (Req.RawWebRequest.ContentType.Contains('application/json')) then
    begin
      Res.RawWebResponse.Content := TJsonFlow.ObjectToJsonString(Res.Content);
      Res.RawWebResponse.ContentType := 'application/json; charset=' + Charset;
    end;
    THorseRequest.Res := nil;
  end;
end;

{ THorseRequestHelper }

function THorseRequestHelper.Body<T>: T;
var
  LJSON: String;
begin
  Result := nil;

  if (MethodType in [mtPost, mtPut, mtPatch]) and
     (RawWebRequest.ContentType.Contains('application/json')) then
  begin
    LJSON := RawWebRequest.Content;
    try
      if LJSON.StartsWith('[') then
        Result := T(TJsonFlow.JsonToObjectList<T>(LJSON))
      else
        Result := T(TJsonFlow.JsonToObject<T>(LJSON));
    except
      Res.Send('Invalid JSON').Status(THTTPStatus.BadRequest);
      raise EHorseCallbackInterrupted.Create;
    end;
  end;
end;

end.
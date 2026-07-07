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

unit JsonFlow.MiddlewareDatatime;

interface

uses
  System.Rtti,
  System.TypInfo,
  System.SysUtils,
  JsonFlow.Utils,
  JsonFlow.Interfaces;

type
  TMiddlewareDateTime = class(TInterfacedObject, IEventMiddleware,
                                                 IGetValueMiddleware,
                                                 ISetValueMiddleware)
  private
    FFormatSettings: TFormatSettings;
  public
    constructor Create(const AFormatSettings: TFormatSettings);
    procedure GetValue(const AInstance: TObject; const AProperty: TRttiProperty;
      var AValue: Variant; var ABreak: Boolean);
    procedure SetValue(const AInstance: TObject; const AProperty: TRttiProperty;
      var AValue: Variant; var ABreak: Boolean);
  end;

implementation

{ TMiddlewareDateTime }

constructor TMiddlewareDateTime.Create(const AFormatSettings: TFormatSettings);
begin
  FFormatSettings := AFormatSettings;
end;

procedure TMiddlewareDateTime.GetValue(const AInstance: TObject; const AProperty: TRttiProperty;
  var AValue: Variant; var ABreak: Boolean);
begin
  // DateTime Validate
  if AProperty.PropertyType.Handle = TypeInfo(TDateTime) then
  begin
    AValue := FormatDateTime('yyyy-mm-dd', AProperty.GetValue(AInstance).AsExtended);
    ABreak := True;
  end;
end;

procedure TMiddlewareDateTime.SetValue(const AInstance: TObject; const AProperty: TRttiProperty;
  var AValue: Variant; var ABreak: Boolean);
begin
  // DateTime Validate
  if AProperty.PropertyType.Handle = TypeInfo(TDateTime) then
  begin
    AProperty.SetValue(AInstance, Iso8601ToDateTime(AValue, True));
    ABreak := True;
  end;
end;

end.

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

unit JsonFlow.Value;

interface

uses
  System.Math,
  System.TypInfo,
  System.Classes,
  System.SysUtils,
  System.StrUtils,
  JsonFlow.Utils,
  JsonFlow.Interfaces;

type
  TJSONValue = class abstract(TInterfacedObject, IJSONElement, IJSONValue)
  protected
    FFormatSettings: TFormatSettings;
    function _GetAsBoolean: Boolean; virtual; abstract;
    procedure _SetAsBoolean(const AValue: Boolean); virtual; abstract;
    function _GetAsInteger: Int64; virtual; abstract;
    procedure _SetAsInteger(const AValue: Int64); virtual; abstract;
    function _GetAsFloat: Double; virtual; abstract;
    procedure _SetAsFloat(const AValue: Double); virtual; abstract;
    function _GetAsString: String; virtual; abstract;
    procedure _SetAsString(const AValue: String); virtual; abstract;
  public
    constructor Create; overload; virtual;
    destructor Destroy; override;
    procedure SaveToStream(AStream: TStream; const AIdent: Boolean = False);
    function AsJSON(const AIdent: Boolean = False): String; virtual; abstract;
    function Clone: IJSONElement; virtual; abstract;
    function IsString: Boolean; virtual;
    function IsInteger: Boolean; virtual;
    function IsFloat: Boolean; virtual;
    function IsBoolean: Boolean; virtual;
    function IsNull: Boolean; virtual;
    function IsDate: Boolean; virtual;
    function TypeName: string;
    property AsBoolean: Boolean read _GetAsBoolean write _SetAsBoolean;
    property AsInteger: Int64 read _GetAsInteger write _SetAsInteger;
    property AsFloat: Double read _GetAsFloat write _SetAsFloat;
    property AsString: String read _GetAsString write _SetAsString;
  end;

  TJSONValueString = class(TJSONValue)
  private
    FValue: String;
    function _GetValue: String;
  protected
    function _GetAsInteger: Int64; override;
    procedure _SetAsInteger(const AValue: Int64); override;
    function _GetAsString: String; override;
    procedure _SetAsString(const AValue: String); override;
    function _GetAsFloat: Double; override;
    procedure _SetAsFloat(const AValue: Double); override;
    function _GetAsBoolean: Boolean; override;
    procedure _SetAsBoolean(const AValue: Boolean); override;
  public
    constructor Create(const AValue: String); overload;
    function AsJSON(const AIdent: Boolean = False): String; override;
    function Clone: IJSONElement; override;
    function IsString: Boolean; override;
    property Value: String read _GetValue;
  end;

  TJSONValueBoolean = class(TJSONValue)
  private
    FValue: Boolean;
    function _GetValue: Boolean;
  protected
    function _GetAsInteger: Int64; override;
    procedure _SetAsInteger(const AValue: Int64); override;
    function _GetAsString: String; override;
    procedure _SetAsString(const AValue: String); override;
    function _GetAsBoolean: Boolean; override;
    procedure _SetAsBoolean(const AValue: Boolean); override;
    function _GetAsFloat: Double; override;
    procedure _SetAsFloat(const AValue: Double); override;
  public
    constructor Create(const AValue: Boolean); overload;
    function AsJSON(const AIdent: Boolean = False): String; override;
    function Clone: IJSONElement; override;
    function IsBoolean: Boolean; override;
    property Value: Boolean read _GetValue;
  end;

  TJSONValueNull = class(TJSONValue)
  private
    FValue: Byte;
    function _GetValue: Byte;
  protected
    function _GetAsInteger: Int64; override;
    procedure _SetAsInteger(const AValue: Int64); override;
    function _GetAsString: String; override;
    procedure _SetAsString(const AValue: String); override;
    function _GetAsBoolean: Boolean; override;
    procedure _SetAsBoolean(const AValue: Boolean); override;
    function _GetAsFloat: Double; override;
    procedure _SetAsFloat(const AValue: Double); override;
  public
    constructor Create(const AValue: Byte = 0); overload;
    function AsJSON(const AIdent: Boolean = False): String; override;
    function Clone: IJSONElement; override;
    function IsNull: Boolean; override;
    property Value: Byte read _GetValue;
  end;

  TJSONValueInteger = class(TJSONValue)
  private
    FValue: Int64;
    function _GetValue: Int64;
  protected
    function _GetAsInteger: Int64; override;
    procedure _SetAsInteger(const AValue: Int64); override;
    function _GetAsString: String; override;
    procedure _SetAsString(const AValue: String); override;
    function _GetAsFloat: Double; override;
    procedure _SetAsFloat(const AValue: Double); override;
    function _GetAsBoolean: Boolean; override;
    procedure _SetAsBoolean(const AValue: Boolean); override;
  public
    constructor Create(const AValue: Int64); overload;
    function AsJSON(const AIdent: Boolean = False): String; override;
    function Clone: IJSONElement; override;
    function IsInteger: Boolean; override;
    property Value: Int64 read _GetValue;
  end;

  TJSONValueFloat = class(TJSONValue)
  private
    FValue: Double;
    function _GetValue: Double;
  protected
    function _GetAsInteger: Int64; override;
    procedure _SetAsInteger(const AValue: Int64); override;
    function _GetAsString: String; override;
    procedure _SetAsString(const AValue: String); override;
    function _GetAsFloat: Double; override;
    procedure _SetAsFloat(const AValue: Double); override;
    function _GetAsBoolean: Boolean; override;
    procedure _SetAsBoolean(const AValue: Boolean); override;
  public
    constructor Create(const AValue: Double); overload;
    constructor Create(const AValue: Double; const AFormatSettings: TFormatSettings); overload;
    function AsJSON(const AIdent: Boolean = False): String; override;
    function Clone: IJSONElement; override;
    function IsFloat: Boolean; override;
    property Value: Double read _GetValue;
  end;

  TJSONValueDateTime = class(TJSONValue)
  private
    FValue: TDateTime;
    function _GetValue: TDateTime;
  protected
    function _GetAsBoolean: Boolean; override;
    procedure _SetAsBoolean(const AValue: Boolean); override;
    function _GetAsInteger: Int64; override;
    procedure _SetAsInteger(const AValue: Int64); override;
    function _GetAsFloat: Double; override;
    procedure _SetAsFloat(const AValue: Double); override;
    function _GetAsString: String; override;
    procedure _SetAsString(const AValue: String); override;
  public
    constructor Create(const AValue: TDateTime); overload;
    constructor Create(const AValue: String; const AUseISO8601: Boolean); overload;
    function AsJSON(const AIdent: Boolean = False): String; override;
    function Clone: IJSONElement; override;
    function IsDate: Boolean; override;
    property Value: TDateTime read _GetValue;
  end;

implementation

constructor TJSONValue.Create;
begin
  FFormatSettings := TFormatSettings.Create('en-US');
  FFormatSettings.ShortDateFormat := 'yyyy-mm-dd';
  FFormatSettings.DateSeparator := '-';
  FFormatSettings.TimeSeparator := ':';
  FFormatSettings.DecimalSeparator := '.';
end;

destructor TJSONValue.Destroy;
begin
  inherited;
end;

function TJSONValue.IsBoolean: Boolean;
begin
  Result := False;
end;

function TJSONValue.IsDate: Boolean;
begin
  Result := False;
end;

function TJSONValue.IsFloat: Boolean;
begin
  Result := False;
end;

function TJSONValue.IsNull: Boolean;
begin
  Result := False;
end;

function TJSONValue.IsInteger: Boolean;
begin
  Result := False;
end;

function TJSONValue.IsString: Boolean;
begin
  Result := False;
end;

procedure TJSONValue.SaveToStream(AStream: TStream; const AIdent: Boolean);
var
  LJson: String;
  LBytes: TBytes;
begin
  LJson := AsJSON(AIdent);
  LBytes := TEncoding.UTF8.GetBytes(LJson);
  AStream.WriteBuffer(LBytes, Length(LBytes));
end;

function TJSONValue.TypeName: string;
begin
  if      IsString  then Result := 'string'
  else if IsInteger then Result := 'integer'
  else if IsFloat   then Result := 'number'
  else if IsBoolean then Result := 'boolean'
  else if IsNull    then Result := 'null'
  else if IsDate    then Result := 'string';
end;

{ TJSONValueString }

function TJSONValueString.AsJSON(const AIdent: Boolean = False): String;
var
  LBuilder: TStringBuilder;
  LResult: String;
  LFor: Integer;
  LChar: Char;
begin
  LBuilder := TStringBuilder.Create;
  try
    LBuilder.Append('"');
    for LFor := 1 to Length(FValue) do
    begin
      LChar := FValue[LFor];
      case LChar of
        '"': LBuilder.Append('\"');
        '\': LBuilder.Append('\\');
        #8: LBuilder.Append('\b');
        #9: LBuilder.Append('\t');
        #10: LBuilder.Append('\n');
        #12: LBuilder.Append('\f');
        #13: LBuilder.Append('\r');
        #0..#7, #11, #14..#31:
          LBuilder.Append('\u00' + IntToHex(Ord(LChar), 2));
        else
          LBuilder.Append(LChar);
      end;
    end;
    LBuilder.Append('"');
    LResult := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
  Result := LResult;
end;

function TJSONValueString.Clone: IJSONElement;
begin
  Result := TJSONValueString.Create(FValue);
end;

constructor TJSONValueString.Create(const AValue: String);
begin
  inherited Create;
  FValue := AValue;
end;

function TJSONValueString.IsString: Boolean;
begin
  Result := True;
end;

function TJSONValueString._GetAsBoolean: Boolean;
begin
  Result := StrToBoolDef(FValue, False);
end;

function TJSONValueString._GetAsFloat: Double;
begin
  Result := StrToFloatDef(FValue, 0, FFormatSettings);
end;

function TJSONValueString._GetAsInteger: Int64;
begin
  Result := StrToInt64Def(FValue, 0);
end;

function TJSONValueString._GetAsString: String;
begin
  Result := FValue;
end;

function TJSONValueString._GetValue: String;
begin
  Result := FValue;
end;

procedure TJSONValueString._SetAsBoolean(const AValue: Boolean);
begin
  FValue := BoolToStr(AValue);
end;

procedure TJSONValueString._SetAsFloat(const AValue: Double);
begin
  FValue := FloatToStr(AValue, FFormatSettings);
end;

procedure TJSONValueString._SetAsInteger(const AValue: Int64);
begin
  FValue := IntToStr(AVAlue);
end;

procedure TJSONValueString._SetAsString(const AValue: String);
begin
  FValue := AVAlue;
end;

{ TJSONValueBoolean }

function TJSONValueBoolean.AsJSON(const AIdent: Boolean): String;
begin
  Result := IfThen(FValue, JSON_TRUE, JSON_FALSE);
end;

function TJSONValueBoolean.Clone: IJSONElement;
begin
  Result := TJSONValueBoolean.Create(FVAlue);
end;

constructor TJSONValueBoolean.Create(const AValue: Boolean);
begin
  inherited Create;
  FValue := AValue;
end;

function TJSONValueBoolean.IsBoolean: Boolean;
begin
  Result := True;
end;

function TJSONValueBoolean._GetAsBoolean: Boolean;
begin
  Result := FValue;
end;

function TJSONValueBoolean._GetAsFloat: Double;
begin
  Result := IfThen(FValue, 1.0, 0.0);
end;

function TJSONValueBoolean._GetAsInteger: Int64;
begin
  Result := IfThen(FValue, 1, 0);
end;

function TJSONValueBoolean._GetAsString: String;
begin
  Result := BoolToStr(FValue, True);
end;

function TJSONValueBoolean._GetValue: Boolean;
begin
  Result := FValue;
end;

procedure TJSONValueBoolean._SetAsBoolean(const AValue: Boolean);
begin
  FValue := AValue;
end;

procedure TJSONValueBoolean._SetAsFloat(const AValue: Double);
begin
  FValue := Trunc(AValue) <> 0;
end;

procedure TJSONValueBoolean._SetAsInteger(const AValue: Int64);
begin
  FValue := Boolean(AValue);
end;

procedure TJSONValueBoolean._SetAsString(const AValue: String);
begin
  FValue := StrToBool(AValue);
end;

{ TJSONValueNull }

function TJSONValueNull.AsJSON(const AIdent: Boolean): String;
begin
  Result := JSON_NULL;
end;

function TJSONValueNull.Clone: IJSONElement;
begin
  Result := TJSONValueNull.Create;
end;

constructor TJSONValueNull.Create(const AValue: Byte);
begin
  inherited Create;
  FValue := AValue;
end;

function TJSONValueNull.IsNull: Boolean;
begin
  Result := True;
end;

function TJSONValueNull._GetAsBoolean: Boolean;
begin
  raise EConvertError.Create('Cannot convert JSONValueNull to Boolean');
end;

function TJSONValueNull._GetAsFloat: Double;
begin
  raise EConvertError.Create('Cannot convert JSONValueNull to Float');
end;

function TJSONValueNull._GetAsInteger: Int64;
begin
  raise EConvertError.Create('Cannot convert JSONValueNull to Integer');
end;

function TJSONValueNull._GetAsString: String;
begin
  Result := JSON_NULL;
end;

function TJSONValueNull._GetValue: Byte;
begin
  Result := FValue;
end;

procedure TJSONValueNull._SetAsBoolean(const AValue: Boolean);
begin
  raise EConvertError.Create('Cannot convert JSONValueNull from Boolean');
end;

procedure TJSONValueNull._SetAsFloat(const AValue: Double);
begin
  raise EConvertError.Create('Cannot convert JSONValueNull from Float');
end;

procedure TJSONValueNull._SetAsInteger(const AValue: Int64);
begin
  raise EConvertError.Create('Cannot convert JSONValueNull from Integer');
end;

procedure TJSONValueNull._SetAsString(const AValue: String);
begin
  raise EConvertError.Create('Cannot convert JSONValueNull from String');
end;

{ TJSONValueInteger }

constructor TJSONValueInteger.Create(const AValue: Int64);
begin
  inherited Create;
  FValue := AValue;
end;

function TJSONValueInteger.IsInteger: Boolean;
begin
  Result := True;
end;

function TJSONValueInteger.AsJSON(const AIdent: Boolean): String;
begin
  Result := IntToStr(FValue);
end;

function TJSONValueInteger.Clone: IJSONElement;
begin
  Result := TJSONValueInteger.Create(FValue);
end;

function TJSONValueInteger._GetAsBoolean: Boolean;
begin
  Result := FValue <> 0;
end;

function TJSONValueInteger._GetAsFloat: Double;
begin
  Result := FValue;
end;

function TJSONValueInteger._GetAsInteger: Int64;
begin
  Result := FValue;
end;

function TJSONValueInteger._GetAsString: String;
begin
  Result := IntToStr(FValue);
end;

function TJSONValueInteger._GetValue: Int64;
begin
  Result := FValue;
end;

procedure TJSONValueInteger._SetAsBoolean(const AValue: Boolean);
begin
  FValue := Int64(AVAlue);
end;

procedure TJSONValueInteger._SetAsFloat(const AValue: Double);
begin
  FValue := Trunc(AValue);
end;

procedure TJSONValueInteger._SetAsInteger(const AValue: Int64);
begin
  FValue := AValue;
end;

procedure TJSONValueInteger._SetAsString(const AValue: String);
begin
  FValue := StrToInt64Def(AValue, 0);
end;

{ TJSONValueFloat }

function TJSONValueFloat.AsJSON(const AIdent: Boolean): String;
begin
  Result := FloatToStr(FValue, FFormatSettings);
end;

function TJSONValueFloat.Clone: IJSONElement;
begin
  Result := TJSONValueFloat.Create(FValue, FFormatSettings);
end;

constructor TJSONValueFloat.Create(const AValue: Double);
begin
  inherited Create;
  FValue := AValue;
end;

constructor TJSONValueFloat.Create(const AValue: Double; const AFormatSettings: TFormatSettings);
begin
  Create(AValue);
  FFormatSettings := AFormatSettings;
end;

function TJSONValueFloat.IsFloat: Boolean;
begin
  Result := True;
end;

function TJSONValueFloat._GetAsBoolean: Boolean;
begin
  Result := FValue <> 0;
end;

function TJSONValueFloat._GetAsFloat: Double;
begin
  Result := FValue;
end;

function TJSONValueFloat._GetAsInteger: Int64;
begin
  Result := Trunc(FValue);
end;

function TJSONValueFloat._GetAsString: String;
begin
  Result := FloatToStr(FValue, FFormatSettings);
end;

function TJSONValueFloat._GetValue: Double;
begin
  Result := FValue;
end;

procedure TJSONValueFloat._SetAsBoolean(const AValue: Boolean);
begin
  FValue := Integer(AValue);
end;

procedure TJSONValueFloat._SetAsFloat(const AValue: Double);
begin
  FValue := AValue;
end;

procedure TJSONValueFloat._SetAsInteger(const AValue: Int64);
begin
  FValue := Avalue;
end;

procedure TJSONValueFloat._SetAsString(const AValue: String);
begin
  FValue := StrToFloatDef(AValue, 0, FFormatSettings);
end;

{ TJSONValueDateTime }

function TJSONValueDateTime.AsJSON(const AIdent: Boolean): String;
begin
  Result := '"' + DateTimeToIso8601(FValue, True) + '"';
end;

function TJSONValueDateTime.Clone: IJSONElement;
begin
  Result := TJSONValueDateTime.Create(DateTimeToIso8601(FValue, True), True);
end;

constructor TJSONValueDateTime.Create(const AValue: TDateTime);
begin
  inherited Create;
  FValue := AValue;
end;

constructor TJSONValueDateTime.Create(const AValue: String; const AUseISO8601: Boolean);
begin
  inherited Create;
  FValue := Iso8601ToDateTime(AValue, AUseISO8601);
end;

function TJSONValueDateTime.IsDate: Boolean;
begin
  Result := True;
end;

function TJSONValueDateTime._GetAsBoolean: Boolean;
begin
  Result := FValue <> 0;
end;

function TJSONValueDateTime._GetAsFloat: Double;
begin
  Result := FValue;
end;

function TJSONValueDateTime._GetAsInteger: Int64;
begin
  Result := Trunc(FValue);
end;

function TJSONValueDateTime._GetAsString: String;
begin
  Result := DateTimeToIso8601(FValue, True);
end;

function TJSONValueDateTime._GetValue: TDateTime;
begin
  Result := FValue;
end;

procedure TJSONValueDateTime._SetAsBoolean(const AValue: Boolean);
begin
  if AValue then
    FValue := Now
  else
    FValue := 0;
end;

procedure TJSONValueDateTime._SetAsFloat(const AValue: Double);
begin
  FValue := AValue;
end;

procedure TJSONValueDateTime._SetAsInteger(const AValue: Int64);
begin
  FValue := AValue;
end;

procedure TJSONValueDateTime._SetAsString(const AValue: String);
begin
  FValue := Iso8601ToDateTime(AValue, True);
end;

end.

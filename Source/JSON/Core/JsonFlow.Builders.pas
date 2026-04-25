{ Compatibility shim: TJsonBuilder wraps the TJsonFlow static API.
  JsonFlow renamed TJsonBuilder to TJsonFlow (static class) in v2.x.
  This unit restores the TJsonBuilder interface expected by Janus.Json.pas. }

unit JsonFlow.Builders;

interface

uses
  Rtti,
  SysUtils,
  Variants,
  Generics.Collections,
  JsonFlow,
  JsonFlow.Utils,
  JsonFlow.Interfaces;

type
  TGetValueEvent = procedure(const AInstance: TObject;
    const AProperty: TRttiProperty; var AResult: Variant;
    var ABreak: Boolean) of object;

  TSetValueEvent = procedure(const AInstance: TObject;
    const AProperty: TRttiProperty; const AValue: Variant;
    var ABreak: Boolean) of object;

  TJsonBuilder = class
  private
    FUseISO8601: Boolean;
    FGetValueEvent: TGetValueEvent;
    FSetValueEvent: TSetValueEvent;
    FGetMiddleware: IEventMiddleware;
    FSetMiddleware: IEventMiddleware;
    procedure _SetOnGetValue(const AEvent: TGetValueEvent);
    procedure _SetOnSetValue(const AEvent: TSetValueEvent);
  public
    constructor Create;
    destructor Destroy; override;
    function ObjectToJSON(const AObject: TObject;
      const AStoreClassName: Boolean = False): String;
    function JSONToObject(const AObject: TObject;
      const AJson: String): Boolean; overload;
    function JSONToObject<T: class, constructor>(const AJson: String): T; overload;
    function JSONToObjectList<T: class, constructor>(
      const AJson: String): TObjectList<T>;
    property OnGetValue: TGetValueEvent read FGetValueEvent write _SetOnGetValue;
    property OnSetValue: TSetValueEvent read FSetValueEvent write _SetOnSetValue;
    property UseISO8601DateFormat: Boolean read FUseISO8601 write FUseISO8601;
  end;

var
  GJsonBrFormatSettings: TFormatSettings;

implementation

type
  TGetValueAdapter = class(TInterfacedObject, IEventMiddleware, IGetValueMiddleware)
  private
    FEvent: TGetValueEvent;
  public
    constructor Create(const AEvent: TGetValueEvent);
    procedure GetValue(const AInstance: TObject; const AProperty: TRttiProperty;
      var AValue: Variant; var ABreak: Boolean);
  end;

  TSetValueAdapter = class(TInterfacedObject, IEventMiddleware, ISetValueMiddleware)
  private
    FEvent: TSetValueEvent;
  public
    constructor Create(const AEvent: TSetValueEvent);
    procedure SetValue(const AInstance: TObject; const AProperty: TRttiProperty;
      var AValue: Variant; var ABreak: Boolean);
  end;

{ TGetValueAdapter }

constructor TGetValueAdapter.Create(const AEvent: TGetValueEvent);
begin
  FEvent := AEvent;
end;

procedure TGetValueAdapter.GetValue(const AInstance: TObject;
  const AProperty: TRttiProperty; var AValue: Variant; var ABreak: Boolean);
begin
  if Assigned(FEvent) then
    FEvent(AInstance, AProperty, AValue, ABreak);
end;

{ TSetValueAdapter }

constructor TSetValueAdapter.Create(const AEvent: TSetValueEvent);
begin
  FEvent := AEvent;
end;

procedure TSetValueAdapter.SetValue(const AInstance: TObject;
  const AProperty: TRttiProperty; var AValue: Variant; var ABreak: Boolean);
begin
  if Assigned(FEvent) then
    FEvent(AInstance, AProperty, AValue, ABreak);
end;

{ TJsonBuilder }

constructor TJsonBuilder.Create;
begin
  FUseISO8601 := False;
end;

destructor TJsonBuilder.Destroy;
begin
  TJsonFlow.ClearMiddlewares;
  inherited;
end;

procedure TJsonBuilder._SetOnGetValue(const AEvent: TGetValueEvent);
begin
  FGetValueEvent := AEvent;
  FGetMiddleware := TGetValueAdapter.Create(AEvent);
  TJsonFlow.AddMiddleware(FGetMiddleware);
end;

procedure TJsonBuilder._SetOnSetValue(const AEvent: TSetValueEvent);
begin
  FSetValueEvent := AEvent;
  FSetMiddleware := TSetValueAdapter.Create(AEvent);
  TJsonFlow.AddMiddleware(FSetMiddleware);
end;

function TJsonBuilder.ObjectToJSON(const AObject: TObject;
  const AStoreClassName: Boolean): String;
begin
  Result := TJsonFlow.ObjectToJsonString(AObject, AStoreClassName);
end;

function TJsonBuilder.JSONToObject(const AObject: TObject;
  const AJson: String): Boolean;
begin
  try
    TJsonFlow.JsonToObject(AJson, AObject);
    Result := True;
  except
    Result := False;
  end;
end;

function TJsonBuilder.JSONToObject<T>(const AJson: String): T;
begin
  Result := TJsonFlow.JsonToObject<T>(AJson);
end;

function TJsonBuilder.JSONToObjectList<T>(const AJson: String): TObjectList<T>;
begin
  Result := TJsonFlow.JsonToObjectList<T>(AJson);
end;

initialization
  GJsonBrFormatSettings := JsonFormatSettings;

end.

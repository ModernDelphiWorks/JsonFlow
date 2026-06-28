unit Demo.JsonFlow.Middlewares;

{
  Demonstração do sistema de Middlewares do JsonFlow.

  Middlewares são interceptores que entram na esteira de serialização/deserialização
  para tratar tipos que o Delphi não processa nativamente — como Nullable<T> e datas
  em formatos regionais (ex.: DD/MM/YYYY do Brasil).

  O JsonFlow disponibiliza duas interfaces principais:
    - IGetValueMiddleware: intercepta a LEITURA de um valor (serialização, objeto → JSON)
    - ISetValueMiddleware: intercepta a ESCRITA de um valor (deserialização, JSON → objeto)

  Para ativar um middleware, basta registrá-lo em LSerializer.Middlewares.Add(...)
  antes de chamar FromObject ou ToObject.
}

interface

uses
  System.Rtti,
  System.TypInfo,
  System.SysUtils,
  System.Variants,
  JsonFlow.Interfaces;

type
  // ---------------------------------------------------------------------------
  // Tipo Nullable<T> simples para demonstração
  // O Delphi padrão não possui Nullable built-in; este é um padrão comum de uso.
  // ---------------------------------------------------------------------------
  TNullableInteger = record
    FHasValue: Boolean;
    FValue: Integer;
    procedure SetValue(const AValue: Integer);
    procedure Clear;
    function HasValue: Boolean;
    function Value: Integer;
    class function Empty: TNullableInteger; static;
    class function From(const AValue: Integer): TNullableInteger; static;
  end;

  // ---------------------------------------------------------------------------
  // Middleware 1: Nullable<Integer>
  //
  // Intercepta propriedades do tipo TNullableInteger e as serializa como um
  // número JSON normal (ou "null" se não tiver valor).
  // Na deserialização, converte o número JSON de volta para TNullableInteger.
  // ---------------------------------------------------------------------------
  TMiddlewareNullableInteger = class(TInterfacedObject, IEventMiddleware,
                                                        IGetValueMiddleware,
                                                        ISetValueMiddleware)
  public
    procedure GetValue(const AInstance: TObject; const AProperty: TRttiProperty;
      var AValue: Variant; var ABreak: Boolean);
    procedure SetValue(const AInstance: TObject; const AProperty: TRttiProperty;
      var AValue: Variant; var ABreak: Boolean);
  end;

  // ---------------------------------------------------------------------------
  // Middleware 2: DateTime em múltiplos formatos
  //
  // Suporta leitura de datas em formato brasileiro (DD/MM/YYYY) e serialização
  // no formato ISO8601 padrão (YYYY-MM-DD), facilitando integração com sistemas
  // legados que usam formatos regionais de data.
  // ---------------------------------------------------------------------------
  TMiddlewareBrazilianDate = class(TInterfacedObject, IEventMiddleware,
                                                       IGetValueMiddleware,
                                                       ISetValueMiddleware)
  private
    const ISO_FORMAT   = 'yyyy-mm-dd"T"hh:nn:ss';
    const BR_FORMAT    = 'dd/mm/yyyy';
  public
    procedure GetValue(const AInstance: TObject; const AProperty: TRttiProperty;
      var AValue: Variant; var ABreak: Boolean);
    procedure SetValue(const AInstance: TObject; const AProperty: TRttiProperty;
      var AValue: Variant; var ABreak: Boolean);
  end;

implementation

{ TNullableInteger }

procedure TNullableInteger.SetValue(const AValue: Integer);
begin
  FValue := AValue;
  FHasValue := True;
end;

procedure TNullableInteger.Clear;
begin
  FHasValue := False;
  FValue := 0;
end;

function TNullableInteger.HasValue: Boolean;
begin
  Result := FHasValue;
end;

function TNullableInteger.Value: Integer;
begin
  if not FHasValue then
    raise Exception.Create('TNullableInteger: attempt to read value when HasValue = False');
  Result := FValue;
end;

class function TNullableInteger.Empty: TNullableInteger;
begin
  Result.Clear;
end;

class function TNullableInteger.From(const AValue: Integer): TNullableInteger;
begin
  Result.SetValue(AValue);
end;

{ TMiddlewareNullableInteger }

procedure TMiddlewareNullableInteger.GetValue(const AInstance: TObject;
  const AProperty: TRttiProperty; var AValue: Variant; var ABreak: Boolean);
var
  LRawValue: TValue;
  LNullable: TNullableInteger;
begin
  // Só trata propriedades do tipo TNullableInteger
  if AProperty.PropertyType.Handle <> TypeInfo(TNullableInteger) then
    Exit;

  LRawValue := AProperty.GetValue(AInstance);
  LNullable := LRawValue.AsType<TNullableInteger>;

  if LNullable.HasValue then
    AValue := LNullable.Value
  else
    AValue := Null; // serializa como JSON null

  ABreak := True; // interrompe a cadeia — este middleware tratou o tipo
end;

procedure TMiddlewareNullableInteger.SetValue(const AInstance: TObject;
  const AProperty: TRttiProperty; var AValue: Variant; var ABreak: Boolean);
var
  LNullable: TNullableInteger;
begin
  if AProperty.PropertyType.Handle <> TypeInfo(TNullableInteger) then
    Exit;

  if VarIsNull(AValue) or VarIsEmpty(AValue) then
    LNullable := TNullableInteger.Empty
  else
    LNullable := TNullableInteger.From(Integer(AValue));

  AProperty.SetValue(AInstance, TValue.From<TNullableInteger>(LNullable));
  ABreak := True;
end;

{ TMiddlewareBrazilianDate }

procedure TMiddlewareBrazilianDate.GetValue(const AInstance: TObject;
  const AProperty: TRttiProperty; var AValue: Variant; var ABreak: Boolean);
var
  LFS: TFormatSettings;
begin
  // Só intercepta TDateTime
  if AProperty.PropertyType.Handle <> TypeInfo(TDateTime) then
    Exit;

  // Serializa sempre em ISO8601 — formato universal para JSON
  LFS := TFormatSettings.Create('en-US');
  AValue := FormatDateTime(ISO_FORMAT, AProperty.GetValue(AInstance).AsExtended, LFS);
  ABreak := True;
end;

procedure TMiddlewareBrazilianDate.SetValue(const AInstance: TObject;
  const AProperty: TRttiProperty; var AValue: Variant; var ABreak: Boolean);
var
  LDateStr: string;
  LDateTime: TDateTime;
  LFSBr: TFormatSettings;
begin
  if AProperty.PropertyType.Handle <> TypeInfo(TDateTime) then
    Exit;

  LDateStr := VarToStr(AValue);

  // Tenta primeiro ISO8601
  if TryStrToDateTime(LDateStr, LDateTime) then
  begin
    AProperty.SetValue(AInstance, LDateTime);
    ABreak := True;
    Exit;
  end;

  // Tenta formato brasileiro DD/MM/YYYY
  LFSBr := TFormatSettings.Create('pt-BR');
  if TryStrToDateTime(LDateStr, LDateTime, LFSBr) then
  begin
    AProperty.SetValue(AInstance, LDateTime);
    ABreak := True;
  end;
end;

end.

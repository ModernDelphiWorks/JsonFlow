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

unit JsonFlow.Serializer;

interface

uses
  System.Rtti,
  System.TypInfo,
  System.SysUtils,
  System.Classes,
  System.Variants,
  System.Generics.Collections,
  JsonFlow.Utils,
  JsonFlow.Interfaces,
  JsonFlow.Value,
  JsonFlow.Objects,
  JsonFlow.Arrays,
  JsonFlow.Serializer.CircularRef,
  JsonFlow.Serializer.Attributes;

type
  /// <summary>
  /// Middleware para customização da serialização
  /// </summary>
  TJSONSerializerMiddleware = class abstract
  public
    function BeforeSerialize(const APropertyName: string; const AValue: TValue; var AResult: IJSONElement): Boolean; virtual; abstract;
    function AfterSerialize(const APropertyName: string; const AValue: TValue; var AResult: IJSONElement): Boolean; virtual; abstract;
    function BeforeDeserialize(const APropertyName: string; const AElement: IJSONElement; var AValue: TValue): Boolean; virtual; abstract;
    function AfterDeserialize(const APropertyName: string; const AElement: IJSONElement; var AValue: TValue): Boolean; virtual; abstract;
  end;

  /// <summary>
  /// Opções avançadas de serialização
  /// </summary>
  TJSONSerializerOptions = record
    UsePool: Boolean;
    DetectCircularReferences: Boolean;
    CircularReferenceStrategy: TCircularReferenceStrategy;
    ProcessAttributes: Boolean;
    IgnoreNullValues: Boolean;
    DateTimeFormat: string;
    FloatFormat: string;
    MaxDepth: Integer;
    
    class function Default: TJSONSerializerOptions; static;
  end;

  /// <summary>
  /// Serializador JSON usando RTTI
  /// </summary>
  TJSONSerializer = class
  private
    FFormatSettings: TFormatSettings;
    FLogProc: TProc<String>;
    FMiddlewares: TList<IEventMiddleware>;
    FUseISO8601DateFormat: Boolean;
    FOptions: TJSONSerializerOptions;
    FCircularRefManager: TAdvancedCircularReferenceManager;
    FAttributeHelper: TJSONAttributeHelper;
  private
    FContext: TRttiContext;
    FTypeCache: TDictionary<TClass, TPair<TRttiType, TList<TRttiProperty>>>;
    procedure _Log(const AMessage: string);
    function _GetCachedType(AClass: TClass): TPair<TRttiType, TList<TRttiProperty>>;
    procedure _JSONToProperty(const AProperty: TRttiProperty; const AInstance: TObject;
      const AElement: IJSONElement);
    function _JSONFromProperty(const AProperty: TRttiProperty; const AInstance: TObject;
      const AStoreClassName: Boolean): IJSONElement;
    function _SerializeTValue(const AValue: TValue; const AStoreClassName: Boolean): IJSONElement;
    function _CreateNestedArray(const AArrayType: TRttiDynamicArrayType;
      const AJSONArray: IJSONArray): TValue;
    function _JSONToVariant(const AElement: IJSONElement): Variant;
    function _JSONToElement(const AValue: Variant): IJSONElement;
    
    // Direct stream private writers
    procedure _WriteObject(AObject: TObject; ABuilder: TStringBuilder; const AStoreClassName: Boolean);
    procedure _WriteTValue(const AValue: TValue; ABuilder: TStringBuilder; const AStoreClassName: Boolean);
    procedure _AppendEscapedString(const AValue: string; ABuilder: TStringBuilder);
  public
    constructor Create; overload;
    constructor Create(const AFormatSettings: TFormatSettings; const AUseISO8601DateFormat: Boolean = True); overload;
    constructor Create(const AOptions: TJSONSerializerOptions); overload;
    destructor Destroy; override;
    function FromObject(AObject: TObject; AStoreClassName: Boolean = False): IJSONElement;
    function ToObject(const AElement: IJSONElement; AObject: TObject): Boolean;
    
    // Direct stream public API
    function SerializeToString(AObject: TObject; AStoreClassName: Boolean = False): string;
    procedure SerializeToStream(AObject: TObject; AStream: TStream; AStoreClassName: Boolean = False);
  public
    procedure OnLog(const ALogProc: TProc<String>);
    property Middlewares: TList<IEventMiddleware> read FMiddlewares;
    property Options: TJSONSerializerOptions read FOptions write FOptions;
  end;

  /// <summary>
  /// Factory para criação de serializadores
  /// </summary>
  TJSONSerializerFactory = class
  public
    class function CreateSerializer(const AOptions: TJSONSerializerOptions): TJSONSerializer;
    class function CreateWithDefaults: TJSONSerializer;
    class function CreateWithPool: TJSONSerializer;
    class function CreateWithCircularRefDetection: TJSONSerializer;
    class function CreateWithAttributes: TJSONSerializer;
    class function CreateFull: TJSONSerializer; // Todas as funcionalidades
  end;

implementation

uses
  System.DateUtils;

{ TJSONSerializerOptions }

class function TJSONSerializerOptions.Default: TJSONSerializerOptions;
begin
  Result.UsePool := False;
  Result.DetectCircularReferences := False;
  Result.CircularReferenceStrategy := crsException;
  Result.ProcessAttributes := False;
  Result.IgnoreNullValues := False;
  Result.DateTimeFormat := 'yyyy-mm-dd"T"hh:nn:ss.zzz"Z"';
  Result.FloatFormat := '0.##########';
  Result.MaxDepth := 100;
end;

{ TJSONSerializer }

constructor TJSONSerializer.Create;
begin
  inherited Create;
  FLogProc := nil;
  FContext := TRttiContext.Create;
  FTypeCache := TDictionary<TClass, TPair<TRttiType, TList<TRttiProperty>>>.Create;
  FMiddlewares := TList<IEventMiddleware>.Create;
  FFormatSettings := TFormatSettings.Create('en-US');
  FFormatSettings.ShortDateFormat := 'yyyy-mm-dd';
  FFormatSettings.DateSeparator := '-';
  FFormatSettings.TimeSeparator := ':';
  FFormatSettings.DecimalSeparator := '.';
  FOptions := TJSONSerializerOptions.Default;
end;

constructor TJSONSerializer.Create(const AFormatSettings: TFormatSettings;
  const AUseISO8601DateFormat: Boolean = True);
begin
  Create;
  FFormatSettings := AFormatSettings;
  FUseISO8601DateFormat := AUseISO8601DateFormat;
end;

constructor TJSONSerializer.Create(const AOptions: TJSONSerializerOptions);
begin
  inherited Create;
  FLogProc := nil;
  FContext := TRttiContext.Create;
  FTypeCache := TDictionary<TClass, TPair<TRttiType, TList<TRttiProperty>>>.Create;
  FMiddlewares := TList<IEventMiddleware>.Create;
  FFormatSettings := TFormatSettings.Create('en-US');
  FFormatSettings.ShortDateFormat := 'yyyy-mm-dd';
  FFormatSettings.DateSeparator := '-';
  FFormatSettings.TimeSeparator := ':';
  FFormatSettings.DecimalSeparator := '.';
  FOptions := AOptions;
  
  if FOptions.DetectCircularReferences then
    FCircularRefManager := TAdvancedCircularReferenceManager.Create(FOptions.CircularReferenceStrategy);
    
  if FOptions.ProcessAttributes then
    FAttributeHelper := TJSONAttributeHelper.Create;
end;

destructor TJSONSerializer.Destroy;
var
  LPair: TPair<TClass, TPair<TRttiType, TList<TRttiProperty>>>;
begin
  for LPair in FTypeCache do
    LPair.Value.Value.Free;
  FAttributeHelper.Free;
  FCircularRefManager.Free;
  FMiddlewares.Free;
  FTypeCache.Free;
  FContext.Free;
  inherited;
end;

procedure TJSONSerializer._Log(const AMessage: string);
begin
  if Assigned(FLogProc) then
    FLogProc(AMessage);
end;

function TJSONSerializer._GetCachedType(AClass: TClass): TPair<TRttiType, TList<TRttiProperty>>;
var
  LRttiType: TRttiType;
  LProperties: TList<TRttiProperty>;
  LProp: TRttiProperty;
begin
  // TryGetValue único no hit — antes eram 2-3 buscas no dicionário por objeto
  // (ContainsKey no _CacheType + FTypeCache[LClass] no chamador).
  if FTypeCache.TryGetValue(AClass, Result) then
    Exit;

  LRttiType := FContext.GetType(AClass);
  if not Assigned(LRttiType) then
    raise EInvalidOperation.Create('RTTI not available for class ' + AClass.ClassName);
  LProperties := TList<TRttiProperty>.Create;
  try
    for LProp in LRttiType.GetProperties do
    begin
      if LProp.IsReadable then
      begin
        LProperties.Add(LProp);
      end;
    end;
    Result := TPair<TRttiType, TList<TRttiProperty>>.Create(LRttiType, LProperties);
    FTypeCache.Add(AClass, Result);
  except
    LProperties.Free;
    raise;
  end;
end;

function TJSONSerializer._JSONFromProperty(const AProperty: TRttiProperty; const AInstance: TObject;
  const AStoreClassName: Boolean): IJSONElement;
var
  LValue: TValue;
  LFor: Integer;
  LMiddle: IEventMiddleware;
  LGetMiddle: IGetValueMiddleware;
  LResult: Variant;
  LBreak: Boolean;
  LConverter: IJSONPropertyConverter;
begin
  if not Assigned(AInstance) then
    raise EArgumentNilException.Create('Instance cannot be nil');

  // Custom property converter
  if FOptions.ProcessAttributes then
  begin
    LConverter := TJSONAttributeHelper.GetCustomConverter(AProperty);
    if Assigned(LConverter) then
    begin
      Result := LConverter.ToJSON(AProperty.GetValue(AInstance), AProperty);
      Exit;
    end;
  end;

  // Middlewares
  for LFor := 0 to FMiddlewares.Count - 1 do
  begin
    LMiddle := FMiddlewares[LFor];
    if Supports(LMiddle, IGetValueMiddleware, LGetMiddle) then
    begin
      LBreak := False;
      LGetMiddle.GetValue(AInstance, AProperty, LResult, LBreak);
      if LBreak then
      begin
        Result := _JSONToElement(LResult);
        Exit;
      end;
    end;
  end;

  LValue := AProperty.GetValue(AInstance);
  Result := _SerializeTValue(LValue, AStoreClassName);
end;

function TJSONSerializer._SerializeTValue(const AValue: TValue; const AStoreClassName: Boolean): IJSONElement;
var
  LObj: TObject;
  LArray: IJSONArray;
  LFor: Integer;
  LValueIndex: TValue;
  LTypeInfo: PTypeInfo;
begin
  case AValue.Kind of
    tkInteger, tkInt64:
      Result := TJSONValueInteger.Create(AValue.AsInt64);
    tkFloat:
      begin
        LTypeInfo := AValue.TypeInfo;
        if (LTypeInfo = TypeInfo(TDateTime)) or (LTypeInfo = TypeInfo(TDate)) or (LTypeInfo = TypeInfo(TTime)) then
          Result := TJSONValueDateTime.Create(AValue.AsExtended)
        else if Assigned(LTypeInfo) then
        begin
          case GetTypeData(LTypeInfo)^.FloatType of
            ftSingle, ftDouble, ftExtended, ftComp:
              Result := TJSONValueFloat.Create(AValue.AsExtended, FFormatSettings);
            ftCurr:
              Result := TJSONValueFloat.Create(AValue.AsCurrency, FFormatSettings);
          end;
        end
        else
          Result := TJSONValueFloat.Create(AValue.AsExtended, FFormatSettings);
      end;
    tkString, tkLString, tkWString, tkUString:
      Result := TJSONValueString.Create(AValue.AsString);
    tkEnumeration:
      if AValue.TypeInfo = TypeInfo(Boolean) then
        Result := TJSONValueBoolean.Create(AValue.AsBoolean)
      else
        Result := TJSONValueString.Create(AValue.ToString);
    tkClass:
      begin
        LObj := AValue.AsObject;
        if Assigned(LObj) then
          Result := FromObject(LObj, AStoreClassName)
        else
          Result := TJSONValueNull.Create;
      end;
    tkDynArray:
      begin
        LArray := TJSONArray.Create;
        for LFor := 0 to AValue.GetArrayLength - 1 do
        begin
          LValueIndex := AValue.GetArrayElement(LFor);
          LArray.Add(_SerializeTValue(LValueIndex, AStoreClassName));
        end;
        Result := LArray;
      end;
    else
      Result := TJSONValueNull.Create;
  end;
end;

function TJSONSerializer._CreateNestedArray(const AArrayType: TRttiDynamicArrayType;
  const AJSONArray: IJSONArray): TValue;
var
  LFor: Integer;
  LValueInterface: IJSONValue;
  LNestedArray: IJSONArray;
  LDouble: TArray<Double>;
  LInteger: TArray<Integer>;
  LString: TArray<String>;
  LBoolean: TArray<Boolean>;
  LObjectList: TArray<TObject>;
  LNested: TArray<TValue>;
  LObject: TObject;
begin
  if not Assigned(AJSONArray) then
  begin
    Exit(TValue.FromArray(AArrayType.Handle, []));
  end;

  case AArrayType.ElementType.TypeKind of
    tkFloat:
      begin
        SetLength(LDouble, AJSONArray.Count);
        for LFor := 0 to AJSONArray.Count - 1 do
        begin
          if Supports(AJSONArray.GetItem(LFor), IJSONValue, LValueInterface) then
          begin
            if LValueInterface is TJSONValueFloat then
              LDouble[LFor] := TJSONValueFloat(LValueInterface).Value
            else if LValueInterface is TJSONValueInteger then
              LDouble[LFor] := TJSONValueInteger(LValueInterface).Value
            else
            begin
              try
                LDouble[LFor] := LValueInterface.AsFloat;
              except
                on E: Exception do
                  LDouble[LFor] := 0.0;
              end;
            end;
          end
          else
          begin
            LDouble[LFor] := 0.0;
          end;
        end;
        Result := TValue.From<TArray<Double>>(LDouble);
      end;
    tkInteger, tkInt64:
      begin
        SetLength(LInteger, AJSONArray.Count);
        for LFor := 0 to AJSONArray.Count - 1 do
          if Supports(AJSONArray.GetItem(LFor), IJSONValue, LValueInterface) then
            if LValueInterface is TJSONValueInteger then
              LInteger[LFor] := TJSONValueInteger(LValueInterface).Value;
        Result := TValue.From<TArray<Integer>>(LInteger);
      end;
    tkString, tkLString, tkWString, tkUString:
      begin
        SetLength(LString, AJSONArray.Count);
        for LFor := 0 to AJSONArray.Count - 1 do
          if Supports(AJSONArray.GetItem(LFor), IJSONValue, LValueInterface) then
            if LValueInterface is TJSONValueString then
              LString[LFor] := TJSONValueString(LValueInterface).Value;
        Result := TValue.From<TArray<String>>(LString);
      end;
    tkEnumeration:
      if AArrayType.ElementType.Handle = TypeInfo(Boolean) then
      begin
        SetLength(LBoolean, AJSONArray.Count);
        for LFor := 0 to AJSONArray.Count - 1 do
          if Supports(AJSONArray.GetItem(LFor), IJSONValue, LValueInterface) then
            if LValueInterface is TJSONValueBoolean then
              LBoolean[LFor] := TJSONValueBoolean(LValueInterface).Value;
        Result := TValue.From<TArray<Boolean>>(LBoolean);
      end;
    tkClass:
      begin
        SetLength(LObjectList, AJSONArray.Count);
        try
          for LFor := 0 to AJSONArray.Count - 1 do
          begin
            if Supports(AJSONArray.GetItem(LFor), IJSONObject) then
            begin
              LObject := AArrayType.ElementType.AsInstance.MetaclassType.Create;
              LObjectList[LFor] := LObject;
              ToObject(AJSONArray.GetItem(LFor), LObject);
            end;
          end;
          
          var LValues: TArray<TValue>;
          SetLength(LValues, Length(LObjectList));
          for LFor := 0 to Length(LObjectList) - 1 do
            LValues[LFor] := LObjectList[LFor];
            
          Result := TValue.FromArray(AArrayType.Handle, LValues);
        except
          for LObject in LObjectList do
            if Assigned(LObject) then
              LObject.Free;
          raise;
        end;
      end;
    tkDynArray:
      begin
        SetLength(LNested, AJSONArray.Count);
        for LFor := 0 to AJSONArray.Count - 1 do
        begin
          if Supports(AJSONArray.GetItem(LFor), IJSONArray, LNestedArray) then
            LNested[LFor] := _CreateNestedArray(AArrayType.ElementType as TRttiDynamicArrayType, LNestedArray);
        end;
        Result := TValue.FromArray(AArrayType.Handle, LNested);
      end;
    else
      Result := TValue.FromArray(AArrayType.Handle, []);
  end;
end;

procedure TJSONSerializer._JSONToProperty(const AProperty: TRttiProperty; const AInstance: TObject;
  const AElement: IJSONElement);
var
  LValue: TValue;
  LObject: TObject;
  LArray: IJSONArray;
  LValueInterface: IJSONValue;
  LArrayType: TRttiDynamicArrayType;
  LFor: Integer;
  LMiddle: IEventMiddleware;
  LSetMiddle: ISetValueMiddleware;
  LResult: Variant;
  LBreak: Boolean;
  LIntValue: Integer;
begin
  if not Assigned(AInstance) then
    raise EArgumentNilException.Create('Instance cannot be nil');
  if not AProperty.IsWritable then
    Exit;
  // Middlewares
  for LFor := 0 to FMiddlewares.Count - 1 do
  begin
    LMiddle := FMiddlewares[LFor];
    if Supports(LMiddle, ISetValueMiddleware, LSetMiddle) then
    begin
      LBreak := False;
      LResult := _JSONToVariant(AElement);
      LSetMiddle.SetValue(AInstance, AProperty, LResult, LBreak);
      if LBreak then
        Exit;
    end;
  end;

  if not Assigned(AElement) or (AElement is TJSONValueNull) then
  begin
    case AProperty.PropertyType.TypeKind of
      tkInteger, tkInt64: AProperty.SetValue(AInstance, 0);
      tkFloat: AProperty.SetValue(AInstance, 0.0);
      tkString, tkLString, tkWString, tkUString: AProperty.SetValue(AInstance, '');
      tkEnumeration:
        if AProperty.PropertyType.Handle = TypeInfo(Boolean) then
          AProperty.SetValue(AInstance, False);
      tkClass: AProperty.SetValue(AInstance, nil);
      tkDynArray: AProperty.SetValue(AInstance, TValue.FromArray(AProperty.PropertyType.Handle, []));
    end;
    Exit;
  end;

  case AProperty.PropertyType.TypeKind of
    tkInteger, tkInt64:
      if Supports(AElement, IJSONValue, LValueInterface) then
        if LValueInterface is TJSONValueInteger then
          AProperty.SetValue(AInstance, TJSONValueInteger(LValueInterface).Value);
    tkFloat:
      if Supports(AElement, IJSONValue, LValueInterface) then
      begin
        // Monta a mensagem só com log ativo — o argumento era avaliado sempre
        // (3 concatenações + AsJSON) para cada propriedade float/date.
        if Assigned(FLogProc) then
          _Log('Property: ' + AProperty.Name + ', Class: ' + AInstance.ClassName + ', Value: ' + LValueInterface.AsJSON);
        if LValueInterface is TJSONValueDateTime then
          AProperty.SetValue(AInstance, TJSONValueDateTime(LValueInterface).Value)
        else if LValueInterface is TJSONValueFloat then
          AProperty.SetValue(AInstance, TJSONValueFloat(LValueInterface).Value)
        else if LValueInterface is TJSONValueNull then
          _Log('Warning: Date received as null, expected string');
      end;
    tkString, tkLString, tkWString, tkUString:
      if Supports(AElement, IJSONValue, LValueInterface) then
        if LValueInterface is TJSONValueString then
          AProperty.SetValue(AInstance, TJSONValueString(LValueInterface).Value);
    tkEnumeration:
      if AProperty.PropertyType.Handle = TypeInfo(Boolean) then
      begin
        if Supports(AElement, IJSONValue, LValueInterface) then
          if LValueInterface is TJSONValueBoolean then
            AProperty.SetValue(AInstance, TJSONValueBoolean(LValueInterface).Value);
      end
      else
      begin
        if Supports(AElement, IJSONValue, LValueInterface) then
        begin
          LIntValue := GetEnumValue(AProperty.PropertyType.Handle, LValueInterface.AsString);
          if LIntValue <> -1 then
            AProperty.SetValue(AInstance, TValue.FromOrdinal(AProperty.PropertyType.Handle, LIntValue));
        end;
      end;
    tkClass:
      begin
        LObject := AProperty.GetValue(AInstance).AsObject;
        if Assigned(LObject) and Supports(AElement, IJSONObject) then
          ToObject(AElement, LObject);
      end;
    tkDynArray:
      begin
        if Supports(AElement, IJSONArray, LArray) then
        begin
          LArrayType := AProperty.PropertyType as TRttiDynamicArrayType;
          LValue := _CreateNestedArray(LArrayType, LArray);
          if LValue.IsArray then
            AProperty.SetValue(AInstance, LValue);
        end;
      end;
  end;
end;

function TJSONSerializer._JSONToVariant(const AElement: IJSONElement): Variant;
var
  LValue: IJSONValue;
begin
  if Supports(AElement, IJSONValue, LValue) then
  begin
    if LValue is TJSONValueString then
      Result := TJSONValueString(LValue).Value
    else if LValue is TJSONValueInteger then
      Result := TJSONValueInteger(LValue).Value
    else if LValue is TJSONValueFloat then
      Result := TJSONValueFloat(LValue).Value
    else if LValue is TJSONValueBoolean then
      Result := TJSONValueBoolean(LValue).Value
    else if LValue is TJSONValueDateTime then
      Result := TJSONValueDateTime(LValue).AsString
    else if LValue is TJSONValueNull then
      Result := Null
    else
      Result := LValue.AsString;
  end
  else if Supports(AElement, IJSONObject) then
    Result := AElement.AsJSON
  else if Supports(AElement, IJSONArray) then
    Result := AElement.AsJSON
  else
    Result := Null;
end;

function TJSONSerializer._JSONToElement(const AValue: Variant): IJSONElement;
begin
  case TVarData(AValue).VType of
    varString, varUString: Result := TJSONValueString.Create(VarToStr(AValue));
    varInteger, varInt64: Result := TJSONValueInteger.Create(Int64(AValue));
    varDouble: Result := TJSONValueFloat.Create(Double(AValue), FFormatSettings);
    varBoolean: Result := TJSONValueBoolean.Create(Boolean(AValue));
    varNull: Result := TJSONValueNull.Create;
    else
      raise Exception.Create('Unsupported variant type');
  end;
end;
function TJSONSerializer.FromObject(AObject: TObject; AStoreClassName: Boolean): IJSONElement;
var
  LClass: TClass;
  LTypeInfo: TPair<TRttiType, TList<TRttiProperty>>;
  LProp: TRttiProperty;
  LJsonObj: IJSONObject;
  LElement: IJSONElement;
  LPropName: string;
begin
  if not Assigned(AObject) then
    raise EArgumentNilException.Create('Object cannot be nil');

  LClass := AObject.ClassType;
  LTypeInfo := _GetCachedType(LClass);

  LJsonObj := TJSONObject.Create;
  try
    if AStoreClassName then
      LJsonObj.Add('$class', TJSONValueString.Create(LClass.ClassName));

    for LProp in LTypeInfo.Value do
    begin
      if FOptions.ProcessAttributes then
      begin
        if TJSONAttributeHelper.ShouldIgnoreProperty(LProp) then
          Continue;

        if not TJSONAttributeHelper.ShouldIncludeValue(LProp, LProp.GetValue(AObject)) then
          Continue;

        LPropName := TJSONAttributeHelper.GetJSONPropertyName(LProp);
      end
      else
      begin
        if FOptions.IgnoreNullValues and LProp.GetValue(AObject).IsEmpty then
          Continue;
        LPropName := LProp.Name;
      end;

      LElement := _JSONFromProperty(LProp, AObject, AStoreClassName);

      if FOptions.IgnoreNullValues and (LElement is TJSONValueNull) then
        Continue;

      LJsonObj.Add(LPropName, LElement);
    end;
    Result := LJsonObj;
  except
    LJsonObj := nil;
    raise;
  end;
end;

procedure TJSONSerializer.OnLog(const ALogProc: TProc<String>);
begin
  FLogProc := ALogProc;
end;

function TJSONSerializer.ToObject(const AElement: IJSONElement; AObject: TObject): Boolean;
var
  LClass: TClass;
  LTypeInfo: TPair<TRttiType, TList<TRttiProperty>>;
  LJsonObj: IJSONObject;
  LProp: TRttiProperty;
  LKey: String;
  LElement: IJSONElement;
  LConverter: IJSONPropertyConverter;
begin
  if not Assigned(AObject) then
    raise EArgumentNilException.Create('Object cannot be nil');
  if not Assigned(AElement) then
    raise EArgumentNilException.Create('Element cannot be nil');

  if not Supports(AElement, IJSONObject, LJsonObj) then
    raise EArgumentException.Create('Element must be a JSON object');

  LClass := AObject.ClassType;
  LTypeInfo := _GetCachedType(LClass);

  for LProp in LTypeInfo.Value do
  begin
    if FOptions.ProcessAttributes then
    begin
      if TJSONAttributeHelper.ShouldIgnoreProperty(LProp) then
        Continue;
      LKey := TJSONAttributeHelper.GetJSONPropertyName(LProp);
    end
    else
      LKey := LProp.Name;

    // TryGetValue único — antes eram dois lookups (ContainsKey + GetValue)
    if LJsonObj.TryGetValue(LKey, LElement) then
    begin
      if FOptions.ProcessAttributes then
      begin
        LConverter := TJSONAttributeHelper.GetCustomConverter(LProp);
        if Assigned(LConverter) then
        begin
          LProp.SetValue(AObject, LConverter.FromJSON(LElement, LProp));
          Continue;
        end;
      end;

      _JSONToProperty(LProp, AObject, LElement);
    end;
  end;
  Result := True;
end;

procedure TJSONSerializer._AppendEscapedString(const AValue: string; ABuilder: TStringBuilder);
var
  LFor: Integer;
  LStart: Integer;
  LLen: Integer;
  LChar: Char;
begin
  // Fast-path: a imensa maioria das strings não tem nada a escapar — copia
  // trechos "limpos" em bloco direto no builder de destino, sem builder
  // intermediário nem string temporária (antes: 1 TStringBuilder + 1 cópia
  // por valor string serializado).
  LLen := Length(AValue);
  LStart := 1;
  for LFor := 1 to LLen do
  begin
    LChar := AValue[LFor];
    if (LChar = '"') or (LChar = '\') or (LChar < #32) then
    begin
      if LFor > LStart then
        ABuilder.Append(AValue, LStart - 1, LFor - LStart);
      case LChar of
        '"': ABuilder.Append('\"');
        '\': ABuilder.Append('\\');
        #8: ABuilder.Append('\b');
        #9: ABuilder.Append('\t');
        #10: ABuilder.Append('\n');
        #12: ABuilder.Append('\f');
        #13: ABuilder.Append('\r');
        else
          ABuilder.Append('\u00').Append(IntToHex(Ord(LChar), 2));
      end;
      LStart := LFor + 1;
    end;
  end;
  if LStart = 1 then
    ABuilder.Append(AValue)
  else if LStart <= LLen then
    ABuilder.Append(AValue, LStart - 1, LLen - LStart + 1);
end;

procedure TJSONSerializer._WriteTValue(const AValue: TValue; ABuilder: TStringBuilder; const AStoreClassName: Boolean);
var
  LObj: TObject;
  LFor: Integer;
  LArrayLen: Integer;
  LTypeInfo: PTypeInfo;
  LDouble: Double;
  LDate: TDateTime;
begin
  case AValue.Kind of
    tkInteger, tkInt64:
      ABuilder.Append(AValue.AsInt64);
    tkFloat:
      begin
        LTypeInfo := AValue.TypeInfo;
        if (LTypeInfo = TypeInfo(TDateTime)) or (LTypeInfo = TypeInfo(TDate)) or (LTypeInfo = TypeInfo(TTime)) then
        begin
          LDate := AValue.AsExtended;
          ABuilder.Append('"');
          if FUseISO8601DateFormat then
            ABuilder.Append(DateTimeToIso8601(LDate, True))
          else if FOptions.DateTimeFormat <> '' then
            ABuilder.Append(FormatDateTime(FOptions.DateTimeFormat, LDate))
          else
            ABuilder.Append(DateTimeToIso8601(LDate, True));
          ABuilder.Append('"');
        end
        else
        begin
          LDouble := AValue.AsExtended;
          ABuilder.Append(FormatFloat(FOptions.FloatFormat, LDouble, FFormatSettings));
        end;
      end;
    tkChar, tkWChar, tkLString, tkWString, tkUString:
      begin
        ABuilder.Append('"');
        _AppendEscapedString(AValue.AsString, ABuilder);
        ABuilder.Append('"');
      end;
    tkEnumeration:
      begin
        if AValue.TypeInfo = TypeInfo(Boolean) then
        begin
          if AValue.AsBoolean then
            ABuilder.Append('true')
          else
            ABuilder.Append('false');
        end
        else
        begin
          ABuilder.Append('"');
          ABuilder.Append(GetEnumName(AValue.TypeInfo, AValue.AsOrdinal));
          ABuilder.Append('"');
        end;
      end;
    tkClass:
      begin
        LObj := AValue.AsObject;
        if not Assigned(LObj) then
          ABuilder.Append('null')
        else
          _WriteObject(LObj, ABuilder, AStoreClassName);
      end;
    tkDynArray:
      begin
        LArrayLen := AValue.GetArrayLength;
        ABuilder.Append('[');
        for LFor := 0 to LArrayLen - 1 do
        begin
          if LFor > 0 then
            ABuilder.Append(',');
          _WriteTValue(AValue.GetArrayElement(LFor), ABuilder, AStoreClassName);
        end;
        ABuilder.Append(']');
      end;
    else
      ABuilder.Append('null');
  end;
end;

procedure TJSONSerializer._WriteObject(AObject: TObject; ABuilder: TStringBuilder; const AStoreClassName: Boolean);
var
  LClass: TClass;
  LTypeInfo: TPair<TRttiType, TList<TRttiProperty>>;
  LProp: TRttiProperty;
  LPropName: string;
  LValue: TValue;
  LFirst: Boolean;
begin
  if not Assigned(AObject) then
  begin
    ABuilder.Append('null');
    Exit;
  end;

  LClass := AObject.ClassType;
  LTypeInfo := _GetCachedType(LClass);

  ABuilder.Append('{');
  LFirst := True;

  if AStoreClassName then
  begin
    ABuilder.Append('"$class":"');
    ABuilder.Append(LClass.ClassName);
    ABuilder.Append('"');
    LFirst := False;
  end;

  for LProp in LTypeInfo.Value do
  begin
    LValue := LProp.GetValue(AObject);

    if FOptions.IgnoreNullValues and LValue.IsEmpty then
      Continue;

    if FOptions.ProcessAttributes then
    begin
      if TJSONAttributeHelper.ShouldIgnoreProperty(LProp) then
        Continue;
      if not TJSONAttributeHelper.ShouldIncludeValue(LProp, LValue) then
        Continue;
      LPropName := TJSONAttributeHelper.GetJSONPropertyName(LProp);
    end
    else
      LPropName := LProp.Name;

    if not LFirst then
      ABuilder.Append(',');
    LFirst := False;

    ABuilder.Append('"');
    ABuilder.Append(LPropName);
    ABuilder.Append('":');

    _WriteTValue(LValue, ABuilder, AStoreClassName);
  end;
  ABuilder.Append('}');
end;

function TJSONSerializer.SerializeToString(AObject: TObject; AStoreClassName: Boolean): string;
var
  LBuilder: TStringBuilder;
begin
  // Capacidade inicial evita a escada de realocações (16 chars dobrando até
  // centenas de KB) em documentos grandes; 4KB é irrisório para os pequenos.
  LBuilder := TStringBuilder.Create(4096);
  try
    _WriteObject(AObject, LBuilder, AStoreClassName);
    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

procedure TJSONSerializer.SerializeToStream(AObject: TObject; AStream: TStream; AStoreClassName: Boolean);
var
  LStr: string;
  LBytes: TBytes;
begin
  LStr := SerializeToString(AObject, AStoreClassName);
  LBytes := TEncoding.UTF8.GetBytes(LStr);
  if Length(LBytes) > 0 then
    AStream.WriteBuffer(LBytes[0], Length(LBytes));
end;

{ TJSONSerializerFactory }

class function TJSONSerializerFactory.CreateSerializer(const AOptions: TJSONSerializerOptions): TJSONSerializer;
begin
  Result := TJSONSerializer.Create(AOptions);
end;

class function TJSONSerializerFactory.CreateWithDefaults: TJSONSerializer;
begin
  Result := TJSONSerializer.Create(TJSONSerializerOptions.Default);
end;

class function TJSONSerializerFactory.CreateWithPool: TJSONSerializer;
var
  LOptions: TJSONSerializerOptions;
begin
  LOptions := TJSONSerializerOptions.Default;
  LOptions.UsePool := True;
  Result := TJSONSerializer.Create(LOptions);
end;

class function TJSONSerializerFactory.CreateWithCircularRefDetection: TJSONSerializer;
var
  LOptions: TJSONSerializerOptions;
begin
  LOptions := TJSONSerializerOptions.Default;
  LOptions.DetectCircularReferences := True;
  Result := TJSONSerializer.Create(LOptions);
end;

class function TJSONSerializerFactory.CreateWithAttributes: TJSONSerializer;
var
  LOptions: TJSONSerializerOptions;
begin
  LOptions := TJSONSerializerOptions.Default;
  LOptions.ProcessAttributes := True;
  Result := TJSONSerializer.Create(LOptions);
end;

class function TJSONSerializerFactory.CreateFull: TJSONSerializer;
var
  LOptions: TJSONSerializerOptions;
begin
  LOptions := TJSONSerializerOptions.Default;
  LOptions.UsePool := True;
  LOptions.DetectCircularReferences := True;
  LOptions.ProcessAttributes := True;
  LOptions.IgnoreNullValues := True;
  Result := TJSONSerializer.Create(LOptions);
end;

end.

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
    procedure _CacheType(AClass: TClass);
    procedure _JSONToProperty(const AProperty: TRttiProperty; const AInstance: TObject;
      const AElement: IJSONElement);
    function _JSONFromProperty(const AProperty: TRttiProperty; const AInstance: TObject;
      const AStoreClassName: Boolean): IJSONElement;
    function _CreateNestedArray(const AArrayType: TRttiDynamicArrayType;
      const AJSONArray: IJSONArray): TValue;
    function _JSONToVariant(const AElement: IJSONElement): Variant;
    function _JSONToElement(const AValue: Variant): IJSONElement;
  public
    constructor Create; overload;
    constructor Create(const AFormatSettings: TFormatSettings; const AUseISO8601DateFormat: Boolean = True); overload;
    constructor Create(const AOptions: TJSONSerializerOptions); overload;
    destructor Destroy; override;
    function FromObject(AObject: TObject; AStoreClassName: Boolean = False): IJSONElement;
    function ToObject(const AElement: IJSONElement; AObject: TObject): Boolean;
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

procedure TJSONSerializer._CacheType(AClass: TClass);
var
  LRttiType: TRttiType;
  LProperties: TList<TRttiProperty>;
  LProp: TRttiProperty;
begin
  if not FTypeCache.ContainsKey(AClass) then
  begin
    LRttiType := FContext.GetType(AClass);
    if not Assigned(LRttiType) then
      raise EInvalidOperation.Create('RTTI not available for class ' + AClass.ClassName);
    LProperties := TList<TRttiProperty>.Create;
    for LProp in LRttiType.GetProperties do
    begin
      if LProp.IsReadable then
      begin
        LProperties.Add(LProp);
      end;
    end;
    FTypeCache.Add(AClass, TPair<TRttiType, TList<TRttiProperty>>.Create(LRttiType, LProperties));
  end;
end;

function TJSONSerializer._JSONFromProperty(const AProperty: TRttiProperty; const AInstance: TObject;
  const AStoreClassName: Boolean): IJSONElement;
var
  LValue: TValue;
  LValueIndex: TValue;
  LObj: TObject;
  LArray: IJSONArray;
  LFor: Integer;
  LMiddle: IEventMiddleware;
  LGetMiddle: IGetValueMiddleware;
  LResult: Variant;
  LBreak: Boolean;
  LTypeInfo: PTypeInfo;
begin
  if not Assigned(AInstance) then
    raise EArgumentNilException.Create('Instance cannot be nil');

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
  case AProperty.PropertyType.TypeKind of
    tkInteger, tkInt64:
      Result := TJSONValueInteger.Create(LValue.AsInt64);
    tkFloat:
      begin
        LTypeInfo := AProperty.PropertyType.Handle;
        if (LTypeInfo = TypeInfo(TDateTime)) or (LTypeInfo = TypeInfo(TDate)) or (LTypeInfo = TypeInfo(TTime)) then
          Result := TJSONValueDateTime.Create(AProperty.GetValue(AInstance).AsExtended)
        else
          case GetTypeData(LTypeInfo)^.FloatType of
            ftSingle:
              Result := TJSONValueFloat.Create(StrToFloat(LValue.AsString, FFormatSettings), FFormatSettings);
            ftDouble:
              Result := TJSONValueFloat.Create(LValue.AsExtended, FFormatSettings);
            ftExtended:
              Result := TJSONValueFloat.Create(LValue.AsExtended, FFormatSettings);
            ftComp:
              Result := TJSONValueFloat.Create(LValue.AsExtended, FFormatSettings);
            ftCurr:
              Result := TJSONValueFloat.Create(LValue.AsCurrency, FFormatSettings);
          end;
      end;
    tkString, tkLString, tkWString, tkUString:
      Result := TJSONValueString.Create(LValue.AsString);
    tkEnumeration:
      if AProperty.PropertyType.Handle = TypeInfo(Boolean) then
        Result := TJSONValueBoolean.Create(LValue.AsBoolean)
      else
        Result := TJSONValueString.Create(LValue.ToString);
    tkClass:
      begin
        LObj := LValue.AsObject;
        if Assigned(LObj) then
          Result := FromObject(LObj, AStoreClassName)
        else
          Result := TJSONValueNull.Create;
      end;
    tkDynArray:
      begin
        LArray := TJSONArray.Create;
        for LFor := 0 to LValue.GetArrayLength - 1 do
        begin
          LValueIndex := LValue.GetArrayElement(LFor);
          case LValueIndex.Kind of
            tkInteger, tkInt64:
              LArray.Add(TJSONValueInteger.Create(LValueIndex.AsInt64));
            tkFloat:
              LArray.Add(TJSONValueFloat.Create(LValueIndex.AsExtended, FFormatSettings));
            tkString, tkLString, tkWString, tkUString:
              LArray.Add(TJSONValueString.Create(LValueIndex.AsString));
            tkEnumeration:
              if LValueIndex.TypeInfo = TypeInfo(Boolean) then
                LArray.Add(TJSONValueBoolean.Create(LValueIndex.AsBoolean))
              else
                LArray.Add(TJSONValueString.Create(LValueIndex.ToString));
            tkClass:
              begin
                LObj := LValueIndex.AsObject;
                if Assigned(LObj) then
                  LArray.Add(FromObject(LObj, AStoreClassName))
                else
                  LArray.Add(TJSONValueNull.Create);
              end;
            tkDynArray:
              LArray.Add(_JSONFromProperty(AProperty, LValueIndex.AsObject, AStoreClassName));
            else
              LArray.Add(TJSONValueNull.Create);
          end;
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
        for LFor := 0 to AJSONArray.Count - 1 do
          if Supports(AJSONArray.GetItem(LFor), IJSONObject) then
          begin
            LObject := AArrayType.ElementType.AsInstance.MetaclassType.Create;
            try
              ToObject(AJSONArray.GetItem(LFor), LObject);
              LObjectList[LFor] := LObject;
            except
              LObject.Free;
              raise;
            end;
          end;
        try
          Result := TValue.From<TArray<TObject>>(LObjectList);
        finally
          for LObject in LObjectList do
            if Assigned(LObject) then
              LObject.Free;
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
begin
  if not AProperty.IsWritable then
    Exit;
  if not Assigned(AInstance) then
    raise EArgumentNilException.Create('Instance cannot be nil');

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
        if Supports(AElement, IJSONValue, LValueInterface) then
          if LValueInterface is TJSONValueBoolean then
            AProperty.SetValue(AInstance, TJSONValueBoolean(LValueInterface).Value);
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
          begin
            if LArrayType.ElementType.TypeKind = tkDynArray then
              AProperty.SetValue(AInstance, LValue)
            else if LArrayType.ElementType.TypeKind = tkFloat then
              AProperty.SetValue(AInstance, LValue)
            else
              AProperty.SetValue(AInstance, LValue);
          end;
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
begin
  if not Assigned(AObject) then
    raise EArgumentNilException.Create('Object cannot be nil');

  LClass := AObject.ClassType;
  _CacheType(LClass);
  LTypeInfo := FTypeCache[LClass];

  LJsonObj := TJSONObject.Create;
  try
    if AStoreClassName then
      LJsonObj.Add('$class', TJSONValueString.Create(LClass.ClassName));

    for LProp in LTypeInfo.Value do
    begin
      LElement := _JSONFromProperty(LProp, AObject, AStoreClassName);
      LJsonObj.Add(LProp.Name, LElement);
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
begin
  if not Assigned(AObject) then
    raise EArgumentNilException.Create('Object cannot be nil');
  if not Assigned(AElement) then
    raise EArgumentNilException.Create('Element cannot be nil');

  if not Supports(AElement, IJSONObject, LJsonObj) then
    raise EArgumentException.Create('Element must be a JSON object');

  LClass := AObject.ClassType;
  _CacheType(LClass);
  LTypeInfo := FTypeCache[LClass];

  for LProp in LTypeInfo.Value do
  begin
    LKey := LProp.Name;
    if LJsonObj.ContainsKey(LKey) then
      _JSONToProperty(LProp, AObject, LJsonObj.GetValue(LKey));
  end;
  Result := True;
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

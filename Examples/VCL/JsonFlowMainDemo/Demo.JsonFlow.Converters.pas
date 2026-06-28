unit Demo.JsonFlow.Converters;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Rtti,
  System.Types,
  System.TypInfo,
  System.Generics.Collections,
  Data.DB,
  Vcl.Graphics,
  JsonFlow.Interfaces,
  JsonFlow.Serializer.Attributes,
  JsonFlow.Value,
  JsonFlow.Objects,
  JsonFlow.Arrays;

type
  // GUID Converter
  TGUIDConverter = class(TInterfacedObject, IJSONPropertyConverter)
  public
    function ToJSON(const AValue: TValue; const AProperty: TRttiProperty): IJSONElement;
    function FromJSON(const AElement: IJSONElement; const AProperty: TRttiProperty): TValue;
  end;

  // TFont Converter
  TFontConverter = class(TInterfacedObject, IJSONPropertyConverter)
  public
    function ToJSON(const AValue: TValue; const AProperty: TRttiProperty): IJSONElement;
    function FromJSON(const AElement: IJSONElement; const AProperty: TRttiProperty): TValue;
  end;

  // TPoint3D (X, Y, Z) Converter
  TPoint3D = record
    X, Y, Z: Single;
    constructor Create(AX, AY, AZ: Single);
  end;

  TPoint3DConverter = class(TInterfacedObject, IJSONPropertyConverter)
  public
    function ToJSON(const AValue: TValue; const AProperty: TRttiProperty): IJSONElement;
    function FromJSON(const AElement: IJSONElement; const AProperty: TRttiProperty): TValue;
  end;

  // TSetSpeed Converter
  TSetSpeedConverter = class(TInterfacedObject, IJSONPropertyConverter)
  public
    function ToJSON(const AValue: TValue; const AProperty: TRttiProperty): IJSONElement;
    function FromJSON(const AElement: IJSONElement; const AProperty: TRttiProperty): TValue;
  end;

  // TSetWeekDays Converter
  TSetWeekDaysConverter = class(TInterfacedObject, IJSONPropertyConverter)
  public
    function ToJSON(const AValue: TValue; const AProperty: TRttiProperty): IJSONElement;
    function FromJSON(const AElement: IJSONElement; const AProperty: TRttiProperty): TValue;
  end;

  // TVector3f Converter
  TVector3fConverter = class(TInterfacedObject, IJSONPropertyConverter)
  public
    function ToJSON(const AValue: TValue; const AProperty: TRttiProperty): IJSONElement;
    function FromJSON(const AElement: IJSONElement; const AProperty: TRttiProperty): TValue;
  end;

  // TStringList Converter
  TStringListConverter = class(TInterfacedObject, IJSONPropertyConverter)
  public
    function ToJSON(const AValue: TValue; const AProperty: TRttiProperty): IJSONElement;
    function FromJSON(const AElement: IJSONElement; const AProperty: TRttiProperty): TValue;
  end;

  // TDataSet Converter
  TDataSetConverter = class(TInterfacedObject, IJSONPropertyConverter)
  public
    function ToJSON(const AValue: TValue; const AProperty: TRttiProperty): IJSONElement;
    function FromJSON(const AElement: IJSONElement; const AProperty: TRttiProperty): TValue;
  end;

  // TNoteItemListConverter
  TNoteItemListConverter = class(TInterfacedObject, IJSONPropertyConverter)
  public
    function ToJSON(const AValue: TValue; const AProperty: TRttiProperty): IJSONElement;
    function FromJSON(const AElement: IJSONElement; const AProperty: TRttiProperty): TValue;
  end;

  // TNoteItemDictionaryConverter
  TNoteItemDictionaryConverter = class(TInterfacedObject, IJSONPropertyConverter)
  public
    function ToJSON(const AValue: TValue; const AProperty: TRttiProperty): IJSONElement;
    function FromJSON(const AElement: IJSONElement; const AProperty: TRttiProperty): TValue;
  end;

implementation

uses
  JsonFlow.Serializer,
  JsonFlow.Converter.Dataset,
  FireDAC.Comp.Client,
  Demo.JsonFlow.Entities;

{ TGUIDConverter }

function TGUIDConverter.ToJSON(const AValue: TValue; const AProperty: TRttiProperty): IJSONElement;
var
  LGUID: TGUID;
begin
  LGUID := AValue.AsType<TGUID>;
  Result := TJSONValueString.Create(GUIDToString(LGUID));
end;

function TGUIDConverter.FromJSON(const AElement: IJSONElement; const AProperty: TRttiProperty): TValue;
var
  LValueStr: string;
begin
  if Assigned(AElement) and (AElement is TJSONValueString) then
  begin
    LValueStr := TJSONValueString(AElement).Value;
    Result := TValue.From<TGUID>(StringToGUID(LValueStr));
  end
  else
    Result := TValue.From<TGUID>(StringToGUID('{00000000-0000-0000-0000-000000000000}'));
end;

{ TFontConverter }

function TFontConverter.ToJSON(const AValue: TValue; const AProperty: TRttiProperty): IJSONElement;
var
  LFont: TFont;
  LObj: IJSONObject;
  LStyles: IJSONArray;
  LStyle: TFontStyle;
begin
  LFont := TFont(AValue.AsObject);
  LObj := TJSONObject.Create;
  if Assigned(LFont) then
  begin
    LObj.Add('Name', TJSONValueString.Create(LFont.Name));
    LObj.Add('Size', TJSONValueInteger.Create(LFont.Size));
    LObj.Add('Color', TJSONValueInteger.Create(LFont.Color));
    
    LStyles := TJSONArray.Create;
    for LStyle := fsBold to fsStrikeOut do
    begin
      if LStyle in LFont.Style then
        LStyles.Add(TJSONValueString.Create(GetEnumName(TypeInfo(TFontStyle), Ord(LStyle))));
    end;
    LObj.Add('Style', LStyles);
  end;
  Result := LObj;
end;

function TFontConverter.FromJSON(const AElement: IJSONElement; const AProperty: TRttiProperty): TValue;
var
  LFont: TFont;
  LObj: IJSONObject;
  LElem: IJSONElement;
  LVal: IJSONValue;
  LStylesArr: IJSONArray;
  LFor: Integer;
  LStyle: TFontStyle;
  LStyleName: string;
  LStyleSet: TFontStyles;
begin
  LFont := TFont.Create;
  try
    LStyleSet := [];
    if Assigned(AElement) and Supports(AElement, IJSONObject, LObj) then
    begin
      if LObj.ContainsKey('Name') then
      begin
        LElem := LObj.GetValue('Name');
        if Supports(LElem, IJSONValue, LVal) then
          LFont.Name := LVal.AsString;
      end;
      if LObj.ContainsKey('Size') then
      begin
        LElem := LObj.GetValue('Size');
        if Supports(LElem, IJSONValue, LVal) then
          LFont.Size := LVal.AsInteger;
      end;
      if LObj.ContainsKey('Color') then
      begin
        LElem := LObj.GetValue('Color');
        if Supports(LElem, IJSONValue, LVal) then
          LFont.Color := LVal.AsInteger;
      end;
      if LObj.ContainsKey('Style') then
      begin
        LElem := LObj.GetValue('Style');
        if Supports(LElem, IJSONArray, LStylesArr) then
        begin
          for LFor := 0 to LStylesArr.Count - 1 do
          begin
            if Supports(LStylesArr.GetItem(LFor), IJSONValue, LVal) then
            begin
              LStyleName := LVal.AsString;
              LStyle := TFontStyle(GetEnumValue(TypeInfo(TFontStyle), LStyleName));
              Include(LStyleSet, LStyle);
            end;
          end;
          LFont.Style := LStyleSet;
        end;
      end;
    end;
    Result := LFont;
  except
    LFont.Free;
    raise;
  end;
end;

{ TPoint3D }

constructor TPoint3D.Create(AX, AY, AZ: Single);
begin
  X := AX;
  Y := AY;
  Z := AZ;
end;

{ TPoint3DConverter }

function TPoint3DConverter.ToJSON(const AValue: TValue; const AProperty: TRttiProperty): IJSONElement;
var
  LPoint: TPoint3D;
  LObj: IJSONObject;
begin
  LPoint := AValue.AsType<TPoint3D>;
  LObj := TJSONObject.Create;
  LObj.Add('X', TJSONValueFloat.Create(LPoint.X));
  LObj.Add('Y', TJSONValueFloat.Create(LPoint.Y));
  LObj.Add('Z', TJSONValueFloat.Create(LPoint.Z));
  Result := LObj;
end;

function TPoint3DConverter.FromJSON(const AElement: IJSONElement; const AProperty: TRttiProperty): TValue;
var
  LPoint: TPoint3D;
  LObj: IJSONObject;
  LElem: IJSONElement;
  LVal: IJSONValue;
begin
  LPoint.X := 0;
  LPoint.Y := 0;
  LPoint.Z := 0;
  
  if Assigned(AElement) and Supports(AElement, IJSONObject, LObj) then
  begin
    if LObj.ContainsKey('X') then
    begin
      LElem := LObj.GetValue('X');
      if Supports(LElem, IJSONValue, LVal) then
        LPoint.X := LVal.AsFloat;
    end;
    if LObj.ContainsKey('Y') then
    begin
      LElem := LObj.GetValue('Y');
      if Supports(LElem, IJSONValue, LVal) then
        LPoint.Y := LVal.AsFloat;
    end;
    if LObj.ContainsKey('Z') then
    begin
      LElem := LObj.GetValue('Z');
      if Supports(LElem, IJSONValue, LVal) then
        LPoint.Z := LVal.AsFloat;
    end;
  end;
  
  Result := TValue.From<TPoint3D>(LPoint);
end;

{ TSetSpeedConverter }

function TSetSpeedConverter.ToJSON(const AValue: TValue; const AProperty: TRttiProperty): IJSONElement;
var
  LSetVal: TSetSpeed;
  LSet: Byte;
  LArray: IJSONArray;
  LSpeed: TEnumSpeed;
begin
  LSetVal := AValue.AsType<TSetSpeed>;
  LSet := Byte(LSetVal);
  LArray := TJSONArray.Create;
  for LSpeed := TEnumSpeed.Low to TEnumSpeed.High do
  begin
    if (LSet and (1 shl Ord(LSpeed))) <> 0 then
      LArray.Add(TJSONValueString.Create(GetEnumName(TypeInfo(TEnumSpeed), Ord(LSpeed))));
  end;
  Result := LArray;
end;

function TSetSpeedConverter.FromJSON(const AElement: IJSONElement; const AProperty: TRttiProperty): TValue;
var
  LArray: IJSONArray;
  LFor: Integer;
  LElem: IJSONElement;
  LVal: IJSONValue;
  LSpeed: TEnumSpeed;
  LSet: Byte;
  LSpeedName: string;
begin
  LSet := 0;
  if Assigned(AElement) and Supports(AElement, IJSONArray, LArray) then
  begin
    for LFor := 0 to LArray.Count - 1 do
    begin
      LElem := LArray.GetItem(LFor);
      if Supports(LElem, IJSONValue, LVal) then
      begin
        LSpeedName := LVal.AsString;
        LSpeed := TEnumSpeed(GetEnumValue(TypeInfo(TEnumSpeed), LSpeedName));
        LSet := LSet or (1 shl Ord(LSpeed));
      end;
    end;
  end;
  Result := TValue.From<TSetSpeed>(TSetSpeed(LSet));
end;

{ TSetWeekDaysConverter }

function TSetWeekDaysConverter.ToJSON(const AValue: TValue; const AProperty: TRttiProperty): IJSONElement;
var
  LSetVal: TSetWeekDays;
  LSet: Byte;
  LArray: IJSONArray;
  LDay: Integer;
begin
  LSetVal := AValue.AsType<TSetWeekDays>;
  LSet := Byte(LSetVal);
  LArray := TJSONArray.Create;
  for LDay := 1 to 7 do
  begin
    if (LSet and (1 shl LDay)) <> 0 then
      LArray.Add(TJSONValueInteger.Create(LDay));
  end;
  Result := LArray;
end;

function TSetWeekDaysConverter.FromJSON(const AElement: IJSONElement; const AProperty: TRttiProperty): TValue;
var
  LArray: IJSONArray;
  LFor: Integer;
  LElem: IJSONElement;
  LVal: IJSONValue;
  LDay: Integer;
  LSet: Byte;
begin
  LSet := 0;
  if Assigned(AElement) and Supports(AElement, IJSONArray, LArray) then
  begin
    for LFor := 0 to LArray.Count - 1 do
    begin
      LElem := LArray.GetItem(LFor);
      if Supports(LElem, IJSONValue, LVal) then
      begin
        LDay := LVal.AsInteger;
        if (LDay >= 1) and (LDay <= 7) then
          LSet := LSet or (1 shl LDay);
      end;
    end;
  end;
  Result := TValue.From<TSetWeekDays>(TSetWeekDays(LSet));
end;

{ TVector3fConverter }

function TVector3fConverter.ToJSON(const AValue: TValue; const AProperty: TRttiProperty): IJSONElement;
var
  LVec: TVector3f;
  LObj: IJSONObject;
begin
  LVec := AValue.AsType<TVector3f>;
  LObj := TJSONObject.Create;
  LObj.Add('X', TJSONValueFloat.Create(LVec.X));
  LObj.Add('Y', TJSONValueFloat.Create(LVec.Y));
  LObj.Add('Z', TJSONValueFloat.Create(LVec.Z));
  Result := LObj;
end;

function TVector3fConverter.FromJSON(const AElement: IJSONElement; const AProperty: TRttiProperty): TValue;
var
  LVec: TVector3f;
  LObj: IJSONObject;
  LElem: IJSONElement;
  LVal: IJSONValue;
begin
  LVec.X := 0; LVec.Y := 0; LVec.Z := 0;
  if Assigned(AElement) and Supports(AElement, IJSONObject, LObj) then
  begin
    if LObj.ContainsKey('X') then
    begin
      LElem := LObj.GetValue('X');
      if Supports(LElem, IJSONValue, LVal) then LVec.X := LVal.AsFloat;
    end;
    if LObj.ContainsKey('Y') then
    begin
      LElem := LObj.GetValue('Y');
      if Supports(LElem, IJSONValue, LVal) then LVec.Y := LVal.AsFloat;
    end;
    if LObj.ContainsKey('Z') then
    begin
      LElem := LObj.GetValue('Z');
      if Supports(LElem, IJSONValue, LVal) then LVec.Z := LVal.AsFloat;
    end;
  end;
  Result := TValue.From<TVector3f>(LVec);
end;

{ TStringListConverter }

function TStringListConverter.ToJSON(const AValue: TValue; const AProperty: TRttiProperty): IJSONElement;
var
  LList: TStringList;
  LArray: IJSONArray;
  I: Integer;
begin
  LList := TStringList(AValue.AsObject);
  LArray := TJSONArray.Create;
  if Assigned(LList) then
  begin
    for I := 0 to LList.Count - 1 do
      LArray.Add(TJSONValueString.Create(LList[I]));
  end;
  Result := LArray;
end;

function TStringListConverter.FromJSON(const AElement: IJSONElement; const AProperty: TRttiProperty): TValue;
var
  LList: TStringList;
  LArray: IJSONArray;
  I: Integer;
  LVal: IJSONValue;
begin
  LList := TStringList.Create;
  try
    if Assigned(AElement) and Supports(AElement, IJSONArray, LArray) then
    begin
      for I := 0 to LArray.Count - 1 do
      begin
        if Supports(LArray.GetItem(I), IJSONValue, LVal) then
          LList.Add(LVal.AsString);
      end;
    end;
    Result := LList;
  except
    LList.Free;
    raise;
  end;
end;

{ TDataSetConverter }

function TDataSetConverter.ToJSON(const AValue: TValue; const AProperty: TRttiProperty): IJSONElement;
var
  LDataSet: TDataSet;
  LConverter: TJSONDatasetConverter;
  LOptions: TDatasetToJSONOptions;
begin
  LDataSet := TDataSet(AValue.AsObject);
  if not Assigned(LDataSet) then
    Exit(TJSONValueNull.Create);

  LOptions := TDatasetToJSONOptions.Default;
  LConverter := TJSONDatasetConverter.Create(LOptions);
  try
    Result := LConverter.DatasetToJSONArray(LDataSet);
  finally
    LConverter.Free;
  end;
end;

function TDataSetConverter.FromJSON(const AElement: IJSONElement; const AProperty: TRttiProperty): TValue;
var
  LArray: IJSONArray;
  LMemTable: TFDMemTable;
  LConverter: TJSONDatasetConverter;
  LOptions: TDatasetToJSONOptions;
begin
  LMemTable := TFDMemTable.Create(nil);
  try
    // Re-create simple structure for demo DataSet loading
    LMemTable.FieldDefs.Add('ID', ftInteger);
    LMemTable.FieldDefs.Add('Description', ftString, 50);
    LMemTable.FieldDefs.Add('Value', ftFloat);
    LMemTable.CreateDataSet;

    if Assigned(AElement) and Supports(AElement, IJSONArray, LArray) then
    begin
      LOptions := TDatasetToJSONOptions.Default;
      LConverter := TJSONDatasetConverter.Create(LOptions);
      try
        LConverter.JSONArrayToDataset(LArray, LMemTable, True);
      finally
        LConverter.Free;
      end;
    end;
    Result := LMemTable;
  except
    LMemTable.Free;
    raise;
  end;
end;

{ TNoteItemListConverter }

function TNoteItemListConverter.ToJSON(const AValue: TValue; const AProperty: TRttiProperty): IJSONElement;
var
  LList: TObjectList<TNoteItem>;
  LArray: IJSONArray;
  LItem: TNoteItem;
  LSerializer: TJSONSerializer;
begin
  LList := TObjectList<TNoteItem>(AValue.AsObject);
  LArray := TJSONArray.Create;
  if Assigned(LList) then
  begin
    LSerializer := TJSONSerializer.Create;
    try
      for LItem in LList do
        LArray.Add(LSerializer.FromObject(LItem));
    finally
      LSerializer.Free;
    end;
  end;
  Result := LArray;
end;

function TNoteItemListConverter.FromJSON(const AElement: IJSONElement; const AProperty: TRttiProperty): TValue;
var
  LList: TObjectList<TNoteItem>;
  LArray: IJSONArray;
  I: Integer;
  LItem: TNoteItem;
  LSerializer: TJSONSerializer;
begin
  LList := TObjectList<TNoteItem>.Create(True);
  try
    if Assigned(AElement) and Supports(AElement, IJSONArray, LArray) then
    begin
      LSerializer := TJSONSerializer.Create;
      try
        for I := 0 to LArray.Count - 1 do
        begin
          LItem := TNoteItem.Create;
          try
            LSerializer.ToObject(LArray.GetItem(I), LItem);
            LList.Add(LItem);
          except
            LItem.Free;
            raise;
          end;
        end;
      finally
        LSerializer.Free;
      end;
    end;
    Result := LList;
  except
    LList.Free;
    raise;
  end;
end;

{ TNoteItemDictionaryConverter }

function TNoteItemDictionaryConverter.ToJSON(const AValue: TValue; const AProperty: TRttiProperty): IJSONElement;
var
  LDict: TObjectDictionary<string, TNoteItem>;
  LObj: IJSONObject;
  LPair: TPair<string, TNoteItem>;
  LSerializer: TJSONSerializer;
begin
  LDict := TObjectDictionary<string, TNoteItem>(AValue.AsObject);
  LObj := TJSONObject.Create;
  if Assigned(LDict) then
  begin
    LSerializer := TJSONSerializer.Create;
    try
      for LPair in LDict do
        LObj.Add(LPair.Key, LSerializer.FromObject(LPair.Value));
    finally
      LSerializer.Free;
    end;
  end;
  Result := LObj;
end;

function TNoteItemDictionaryConverter.FromJSON(const AElement: IJSONElement; const AProperty: TRttiProperty): TValue;
var
  LDict: TObjectDictionary<string, TNoteItem>;
  LObj: IJSONObject;
  LSerializer: TJSONSerializer;
begin
  LDict := TObjectDictionary<string, TNoteItem>.Create([doOwnsValues]);
  try
    if Assigned(AElement) and Supports(AElement, IJSONObject, LObj) then
    begin
      LSerializer := TJSONSerializer.Create;
      try
        LObj.ForEach(procedure(AKey: string; AVal: IJSONElement)
          var
            LItem: TNoteItem;
          begin
            LItem := TNoteItem.Create;
            try
              LSerializer.ToObject(AVal, LItem);
              LDict.Add(AKey, LItem);
            except
              LItem.Free;
              raise;
            end;
          end);
      finally
        LSerializer.Free;
      end;
    end;
    Result := LDict;
  except
    LDict.Free;
    raise;
  end;
end;

end.

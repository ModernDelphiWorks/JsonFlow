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

unit JsonFlow.Converter.XML;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Variants,
  System.Generics.Collections,
  Xml.XMLIntf,
  Xml.XMLDoc,
  JsonFlow.Interfaces,
  JsonFlow.Composer,
  JsonFlow.Objects,
  JsonFlow.Arrays,
  JsonFlow.Value;

type
  /// <summary>
  /// Estratégia para tratamento de atributos XML
  /// </summary>
  TAttributeHandling = (
    ahIgnore,        // Ignorar atributos
    ahAsProperties,  // Converter para propriedades com prefixo @
    ahAsMetadata,    // Incluir em seção metadata
    ahMergeWithText  // Mesclar com conteúdo de texto
  );

  /// <summary>
  /// Estratégia para tratamento de namespaces
  /// </summary>
  TNamespaceHandling = (
    nhIgnore,        // Ignorar namespaces
    nhPreserve,      // Preservar como prefixo
    nhAsAttribute,   // Converter para atributo
    nhAsMetadata     // Incluir em metadata
  );

  /// <summary>
  /// Estratégia para elementos vazios
  /// </summary>
  TEmptyElementHandling = (
    eehNull,         // Converter para null
    eehEmptyString,  // Converter para string vazia
    eehEmptyObject,  // Converter para objeto vazio
    eehSkip          // Pular elemento
  );

  /// <summary>
  /// Opções para conversão XML ? JSON
  /// </summary>
  TXMLToJSONOptions = record
    AttributeHandling: TAttributeHandling;
    NamespaceHandling: TNamespaceHandling;
    EmptyElementHandling: TEmptyElementHandling;
    AttributePrefix: string;
    TextNodeName: string;
    ArrayElementName: string;
    PreserveWhitespace: Boolean;
    TrimTextContent: Boolean;
    ConvertNumbers: Boolean;
    ConvertBooleans: Boolean;
    ConvertDates: Boolean;
    DateTimeFormat: string;
    IgnoreComments: Boolean;
    IgnoreProcessingInstructions: Boolean;
    
    class function Default: TXMLToJSONOptions; static;
  end;

  /// <summary>
  /// Opções para conversão JSON ? XML
  /// </summary>
  TJSONToXMLOptions = record
    RootElementName: string;
    ArrayElementName: string;
    AttributePrefix: string;
    TextNodeName: string;
    DefaultNamespace: string;
    IndentXML: Boolean;
    XMLDeclaration: Boolean;
    XMLVersion: string;
    XMLEncoding: string;
    NullElementHandling: TEmptyElementHandling;
    
    class function Default: TJSONToXMLOptions; static;
  end;

  /// <summary>
  /// Mapeamento de elemento XML customizado
  /// </summary>
  TXMLElementMapping = record
    XMLPath: string;
    JSONPath: string;
    ConverterClass: TClass;
    
    constructor Create(const AXMLPath, AJSONPath: string; AConverterClass: TClass = nil);
  end;

  /// <summary>
  /// Interface para conversores de elemento customizados
  /// </summary>
  IXMLElementConverter = interface
    ['{24B64A3D-DFBA-45C2-89C8-EB5434CB7F1D}']
    function XMLToJSON(ANode: IXMLNode): IJSONElement;
    function JSONToXML(AElement: IJSONElement; AParentNode: IXMLNode; const AElementName: string): IXMLNode;
  end;

  /// <summary>
  /// Conversor principal XML ? JSON
  /// </summary>
  TJSONXMLConverter = class
  private
    FComposer: TJSONComposer;
    FXMLToJSONOptions: TXMLToJSONOptions;
    FJSONToXMLOptions: TJSONToXMLOptions;
    FElementMappings: TDictionary<string, TXMLElementMapping>;
    FCustomConverters: TDictionary<string, IXMLElementConverter>;
    FOnProgress: TProc<Integer, Integer>; // Current, Total
  private
    function ProcessXMLNode(ANode: IXMLNode): IJSONElement;
    function ProcessXMLAttributes(ANode: IXMLNode): IJSONObject;
    function GetElementConverter(const AElementName: string): IXMLElementConverter;
    function DetectValueType(const AValue: string): IJSONElement;
    function IsNumeric(const AValue: string): Boolean;
    function IsBoolean(const AValue: string): Boolean;
    function IsDateTime(const AValue: string): Boolean;
    procedure ProcessJSONToXML(AElement: IJSONElement; AParentNode: IXMLNode; const AElementName: string);
    function CreateXMLDocument: IXMLDocument;
    function SanitizeElementName(const AName: string): string;
    function GetNamespaceInfo(ANode: IXMLNode): TPair<string, string>; // Prefix, URI
  public
    constructor Create(const AXMLToJSONOptions: TXMLToJSONOptions; const AJSONToXMLOptions: TJSONToXMLOptions);
    destructor Destroy; override;
    
    // Conversão XML ? JSON
    function XMLToJSON(const AXML: string): string; overload;
    function XMLToJSON(AXMLDocument: IXMLDocument): string; overload;
    function XMLToJSON(AXMLNode: IXMLNode): string; overload;
    function XMLNodeToJSONObject(ANode: IXMLNode): IJSONObject;
    
    // Conversão JSON ? XML
    function JSONToXML(const AJSON: string): string; overload;
    function JSONToXML(AJSONElement: IJSONElement): string; overload;
    function JSONToXMLDocument(const AJSON: string): IXMLDocument; overload;
    function JSONToXMLDocument(AJSONElement: IJSONElement): IXMLDocument; overload;
    
    // Operações específicas
    function XMLSchemaToJSONSchema(const AXMLSchema: string): string;
    function JSONSchemaToXMLSchema(const AJSONSchema: string): string;
    function ValidateXMLAgainstJSON(const AXML, AJSON: string): TArray<string>;
    function ValidateJSONAgainstXML(const AJSON, AXML: string): TArray<string>;
    
    // Processamento de arquivos
    procedure XMLFileToJSONFile(const AXMLFileName, AJSONFileName: string);
    procedure JSONFileToXMLFile(const AJSONFileName, AXMLFileName: string);
    
    // Processamento de streams
    procedure XMLStreamToJSONStream(AXMLStream, AJSONStream: TStream);
    procedure JSONStreamToXMLStream(AJSONStream, AXMLStream: TStream);
    
    // Mapeamentos customizados
    procedure AddElementMapping(const AXMLPath, AJSONPath: string; AConverterClass: TClass = nil);
    procedure RemoveElementMapping(const AXMLPath: string);
    procedure ClearElementMappings;
    
    // Conversores customizados
    procedure AddCustomConverter(const AElementName: string; AConverter: IXMLElementConverter);
    procedure RemoveCustomConverter(const AElementName: string);
    
    // Propriedades
    property XMLToJSONOptions: TXMLToJSONOptions read FXMLToJSONOptions write FXMLToJSONOptions;
    property JSONToXMLOptions: TJSONToXMLOptions read FJSONToXMLOptions write FJSONToXMLOptions;
    property OnProgress: TProc<Integer, Integer> read FOnProgress write FOnProgress;
  end;

  /// <summary>
  /// Conversor para elementos CDATA
  /// </summary>
  TCDATAConverter = class(TInterfacedObject, IXMLElementConverter)
  public
    function XMLToJSON(ANode: IXMLNode): IJSONElement;
    function JSONToXML(AElement: IJSONElement; AParentNode: IXMLNode; const AElementName: string): IXMLNode;
  end;

  /// <summary>
  /// Conversor para elementos com conteúdo misto
  /// </summary>
  TMixedContentConverter = class(TInterfacedObject, IXMLElementConverter)
  public
    function XMLToJSON(ANode: IXMLNode): IJSONElement;
    function JSONToXML(AElement: IJSONElement; AParentNode: IXMLNode; const AElementName: string): IXMLNode;
  end;

  /// <summary>
  /// Conversor para elementos com namespace específico
  /// </summary>
  TNamespaceConverter = class(TInterfacedObject, IXMLElementConverter)
  private
    FNamespaceURI: string;
    FPrefix: string;
  public
    constructor Create(const ANamespaceURI, APrefix: string);
    function XMLToJSON(ANode: IXMLNode): IJSONElement;
    function JSONToXML(AElement: IJSONElement; AParentNode: IXMLNode; const AElementName: string): IXMLNode;
  end;

  /// <summary>
  /// Factory para criação de conversores XML
  /// </summary>
  TXMLConverterFactory = class
  public
    class function CreateConverter(const AXMLToJSONOptions: TXMLToJSONOptions; const AJSONToXMLOptions: TJSONToXMLOptions): TJSONXMLConverter;
    class function CreateWithDefaults: TJSONXMLConverter;
    class function CreateForSOAP: TJSONXMLConverter;
    class function CreateForREST: TJSONXMLConverter;
    class function CreateForConfig: TJSONXMLConverter;
  end;

implementation

uses
  System.StrUtils,
  System.DateUtils,
  System.RegularExpressions;

{ TXMLToJSONOptions }

class function TXMLToJSONOptions.Default: TXMLToJSONOptions;
begin
  Result.AttributeHandling := ahAsProperties;
  Result.NamespaceHandling := nhPreserve;
  Result.EmptyElementHandling := eehNull;
  Result.AttributePrefix := '@';
  Result.TextNodeName := '#text';
  Result.ArrayElementName := 'item';
  Result.PreserveWhitespace := False;
  Result.TrimTextContent := True;
  Result.ConvertNumbers := True;
  Result.ConvertBooleans := True;
  Result.ConvertDates := False;
  Result.DateTimeFormat := 'yyyy-mm-dd"T"hh:nn:ss.zzz"Z"';
  Result.IgnoreComments := True;
  Result.IgnoreProcessingInstructions := True;
end;

{ TJSONToXMLOptions }

class function TJSONToXMLOptions.Default: TJSONToXMLOptions;
begin
  Result.RootElementName := 'root';
  Result.ArrayElementName := 'item';
  Result.AttributePrefix := '@';
  Result.TextNodeName := '#text';
  Result.DefaultNamespace := '';
  Result.IndentXML := True;
  Result.XMLDeclaration := True;
  Result.XMLVersion := '1.0';
  Result.XMLEncoding := 'UTF-8';
  Result.NullElementHandling := eehNull;
end;

{ TXMLElementMapping }

constructor TXMLElementMapping.Create(const AXMLPath, AJSONPath: string; AConverterClass: TClass);
begin
  XMLPath := AXMLPath;
  JSONPath := AJSONPath;
  ConverterClass := AConverterClass;
end;

{ TJSONXMLConverter }

constructor TJSONXMLConverter.Create(const AXMLToJSONOptions: TXMLToJSONOptions; const AJSONToXMLOptions: TJSONToXMLOptions);
begin
  inherited Create;
  FComposer := TJSONComposer.Create;
  FXMLToJSONOptions := AXMLToJSONOptions;
  FJSONToXMLOptions := AJSONToXMLOptions;
  FElementMappings := TDictionary<string, TXMLElementMapping>.Create;
  FCustomConverters := TDictionary<string, IXMLElementConverter>.Create;
end;

destructor TJSONXMLConverter.Destroy;
begin
  FCustomConverters.Free;
  FElementMappings.Free;
  FComposer.Free;
  inherited;
end;

function TJSONXMLConverter.ProcessXMLNode(ANode: IXMLNode): IJSONElement;
var
  LConverter: IXMLElementConverter;
  LObject: IJSONObject;
  LArray: IJSONArray;
  LChildNode: IXMLNode;
  LChildElements: TDictionary<string, TList<IXMLNode>>;
  LElementName: string;
  LElementList: TList<IXMLNode>;
  I: Integer;
  LTextContent: string;
  LHasAttributes: Boolean;
  LHasChildren: Boolean;
begin
  // Verificar conversor customizado
  LConverter := GetElementConverter(ANode.NodeName);
  if Assigned(LConverter) then
  begin
    Result := LConverter.XMLToJSON(ANode);
    Exit;
  end;
  
  // Ignorar comentários e instruções de processamento
  if ((ANode.NodeType = ntComment) and FXMLToJSONOptions.IgnoreComments) or
     ((ANode.NodeType = ntProcessingInstr) and FXMLToJSONOptions.IgnoreProcessingInstructions) then
  begin
    Result := nil;
    Exit;
  end;
  
  // Processar nó de texto
  if ANode.NodeType = ntText then
  begin
    LTextContent := ANode.Text;
    if FXMLToJSONOptions.TrimTextContent then
      LTextContent := Trim(LTextContent);
      
    if (LTextContent = '') and not FXMLToJSONOptions.PreserveWhitespace then
    begin
      Result := nil;
      Exit;
    end;
    
    if FXMLToJSONOptions.ConvertNumbers or FXMLToJSONOptions.ConvertBooleans or FXMLToJSONOptions.ConvertDates then
      Result := DetectValueType(LTextContent)
    else
      Result := TJSONValueString.Create(LTextContent);
    Exit;
  end;
  
  // Verificar se tem atributos e filhos
  LHasAttributes := ANode.AttributeNodes.Count > 0;
  LHasChildren := ANode.ChildNodes.Count > 0;
  
  // Elemento vazio
  if not LHasAttributes and not LHasChildren then
  begin
    case FXMLToJSONOptions.EmptyElementHandling of
      eehNull: Result := TJSONValueNull.Create;
      eehEmptyString: Result := TJSONValueString.Create('');
      eehEmptyObject: Result := TJSONObject.Create;
      eehSkip: Result := nil;
    else
      Result := TJSONValueNull.Create;
    end;
    Exit;
  end;
  
  LObject := TJSONObject.Create;
  
  // Processar atributos
  if LHasAttributes and (FXMLToJSONOptions.AttributeHandling <> ahIgnore) then
  begin
    case FXMLToJSONOptions.AttributeHandling of
      ahAsProperties:
        begin
          for I := 0 to ANode.AttributeNodes.Count - 1 do
          begin
            LChildNode := ANode.AttributeNodes[I];
            LObject.Add(FXMLToJSONOptions.AttributePrefix + LChildNode.NodeName, 
                       DetectValueType(LChildNode.Text));
          end;
        end;
      ahAsMetadata:
        begin
          var LMetadata := TJSONObject.Create;
          for I := 0 to ANode.AttributeNodes.Count - 1 do
          begin
            LChildNode := ANode.AttributeNodes[I];
            LMetadata.Add(LChildNode.NodeName, DetectValueType(LChildNode.Text));
          end;
          LObject.Add('metadata', LMetadata);
        end;
    end;
  end;
  
  // Agrupar elementos filhos por nome
  LChildElements := TDictionary<string, TList<IXMLNode>>.Create;
  try
    for I := 0 to ANode.ChildNodes.Count - 1 do
    begin
      LChildNode := ANode.ChildNodes[I];
      LElementName := LChildNode.NodeName;
      
      if not LChildElements.ContainsKey(LElementName) then
        LChildElements.Add(LElementName, TList<IXMLNode>.Create);
      LChildElements[LElementName].Add(LChildNode);
    end;
    
    // Processar elementos agrupados
    for LElementName in LChildElements.Keys do
    begin
      LElementList := LChildElements[LElementName];
      
      if LElementList.Count = 1 then
      begin
        // Elemento único
        var LElement := ProcessXMLNode(LElementList[0]);
        if Assigned(LElement) then
          LObject.Add(LElementName, LElement);
      end
      else
      begin
        // Múltiplos elementos = array
        LArray := TJSONArray.Create;
        for LChildNode in LElementList do
        begin
          var LElement := ProcessXMLNode(LChildNode);
          if Assigned(LElement) then
            LArray.Add(LElement);
        end;
        LObject.Add(LElementName, LArray);
      end;
    end;
    
  finally
    for LElementList in LChildElements.Values do
      LElementList.Free;
    LChildElements.Free;
  end;
  
  // Se o objeto tem apenas conteúdo de texto e não tem atributos, retornar apenas o texto
  if (LObject.Count = 1) and LObject.ContainsKey(FXMLToJSONOptions.TextNodeName) and not LHasAttributes then
  begin
    Result := LObject.GetValue(FXMLToJSONOptions.TextNodeName);
  end
  else
    Result := LObject;
end;

function TJSONXMLConverter.ProcessXMLAttributes(ANode: IXMLNode): IJSONObject;
var
  I: Integer;
  LAttrNode: IXMLNode;
begin
  Result := TJSONObject.Create;
  
  for I := 0 to ANode.AttributeNodes.Count - 1 do
  begin
    LAttrNode := ANode.AttributeNodes[I];
    Result.Add(FXMLToJSONOptions.AttributePrefix + LAttrNode.NodeName, 
               DetectValueType(LAttrNode.Text));
  end;
end;

function TJSONXMLConverter.GetElementConverter(const AElementName: string): IXMLElementConverter;
begin
  if FCustomConverters.ContainsKey(AElementName) then
    Result := FCustomConverters[AElementName]
  else
    Result := nil;
end;

function TJSONXMLConverter.DetectValueType(const AValue: string): IJSONElement;
var
  LIntValue: Int64;
  LFloatValue: Double;
  LBoolValue: Boolean;
  LDateValue: TDateTime;
begin
  if AValue = '' then
  begin
    Result := TJSONValueString.Create('');
    Exit;
  end;
  
  // Tentar converter para número
  if FXMLToJSONOptions.ConvertNumbers and IsNumeric(AValue) then
  begin
    if TryStrToInt64(AValue, LIntValue) then
      Result := TJSONValueInteger.Create(LIntValue)
    else if TryStrToFloat(AValue, LFloatValue) then
      Result := TJSONValueFloat.Create(LFloatValue)
    else
      Result := TJSONValueString.Create(AValue);
    Exit;
  end;
  
  // Tentar converter para boolean
  if FXMLToJSONOptions.ConvertBooleans and IsBoolean(AValue) then
  begin
    LBoolValue := SameText(AValue, 'true') or SameText(AValue, '1') or SameText(AValue, 'yes');
    Result := TJSONValueBoolean.Create(LBoolValue);
    Exit;
  end;
  
  // Tentar converter para data/hora
  if FXMLToJSONOptions.ConvertDates and IsDateTime(AValue) then
  begin
    if TryStrToDateTime(AValue, LDateValue) then
      Result := TJSONValueDateTime.Create(LDateValue)
    else
      Result := TJSONValueString.Create(AValue);
    Exit;
  end;
  
  // Padrão: string
  Result := TJSONValueString.Create(AValue);
end;

function TJSONXMLConverter.IsNumeric(const AValue: string): Boolean;
var
  LDummy: Double;
begin
  Result := TryStrToFloat(AValue, LDummy);
end;

function TJSONXMLConverter.IsBoolean(const AValue: string): Boolean;
begin
  Result := SameText(AValue, 'true') or SameText(AValue, 'false') or
            SameText(AValue, '1') or SameText(AValue, '0') or
            SameText(AValue, 'yes') or SameText(AValue, 'no');
end;

function TJSONXMLConverter.IsDateTime(const AValue: string): Boolean;
var
  LDummy: TDateTime;
begin
  Result := TryStrToDateTime(AValue, LDummy) or
            TryISO8601ToDate(AValue, LDummy);
end;

function TJSONXMLConverter.XMLToJSON(const AXML: string): string;
var
  LXMLDoc: IXMLDocument;
begin
  LXMLDoc := CreateXMLDocument;
  LXMLDoc.LoadFromXML(AXML);
  Result := XMLToJSON(LXMLDoc);
end;

function TJSONXMLConverter.XMLToJSON(AXMLDocument: IXMLDocument): string;
var
  LRootElement: IJSONElement;
begin
  if not Assigned(AXMLDocument.DocumentElement) then
    raise Exception.Create('XML document has no root element');
    
  LRootElement := ProcessXMLNode(AXMLDocument.DocumentElement);
  
  FComposer.Clear;
  FComposer.Add(AXMLDocument.DocumentElement.NodeName, LRootElement);
//  Result := FComposer.GetJSONString;
end;

function TJSONXMLConverter.XMLToJSON(AXMLNode: IXMLNode): string;
var
  LElement: IJSONElement;
begin
  LElement := ProcessXMLNode(AXMLNode);
  if Supports(LElement, IJSONObject) then
    Result := IJSONObject(LElement).AsJSON
  else if Supports(LElement, IJSONArray) then
    Result := IJSONArray(LElement).AsJSON
  else if Supports(LElement, IJSONValue) then
    Result := IJSONValue(LElement).AsJSON
  else
    Result := 'null';
end;

function TJSONXMLConverter.XMLNodeToJSONObject(ANode: IXMLNode): IJSONObject;
var
  LElement: IJSONElement;
begin
  LElement := ProcessXMLNode(ANode);
  if Supports(LElement, IJSONObject, Result) then
    Exit
  else
    raise Exception.Create('XML node could not be converted to JSON object');
end;

procedure TJSONXMLConverter.ProcessJSONToXML(AElement: IJSONElement; AParentNode: IXMLNode; const AElementName: string);
var
  LNewNode: IXMLNode;
  LObject: IJSONObject;
  LArray: IJSONArray;
  LValue: IJSONValue;
  I: Integer;
  LKey: string;
  LChildElement: IJSONElement;
begin
  if not Assigned(AElement) then
    Exit;
    
  if Supports(AElement, IJSONObject, LObject) then
  begin
    LNewNode := AParentNode.AddChild(SanitizeElementName(AElementName));
    
    for I := 0 to LObject.Count - 1 do
    begin
//      LKey := LObject.GetKey(I);
      LChildElement := LObject.GetValue(LKey);
      
      // Verificar se é atributo
      if StartsText(FJSONToXMLOptions.AttributePrefix, LKey) then
      begin
        LKey := Copy(LKey, Length(FJSONToXMLOptions.AttributePrefix) + 1, MaxInt);
        if Supports(LChildElement, IJSONValue, LValue) then
          LNewNode.Attributes[LKey] := LValue.AsString;
      end
      // Verificar se é conteúdo de texto
      else if SameText(LKey, FJSONToXMLOptions.TextNodeName) then
      begin
        if Supports(LChildElement, IJSONValue, LValue) then
          LNewNode.Text := LValue.AsString;
      end
      else
      begin
        ProcessJSONToXML(LChildElement, LNewNode, LKey);
      end;
    end;
  end
  else if Supports(AElement, IJSONArray, LArray) then
  begin
    for I := 0 to LArray.Count - 1 do
    begin
      LChildElement := LArray.GetItem(I);
      ProcessJSONToXML(LChildElement, AParentNode, AElementName);
    end;
  end
  else if Supports(AElement, IJSONValue, LValue) then
  begin
    LNewNode := AParentNode.AddChild(SanitizeElementName(AElementName));
    
    if LValue is TJSONValueNull then
    begin
      case FJSONToXMLOptions.NullElementHandling of
        eehNull: LNewNode.Text := '';
        eehEmptyString: LNewNode.Text := '';
        eehSkip: AParentNode.ChildNodes.Remove(LNewNode);
      end;
    end
    else
      LNewNode.Text := LValue.AsString;
  end;
end;

function TJSONXMLConverter.CreateXMLDocument: IXMLDocument;
begin
  Result := TXMLDocument.Create(nil);
  Result.Active := True;
  
  if FJSONToXMLOptions.XMLDeclaration then
  begin
    Result.Version := FJSONToXMLOptions.XMLVersion;
    Result.Encoding := FJSONToXMLOptions.XMLEncoding;
  end;
end;

function TJSONXMLConverter.SanitizeElementName(const AName: string): string;
begin
  Result := AName;
  // Remover caracteres inválidos para nomes de elementos XML
  Result := TRegEx.Replace(Result, '[^a-zA-Z0-9_\-\.]', '_');
  
  // Garantir que não comece com número
  if (Length(Result) > 0) and CharInSet(Result[1], ['0'..'9']) then
    Result := '_' + Result;
end;

function TJSONXMLConverter.GetNamespaceInfo(ANode: IXMLNode): TPair<string, string>;
var
  LNodeName: string;
  LColonPos: Integer;
begin
  LNodeName := ANode.NodeName;
  LColonPos := Pos(':', LNodeName);
  
  if LColonPos > 0 then
  begin
    Result.Key := Copy(LNodeName, 1, LColonPos - 1); // Prefix
    Result.Value := ANode.NamespaceURI; // URI
  end
  else
  begin
    Result.Key := '';
    Result.Value := ANode.NamespaceURI;
  end;
end;

function TJSONXMLConverter.JSONToXML(const AJSON: string): string;
var
  LComposer: TJSONComposer;
  LElement: IJSONElement;
begin
  LComposer := TJSONComposer.Create;
  try
    LComposer.LoadJSON(AJSON);
//    LElement := LComposer.GetJSONElement;
    Result := JSONToXML(LElement);
  finally
    LComposer.Free;
  end;
end;

function TJSONXMLConverter.JSONToXML(AJSONElement: IJSONElement): string;
var
  LXMLDoc: IXMLDocument;
begin
  LXMLDoc := JSONToXMLDocument(AJSONElement);
  Result := LXMLDoc.XML.Text;
end;

function TJSONXMLConverter.JSONToXMLDocument(const AJSON: string): IXMLDocument;
var
  LComposer: TJSONComposer;
  LElement: IJSONElement;
begin
  LComposer := TJSONComposer.Create;
  try
    LComposer.LoadJSON(AJSON);
//    LElement := LComposer.GetJSONElement;
    Result := JSONToXMLDocument(LElement);
  finally
    LComposer.Free;
  end;
end;

function TJSONXMLConverter.JSONToXMLDocument(AJSONElement: IJSONElement): IXMLDocument;
var
  LObject: IJSONObject;
begin
  Result := CreateXMLDocument;
  
  if Supports(AJSONElement, IJSONObject, LObject) then
  begin
    if LObject.Count = 1 then
    begin
      // Usar a primeira chave como elemento raiz
//      ProcessJSONToXML(LObject.GetValue(LObject.GetKey(0)), Result, LObject.GetKey(0));
    end
    else
    begin
      // Usar nome padrão como elemento raiz
//      ProcessJSONToXML(AJSONElement, Result, FJSONToXMLOptions.RootElementName);
    end;
  end
  else
  begin
//    ProcessJSONToXML(AJSONElement, Result, FJSONToXMLOptions.RootElementName);
  end;
end;

function TJSONXMLConverter.XMLSchemaToJSONSchema(const AXMLSchema: string): string;
begin
  // TODO: Implementar conversão de XML Schema para JSON Schema
  Result := '{"type": "object"}';
end;

function TJSONXMLConverter.JSONSchemaToXMLSchema(const AJSONSchema: string): string;
begin
  // TODO: Implementar conversão de JSON Schema para XML Schema
  Result := '<?xml version="1.0"?><xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema"></xs:schema>';
end;

function TJSONXMLConverter.ValidateXMLAgainstJSON(const AXML, AJSON: string): TArray<string>;
begin
  // TODO: Implementar validação
  SetLength(Result, 0);
end;

function TJSONXMLConverter.ValidateJSONAgainstXML(const AJSON, AXML: string): TArray<string>;
begin
  // TODO: Implementar validação
  SetLength(Result, 0);
end;

procedure TJSONXMLConverter.XMLFileToJSONFile(const AXMLFileName, AJSONFileName: string);
var
  LXMLStream, LJSONStream: TFileStream;
begin
  LXMLStream := TFileStream.Create(AXMLFileName, fmOpenRead);
  try
    LJSONStream := TFileStream.Create(AJSONFileName, fmCreate);
    try
      XMLStreamToJSONStream(LXMLStream, LJSONStream);
    finally
      LJSONStream.Free;
    end;
  finally
    LXMLStream.Free;
  end;
end;

procedure TJSONXMLConverter.JSONFileToXMLFile(const AJSONFileName, AXMLFileName: string);
var
  LJSONStream, LXMLStream: TFileStream;
begin
  LJSONStream := TFileStream.Create(AJSONFileName, fmOpenRead);
  try
    LXMLStream := TFileStream.Create(AXMLFileName, fmCreate);
    try
      JSONStreamToXMLStream(LJSONStream, LXMLStream);
    finally
      LXMLStream.Free;
    end;
  finally
    LJSONStream.Free;
  end;
end;

procedure TJSONXMLConverter.XMLStreamToJSONStream(AXMLStream, AJSONStream: TStream);
var
  LReader: TStreamReader;
  LWriter: TStreamWriter;
  LXML, LJSON: string;
begin
  LReader := TStreamReader.Create(AXMLStream);
  try
    LXML := LReader.ReadToEnd;
    LJSON := XMLToJSON(LXML);
    
    LWriter := TStreamWriter.Create(AJSONStream);
    try
      LWriter.Write(LJSON);
    finally
      LWriter.Free;
    end;
  finally
    LReader.Free;
  end;
end;

procedure TJSONXMLConverter.JSONStreamToXMLStream(AJSONStream, AXMLStream: TStream);
var
  LReader: TStreamReader;
  LWriter: TStreamWriter;
  LJSON, LXML: string;
begin
  LReader := TStreamReader.Create(AJSONStream);
  try
    LJSON := LReader.ReadToEnd;
    LXML := JSONToXML(LJSON);
    
    LWriter := TStreamWriter.Create(AXMLStream);
    try
      LWriter.Write(LXML);
    finally
      LWriter.Free;
    end;
  finally
    LReader.Free;
  end;
end;

procedure TJSONXMLConverter.AddElementMapping(const AXMLPath, AJSONPath: string; AConverterClass: TClass);
begin
  FElementMappings.AddOrSetValue(AXMLPath, TXMLElementMapping.Create(AXMLPath, AJSONPath, AConverterClass));
end;

procedure TJSONXMLConverter.RemoveElementMapping(const AXMLPath: string);
begin
  FElementMappings.Remove(AXMLPath);
end;

procedure TJSONXMLConverter.ClearElementMappings;
begin
  FElementMappings.Clear;
end;

procedure TJSONXMLConverter.AddCustomConverter(const AElementName: string; AConverter: IXMLElementConverter);
begin
  FCustomConverters.AddOrSetValue(AElementName, AConverter);
end;

procedure TJSONXMLConverter.RemoveCustomConverter(const AElementName: string);
begin
  FCustomConverters.Remove(AElementName);
end;

{ TCDATAConverter }

function TCDATAConverter.XMLToJSON(ANode: IXMLNode): IJSONElement;
begin
  if ANode.NodeType = ntCData then
    Result := TJSONValueString.Create(ANode.Text)
  else
    Result := TJSONValueString.Create(ANode.Text);
end;

function TCDATAConverter.JSONToXML(AElement: IJSONElement; AParentNode: IXMLNode; const AElementName: string): IXMLNode;
var
  LValue: IJSONValue;
begin
  Result := AParentNode.AddChild(AElementName);
  
  if Supports(AElement, IJSONValue, LValue) then
  begin
    Result.NodeValue := '<![CDATA[' + LValue.AsString + ']]>';
  end;
end;

{ TMixedContentConverter }

function TMixedContentConverter.XMLToJSON(ANode: IXMLNode): IJSONElement;
var
  LObject: IJSONObject;
  LArray: IJSONArray;
  I: Integer;
  LChildNode: IXMLNode;
begin
  LObject := TJSONObject.Create;
  LArray := TJSONArray.Create;
  
  // Processar conteúdo misto como array de elementos
  for I := 0 to ANode.ChildNodes.Count - 1 do
  begin
    LChildNode := ANode.ChildNodes[I];
    
    if LChildNode.NodeType = ntText then
    begin
      if Trim(LChildNode.Text) <> '' then
        LArray.Add(TJSONValueString.Create(LChildNode.Text));
    end
    else
    begin
      var LChildObject := TJSONObject.Create;
      LChildObject.Add(LChildNode.NodeName, TJSONValueString.Create(LChildNode.Text));
      LArray.Add(LChildObject);
    end;
  end;
  
  LObject.Add('content', LArray);
  Result := LObject;
end;

function TMixedContentConverter.JSONToXML(AElement: IJSONElement; AParentNode: IXMLNode; const AElementName: string): IXMLNode;
begin
  Result := AParentNode.AddChild(AElementName);
  // TODO: Implementar conversão de conteúdo misto JSON ? XML
end;

{ TNamespaceConverter }

constructor TNamespaceConverter.Create(const ANamespaceURI, APrefix: string);
begin
  inherited Create;
  FNamespaceURI := ANamespaceURI;
  FPrefix := APrefix;
end;

function TNamespaceConverter.XMLToJSON(ANode: IXMLNode): IJSONElement;
var
  LObject: IJSONObject;
begin
  LObject := TJSONObject.Create;
  
  // Adicionar informações de namespace
  if FNamespaceURI <> '' then
  begin
    LObject.Add('@xmlns', TJSONValueString.Create(FNamespaceURI));
    if FPrefix <> '' then
      LObject.Add('@prefix', TJSONValueString.Create(FPrefix));
  end;
  
  // Adicionar conteúdo do elemento
  LObject.Add('value', TJSONValueString.Create(ANode.Text));
  
  Result := LObject;
end;

function TNamespaceConverter.JSONToXML(AElement: IJSONElement; AParentNode: IXMLNode; const AElementName: string): IXMLNode;
var
  LElementName: string;
begin
  if FPrefix <> '' then
    LElementName := FPrefix + ':' + AElementName
  else
    LElementName := AElementName;
    
  Result := AParentNode.AddChild(LElementName, FNamespaceURI);
  
  if Supports(AElement, IJSONValue) then
    Result.Text := IJSONValue(AElement).AsString;
end;

{ TXMLConverterFactory }

class function TXMLConverterFactory.CreateConverter(const AXMLToJSONOptions: TXMLToJSONOptions; const AJSONToXMLOptions: TJSONToXMLOptions): TJSONXMLConverter;
begin
  Result := TJSONXMLConverter.Create(AXMLToJSONOptions, AJSONToXMLOptions);
end;

class function TXMLConverterFactory.CreateWithDefaults: TJSONXMLConverter;
begin
  Result := TJSONXMLConverter.Create(TXMLToJSONOptions.Default, TJSONToXMLOptions.Default);
end;

class function TXMLConverterFactory.CreateForSOAP: TJSONXMLConverter;
var
  LXMLOptions: TXMLToJSONOptions;
  LJSONOptions: TJSONToXMLOptions;
begin
  LXMLOptions := TXMLToJSONOptions.Default;
  LXMLOptions.AttributeHandling := ahAsProperties;
  LXMLOptions.NamespaceHandling := nhPreserve;
  LXMLOptions.EmptyElementHandling := eehNull;
  
  LJSONOptions := TJSONToXMLOptions.Default;
  LJSONOptions.XMLDeclaration := True;
  LJSONOptions.IndentXML := True;
  
  Result := TJSONXMLConverter.Create(LXMLOptions, LJSONOptions);
end;

class function TXMLConverterFactory.CreateForREST: TJSONXMLConverter;
var
  LXMLOptions: TXMLToJSONOptions;
  LJSONOptions: TJSONToXMLOptions;
begin
  LXMLOptions := TXMLToJSONOptions.Default;
  LXMLOptions.AttributeHandling := ahIgnore;
  LXMLOptions.NamespaceHandling := nhIgnore;
  LXMLOptions.ConvertNumbers := True;
  LXMLOptions.ConvertBooleans := True;
  
  LJSONOptions := TJSONToXMLOptions.Default;
  LJSONOptions.IndentXML := False;
  LJSONOptions.XMLDeclaration := False;
  
  Result := TJSONXMLConverter.Create(LXMLOptions, LJSONOptions);
end;

class function TXMLConverterFactory.CreateForConfig: TJSONXMLConverter;
var
  LXMLOptions: TXMLToJSONOptions;
  LJSONOptions: TJSONToXMLOptions;
begin
  LXMLOptions := TXMLToJSONOptions.Default;
  LXMLOptions.AttributeHandling := ahAsProperties;
  LXMLOptions.EmptyElementHandling := eehEmptyString;
  LXMLOptions.TrimTextContent := True;
  
  LJSONOptions := TJSONToXMLOptions.Default;
  LJSONOptions.IndentXML := True;
  LJSONOptions.RootElementName := 'configuration';
  
  Result := TJSONXMLConverter.Create(LXMLOptions, LJSONOptions);
end;

end.

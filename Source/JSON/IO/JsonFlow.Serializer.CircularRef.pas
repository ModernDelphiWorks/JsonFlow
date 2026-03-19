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

unit JsonFlow.Serializer.CircularRef;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections;

type
  /// <summary>
  /// Exceção lançada quando uma referência circular é detectada
  /// </summary>
  ECircularReferenceException = class(Exception)
  private
    FObjectPath: TArray<string>;
  public
    constructor Create(const AObjectPath: TArray<string>);
    property ObjectPath: TArray<string> read FObjectPath;
  end;

  /// <summary>
  /// Detector de referências circulares para serialização de objetos
  /// Mantém uma pilha de objetos sendo serializados para detectar ciclos
  /// </summary>
  TCircularReferenceDetector = class
  private
    FObjectStack: TStack<TObject>;
    FObjectPath: TStack<string>;
    FMaxDepth: Integer;
    FCurrentDepth: Integer;
  public
    constructor Create(const AMaxDepth: Integer = 100);
    destructor Destroy; override;
    
    /// <summary>
    /// Inicia o rastreamento de um objeto
    /// Retorna True se o objeto pode ser serializado, False se é referência circular
    /// </summary>
    function BeginObject(AObject: TObject; const APropertyName: string = ''): Boolean;
    
    /// <summary>
    /// Finaliza o rastreamento de um objeto
    /// </summary>
    procedure EndObject;
    
    /// <summary>
    /// Verifica se um objeto está sendo rastreado (referência circular)
    /// </summary>
    function IsCircularReference(AObject: TObject): Boolean;
    
    /// <summary>
    /// Limpa o detector para reutilização
    /// </summary>
    procedure Clear;
    
    /// <summary>
    /// Obtém o caminho atual dos objetos
    /// </summary>
    function GetCurrentPath: string;
    
    /// <summary>
    /// Profundidade máxima permitida
    /// </summary>
    property MaxDepth: Integer read FMaxDepth write FMaxDepth;
    
    /// <summary>
    /// Profundidade atual
    /// </summary>
    property CurrentDepth: Integer read FCurrentDepth;
  end;

  /// <summary>
  /// Estratégias para lidar com referências circulares
  /// </summary>
  TCircularReferenceStrategy = (
    crsException,    // Lança exceção (padrão)
    crsNull,         // Substitui por null
    crsReference,    // Cria referência com $ref
    crsIgnore        // Ignora a propriedade
  );

  /// <summary>
  /// Gerenciador avançado de referências circulares com diferentes estratégias
  /// </summary>
  TAdvancedCircularReferenceManager = class
  private
    FDetector: TCircularReferenceDetector;
    FStrategy: TCircularReferenceStrategy;
    FObjectIds: TDictionary<TObject, string>;
    FIdCounter: Integer;
  public
    constructor Create(const AStrategy: TCircularReferenceStrategy = crsException);
    destructor Destroy; override;
    
    /// <summary>
    /// Inicia o rastreamento com estratégia específica
    /// </summary>
    function BeginObjectWithStrategy(AObject: TObject; const APropertyName: string = ''): Boolean;
    
    /// <summary>
    /// Finaliza o rastreamento
    /// </summary>
    procedure EndObject;
    
    /// <summary>
    /// Obtém referência para objeto circular
    /// </summary>
    function GetObjectReference(AObject: TObject): string;
    
    /// <summary>
    /// Limpa o gerenciador
    /// </summary>
    procedure Clear;
    
    /// <summary>
    /// Estratégia atual
    /// </summary>
    property Strategy: TCircularReferenceStrategy read FStrategy write FStrategy;
  end;

implementation

{ ECircularReferenceException }

constructor ECircularReferenceException.Create(const AObjectPath: TArray<string>);
var
  LPath: string;
begin
  FObjectPath := AObjectPath;
  LPath := string.Join(' -> ', AObjectPath);
  inherited CreateFmt('Circular reference detected in object path: %s', [LPath]);
end;

{ TCircularReferenceDetector }

constructor TCircularReferenceDetector.Create(const AMaxDepth: Integer);
begin
  inherited Create;
  FObjectStack := TStack<TObject>.Create;
  FObjectPath := TStack<string>.Create;
  FMaxDepth := AMaxDepth;
  FCurrentDepth := 0;
end;

destructor TCircularReferenceDetector.Destroy;
begin
  FObjectPath.Free;
  FObjectStack.Free;
  inherited;
end;

function TCircularReferenceDetector.BeginObject(AObject: TObject; const APropertyName: string): Boolean;
var
  LPathArray: TArray<string>;
  LPath: string;
begin
  if not Assigned(AObject) then
  begin
    Result := True;
    Exit;
  end;
  
  // Verificar profundidade máxima
  if FCurrentDepth >= FMaxDepth then
  begin
    LPathArray := FObjectPath.ToArray;
    raise ECircularReferenceException.Create(LPathArray);
  end;
  
  // Verificar referência circular
  if IsCircularReference(AObject) then
  begin
    LPathArray := FObjectPath.ToArray;
    raise ECircularReferenceException.Create(LPathArray);
  end;
  
  // Adicionar objeto à pilha
  FObjectStack.Push(AObject);
  
  // Adicionar ao caminho
  if APropertyName <> '' then
    LPath := Format('%s(%s)', [AObject.ClassName, APropertyName])
  else
    LPath := AObject.ClassName;
  FObjectPath.Push(LPath);
  
  Inc(FCurrentDepth);
  Result := True;
end;

procedure TCircularReferenceDetector.EndObject;
begin
  if FObjectStack.Count > 0 then
  begin
    FObjectStack.Pop;
    FObjectPath.Pop;
    Dec(FCurrentDepth);
  end;
end;

function TCircularReferenceDetector.IsCircularReference(AObject: TObject): Boolean;
var
  LObj: TObject;
begin
  Result := False;
  if not Assigned(AObject) then
    Exit;
    
  for LObj in FObjectStack do
  begin
    if LObj = AObject then
    begin
      Result := True;
      Break;
    end;
  end;
end;

procedure TCircularReferenceDetector.Clear;
begin
  FObjectStack.Clear;
  FObjectPath.Clear;
  FCurrentDepth := 0;
end;

function TCircularReferenceDetector.GetCurrentPath: string;
var
  LPathArray: TArray<string>;
begin
  LPathArray := FObjectPath.ToArray;
  Result := string.Join(' -> ', LPathArray);
end;

{ TAdvancedCircularReferenceManager }

constructor TAdvancedCircularReferenceManager.Create(const AStrategy: TCircularReferenceStrategy);
begin
  inherited Create;
  FDetector := TCircularReferenceDetector.Create;
  FStrategy := AStrategy;
  FObjectIds := TDictionary<TObject, string>.Create;
  FIdCounter := 1;
end;

destructor TAdvancedCircularReferenceManager.Destroy;
begin
  FObjectIds.Free;
  FDetector.Free;
  inherited;
end;

function TAdvancedCircularReferenceManager.BeginObjectWithStrategy(AObject: TObject; const APropertyName: string): Boolean;
begin
  if not Assigned(AObject) then
  begin
    Result := True;
    Exit;
  end;
  
  // Se é referência circular, aplicar estratégia
  if FDetector.IsCircularReference(AObject) then
  begin
    case FStrategy of
      crsException:
        begin
          Result := FDetector.BeginObject(AObject, APropertyName); // Vai lançar exceção
        end;
      crsNull, crsReference, crsIgnore:
        begin
          Result := False; // Indica que deve ser tratado pela estratégia
        end;
    end;
  end
  else
  begin
    // Não é circular, proceder normalmente
    Result := FDetector.BeginObject(AObject, APropertyName);
    
    // Se estratégia usa referências, registrar o objeto
    if (FStrategy = crsReference) and not FObjectIds.ContainsKey(AObject) then
    begin
      FObjectIds.Add(AObject, Format('obj_%d', [FIdCounter]));
      Inc(FIdCounter);
    end;
  end;
end;

procedure TAdvancedCircularReferenceManager.EndObject;
begin
  FDetector.EndObject;
end;

function TAdvancedCircularReferenceManager.GetObjectReference(AObject: TObject): string;
begin
  if FObjectIds.ContainsKey(AObject) then
    Result := FObjectIds[AObject]
  else
  begin
    Result := Format('obj_%d', [FIdCounter]);
    FObjectIds.Add(AObject, Result);
    Inc(FIdCounter);
  end;
end;

procedure TAdvancedCircularReferenceManager.Clear;
begin
  FDetector.Clear;
  FObjectIds.Clear;
  FIdCounter := 1;
end;

end.
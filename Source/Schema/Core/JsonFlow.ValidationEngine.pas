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

unit JsonFlow.ValidationEngine;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  JsonFlow.Interfaces;

type
  // Usar TRuleType, TValidationStatus, TValidationResult e TValidationError de JsonFlow.Interfaces

  TValidationContext = class;

  // Interface base para regras de valida??o
  IValidationRule = interface
    ['{B3C1CC08-4573-4816-9718-09EAB8B5D8EF}']
    function GetRuleType: TRuleType;
    function GetKeyword: string;
    function Validate(const AValue: IJSONElement; const AContext: TObject): TValidationResult;
  end;

  ISchemaCompiler = interface
    ['{C32A604E-3A2B-40BD-A88E-5D61E9361C50}']
    function ResolveReference(const ARefPath: string): IJSONElement; overload;
    function ResolveReference(const ARefPath: string; const ACurrentSchema: IJSONElement): IJSONElement; overload;
  end;

  ISubschemaEvaluator = interface
    ['{F62F2D68-CC89-4C5C-BCE6-2A4C5A1A18E6}']
    function Evaluate(const AValue: IJSONElement; const ASubschema: IJSONElement; const AContext: TValidationContext): TValidationResult;
  end;

  // Contexto de validação com paths INCREMENTAIS: os full-paths são mantidos
  // como strings atualizadas no push/pop (O(seg)) e lidos em O(1) —
  // GetFullPath/GetFullSchemaPath eram reconstruídos por concatenação em TODO
  // TValidationResult, inclusive nos de sucesso que ninguém lê.
  TValidationContext = class
  private
    FSchema: IJSONElement;
    FPath: string;
    FParent: TValidationContext;
    FPathStack: TArray<string>;
    FPathLens: TArray<Integer>;
    FPathDepth: Integer;
    FFullPath: string;
    FSchemaPath: string;
    FSchemaPathStack: TArray<string>;
    FSchemaLens: TArray<Integer>;
    FSchemaDepth: Integer;
    FFullSchemaPath: string;
    FResolver: ISchemaCompiler;
    FEvaluator: ISubschemaEvaluator;
    procedure _SetSchemaPath(const AValue: string);
    procedure _PushPath(const ASegment: string);
    procedure _PushSchema(const ASegment: string);
  public
    constructor Create(const ASchema: IJSONElement; const APath: string; AParent: TValidationContext; AResolver: ISchemaCompiler); overload;
    constructor Create(const ASchema: IJSONElement; const APath: string; AParent: TValidationContext; AResolver: ISchemaCompiler; const AEvaluator: ISubschemaEvaluator); overload;
    destructor Destroy; override;
    function GetFullPath: string;
    function GetFullSchemaPath: string;
    procedure PushProperty(const APropertyName: string);
    procedure PopProperty;
    procedure PushArrayIndex(AIndex: Integer);
    procedure PopArrayIndex;
    procedure PushSchemaSegment(const ASegment: string);
    procedure PopSchemaSegment;
    property Schema: IJSONElement read FSchema;
    property Path: string read FPath;
    property SchemaPath: string read FSchemaPath write _SetSchemaPath;
    property Resolver: ISchemaCompiler read FResolver write FResolver;
    property Evaluator: ISubschemaEvaluator read FEvaluator write FEvaluator;
  end;

// Fun??es auxiliares
function EscapeJSONPointer(const AValue: string): string;
function CreateValidationError(const APath, AMessage, AFound, AExpected, AKeyword: string; const ASchemaPath: string = ''): TValidationError;
procedure AddErrorToResult(var AResult: TValidationResult; const AError: TValidationError);
function CombineResults(const AResult1, AResult2: TValidationResult): TValidationResult;

implementation

{ TValidationContext }

constructor TValidationContext.Create(const ASchema: IJSONElement; const APath: string; AParent: TValidationContext; AResolver: ISchemaCompiler);
begin
  inherited Create;
  FSchema := ASchema;
  FPath := APath;
  FFullPath := APath;
  FPathDepth := 0;
  FParent := AParent;
  FResolver := AResolver;
  FEvaluator := nil;
  if Assigned(AParent) then
  begin
    FSchemaPath := AParent.FSchemaPath;
    // Cópia da string incremental é O(1) (refcount); os stacks copiam só a
    // profundidade em uso.
    FFullSchemaPath := AParent.FFullSchemaPath;
    FSchemaDepth := AParent.FSchemaDepth;
    FSchemaPathStack := Copy(AParent.FSchemaPathStack, 0, FSchemaDepth);
    FSchemaLens := Copy(AParent.FSchemaLens, 0, FSchemaDepth);
  end
  else
  begin
    FSchemaPath := '';
    FFullSchemaPath := '';
    FSchemaDepth := 0;
  end;
end;

constructor TValidationContext.Create(const ASchema: IJSONElement; const APath: string; AParent: TValidationContext; AResolver: ISchemaCompiler; const AEvaluator: ISubschemaEvaluator);
begin
  Create(ASchema, APath, AParent, AResolver);
  FEvaluator := AEvaluator;
end;

destructor TValidationContext.Destroy;
begin
  FResolver := nil;
  FEvaluator := nil;
  FParent := nil; // Evitar refer?ncia circular
  inherited Destroy;
end;

function TValidationContext.GetFullPath: string;
begin
  // O(1): mantido incrementalmente no push/pop
  if FFullPath = '' then
    Result := '/'
  else
    Result := FFullPath;
end;

function TValidationContext.GetFullSchemaPath: string;
begin
  Result := FFullSchemaPath;
end;

procedure TValidationContext._PushPath(const ASegment: string);
begin
  if FPathDepth = Length(FPathLens) then
  begin
    SetLength(FPathLens, (FPathDepth + 8) * 2);
    SetLength(FPathStack, Length(FPathLens));
  end;
  FPathLens[FPathDepth] := Length(FFullPath);
  FPathStack[FPathDepth] := ASegment;
  Inc(FPathDepth);
  FFullPath := FFullPath + '/' + ASegment;
end;

procedure TValidationContext._PushSchema(const ASegment: string);
begin
  if FSchemaDepth = Length(FSchemaLens) then
  begin
    SetLength(FSchemaLens, (FSchemaDepth + 8) * 2);
    SetLength(FSchemaPathStack, Length(FSchemaLens));
  end;
  FSchemaLens[FSchemaDepth] := Length(FFullSchemaPath);
  FSchemaPathStack[FSchemaDepth] := ASegment;
  Inc(FSchemaDepth);
  FFullSchemaPath := FFullSchemaPath + '/' + ASegment;
end;

procedure TValidationContext._SetSchemaPath(const AValue: string);
var
  LFor: Integer;
begin
  // Troca de base (ex.: resolução de $ref): reconstrói o full path a partir
  // da nova base preservando os segmentos já empilhados.
  FSchemaPath := AValue;
  FFullSchemaPath := AValue;
  for LFor := 0 to FSchemaDepth - 1 do
  begin
    FSchemaLens[LFor] := Length(FFullSchemaPath);
    FFullSchemaPath := FFullSchemaPath + '/' + FSchemaPathStack[LFor];
  end;
end;

procedure TValidationContext.PushProperty(const APropertyName: string);
begin
  // Aplicar escape JSON Pointer se necessário
  _PushPath(EscapeJSONPointer(APropertyName));
end;

procedure TValidationContext.PopProperty;
begin
  if FPathDepth > 0 then
  begin
    Dec(FPathDepth);
    SetLength(FFullPath, FPathLens[FPathDepth]);
  end;
end;

procedure TValidationContext.PushArrayIndex(AIndex: Integer);
begin
  // No formato JSON Pointer, índices de array são tratados como strings simples
  _PushPath(IntToStr(AIndex));
end;

procedure TValidationContext.PushSchemaSegment(const ASegment: string);
begin
  _PushSchema(EscapeJSONPointer(ASegment));
end;

procedure TValidationContext.PopSchemaSegment;
begin
  if FSchemaDepth > 0 then
  begin
    Dec(FSchemaDepth);
    SetLength(FFullSchemaPath, FSchemaLens[FSchemaDepth]);
  end;
end;

procedure TValidationContext.PopArrayIndex;
begin
  if FPathDepth > 0 then
  begin
    Dec(FPathDepth);
    SetLength(FFullPath, FPathLens[FPathDepth]);
  end;
end;

{ Fun??es auxiliares }

function EscapeJSONPointer(const AValue: string): string;
begin
  // Escape conforme RFC 6901: ~ vira ~0, / vira ~1
  Result := StringReplace(AValue, '~', '~0', [rfReplaceAll]);
  Result := StringReplace(Result, '/', '~1', [rfReplaceAll]);
end;

function CreateValidationError(const APath, AMessage, AFound, AExpected, AKeyword: string; const ASchemaPath: string = ''): TValidationError;
begin
  Result.Path := APath;
  Result.SchemaPath := ASchemaPath;
  Result.Message := AMessage;
  Result.FoundValue := AFound;
  Result.ExpectedValue := AExpected;
  Result.Keyword := AKeyword;
  Result.LineNumber := -1;
  Result.ColumnNumber := -1;
  Result.Context := '';
end;

procedure AddErrorToResult(var AResult: TValidationResult; const AError: TValidationError);
var
  LNewLength: Integer;
begin
  LNewLength := Length(AResult.Errors) + 1;
  SetLength(AResult.Errors, LNewLength);
  AResult.Errors[LNewLength - 1] := AError;
  AResult.IsValid := False;
end;

function CombineResults(const AResult1, AResult2: TValidationResult): TValidationResult;
var
  LFor: Integer;
  LBase: Integer;
begin
  Result := AResult1;
  Result.IsValid := AResult1.IsValid and AResult2.IsValid;

  if Length(AResult2.Errors) > 0 then
  begin
    // Atribuição elemento a elemento — o Move anterior copiava os ponteiros
    // das strings do record SEM incrementar refcount (duas arrays finalizando
    // as mesmas strings = corrupção de memória latente).
    LBase := Length(AResult1.Errors);
    SetLength(Result.Errors, LBase + Length(AResult2.Errors));
    for LFor := 0 to Length(AResult2.Errors) - 1 do
      Result.Errors[LBase + LFor] := AResult2.Errors[LFor];
  end;
end;

end.

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

  // Interface para resolver refer?ncias $ref
  ISchemaCompiler = interface
    ['{C32A604E-3A2B-40BD-A88E-5D61E9361C50}']
    function ResolveReference(const ARefPath: string): IJSONElement;
  end;

  ISubschemaEvaluator = interface
    ['{F62F2D68-CC89-4C5C-BCE6-2A4C5A1A18E6}']
    function Evaluate(const AValue: IJSONElement; const ASubschema: IJSONElement; const AContext: TValidationContext): TValidationResult;
  end;

  // Contexto de valida??o simplificado
  TValidationContext = class
  private
    FSchema: IJSONElement;
    FPath: string;
    FParent: TValidationContext;
    FPathStack: TArray<string>;
    FSchemaPath: string;
    FSchemaPathStack: TArray<string>;
    FResolver: ISchemaCompiler;
    FEvaluator: ISubschemaEvaluator;
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
    property SchemaPath: string read FSchemaPath write FSchemaPath;
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
  FParent := AParent;
  FResolver := AResolver;
  FEvaluator := nil;
  SetLength(FPathStack, 0);
  if Assigned(AParent) then
  begin
    FSchemaPath := AParent.FSchemaPath;
    FSchemaPathStack := Copy(AParent.FSchemaPathStack);
  end
  else
  begin
    FSchemaPath := '';
    SetLength(FSchemaPathStack, 0);
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
var
  LFor: Integer;
begin
  Result := FPath;
  for LFor := 0 to Length(FPathStack) - 1 do
  begin
    // Usar formato JSON Pointer padrão com separador '/'
    Result := Result + '/' + FPathStack[LFor];
  end;

  // Se o resultado estiver vazio, retornar a raiz JSON Pointer
  if Result = '' then
    Result := '/';
end;

function TValidationContext.GetFullSchemaPath: string;
var
  LFor: Integer;
begin
  Result := FSchemaPath;
  for LFor := 0 to Length(FSchemaPathStack) - 1 do
    Result := Result + '/' + FSchemaPathStack[LFor];
end;

procedure TValidationContext.PushProperty(const APropertyName: string);
begin
  SetLength(FPathStack, Length(FPathStack) + 1);
  // Aplicar escape JSON Pointer se necessário
  FPathStack[Length(FPathStack) - 1] := EscapeJSONPointer(APropertyName);
end;

procedure TValidationContext.PopProperty;
begin
  if Length(FPathStack) > 0 then
    SetLength(FPathStack, Length(FPathStack) - 1);
end;

procedure TValidationContext.PushArrayIndex(AIndex: Integer);
begin
  SetLength(FPathStack, Length(FPathStack) + 1);
  // No formato JSON Pointer, índices de array são tratados como strings simples
  FPathStack[Length(FPathStack) - 1] := IntToStr(AIndex);
end;

procedure TValidationContext.PushSchemaSegment(const ASegment: string);
begin
  SetLength(FSchemaPathStack, Length(FSchemaPathStack) + 1);
  FSchemaPathStack[Length(FSchemaPathStack) - 1] := EscapeJSONPointer(ASegment);
end;

procedure TValidationContext.PopSchemaSegment;
begin
  if Length(FSchemaPathStack) > 0 then
    SetLength(FSchemaPathStack, Length(FSchemaPathStack) - 1);
end;

procedure TValidationContext.PopArrayIndex;
begin
  if Length(FPathStack) > 0 then
    SetLength(FPathStack, Length(FPathStack) - 1);
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
begin
  Result := AResult1;
  Result.IsValid := AResult1.IsValid and AResult2.IsValid;

  if Length(AResult2.Errors) > 0 then
  begin
    // Adicionar erros do segundo resultado
    SetLength(Result.Errors, Length(AResult1.Errors) + Length(AResult2.Errors));
    Move(AResult2.Errors[0], Result.Errors[Length(AResult1.Errors)], Length(AResult2.Errors) * SizeOf(TValidationError));
  end;
end;

end.

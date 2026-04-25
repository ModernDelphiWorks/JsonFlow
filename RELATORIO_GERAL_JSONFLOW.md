# Relatório Geral — JsonFlow (Delphi/VCL)

Projeto: `d:\Ecossistema-Delphi\JsonFlow`

Este relatório foi produzido a partir de leitura direta de código-fonte, estrutura de pastas, exemplos e testes existentes no repositório.

---

## 1) Visão Geral (o que é)

O **JsonFlow** é um framework Delphi focado em:

- **Modelo JSON próprio** com interfaces (`IJSONElement`, `IJSONObject`, `IJSONArray`, `IJSONValue`).
- **IO JSON** (leitura/parse e escrita/serialização) via `TJSONReader` e `TJSONWriter`.
- **Composição/edição fluente** de JSON (composer) e operações por path.
- **Serialização/Deserialização** de objetos Delphi via RTTI, com **pipeline de middlewares**.
- **Conversores** (XML ↔ JSON, DataSet ↔ JSON) expostos pela fachada.
- **JSON Schema**: criação fluente (Schema Composer), leitura/detecção de versão, navegação `$ref`, e um validador com regras por keyword.

**Fachada principal (entry-point de uso):** `Source\JsonFlow.pas` (`TJsonFlow`).

---

## 2) Mapa Visual (arquitetura em camadas)

### 2.1 Camadas

1. **API/Fachada**
   - `TJsonFlow` em `Source\JsonFlow.pas`
   - Responsável por simplificar o uso e manter instâncias internas de `Reader/Writer/Serializer/Converters`.

2. **Modelo JSON (core)**
   - Interfaces e tipos centrais em `Source\JSON\Core\JsonFlow.Interfaces.pas`.
   - Implementações em `Source\JSON\Core` e `Source\JSON\Composition`.

3. **IO JSON (leitura e escrita)**
   - Units em `Source\JSON\IO\` (`JsonFlow.Reader.pas`, `JsonFlow.Writer.pas`, `JsonFlow.Navigator.pas`, etc.).

4. **Composição/Edição**
   - JSON: `Source\JSON\Composition\JsonFlow.Composer.pas` (e complementos).
   - JSON Schema: `Source\Schema\Composition\JsonFlow.SchemaComposer.pas`.

5. **Serialização RTTI + Middlewares**
   - `Source\JSON\IO\JsonFlow.Serializer.pas` e units correlatas.
   - Middlewares via interfaces em `JsonFlow.Interfaces.pas`.

6. **JSON Schema (modelagem/validação)**
   - Meta-schema Draft-07 embutido em `Source\Schema\Core\JsonFlow.Schema.pas`.
   - Reader de schema: `Source\Schema\IO\JsonFlow.SchemaReader.pas`.
   - Navigator/Resolver de `$ref`: `Source\Schema\Composition\JsonFlow.SchemaNavigator.pas`.
   - Validator + compiler + rules: `Source\Schema\Validators\JsonFlow.SchemaValidator.pas` e `Source\Schema\Validators\JsonFlow.ValidationRules.*.pas`.

### 2.2 Fluxos (visão “foto”)

**Fluxo A — Objeto Delphi → JSON string**

`TJsonFlow.ObjectToJsonString()` → `TJSONSerializer.FromObject()` → `IJSONElement.AsJSON()`

**Fluxo B — JSON string → Objeto Delphi**

`TJsonFlow.JsonToObject<T>()` → `TJSONReader.Read()` → `TJSONSerializer.ToObject()`

**Fluxo C — Validação JSON Schema (alto nível)**

`TJSONSchemaReader.LoadFrom*()` → detecta versão por `$schema` → `TJSONSchemaValidator.ParseSchema()`
→ `TSchemaCompiler.Compile()` (cria regras) → `TValidationVisitor.Visit(..., CompiledSchema)`

---

## 3) Funcionalidades (por evidência no código)

### 3.1 Fachada `TJsonFlow`

Arquivo: `Source\JsonFlow.pas`

Principais responsabilidades comprovadas no código:

- `ObjectToJsonString()` e `ObjectListToJsonString()`.
- `JsonToObject<T>()`, `JsonToObjectList<T>()`.
- `Parse()` e `ToJson()` (Reader/Writer).
- `AddMiddleware()` e `ClearMiddlewares()` (integração com serializer).
- Conversores XML/DataSet e rotinas de validação simples (`IsValidJSON/IsValidXML`).

### 3.2 Modelo JSON e contratos

Arquivo: `Source\JSON\Core\JsonFlow.Interfaces.pas`

Pontos relevantes:

- `IJSONElement` define a “unidade atômica” do modelo (stringify/clone/TypeName).
- `IJSONObject` e `IJSONArray` suportam operações funcionais (`Filter/Map/ForEach`).
- Tipos de validação de schema: `TValidationError`, `TValidationResult`.

### 3.3 Middlewares (gancho de extensão)

Arquivo: `Source\JSON\Core\JsonFlow.Interfaces.pas`

- `IGetValueMiddleware` e `ISetValueMiddleware` permitem interceptar leitura/escrita de propriedades RTTI.
- A fachada injeta middlewares em `FSerializer.Middlewares`.

### 3.4 JSON Schema — criação fluente

Arquivo: `Source\Schema\Composition\JsonFlow.SchemaComposer.pas`

Recursos observáveis:

- API fluente para montar schema com: `Typ`, `Prop`, `RequiredFields/Req`, `Min/Max`, `MinLen/MaxLen`, `Pattern`, `Enum`, `Cst`, `Default`, `Items`, `Unique`, `MinProps/MaxProps`, `AddProps`, combinadores (`AllOf/AnyOf/OneOf/Neg`), condicionais (`IfThen/Thn/Els`), `PatternProp`, `propertyNames` (via `Add`), `$ref` (`Ref`, `PropRef`, `RefProp`).
- Possui “Smart Mode”: valida contexto de uso de métodos (ex.: não chamar `Items` fora de array) e sugere próximos passos.
- Tenta carregar `json-schema.json` do disco (se existir); se não existir, entra em fallback de regras básicas.

### 3.5 JSON Schema — leitura e detecção de versão

Arquivo: `Source\Schema\IO\JsonFlow.SchemaReader.pas`

- Detecta versão por `$schema` (draft-03/04/06/07/2019-09/2020-12), mas o validador instanciado e o meta-schema embutido são centrados em Draft-07.

### 3.6 JSON Schema — navegação e `$ref`

Arquivo: `Source\Schema\Composition\JsonFlow.SchemaNavigator.pas`

- Resolve JSON Pointer (`/path/like/this`) e anchors (`#anchor`).
- Carrega schemas externos **por arquivo local**.
- HTTP não está implementado (lança exceção ao tentar carregar via `http(s)://`).
- Tem modo safe contra circularidade e profundidade.

---

## 4) Checklist de verificação (para validar que o estudo foi real)

Marque o que você conferir:

- [ ] Existe `TJsonFlow` em `Source\JsonFlow.pas` e ele mantém `FReader/FWriter/FSerializer/FConverters` como `class var`.
- [ ] As interfaces `IJSONElement/IJSONObject/IJSONArray/IJSONValue` estão em `Source\JSON\Core\JsonFlow.Interfaces.pas`.
- [ ] Middlewares RTTI existem como `IGetValueMiddleware/ISetValueMiddleware`.
- [ ] Existe meta-schema Draft-07 como string `DRAFT7METASCHEMA` em `Source\Schema\Core\JsonFlow.Schema.pas`.
- [ ] O validador principal é `TJSONSchemaValidator` e ele compila regras via `TSchemaCompiler.Compile()`.
- [ ] Existem rules separadas em `Source\Schema\Validators\JsonFlow.ValidationRules.*.pas`.
- [ ] Existe `TJSONSchemaNavigator` com suporte a JSON Pointer + anchor + schema externo por arquivo.
- [ ] Há testes DUnitX para schema/composer em `Tests\Schema\*`.
- [ ] Existe governança interna em `.trae\SKILL.md` e referências em `.trae\references\`.

---

# 5) JSON Schema — Diagnóstico Minucioso (ponto de foco)

## 5.1 Estado atual (o que já está presente)

### A) Compiler por keywords + regras

O `TSchemaCompiler` lê o schema (um `IJSONObject`) e monta uma lista de `IValidationRule` conforme as keywords presentes.

Já aparecem suportadas no compiler (por criação de regras):

- `type`
- numéricas: `minimum`, `maximum`, `exclusiveMinimum`, `exclusiveMaximum`, `multipleOf`
- string: `minLength`, `maxLength`, `pattern`, `format`
- objeto: `properties`, `required`, `additionalProperties`, `minProperties`, `maxProperties`
- array: `items`, `minItems`, `maxItems`, `uniqueItems`, `contains`
- combinadores: `allOf`, `anyOf`, `oneOf`, `not`
- condicionais: `if`, `then`, `else`
- `patternProperties`, `propertyNames`

### B) Visitor aplica regras compiladas

O `TValidationVisitor.Visit(..., CompiledSchema)` executa todas as regras do schema compilado.

### C) Contexto de path

O `TValidationContext` monta paths em **JSON Pointer** (com escape RFC6901), o que é adequado para diagnosticar profundidade e nós repetidos.

---

## 5.2 Onde estão as falhas de validação “mais complexa” (profundidade)

O sintoma que você descreveu (“ramificações mais a fundo”, “mesmo nome de tags em nós diferentes”) costuma acontecer quando:

1) as rules aplicam validação **apenas superficial** (ex.: só `type`) ao entrar em subschemas; e/ou
2) a validação não possui um mecanismo único/consistente para “avaliar um subschema completo” em qualquer profundidade.

### Evidência 1 — `properties` valida pouco do subschema

Em `JsonFlow.ValidationRules.Properties.pas`, o método que valida o schema da propriedade (`ValidatePropertySchema`) hoje aplica praticamente:

- resolve `$ref` apenas para `#/$defs/...` (local)
- valida **apenas `type`** do subschema

Ou seja, mesmo que o subschema tenha `minLength`, `pattern`, `minimum`, `required`, combinadores, etc., isso não é aplicado ali.

**Consequência:** validações profundas tendem a “parar” em regras básicas quando entram por `properties`.

### Evidência 2 — `items` desce recursivamente, mas não despacha todas keywords

Em `JsonFlow.ValidationRules.Items.pas`, há recursão para validar itens e descer em `properties` dentro do item.

Porém o motor interno (`ValidateItemAgainstSchema`) também está centrado em `type` + descida estrutural, e não em “compilar+rodar todas as rules do subschema”.

**Consequência:** há profundidade, mas com cobertura parcial de keywords.

---

## 5.3 “Mesmo nome de tags em nós diferentes” — existe impedimento estrutural?

### Do lado do JSON (dados)

Não há impedimento por si só: como o path é JSON Pointer e inclui todo o caminho (`/cliente/endereco/cidade` vs `/fornecedor/endereco/cidade`), nomes repetidos em ramos diferentes são diferenciados pelo path completo.

### Do lado do Schema (compilação/cache)

O risco estrutural para evolução aparece mais na combinação:

- cache de compilação baseado **apenas** em `ASchema.AsJSON` (hash do texto do schema)
- + evolução de `$id`/base URI e `$ref` relativo

Se dois subschemas têm o mesmo JSON textual, mas em contextos de base URI diferentes, esse cache pode causar comportamento incorreto quando a resolução de `$ref` ficar mais avançada.

---

## 5.4 Pode evoluir no formato atual?

**Sim, pode evoluir.** Mas do jeito atual, a evolução tende a ficar “aos pedaços”, porque parte da validação profunda está em regras estruturais (ex.: `properties/items`) com validação parcial, enquanto o compiler/visitor tenta ser o motor principal.

### Principais bloqueios (reais) para alta cobertura

1) Falta de um **dispatcher único de avaliação de subschema** (subschema completo → compila rules → roda rules → desce).
2) `$ref` e resolução estão divididos entre compiler e navigator, com coberturas diferentes.
3) Cache/identidade de schema ainda é simples para cenários com `$id` + `$ref` relativo + múltiplos arquivos.

---

## 5.5 Recomendações objetivas (evolução sem reescrever tudo)

1) **Centralizar avaliação de subschema**
   - Internamente, `properties/items/anyOf/...` não deveriam “validar só type”; deveriam chamar um ponto único: “avaliar este valor contra este subschema”.

2) **Melhorar chave de cache de schema compilado**
   - Incluir contexto mínimo (ex.: base URI atual e/ou JSON Pointer do subschema dentro do root) quando `$ref` relativo existir.

3) **Unificar resolução de `$ref`**
   - Escolher um mecanismo (ou fazer um reutilizar o outro) para evitar divergência e facilitar evolução.

4) **Cobertura por fatias com testes DUnitX**
   - Primeiro estabilizar validação profunda de `properties/items` (para que keywords comuns funcionem em qualquer nível), depois combinadores e condicionais, depois `$ref` hardening.

---

## 6) Materiais de governança e referências internas do projeto

### 6.1 Regras de sintaxe do projeto

Arquivo: `.trae\rules\sintaxe.md`

- Variáveis locais: `L...`
- Variáveis globais: `G...`
- Variáveis de instância: `F...`
- Laços `for`: nunca usar `I`, usar `LFor`, `LIndex`, etc.
- Constantes: `C_...`
- Métodos privados: prefixo `_...`

### 6.2 Skill e referências (pasta `.trae`)

- `.trae\SKILL.md`: define o papel e o processo (diagnóstico → plano → pedir autorização antes de alterar código).
- `.trae\references\delphi-review-checklist.md`: checklist de revisão.
- `.trae\references\json-schema-evolution-plan.md`: guia de evolução de JSON Schema.

---

## 7) Observações finais

- Este relatório prioriza o ponto que você pediu: **JSON Schema** (capacidade atual, por que falha em profundidade, e onde está o bloqueio estrutural).
- Quando você quiser, eu monto (em arquivo separado) um **plano de evolução em fases** com critérios de aceite por keyword e casos de teste, respeitando seu gate de autorização antes de qualquer mudança de código.


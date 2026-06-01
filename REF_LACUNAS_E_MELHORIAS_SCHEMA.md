# Referência — Lacunas e Melhorias (JSON Schema no JsonFlow)

Este documento descreve, de forma minuciosa, o que foi percebido durante a evolução do JSON Schema no JsonFlow:

- o que **ainda não existe** ou não foi iniciado
- o que **funciona**, mas deveria ser melhorado (dívida técnica)
- o que é **decisão de escopo** (intencionalmente não implementado)

Contexto: a suíte `JsonFlow.Schema.Tests` está verde (chegando a ~95 testes na última rodada), com foco em Draft-07 pragmático.

---

## 1) Lacunas funcionais (Draft-07)

### 1.1 `dependencies`

**Status**: não implementado.

**Por que importa**
- Muito usado em schemas Draft-07 existentes.
- É diferente de `required`: permite dependência condicional por presença de uma chave.

**Semântica (Draft-07)**
- `dependencies` é um objeto onde cada chave pode ser:
  1) **array de strings**: se a propriedade existir, as propriedades listadas tornam-se obrigatórias.
  2) **schema**: se a propriedade existir, o objeto deve validar contra o subschema.

**O que implementar**
- Nova rule `JsonFlow.ValidationRules.Dependencies.pas`.
- No compilador (`TSchemaCompiler.Compile`), registrar a rule quando `dependencies` existir.
- Para o modo schema, delegar para `AContext.Evaluator.Evaluate`.
- Para o modo array, usar lógica similar a `required` porém condicionada à presença da chave.

**Testes sugeridos**
- `dependencies` com array: `{a:1}` exige `b`.
- `dependencies` com schema: `{a:1}` exige que `b` seja string minLength>=3.
- Deep: dependencies dentro de `properties` de um objeto aninhado.

---

### 1.2 Alias de `#/definitions/...` (compatibilidade)

**Status**: não suportado explicitamente.

**Por que importa**
- Muitos schemas antigos (Draft-04/06/07) usam `definitions` ao invés de `$defs`.

**O que implementar**
- No resolver de `$ref` (hoje via `TJSONSchemaNavigator`), aceitar:
  - `#/$defs/...` (já esperado)
  - `#/definitions/...` como alias

**Testes sugeridos**
- Schema com `definitions` e `$ref` para `#/definitions/Zip`.
- Deep: `properties/a/$ref` apontando para `#/definitions/...`.

---

### 1.3 `minContains` / `maxContains`

**Status**: não iniciado (keywords modernas; não são Draft-07 core).

**Por que importa**
- Em Draft-2019-09+ o `contains` pode exigir quantidade mínima/máxima de matches.

**Decisão recomendada**
- Se continuar “Draft-07 pragmático”: documentar como **não suportado**.
- Se antecipar: implementar com comportamento claro e testes.

---

### 1.4 `contentMediaType` / `contentEncoding`

**Status**: constam no meta-schema embutido, mas não há validação.

**Nota**
- Na prática, muitas libs tratam como anotações/semânticas externas.
- Se forem suportadas, precisaria definir como validar (ex.: string base64 + media type).

---

## 2) Lacunas funcionais (Drafts novos — não iniciado)

**Status geral**: não iniciado.

Itens típicos:
- `prefixItems` (2020-12) — substitui tuple em `items`
- `unevaluatedItems` / `unevaluatedProperties`
- `dependentRequired` / `dependentSchemas`
- `$dynamicRef` / `$dynamicAnchor`

Recomendação: tratar como projeto separado (um “validador 2019-09/2020-12”) para não misturar semânticas.

---

## 3) Lacunas de diagnóstico (`SchemaPath`)

### 3.1 Cobertura parcial de `SchemaPath`

**Status**: iniciado, mas não universal.

**O que já existe**
- `TValidationContext` mantém stack de schema path.
- Alguns fluxos empurram schema path (ex.: `properties`, `items`, `additionalProperties`).
- Algumas rules já preenchem `SchemaPath` (ex.: `type`, `minLength`).

**O que falta**
- Padronizar `SchemaPath` em TODAS as rules relevantes:
  - `required`
  - `pattern`
  - `minimum/maximum/exclusive*`
  - `multipleOf`
  - `enum/const`
  - `format`
  - `minItems/maxItems/uniqueItems`
  - `minProperties/maxProperties`
  - combinadores (`allOf/anyOf/oneOf/not`) com paths para índices (`/anyOf/0/...`)

**Melhoria estrutural recomendada**
- Em vez de cada rule “lembrar” do `SchemaPath`, padronizar que:
  - `CreateValidationError` receba `SchemaPath` padrão baseado em `Context.GetFullSchemaPath` + `Keyword`.
  - A rule só ajusta quando precisa apontar um índice/ramo específico.

---

## 4) Dívidas técnicas (funciona, mas deveria melhorar)

### 4.1 Resolver `$ref` duplicado (dois caminhos)

**Sintoma**
- Existe lógica de resolução dentro do compilador e também no `TJSONSchemaNavigator`.

**Risco**
- Divergência de comportamento entre caminhos.

**Melhoria recomendada**
- Definir um único “resolver oficial” (navigator ou um novo componente), e o compilador sempre delega.

---

### 4.2 Cache key de schema compilado

**Status**: melhorada (inclui base URI), mas ainda frágil.

**Risco**
- Mesmo JSON textual, mas origem/base diferentes, pode colidir semanticamente.

**Melhoria recomendada**
- Chave composta que inclua:
  - origem do schema (arquivo/URI)
  - schema pointer atual (`SchemaPath`)
  - hash do conteúdo

---

### 4.3 Fallback manual em algumas rules (ex.: `items`)

**Sintoma**
- Algumas rules têm validação manual e também caminho via `Evaluator`.

**Risco**
- Duplicação de lógica, inconsistência de erro e manutenção difícil.

**Melhoria recomendada**
- Consolidar: preferir sempre `Evaluator` e reduzir fallback ao mínimo.

---

### 4.4 Testes com fixtures dependentes do diretório do executável

**Sintoma**
- Resolução de paths em testes pode variar conforme IDE/build.

**Melhoria recomendada**
- Helper único de path para fixtures em `Tests/Schema/...`.

---

## 5) Itens intencionalmente “fora do escopo” (decisão)

- Resolução HTTP de `$ref`: infraestrutura existe, mas mantida desabilitada.
- Drafts 2019-09/2020-12: não prometer conformidade sem implementação dedicada.

---

## 6) Roadmap recomendado (pragmático)

1) Completar `SchemaPath` para as rules mais usadas (required/pattern/min-max/enum/const/format).
2) Implementar `dependencies` + testes.
3) Suportar `#/definitions` como alias.
4) Refactor de `$ref` resolver e cache key (fase técnica).
5) Só depois: drafts novos.


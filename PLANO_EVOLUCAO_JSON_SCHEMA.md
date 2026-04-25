# Plano de Evolução — JSON Schema no JsonFlow

Projeto: `d:\Ecossistema-Delphi\JsonFlow`

Este documento descreve um plano incremental (com critérios de aceite e testes) para elevar a cobertura e a confiabilidade de validação JSON Schema, com foco em validações profundas (ramificações) e cenários com chaves repetidas em nós diferentes.

**Importante (governança):** este plano é apenas de leitura/decisão. Qualquer alteração de código deve ser executada somente após sua autorização explícita, por fase.

---

## 1) Objetivo

1) Fazer com que validações de keywords comuns funcionem **em qualquer profundidade**, e não apenas no nível raiz.
2) Garantir que erros reportem **Path** correto (JSON Pointer) e, idealmente, também **SchemaPath**.
3) Fortalecer `$ref` (local + arquivos) com base URI e proteção contra circularidade.
4) Preservar compatibilidade do framework (API pública e estilo) e permitir evolução em fases.

---

## 2) Estado Atual (resumo técnico)

### 2.1 O que já existe e deve ser preservado

- Arquitetura “compiler → rules → visitor aplica rules” no validador principal.
- `TValidationContext` com path em JSON Pointer e escape RFC6901.
- Regras (units `JsonFlow.ValidationRules.*`) já criadas para várias keywords.
- `TJSONSchemaNavigator` com suporte a JSON Pointer/anchor e loading de schema externo por arquivo.

### 2.2 Gargalo que impede validação profunda

- Regras estruturais como `properties` e `items` hoje validam subschemas de forma parcial (tendem a aplicar só `type` e descidas limitadas), então keywords como `minLength`, `pattern`, `minimum`, `required`, combinadores e condicionais não se propagam corretamente para níveis mais profundos.

---

## 3) Princípios de Design (para evitar retrabalho)

1) **Avaliação de subschema em um único lugar**: sempre que um valor precisar ser validado contra um subschema (ex.: dentro de `properties`, `items`, `anyOf`…), deve existir um “ponto único” interno que:
   - receba o `IJSONElement` do subschema;
   - compile/obtenha regras para aquele subschema (com cache);
   - aplique todas as regras ao valor;
   - retorne `TValidationResult`.

2) **Separar papéis (mesmo que em poucas classes)**:
   - resolução de referência (`$ref`)
   - compilação
   - contexto de avaliação (paths)
   - despacho de keywords (rules)
   - coleta e formatação de erros

3) **Compatibilidade primeiro**:
   - manter API pública;
   - introduzir novas estruturas como internas;
   - evoluir keyword por keyword com testes.

---

## 4) Escopo de Draft (meta)

O projeto declara foco em Draft-07 (meta-schema embutido e validator default). O plano abaixo assume:

- **Meta-alvo principal:** Draft-07 com boa cobertura pragmática.
- **Versões adicionais:** manter detecção por `$schema`, mas executar de forma conservadora (sem prometer conformidade total em 2019-09/2020-12 enquanto não houver implementação dedicada).

---

# 5) Roadmap em Fases

Cada fase contém: escopo, arquivos candidatos, critérios de aceite e testes DUnitX sugeridos.

---

## Trilha transversal — Higiene e simplificação

Esta trilha roda em paralelo às fases quando aparecerem pontos fora do padrão ou complexidade desnecessária.

### H1 — Remover métricas (limpeza)

Escopo:

- Remover/neutralizar toda a infraestrutura de métricas/telemetria de validação (timers, contadores, estruturas e APIs públicas associadas).
- Garantir que o validador e os testes funcionem sem dependência de métricas.

Critérios de aceite:

- Compilação sem warnings/AV relacionados a métricas.
- Nenhuma referência a `EnableMetrics`, `TValidationMetrics`, `ResetMetrics`, `GetMetrics` no núcleo de validação.

### H2 — Padronização de código (refactor contínuo)

Escopo:

- Ao tocar em qualquer unit, alinhar com o padrão do projeto:
  - variáveis locais `L...`, membros `F...`, constantes `C_...`, privados `_...`.
  - mover testes para a pasta/categoria correta quando necessário.

Critérios de aceite:

- Novas alterações não adicionam código fora do padrão.
- Estrutura de testes segue por categoria (ex.: `Tests/Schema/Validators/*`).

### Pós-resolução (retomar depois)

- Reintroduzir **métricas** e **cache/memoization** apenas após a validação estar correta e estável.
- Implementar como addon/feature flag para não poluir o núcleo do validador.

## Fase 0 — Baseline e “grade de aceitação”

### Escopo

1) Definir um conjunto mínimo de casos “verdade/falso” para:
   - tipos, strings, números, arrays e objetos;
   - validação profunda (nível 3+);
   - chaves repetidas em ramos diferentes;
   - mensagens com `Path` correto.
2) Mapear onde esses testes devem morar (padrão já existente em `Tests\Schema\*`).

### Arquivos candidatos

- `Tests\Schema\Validators\JsonFlow.TestsSchemaValidator*.pas`
- `Tests\Schema\Core\JsonFlow.TestsSchemaComposerDuplicate.pas` (já tem muitos cenários, dá para extrair casos menores)

### Critérios de aceite

- Uma suite pequena e objetiva que falha hoje nos pontos de profundidade e serve como “régua” do progresso.

### Testes sugeridos (nomes/temas)

- `TSchemaDeepValidationTests.Test_Path_Distinguishes_SameKey_In_Different_Branches`
- `TSchemaDeepValidationTests.Test_Nested_MinLength_Applies`
- `TSchemaDeepValidationTests.Test_Nested_Required_Applies`

---

## Fase 1 — Avaliação completa de subschema (fundação)

### Por que esta fase é a chave

Sem isso, qualquer keyword nova continuará funcionando “só em alguns lugares”. Esta fase cria o “motor” que permite cobertura real em profundidade.

### Escopo

1) Criar um mecanismo interno: **EvaluateSubschema(AValue, ASubschema, AContext)**.
2) Refatorar `properties` e `items` para usar esse mecanismo, em vez de validar subschema manualmente.
3) Garantir que `Path` seja preservado e acumulado via `TValidationContext`.

### Arquivos candidatos

- `Source\Schema\Validators\JsonFlow.SchemaValidator.pas`
- `Source\Schema\Validators\JsonFlow.ValidationRules.Properties.pas`
- `Source\Schema\Validators\JsonFlow.ValidationRules.Items.pas`
- `Source\Schema\Core\JsonFlow.ValidationEngine.pas` (se precisar enriquecer contexto)

### Critérios de aceite

- `minLength/pattern/minimum/maximum/required` passam a funcionar em propriedades aninhadas.
- Arrays aninhados passam a validar itens com as mesmas keywords de nível raiz.
- Casos com `cliente.endereco.cidade` e `fornecedor.endereco.cidade` retornam paths distintos e corretos.

### Testes DUnitX sugeridos

- `TSchemaDeepValidationTests.Test_Object_Deep_String_MinLength`
- `TSchemaDeepValidationTests.Test_Object_Deep_Number_Range`
- `TSchemaDeepValidationTests.Test_Array_Deep_Items_String_Pattern`
- `TSchemaDeepValidationTests.Test_SameKey_In_DifferentBranches_DoesNotCollide`

---

## Fase 2 — Cobertura forte de keywords de objeto

### Escopo

1) `required` em profundidade (incluindo em subschemas dentro de `allOf/if/then/else`).
2) `additionalProperties` com distinção clara:
   - boolean
   - schema (validar propriedades adicionais contra um subschema)
3) `patternProperties` (validar chaves que batem regex).
4) `propertyNames` (validar o nome da propriedade por um subschema).
5) `minProperties/maxProperties`.

### Arquivos candidatos

- `Source\Schema\Validators\JsonFlow.ValidationRules.AdditionalProperties.pas`
- `Source\Schema\Validators\JsonFlow.ValidationRules.PatternProperties.pas`
- `Source\Schema\Validators\JsonFlow.ValidationRules.PropertyNames.pas`
- `Source\Schema\Validators\JsonFlow.ValidationRules.Required.pas`

### Critérios de aceite

- Um objeto aninhado viola `additionalProperties: false` e o erro aponta para a chave excedente.
- `patternProperties` aplica validação para chaves que casam regex, inclusive com chaves repetidas em ramos diferentes.
- `propertyNames` valida o “nome da tag” (chave) e retorna erro com `Path` no ponto correto.

### Testes sugeridos

- `TObjectKeywordsTests.Test_AdditionalProperties_False_Nested`
- `TObjectKeywordsTests.Test_AdditionalProperties_Schema_Nested`
- `TObjectKeywordsTests.Test_PatternProperties_Nested`
- `TObjectKeywordsTests.Test_PropertyNames_Nested`

---

## Fase 3 — Cobertura forte de keywords de array

### Escopo

1) `items` com as duas formas do Draft-07:
   - schema único
   - array de schemas por posição (tuple validation)
2) `additionalItems` (quando `items` for array).
3) `contains` + `minContains/maxContains` (se decidir antecipar comportamento moderno, deixar claro no comportamento).
4) `uniqueItems`, `minItems/maxItems` em profundidade.

### Arquivos candidatos

- `Source\Schema\Validators\JsonFlow.ValidationRules.Items.pas`
- `Source\Schema\Validators\JsonFlow.ValidationRules.Contains.pas`
- `Source\Schema\Validators\JsonFlow.ValidationRules.UniqueItems.pas`

### Critérios de aceite

- Tuple validation funciona: `items: [{...}, {...}]` valida por índice.
- Quando excede a quantidade de schemas do tuple, `additionalItems` decide se permite/valida.
- `contains` detecta pelo menos um item válido e reporta erro quando nenhum satisfaz.

### Testes sugeridos

- `TArrayKeywordsTests.Test_Items_SingleSchema_Deep`
- `TArrayKeywordsTests.Test_Items_TupleSchemas_ByIndex`
- `TArrayKeywordsTests.Test_AdditionalItems_False`
- `TArrayKeywordsTests.Test_Contains_Nested`

---

## Fase 4 — Combinadores e condicionais (com rastreabilidade)

### Escopo

1) Garantir comportamento correto e consistente de:
   - `allOf`
   - `anyOf`
   - `oneOf`
   - `not`
2) `if/then/else` com paths precisos.
3) Padronizar como os erros são agregados:
   - em `anyOf/oneOf`, o que retorna quando falha?
   - manter mensagens úteis sem explodir volume.

### Arquivos candidatos

- `Source\Schema\Validators\JsonFlow.ValidationRules.AllOf.pas`
- `Source\Schema\Validators\JsonFlow.ValidationRules.AnyOf.pas`
- `Source\Schema\Validators\JsonFlow.ValidationRules.OneOf.pas`
- `Source\Schema\Validators\JsonFlow.ValidationRules.NotRule.pas`
- `Source\Schema\Validators\JsonFlow.ValidationRules.Conditional.pas`

### Critérios de aceite

- `oneOf` falha quando 0 ou >1 schemas batem.
- `anyOf` falha quando nenhum bate.
- `if/then/else` escolhe corretamente o ramo e aplica validações profundas.

### Testes sugeridos

- `TCombinatorsTests.Test_AllOf_Aggregates_Errors_WithPaths`
- `TCombinatorsTests.Test_AnyOf_Failure_Message_And_Path`
- `TCombinatorsTests.Test_OneOf_MultipleMatches_Fails`
- `TConditionalTests.Test_IfThenElse_Deep`

---

## Fase 5 — `$ref`, `$defs`, base URI e circularidade (hardening)

### Escopo

1) Consolidar resolução de referências para reduzir divergência:
   - decidir se o `TSchemaCompiler` passa a usar `TJSONSchemaNavigator` internamente, ou se o navigator passa a ser o resolver padrão.
2) Evoluir cache key do schema compilado:
   - não depender só do JSON textual (`AsJSON`), incluir contexto mínimo (base URI + localização/pointer).
3) Suportar arquivos externos com `$ref` relativos:
   - `./schemas/endereco.json#/...`
4) Detecção de referência circular e limite de profundidade:
   - reaproveitar estratégia do navigator safe.
5) Definir claramente escopo de HTTP:
   - manter desabilitado por padrão;
   - se habilitar, fazer opt-in e com cache.

### Arquivos candidatos

- `Source\Schema\Composition\JsonFlow.SchemaNavigator.pas`
- `Source\Schema\Validators\JsonFlow.SchemaValidator.pas` (resolver/caching)
- `Source\Schema\IO\JsonFlow.SchemaReader.pas` (base path e fluxo de validação)

### Critérios de aceite

- `$ref` local `#/$defs/...` funciona em qualquer profundidade.
- `$ref` para arquivo funciona com base path.
- Circularidade é detectada e reportada sem stack overflow.

### Testes sugeridos

- `TRefResolutionTests.Test_LocalDefs_Ref_Deep`
- `TRefResolutionTests.Test_FileRef_WithRelativePath`
- `TRefResolutionTests.Test_CircularRef_Detected`

---

## Fase 6 — Melhorar diagnósticos: `SchemaPath`, mensagens e logs

### Escopo

1) Popular `SchemaPath` em `TValidationError`.
2) Uniformizar mensagens e “Keyword” em falhas.
3) Logs úteis (opcionais) por:
   - início/fim de compile
   - dispatch de keyword
   - resolução de `$ref`
   - transição de path

### Arquivos candidatos

- `Source\JSON\Core\JsonFlow.Interfaces.pas` (estrutura do erro já existe)
- `Source\Schema\Core\JsonFlow.ValidationEngine.pas`
- `Source\Schema\Validators\JsonFlow.SchemaValidator.pas`
- `Source\Schema\Validators\JsonFlow.ValidationRules.*.pas`

### Critérios de aceite

- Em um erro, além de `Path`, o `SchemaPath` aponta para a keyword/trecho do schema que falhou (ex.: `/properties/endereco/properties/cep/minLength`).
- Logs podem ser ativados sem custo alto em produção (já há gating por `EnableDetailedLogging`).

---

# 6) Casos-âncora (os que provam que “ramificações profundas” estão resolvidas)

## Caso A — Mesmo nome de tag em nós diferentes

Schema: objeto com `cliente` e `fornecedor`, ambos com `endereco.cep` com regras diferentes.

Critério: erro deve apontar exatamente:

- `/cliente/endereco/cep` quando o cliente falha
- `/fornecedor/endereco/cep` quando o fornecedor falha

## Caso B — Subschema profundo com `required` e `additionalProperties`

Critério: faltas e extras devem ser detectados no nível correto, sem “vazar” para o pai.

## Caso C — Array profundo com tuple `items` + `additionalItems`

Critério: validação por índice, e excesso controlado por `additionalItems`.

---

# 7) Critérios de “Pronto para Produção” (para considerar o schema maduro)

1) Cobertura estável de keywords essenciais em profundidade:

- objeto: `type`, `properties`, `required`, `additionalProperties`, `patternProperties`, `propertyNames`
- array: `items` (schema e tuple), `additionalItems`, `minItems/maxItems`, `uniqueItems`, `contains`
- valores: `minLength/maxLength/pattern`, `minimum/maximum/exclusive*/multipleOf`, `enum/const`, `format`
- lógica: `allOf/anyOf/oneOf/not`, `if/then/else`
- refs: `$ref`, `$defs`, arquivo externo (HTTP opcional)

2) Testes:

- pelo menos 1 fixture por família (objeto/array/refs/combinadores/condicionais)
- casos válidos e inválidos
- asserts de `Path` e (quando implementado) `SchemaPath`

3) Performance:

- cache de schema compilado com chave correta (context-aware)
- sem regressões graves em cenários comuns (validar 10k objetos simples)

---

# 8) Pedido de autorização (para execução)

Quando você estiver confortável com o plano, a ordem recomendada de execução é:

1) **Fase 0** (criar a régua de testes)
2) **Fase 1** (avaliação completa de subschema)

Essas duas já devem atacar diretamente o problema que você citou (profundidade + chaves repetidas em ramos diferentes). Depois seguimos para as demais.

Quando você quiser, me diga:

- “Autorizo executar a Fase 0”

e eu preparo os testes iniciais (sem mudar o comportamento além do necessário). Depois disso, peço sua autorização novamente para a Fase 1.

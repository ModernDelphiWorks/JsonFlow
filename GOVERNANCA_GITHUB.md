# Governança GitHub — JsonFlow (Sprint / Issues / Project Cards)

Repositório: `https://github.com/ModernDelphiWorks-Ent/JsonFlow`

Project (GitHub Projects): **JsonFlow-Project** (privado, apenas assinantes)

Este arquivo documenta a governança acordada (modelo final):

- Criar **Sprint** para execução das etapas.
- Cada etapa = **1 Issue no repo principal (público)** + **1 Card no Project privado (assinantes)**.
- O público acompanha **somente as Issues** no repo principal.
- O Project privado é apenas para gerenciamento interno.
- Ao concluir a etapa internamente, a Issue do repo principal deve ser **fechada** (manual ou automação).
- O assistente **não faz push/PR/release**.

---

## 1) Estrutura sugerida da esteira (colunas) — Project privado

Se o `JsonFlow-Project` ainda não tiver colunas, sugestão mínima:

- `Backlog`
- `Ready`
- `In Progress`
- `Review`
- `Done`

Automação (opcional):

- Como o Project é **privado**, a automação serve apenas para assinantes.
- O GitHub não fecha Issues automaticamente só por mover item de Project. Para fechar automaticamente, é necessário automação via API (ex.: GitHub Actions/GraphQL) com permissão para fechar Issue no repo principal.

---

## 2) Sprint (inicialização)

### Sprint sugerida

- Nome: `JSON Schema Evolution - Sprint 01`
- Objetivo: Implementar evolução por fases do arquivo `PLANO_EVOLUCAO_JSON_SCHEMA.md`

Observação: datas (início/fim) você define conforme seu calendário. Se você me disser as datas, eu atualizo este arquivo com o período.

---

## 3) Backlog de etapas (Issues públicas e Cards privados)

Fonte do plano: `PLANO_EVOLUCAO_JSON_SCHEMA.md`

Cada item abaixo corresponde a:

- 1 **Issue no repo principal (público)**
- 1 **Card no `JsonFlow-Project` (privado, assinantes)**

### ETAPA 0 — Baseline (régua de testes)

- Issue title: `[Schema Evolution] Fase 0 - Baseline de testes e grade de aceitação`
- Labels sugeridos: `schema`, `tests`, `governance`
- Card: criar no `JsonFlow-Project` e colocar em `Backlog` (ou `Ready` se for iniciar agora)
- Definition of Done:
  - Suite DUnitX mínima com casos de profundidade (nível 3+) e chaves repetidas em ramos diferentes.
  - Pelo menos 3 testes falhando hoje para provar o gap (deep validation).

### ETAPA 1 — Avaliação completa de subschema (fundação)

- Issue title: `[Schema Evolution] Fase 1 - Avaliação completa de subschema (deep validation)`
- Labels sugeridos: `schema`, `core`, `refactor-safe`
- Card: `Backlog`
- Definition of Done:
  - `properties` e `items` passam a validar subschemas usando um mecanismo único.
  - Casos-âncora com chaves repetidas em ramos diferentes passam com `Path` correto.

### ETAPA 2 — Keywords de objeto (cobertura forte)

- Issue title: `[Schema Evolution] Fase 2 - Keywords de objeto (required/additionalProperties/patternProperties/propertyNames)`
- Labels sugeridos: `schema`, `object-keywords`
- Card: `Backlog`
- Definition of Done:
  - `required`, `additionalProperties` (boolean e schema), `patternProperties`, `propertyNames`, `minProperties/maxProperties` funcionando em profundidade.

### ETAPA 3 — Keywords de array (cobertura forte)

- Issue title: `[Schema Evolution] Fase 3 - Keywords de array (items/tuple/additionalItems/contains/uniqueItems)`
- Labels sugeridos: `schema`, `array-keywords`
- Card: `Backlog`
- Definition of Done:
  - `items` schema único + tuple por índice.
  - `additionalItems` quando `items` for array.
  - `contains` e `uniqueItems` funcionando em profundidade.

### ETAPA 4 — Combinadores e condicionais

- Issue title: `[Schema Evolution] Fase 4 - Combinadores e condicionais (allOf/anyOf/oneOf/not/if-then-else)`
- Labels sugeridos: `schema`, `logic`
- Card: `Backlog`
- Definition of Done:
  - Combinadores e `if/then/else` com agregação de erros consistente e paths precisos.

### ETAPA 5 — `$ref`, `$defs`, base URI e circularidade (hardening)

- Issue title: `[Schema Evolution] Fase 5 - Hardening de refs ($ref/$defs/baseURI/circularidade)`
- Labels sugeridos: `schema`, `refs`
- Card: `Backlog`
- Definition of Done:
  - `$ref` local e por arquivo (relativo) funcionando.
  - Proteção contra circularidade.
  - Cache de schema compilado context-aware (não só `AsJSON`).

### ETAPA 6 — Diagnósticos (SchemaPath/logs/mensagens)

- Issue title: `[Schema Evolution] Fase 6 - Diagnósticos (SchemaPath, logs e padronização de erros)`
- Labels sugeridos: `schema`, `observability`
- Card: `Backlog`
- Definition of Done:
  - `SchemaPath` populado e mensagens padronizadas.
  - Logs úteis com gating (produção vs debug).

---

## 4) Ritual por sessão (obrigatório)

Ao iniciar uma sessão:

1) Identificar qual etapa está ativa.
2) Mover o Card da etapa para a coluna correta (ex.: `In Progress`) no Project privado.
3) Manter a Issue pública atualizada (comentário curto quando necessário).
4) Se a etapa foi concluída:
   - mover Card para `Done` (privado).
   - fechar a Issue no repo principal (público).

---

## 5) Observações

- Eu não farei push/PR/release.
- Como o Project é privado, ele não serve como vitrine pública; a vitrine pública é o conjunto de Issues no repo principal.
- Se você quiser fechamento automático de Issue quando o Card privado chegar em `Done`, isso exigirá uma automação com token que tenha acesso ao Project privado e permissão para fechar Issues no repo principal.

---

## 6) Automação (opcional) — Fechar Issue pública quando Card privado estiver em Done

Arquivos incluídos no repositório:

- `.github/workflows/project_done_close_issues.yml`

### Como funciona

- A automação roda a cada 30 minutos (e também pode ser executada manualmente).
- Ela lê o Project privado (`JsonFlow-Project`) via GraphQL e procura itens com `Status = Done`.
- Para cada item que referencia uma Issue do repo público `ModernDelphiWorks-Ent/JsonFlow` ainda aberta, ela fecha a Issue e comenta.

Observação importante:

- O parâmetro `dry_run` vem do `workflow_dispatch` (inputs do evento). No script, ele deve ser lido via `context.payload.inputs.dry_run`.

### O que você precisa configurar (no GitHub)

1) Criar/usar um token (PAT) com permissões para:
   - ler o Project privado (Projects v2)
   - fechar issues no repo público

2) Adicionar esse token como secret **no repo onde o workflow vai rodar**:

- Secret name: `PROJECT_SYNC_PAT`

Passo a passo no GitHub:

- `Settings` → `Secrets and variables` → `Actions` → `New repository secret`
- Name: `PROJECT_SYNC_PAT`
- Value: (colar o token)

### Ajustes que você pode precisar fazer

No arquivo `.github/workflows/project_done_close_issues.yml`, revise estes valores:

- `PROJECT_OWNER` (org/usuário dono do Project)
- `PROJECT_NUMBER` (número do Project na URL)
- `STATUS_FIELD_NAME` (nome do campo de status)
- `DONE_OPTION_NAME` (nome da opção Done)
- `TARGET_REPO` (repo público que contém as issues)

Modelo deste projeto (atual):

- Project privado: `ModernDelphiWorks-Ent/projects/1`
- Repo público (issues): `ModernDelphiWorks/JsonFlow`

Logo:

- `PROJECT_OWNER=ModernDelphiWorks-Ent`
- `PROJECT_NUMBER=1`
- `TARGET_REPO=ModernDelphiWorks/JsonFlow`

### Backlog já criado (referência)

Milestone pública criada no repo `ModernDelphiWorks/JsonFlow`:

- `JSON Schema Evolution - Sprint 01`

Issues (todas com a milestone acima):

- Fase 0: `#4`
- Fase 1: `#5`
- Fase 2: `#6`
- Fase 3: `#7`
- Fase 4: `#8`
- Fase 5: `#9`
- Fase 6: `#10`

Teste de automação (fechamento automático validado):

- `#11` (`automation-test`) — item em `Done` fechou a issue via workflow.

### Modo seguro (recomendado para o primeiro teste)

- Rodar manualmente com `dry_run=true`.
- Conferir o log do workflow.
- Depois rodar com `dry_run=false`.

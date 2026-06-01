# Checklist de release (JSON Schema)

## Qualidade

- Rodar `JsonFlow.Schema.Tests` e validar `ExitCode: 0`
- Rodar `JsonFlow.Tests` (suite JSON geral) e validar `ExitCode: 0`

## Compatibilidade

- Garantir que `TJSONSchemaReader` mantém API pública
- Confirmar que mensagens/keywords mudaram somente quando testado e documentado

## Diagnósticos

- Verificar que `TValidationError.Path` (JSON Pointer) e `TValidationError.SchemaPath` são preenchidos em casos-chave

## Referências

- Confirmar `$ref` local (`#/$defs/...`) em profundidade
- Confirmar `$ref` por arquivo relativo (base URI via `$id`)
- Confirmar circularidade sem stack overflow

## Governança (GitHub)

- Card da fase em **Done** ao concluir
- Issue da fase **Closed** (ou marcada como duplicada quando apropriado)
- Comentário na issue com resumo e resultado dos testes (found/passed)

## Documentação e exemplos

- Atualizar `README.md` com links
- Manter `Docs/JSONSchema.md` atualizado
- Exemplo compilável em `Examples/` cobrindo: deep validation, `$ref`, `SchemaPath`


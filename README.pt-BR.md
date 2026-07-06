<p align="center">
  <img src="assets/logo.png" alt="JsonFlow Logo" width="380"/>
</p>

# JsonFlow — Serialização de JSON de alta performance, manipulação dinâmica e validação de Schema Draft-7 para Delphi/Lazarus

[![Delphi XE+](https://img.shields.io/badge/Delphi-XE%20ou%20superior-blue.svg)]()
[![Lazarus Compatible](https://img.shields.io/badge/Lazarus-Compatível-orange.svg)]()
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![CRA-ready](https://img.shields.io/badge/CRA--ready-SBOM%20%2B%20Security%20policy-success)](https://www.pubpascal.dev/packages/jsonflow)

<div align="center">

[English](README.md) · **Português (PT-BR)**

</div>

---

**JsonFlow** é um framework moderno, de alta performance e rico em recursos para manipulação, serialização e validação de JSON Schema Draft 7 em Delphi e Lazarus. Ele fornece um toolkit robusto e corporativo que integra perfeitamente serialização ultra-rápida de objetos, escrita e leitura dinâmica in-place e validação estruturada. Equipado com cache de navegação inteligente, otimizações em lote (batch processing) e pool de objetos multi-thread, o JsonFlow oferece taxas de vazão incomparáveis para servidores, microsserviços e APIs construídas em Object Pascal.

### 🚀 Recursos Principais

*   **Serialização e Deserialização Avançada:** Conversão automatizada de objetos Delphi para JSON e vice-versa usando atributos customizados e pipelines extensíveis.
*   **Composer Dinâmico In-Place:** Carregue e modifique estruturas JSON em tempo de execução usando strings de caminho simples e legíveis (ex: `usuario.endereco[0].cep`).
*   **Validação de JSON Schema Draft 7:** Valide seus dados JSON contra especificações Draft 7 com mapeamento detalhado dos erros (`Path` e `SchemaPath`).
*   **Otimizações Nativas de Performance:**
    *   *Cache de Navegação:* Busca de caminhos repetitivos até 2,5× mais rápida.
    *   *Batch Processing:* Atualizações em massa no JSON até 3,4× mais rápidas.
    *   *Object Pooling:* `TPooledJSONComposer` seguro para multi-threads com velocidade 3,0× superior em laços intensivos.
*   **Middlewares de Processamento:** Criptografe, descriptografe ou formate campos de JSON (como CPFs, CNPJs e datas) dinamicamente no fluxo.
*   **Fila de Validação Assíncrona:** Fila thread-safe em segundo plano para validação em lote com controle de priorização de tarefas.

### 🏛 Matriz de Compatibilidade

| Ambiente / IDE | Plataforma / Compilador | Validador Draft 7 | Pooling de Objetos |
| :--- | :--- | :---: | :---: |
| **Delphi XE ou superior** | VCL, FMX, Console (Win/Linux/macOS/iOS/Android) | ✅ Sim | ✅ Sim |
| **Lazarus / FreePascal** | LCL, Console (Multiplataforma) | ✅ Sim | ✅ Sim |

### 📊 Performance & Benchmarks

Abaixo está o gráfico comparativo demonstrando a superioridade de performance do JsonFlow frente ao JSON nativo do Delphi:

<p align="center">
  <img src="assets/benchmarks.png" alt="Gráfico Comparativo de Performance do JsonFlow" width="800"/>
</p>

O JsonFlow também foi comparado com a popular biblioteca [X-SuperObject](https://github.com/onryldz/x-superobject) — cenário Complex Class (1K a 5K objetos `TCustomer` com `Address` e `Contacts` aninhados). Na escala de 5K (Release, Win32): **deserialização ~6× mais rápida** (50ms vs 316ms) e **serialização ~15× mais rápida** (19ms vs 282ms):

<p align="center">
  <img src="assets/benchmarks-xsuperobject.png" alt="Gráfico Comparativo JsonFlow vs X-SuperObject" width="800"/>
</p>

> **Metodologia:** entidades e massas de dados idênticas para as duas bibliotecas (a mesma suíte usada na comparação com o TJSON nativo acima); o parse do texto JSON fica fora do cronômetro nos dois lados, então os gráficos medem o marshalling puro de objetos; o X-SuperObject recebeu enums como ordinal na entrada, pois a biblioteca não suporta enum como string. Código-fonte completo do benchmark: [`Examples/VCL/JsonFlowBenchmarkXSO`](Examples/VCL/JsonFlowBenchmarkXSO).

### 🐧 Build Multiplataforma — Win32 / Win64 / Linux64

> **Win32 / Win64:** ✅ verificado (2026-06-20, backend real em produção). **Linux64:** as units usadas pelo backend compilam e rodam no Linux; um **build standalone do framework completo** esbarra hoje num **item interno (não-plataforma)** — `IEventMiddleware` está declarado em **ambas** `JsonFlow.Types` e `JsonFlow.Interfaces`, então puxar as duas é ambíguo. Escolher a declaração canônica é um follow-up — **não** é problema de plataforma.

**Para buildar um app consumidor no Linux64:** instale a plataforma Linux 64-bit (RAD Studio GetIt / `GetItCmd -if=delphi_linux -ae`), forneça um SDK Linux (SDK Manager do RAD Studio + PAServer, **ou** um sysroot montado de um toolchain WSL/Linux passado ao `dcclinux64` via `--syslibroot` / `--libpath`), e compile com `dcclinux64`.

### ⚙️ Instalação

**Boss** (recomendado):

```sh
boss install JsonFlow
```

**PubPascal** (portal de pacotes): [pubpascal.dev/packages/jsonflow](https://www.pubpascal.dev/packages/jsonflow)

---

### ⚡️ Início Rápido

#### 1. Serialização Automática de Objetos

```delphi
uses
  JsonFlow.Serializer,
  JsonFlow.Interfaces;

var
  LSerializer: TJSONSerializer;
  LJson: string;
  LUser, LUserCopy: TUser;
begin
  LSerializer := TJSONSerializer.Create;
  try
    LUser := TUser.Create;
    LUser.Name := 'João Silva';
    LUser.Age := 30;

    // Objeto para String JSON
    LJson := LSerializer.ObjectToJSON(LUser);

    // String JSON de volta para Objeto
    LUserCopy := LSerializer.JSONToObject<TUser>(LJson);
  finally
    LSerializer.Free;
  end;
end;
```

#### 2. Edição Dinâmica In-Place (TJSONComposer)

```delphi
uses
  JsonFlow.Composer;

var
  LComposer: TJSONComposer;
  LJsonInput, LUpdatedJson: string;
begin
  LJsonInput := '{"usuario":{"nome":"João","idade":30},"tags":["dev"]}';

  LComposer := TJSONComposer.Create;
  try
    LComposer.LoadJSON(LJsonInput);

    LComposer.EnableCache(1000); // Ativa cache de caminhos
    LComposer.BeginBatch;
    try
      LComposer.SetValue('usuario.idade', 31);
      LComposer.AddToArray('tags', 'lead');
      LComposer.SetValue('usuario.email', 'joao@email.com');
    finally
      LComposer.EndBatch;
    end;

    LUpdatedJson := LComposer.Generate;
  finally
    LComposer.Free;
  end;
end;
```

#### 3. Validação de JSON Schema Draft 7

```delphi
uses
  JsonFlow.SchemaValidator,
  JsonFlow.Interfaces;

var
  LValidator: TSchemaValidator;
  LSchema, LData: IJSONElement;
  LErrors: TList<TValidationError>;
begin
  LValidator := TSchemaValidator.Create;
  try
    LSchema := TJSONElement.ParseFromString(
      '{"type":"object","properties":{"name":{"type":"string","minLength":2}},"required":["name"]}');
    LData := TJSONElement.ParseFromString('{"name":"A"}'); // Falha no minLength

    LValidator.Schema := LSchema;
    LErrors := LValidator.Validate(LData);

    if LErrors.Count > 0 then
      WriteLn('Validação falhou no path: ' + LErrors[0].Path);
  finally
    LValidator.Free;
  end;
end;
```

---

## ⛏️ Contribuição

Contribuições são bem-vindas — relatórios de bugs, melhorias de documentação e pull requests são muito apreciados.

[![Issues](https://img.shields.io/badge/Issues-channel-orange)](../../issues)

**Passos:**

1. Faça um fork do repositório.
2. Crie uma branch de feature: `git checkout -b feat/my-feature`
3. Faça commit seguindo as convenções do projeto.
4. Abra um Pull Request para `main` descrevendo o que mudou e por quê.
5. Aguarde o feedback de revisão.

---

## 📬 Contato

[![Email](https://img.shields.io/badge/Email-isaquesp%40gmail.com-D14836?logo=gmail&logoColor=white)](mailto:isaquesp@gmail.com)

---

## 💲 Doação

Se o JsonFlow economiza seu tempo, considere apoiar o desenvolvimento.

[![Doação](https://img.shields.io/badge/Mercado%20Pago-contribua-blue)](https://link.mercadopago.com.br/isaquepinheiro)

---

## 📄 Licença

Distribuído sob a **Licença MIT**. Consulte [LICENSE](LICENSE) para mais detalhes.

*Copyright © 2025-2026 Isaque Pinheiro.*

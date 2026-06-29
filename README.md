<p align="center">
  <img src="assets/logo.png" alt="JsonFlow Logo" width="380"/>
</p>

# JsonFlow — High-performance JSON serialization, dynamic manipulation, and Draft-7 Schema validation for Delphi/Lazarus

[![Delphi XE+](https://img.shields.io/badge/Delphi-XE%20or%20superior-blue.svg)]()
[![Lazarus Compatible](https://img.shields.io/badge/Lazarus-Compatible-orange.svg)]()
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![CRA-ready](https://img.shields.io/badge/CRA--ready-SBOM%20%2B%20Security%20policy-success)](https://www.pubpascal.dev/packages/jsonflow)

> 🔒 **Supply-chain transparency (CRA-ready):** a machine-readable **SBOM** (CycloneDX) is published on the package portal — [pubpascal.dev/packages/jsonflow](https://www.pubpascal.dev/packages/jsonflow) · security disclosure policy in **[SECURITY.md](SECURITY.md)**.

📚 **[Documentation](https://moderndelphiworks.github.io/JsonFlow/)** · ⬇️ **[Download](../../releases)** · 🐛 **[Issues](../../issues)**

*   [🇬🇧 English](#-english)
*   [🇧🇷 Português](#-português)

---

## 🇬🇧 English

**JsonFlow** is a state-of-the-art, high-performance, and feature-rich JSON manipulation, serialization, and JSON Schema validation framework for Delphi and Lazarus. It provides an enterprise-ready toolkit that integrates high-speed object serialization, in-place dynamic JSON editing, and robust Draft 7 JSON Schema validation under a unified, elegant, and fluent API. By incorporating custom navigation caching, batch mode optimizations, and multi-threaded object pooling, JsonFlow delivers unmatched native parsing and validation speeds for intensive web applications, APIs, and microservices.

### 🚀 Key Features

*   **Advanced Serialization & Deserialization:** Fluidly convert Delphi objects to JSON structures and vice-versa using custom attributes, mapping rules, and extensible pipelines.
*   **In-Place Dynamic Composer:** Load and modify complex JSON structures in-place. Traverse nested elements fluidly using path strings (e.g., `user.address[0].zip`).
*   **Draft 7 JSON Schema Validation:** Fully validate JSON structures against Draft 7 specifications with detailed local error paths (`Path` and `SchemaPath`).
*   **Massive Performance Enhancements:**
    *   *Navigation Cache:* Up to 2.5× speed improvements for repeating JSON path traversals.
    *   *Batch Processing:* Up to 3.4× faster operations for bulk updates.
    *   *Object Pooling:* Thread-safe pooled composers yielding up to 3.0× faster creation/destruction cycles.
*   **Extensible Middleware System:** Intercept, encrypt, decrypt, or format specific JSON fields (e.g., dates, currency, custom types) on the fly.
*   **Asynchronous Validation Queue:** Multi-threaded, thread-safe background schema validation with prioritization.

### 🏛 Compatibility Matrix

| Environment / IDE | Platform / Compiler | Draft 7 Validator | Object Pooling |
| :--- | :--- | :---: | :---: |
| **Delphi XE or superior** | VCL, FMX, Console (Win/Linux/macOS/iOS/Android) | ✅ Yes | ✅ Yes |
| **Lazarus / FreePascal** | LCL, Console (Cross-platform) | ✅ Yes | ✅ Yes |

### 📊 Performance & Benchmarks

Below is a comparison of serialization, composition, and validation performance demonstrating JsonFlow's superiority against native Delphi JSON and other frameworks (e.g., Neon):

<p align="center">
  <img src="assets/benchmarks.png" alt="JsonFlow Performance Comparison Chart" width="800"/>
</p>

Additionally, here is a visual demo of our VCL benchmark suite executing intensive JSON operations:

<p align="center">
  <img src="assets/jsonflow.png" alt="VCL Benchmark Demo Interface" width="800"/>
</p>

### 🐧 Cross-Platform Build — Win32 / Win64 / Linux64

> **Win32 / Win64:** ✅ verified (2026-06-20, real production backend). **Linux64:** the units used by the backend compile and run on Linux; a **standalone full-framework Linux build** currently hits one **internal (non-platform) item** — `IEventMiddleware` is declared in **both** `JsonFlow.Types` and `JsonFlow.Interfaces`, so pulling both is ambiguous. Choosing the canonical declaration is a tracked follow-up — it is **not** a platform issue.

**Building a consumer app for Linux64:** install the Linux 64-bit platform (RAD Studio GetIt / `GetItCmd -if=delphi_linux -ae`), provide a Linux SDK (RAD Studio SDK Manager + PAServer, **or** a sysroot assembled from a WSL/Linux toolchain passed to `dcclinux64` via `--syslibroot` / `--libpath`), then compile with `dcclinux64`.

### ⚙️ Installation

**Boss** (recommended):

```sh
boss install JsonFlow
```

**PubPascal** package portal: [pubpascal.dev/packages/jsonflow](https://www.pubpascal.dev/packages/jsonflow)

---

### ⚡️ Quick Start

#### 1. Automatic Object Serialization

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
    LUser.Name := 'John Doe';
    LUser.Age := 30;

    // Object to JSON String
    LJson := LSerializer.ObjectToJSON(LUser);

    // JSON String back to Object
    LUserCopy := LSerializer.JSONToObject<TUser>(LJson);
  finally
    LSerializer.Free;
  end;
end;
```

#### 2. In-Place Dynamic Updating (TJSONComposer)

```delphi
uses
  JsonFlow.Composer;

var
  LComposer: TJSONComposer;
  LJsonInput, LUpdatedJson: string;
begin
  LJsonInput := '{"user":{"name":"John","age":30},"tags":["dev"]}';

  LComposer := TJSONComposer.Create;
  try
    LComposer.LoadJSON(LJsonInput);

    LComposer.EnableCache(1000); // Navigation cache optimization
    LComposer.BeginBatch;
    try
      LComposer.SetValue('user.age', 31);
      LComposer.AddToArray('tags', 'lead');
      LComposer.SetValue('user.email', 'john@email.com');
    finally
      LComposer.EndBatch;
    end;

    LUpdatedJson := LComposer.Generate;
  finally
    LComposer.Free;
  end;
end;
```

#### 3. Draft 7 JSON Schema Validation

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
    LData := TJSONElement.ParseFromString('{"name":"A"}'); // Fails minLength

    LValidator.Schema := LSchema;
    LErrors := LValidator.Validate(LData);

    if LErrors.Count > 0 then
      WriteLn('Validation failed on path: ' + LErrors[0].Path);
  finally
    LValidator.Free;
  end;
end;
```

---

## 🇧🇷 Português

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

Abaixo está o gráfico comparativo de performance de serialização, composição e validação demonstrando a superioridade do JsonFlow frente ao JSON nativo do Delphi e a outros frameworks (como o Neon):

<p align="center">
  <img src="assets/benchmarks.png" alt="Gráfico Comparativo de Performance do JsonFlow" width="800"/>
</p>

Adicionalmente, aqui está a captura da nossa aplicação de benchmark VCL executando as operações intensivas de JSON:

<p align="center">
  <img src="assets/jsonflow.png" alt="Interface VCL do Benchmark do JsonFlow" width="800"/>
</p>

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

## ⛏️ Contributing / Contribuição

Contributions are welcome — bug reports, documentation improvements, and pull requests all help.
Contribuições são bem-vindas — relatórios de bugs, melhorias de documentação e pull requests são muito apreciados.

[![Issues](https://img.shields.io/badge/Issues-channel-orange)](../../issues)

**Steps / Passos:**

1. Fork the repository / Faça um fork do repositório.
2. Create a feature branch: `git checkout -b feat/my-feature` / Crie uma branch de feature.
3. Commit your changes following the project conventions / Faça commit seguindo as convenções do projeto.
4. Open a Pull Request against `main` describing what changed and why / Abra um Pull Request para `main` descrevendo o que mudou e por quê.
5. Wait for review feedback / Aguarde o feedback de revisão.

---

## 📬 Contact / Contato

[![Email](https://img.shields.io/badge/Email-isaquesp%40gmail.com-D14836?logo=gmail&logoColor=white)](mailto:isaquesp@gmail.com)

---

## 💲 Donation / Doação

If JsonFlow saves you time, consider supporting its development.
Se o JsonFlow economiza seu tempo, considere apoiar o desenvolvimento.

[![Doação](https://img.shields.io/badge/PagSeguro-contribua-green)](https://pag.ae/bglQrWD)

---

## 📄 License / Licença

Distributed under the **MIT License**. See [LICENSE](LICENSE) for details.
Distribuído sob a **Licença MIT**. Consulte [LICENSE](LICENSE) para mais detalhes.

*Copyright © 2025-2026 Isaque Pinheiro.*

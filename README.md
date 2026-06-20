# JsonFlow for Delphi

[![Delphi XE+](https://img.shields.io/badge/Delphi-XE%20or%20superior-blue.svg)]()
[![Lazarus Compatible](https://img.shields.io/badge/Lazarus-Compatible-orange.svg)]()
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

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
    *   *Navigation Cache:* Up to 2.5x speed improvements for repeating JSON path traversals.
    *   *Batch Processing:* Up to 3.4x faster operations for bulk updates.
    *   *Object Pooling:* Thread-safe pooled composers yielding up to 3.0x faster creation/destruction cycles.
*   **Extensible Middleware System:** Intercept, encrypt, decrypt, or format specific JSON fields (e.g., dates, currency, custom types) on the fly.
*   **Asynchronous Validation Queue:** Multi-threaded, thread-safe background schema validation with prioritization.

### 🏛 Compatibility Matrix

| Environment / IDE | Platform / Compiler | Draft 7 Validator | Object Pooling |
| :--- | :--- | :---: | :---: |
| **Delphi XE or superior** | VCL, FMX, Console (Win/Linux/macOS/iOS/Android) | ✅ Yes | ✅ Yes |
| **Lazarus / FreePascal** | LCL, Console (Cross-platform) | ✅ Yes | ✅ Yes |

### 🐧 Cross-Platform Build — Win32 / Win64 / Linux64

> **Win32 / Win64:** ✅ verified (2026-06-20, real production backend). **Linux64:** the units used by the backend compile and run on Linux; a **standalone full-framework Linux build** currently hits one **internal (non-platform) item** — `IEventMiddleware` is declared in **both** `JsonFlow.Types` and `JsonFlow.Interfaces`, so pulling both is ambiguous. Choosing the canonical declaration is a tracked follow-up — it is **not** a platform issue.

**Building a consumer app for Linux64:** install the Linux 64-bit platform (RAD Studio GetIt / `GetItCmd -if=delphi_linux -ae`), provide a Linux SDK (RAD Studio SDK Manager + PAServer, **or** a sysroot assembled from a WSL/Linux toolchain passed to `dcclinux64` via `--syslibroot` / `--libpath`), then compile with `dcclinux64`.

### ⚙️ Installation

To install using the package manager [**Boss**](https://github.com/HashLoad/boss):

```sh
boss install JsonFlow
```

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
  LUser: TUser;
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
    LSchema := TJSONElement.ParseFromString('{"type":"object","properties":{"name":{"type":"string","minLength":2}},"required":["name"]}');
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
    *   *Cache de Navegação:* Busca de caminhos repetitivos até 2.5x mais rápida.
    *   *Batch Processing:* Atualizações em massa no JSON até 3.4x mais rápidas.
    *   *Object Pooling:* TPooledJSONComposer seguro para multi-threads com velocidade 3x superior em laços intensivos.
*   **Middlewares de Processamento:** Criptografe, descriptografe ou formate campos de JSON (como CPFs, CNPJs e datas) dinamicamente no fluxo.
*   **Fila de Validação Assíncrona:** Fila thread-safe em segundo plano para validação em lote com controle de priorização de tarefas.

### 🏛 Matriz de Compatibilidade

| Ambiente / IDE | Plataforma / Compilador | Validador Draft 7 | Pooling de Objetos |
| :--- | :--- | :---: | :---: |
| **Delphi XE ou superior** | VCL, FMX, Console (Win/Linux/macOS/iOS/Android) | ✅ Sim | ✅ Sim |
| **Lazarus / FreePascal** | LCL, Console (Multiplataforma) | ✅ Sim | ✅ Sim |

### 🐧 Build Multiplataforma — Win32 / Win64 / Linux64

> **Win32 / Win64:** ✅ verificado (2026-06-20, backend real em produção). **Linux64:** as units usadas pelo backend compilam e rodam no Linux; um **build standalone do framework completo** esbarra hoje num **item interno (não-plataforma)** — `IEventMiddleware` está declarado em **ambas** `JsonFlow.Types` e `JsonFlow.Interfaces`, então puxar as duas é ambíguo. Escolher a declaração canônica é um follow-up — **não** é problema de plataforma.

**Para buildar um app consumidor no Linux64:** instale a plataforma Linux 64-bit (RAD Studio GetIt / `GetItCmd -if=delphi_linux -ae`), forneça um SDK Linux (SDK Manager do RAD Studio + PAServer, **ou** um sysroot montado de um toolchain WSL/Linux passado ao `dcclinux64` via `--syslibroot` / `--libpath`), e compile com `dcclinux64`.

### ⚙️ Instalação

Para instalar usando o gerenciador de pacotes [**Boss**](https://github.com/HashLoad/boss):

```sh
boss install JsonFlow
```

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
  LUser: TUser;
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
    LSchema := TJSONElement.ParseFromString('{"type":"object","properties":{"name":{"type":"string","minLength":2}},"required":["name"]}');
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
*Copyright © 2025-2026 Isaque Pinheiro. Licensed under MIT License.*

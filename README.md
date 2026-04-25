# JsonFlow4D

Um framework completo e avançado para JSON em Delphi/Object Pascal, oferecendo:

- **Serialização/Deserialização**: Conversão automática entre objetos Delphi e JSON
- **TJSONComposer**: Criação fluente de dados JSON
- **TJSONSchemaComposer**: Criação fluente de JSON Schema
- **TSchemaValidator**: Validação robusta de JSON Schema

Com funcionalidades de alta performance, cache persistente, validação assíncrona e sistema de relatórios.

## 🚀 Características Principais

### Serialização e Deserialização
- 🔄 **Conversão automática** entre objetos Delphi e JSON
- 🎯 **Mapeamento inteligente** de propriedades
- 📝 **Suporte a tipos complexos** (arrays, objetos aninhados)
- ⚡ **Performance otimizada** para grandes volumes
- 🔧 **Configuração flexível** de serialização
- 📋 **Atributos personalizados** para controle fino
- 🔌 **Sistema de middleware** para serialização customizada
- 🎨 **Processamento personalizado** de tipos específicos

### 🔄 **Recurso Inovador: Leitura e Atualização Dinâmica de JSON**
- **Reader/Writer Integrado**: Leia dados de JSON existente e atualize-os dinamicamente
- **Navigator Avançado**: Navegue por estruturas JSON complexas usando paths intuitivos
- **Edição In-Place**: Modifique dados JSON sem recriar toda a estrutura
- **Operações Fluentes**: API fluente para carregar, editar e salvar JSON em uma única cadeia
- **Preservação de Estrutura**: Mantenha a integridade dos dados não modificados
- **Performance Otimizada**: Atualizações eficientes sem parsing completo

### Criação de JSON (TJSONComposer)
- 🎨 **API fluente para criação de JSON**
- 🔧 **Sintaxe intuitiva e encadeável**
- 📝 **Suporte a todos os tipos JSON**
- 🔄 **Métodos de conveniência**

#### 🚀 **Melhorias de Performance Nativas**

##### 🎯 Integração Transparente
Todas as melhorias de performance agora estão **integradas nativamente** no `TJSONComposer`, proporcionando:
- **✅ Transparência total**: Sem necessidade de classes separadas
- **✅ Compatibilidade**: Código existente continua funcionando
- **✅ Performance automática**: Otimizações ativadas conforme necessário
- **✅ API unificada**: Todas as funcionalidades em uma única classe

##### 💾 Cache de Navegação (Nativo)
```pascal
LComposer.EnableCache(1000);  // Ativa cache para 1000 paths
LStats := LComposer.GetCacheStats;  // Monitora performance
```
- **Cache automático**: Ativado com `EnableCache()`
- **Estatísticas**: Monitoramento com `GetCacheStats()`
- **Configurável**: Tamanho e comportamento personalizáveis
- **Ganho**: 2.5x mais rápido em operações repetitivas

##### 📦 Operações em Lote (Nativo)
```pascal
LComposer.BeginBatch;
  LComposer.SetValueFast('user.name', 'João');
  LComposer.AddToArrayFast('tags', 'importante');
LComposer.EndBatch;  // Executa todas de uma vez
```
- **Modo batch**: Ativado com `BeginBatch()` / `EndBatch()`
- **Execução otimizada**: Agrupa operações para melhor performance
- **Thread-safe**: Sincronização automática
- **Ganho**: 3.4x mais rápido em operações em massa

##### 🏊 Pool de Objetos (Nativo)
```pascal
// Pool automático
LPooled := TPooledJSONComposer.Create;
// Retorna automaticamente ao pool no Free
```
- **TJSONComposerPool**: Gerenciamento manual de pool
- **TPooledJSONComposer**: Pool automático com global singleton
- **Estatísticas**: Monitoramento de uso e reutilização
- **Ganho**: 3.0x mais rápido em cenários de alta criação/destruição

##### ⚡ Métodos Fast (Nativos)
```pascal
LComposer.SetValueFast('path', value);     // Com cache
LComposer.AddToArrayFast('array', item);   // Com batch
LComposer.RemoveKeyFast('key');            // Otimizado
```

##### 📊 Operações Avançadas (Nativas)
```pascal
LComposer.InsertIntoArray('items', 0, 'first');
LComposer.SetMultipleValues(['key1', 'val1', 'key2', 'val2']);
LComposer.AddMultipleToArray('tags', ['tag1', 'tag2', 'tag3']);
```

##### 🔧 Otimizações Predefinidas (Nativas)
```pascal
LComposer.OptimizeForReading;   // Cache grande
LComposer.OptimizeForWriting;   // Cache pequeno + batch
```

### Criação de Schema (TJSONSchemaComposer)
- 📋 **API fluente para JSON Schema**
- 🧠 **Sugestões inteligentes**
- 🎯 **Context-aware navigation**
- ✨ **Sintaxe fluente avançada**

### Validação Core (TSchemaValidator)
- ✅ **Validação completa de JSON Schema Draft 7**
- 🎯 **API simples e intuitiva**
- 🔍 **Mensagens de erro detalhadas**
- 📍 **Localização precisa de erros (Path e SchemaPath)**
- 🔗 **Resolução de `$ref`** (local em `$defs` e por arquivo relativo com base URI)
- 🎨 **Formatos customizados** extensíveis
- 🔧 **Validadores personalizados** (CPF, CEP, etc.)
- 📋 **Registro dinâmico** de novos formatos

Documentação focada em JSON Schema: `Docs/JSONSchema.md`.

### Performance e Otimização
- ⚡ **Cache inteligente de validação**
- 🧵 **Pool de objetos para gestão de memória**
- 🔄 **Cache persistente entre sessões**
- 📈 **Otimizações de hash e algoritmos**

### Funcionalidades Avançadas
- 🔀 **Validação assíncrona multi-thread**
- 📊 **Sistema completo de métricas**
- 📝 **Relatórios detalhados em múltiplos formatos**
- 🎛️ **Sistema de logging configurável**
- 🔌 **Arquitetura extensível**

### Sistema de Middleware
- 🔧 **Middleware para serialização** customizada
- 🎨 **Processamento personalizado** de tipos específicos
- 🔐 **Middleware de criptografia** para campos sensíveis
- 📅 **Middleware de data/hora** com formatação customizada
- 🔗 **Pipeline extensível** de processamento

### Formatos Customizados
- 🎯 **Validadores personalizados** (CPF, CNPJ, CEP)
- 🌍 **Formatos regionais** (Brasil, internacional)
- 📋 **Registro dinâmico** de novos formatos
- 🔧 **API simples** para criação de validadores
- ✅ **Integração transparente** com JSON Schema

### Formatos de Relatório
- 📄 **HTML** com gráficos interativos
- 📋 **JSON** para integração
- 📊 **CSV** para análise
- 🗂️ **XML** estruturado
- 📑 **PDF** para documentação
- 📝 **Texto** simples

## 📦 Instalação

### Método 1: Clone do Repositório

```bash
git clone https://github.com/seu-usuario/JsonFlow4D.git
cd JsonFlow4D
```

### Método 2: Download Direto

Baixe o ZIP do projeto e extraia em sua pasta de projetos.

### Configuração no Delphi

Adicione os seguintes caminhos ao **Library Path** do seu projeto:

```
$(ProjectDir)\Source\Core
$(ProjectDir)\Source\Schema
$(ProjectDir)\Source\Validation
$(ProjectDir)\Source\Performance
```

## 🎯 Início Rápido

### Exemplo de Serialização/Deserialização

```pascal
uses
  JsonFlow.Serializer,
  JsonFlow.Interfaces;

type
  TPessoa = class
  private
    FNome: string;
    FIdade: Integer;
    FEmail: string;
  public
    property Nome: string read FNome write FNome;
    property Idade: Integer read FIdade write FIdade;
    property Email: string read FEmail write FEmail;
  end;

var
  LPessoa: TPessoa;
  LSerializer: TJSONSerializer;
  LJson: string;
  LPessoaDeserializada: TPessoa;
begin
  LSerializer := TJSONSerializer.Create;
  try
    // Criar objeto
    LPessoa := TPessoa.Create;
    LPessoa.Nome := 'João Silva';
    LPessoa.Idade := 30;
    LPessoa.Email := 'joao@email.com';
    
    // Serializar para JSON
    LJson := LSerializer.ObjectToJSON(LPessoa);
    WriteLn('📤 JSON gerado: ' + LJson);
    
    // Deserializar de volta para objeto
    LPessoaDeserializada := LSerializer.JSONToObject<TPessoa>(LJson);
    WriteLn(Format('📥 Objeto deserializado: %s, %d anos', 
                  [LPessoaDeserializada.Nome, LPessoaDeserializada.Idade]));
    
  finally
    LSerializer.Free;
    LPessoa.Free;
    LPessoaDeserializada.Free;
  end;
end;
```

### Exemplo de Validação Básica

```pascal
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
    // Carregar schema
    LSchema := TJSONElement.ParseFromString('{
      "type": "object",
      "properties": {
        "name": {"type": "string", "minLength": 2},
        "age": {"type": "number", "minimum": 0}
      },
      "required": ["name"]
    }');
    
    LValidator.Schema := LSchema;
    
    // Validar dados
    LData := TJSONElement.ParseFromString('{
      "name": "João Silva",
      "age": 30
    }');
    
    LErrors := LValidator.Validate(LData);
    
    if LErrors.Count = 0 then
      WriteLn('✓ JSON válido!')
    else
    begin
      WriteLn(Format('✗ Encontrados %d erros:', [LErrors.Count]));
      for var LError in LErrors do
        WriteLn(Format('  - %s: %s', [LError.Path, LError.Message]));
    end;
      
  finally
    LValidator.Free;
    LErrors.Free;
  end;
end;
```

### Exemplo com Melhorias de Performance Nativas

```pascal
// Exemplo usando funcionalidades nativas otimizadas
uses
  JsonFlow.Composer,
  JsonFlow.Composer.Pool;

var
  LComposer: TJSONComposer;
  LPooled: TPooledJSONComposer;
  LJsonData: string;
begin
  // 1. USANDO COMPOSER NATIVO COM CACHE
  LComposer := TJSONComposer.Create;
  try
    // Habilitar cache de navegação (2.5x mais rápido)
    LComposer.EnableCache(1000); // Cache para 1000 paths
    
    // Operações em lote (3.4x mais rápido)
    LComposer.BeginBatch;
    try
      LComposer.SetValueFast('usuario.nome', 'Maria');
      LComposer.SetValueFast('usuario.email', 'maria@email.com');
      LComposer.AddToArrayFast('tags', 'importante');
      LComposer.AddToArrayFast('tags', 'urgente');
    finally
      LComposer.EndBatch; // Executa todas as operações de uma vez
    end;
    
    // Operações em massa nativas
    LComposer.SetMultipleValues([
      'config.tema', 'escuro',
      'config.idioma', 'pt-BR',
      'config.notificacoes', True
    ]);
    
    LJsonData := LComposer.Generate;
    WriteLn('JSON com Cache Nativo: ' + LJsonData);
    WriteLn('Cache Stats: ' + LComposer.GetCacheStats);
  finally
    LComposer.Free;
  end;
  
  // 2. USANDO POOLED COMPOSER (Pool Automático)
  LPooled := TPooledJSONComposer.Create;
  try
    LPooled.BeginObject
      .Add('produto', 'Notebook')
      .Add('preco', 2500.99)
      .EndObject;
    LJsonData := LPooled.Generate;
    WriteLn('JSON com Pool Automático: ' + LJsonData);
  finally
    LPooled.Free; // Retorna automaticamente ao pool global
  end;
  
  // 3. USANDO OTIMIZAÇÕES PREDEFINIDAS
  LComposer := TJSONComposer.Create;
  try
    // Otimizar para escrita intensiva
    LComposer.OptimizeForWriting;
    
    LComposer.BeginObject
      .Add('nome', 'João')
      .Add('idade', 30)
      .EndObject;
    LJsonData := LComposer.Generate;
    WriteLn('JSON Otimizado: ' + LJsonData);
  finally
    LComposer.Free;
  end;
end;
```

### Exemplo com Leitura e Atualização Dinâmica

```pascal
// Exemplo Completo: Reader, Writer e Navigator em Ação
var
  LReader: TJSONReader;
  LWriter: TJSONWriter;
  LNavigator: TJSONNavigator;
  LComposer: TJSONComposer;
  LJsonElement: IJSONElement;
  LJsonData, LUpdatedJson: string;
begin
  // JSON original para demonstração
  LJsonData := '{
    "usuario": {
      "nome": "João",
      "idade": 30,
      "endereco": {
        "cidade": "São Paulo",
        "cep": "01000-000"
      }
    },
    "notas": [8.5, 9.0, 7.5],
    "ativo": true
  }';
  
  // 1. LEITURA com TJSONReader
  LReader := TJSONReader.Create;
  try
    LJsonElement := LReader.ReadFromString(LJsonData);
    WriteLn('JSON carregado com sucesso!');
  finally
    LReader.Free;
  end;
  
  // 2. NAVEGAÇÃO com TJSONNavigator
  LNavigator := TJSONNavigator.Create(LJsonElement);
  try
    WriteLn('=== Dados Originais ===');
    WriteLn('Nome: ' + LNavigator.GetString('usuario.nome'));
    WriteLn('Idade: ' + LNavigator.GetInteger('usuario.idade').ToString);
    WriteLn('CEP: ' + LNavigator.GetString('usuario.endereco.cep'));
    WriteLn('Ativo: ' + BoolToStr(LNavigator.GetBoolean('ativo'), True));
    WriteLn('Total de notas: ' + LNavigator.GetArray('notas').Count.ToString);
  finally
    LNavigator.Free;
  end;
  
  // 3. ATUALIZAÇÃO DINÂMICA com TJSONComposer
  LComposer := TJSONComposer.Create;
  try
    // Carregar JSON existente
    LComposer.LoadJSON(LJsonData);
    
    // Modificar valores existentes
    LComposer.SetValue('usuario.idade', 31);
    LComposer.SetValue('usuario.endereco.cep', '01234-567');
    LComposer.SetValue('usuario.endereco.cidade', 'Rio de Janeiro');
    
    // Adicionar nova nota ao array
    LComposer.AddToArray('notas', 9.5);
    LComposer.AddToArray('notas', 8.0);
    
    // Adicionar novos campos
    LComposer.SetValue('usuario.email', 'joao@email.com');
    LComposer.SetValue('usuario.telefone', '(11) 99999-9999');
    LComposer.SetValue('dataAtualizacao', FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
    
    // Gerar JSON atualizado
    LUpdatedJson := LComposer.Generate;
  finally
    LComposer.Free;
  end;
  
  // 4. ESCRITA com TJSONWriter (opcional - para formatação)
  LWriter := TJSONWriter.Create;
  try
    LWriter.IndentSize := 2; // Formatação com indentação
    LReader := TJSONReader.Create;
    try
      LJsonElement := LReader.ReadFromString(LUpdatedJson);
      LUpdatedJson := LWriter.WriteToString(LJsonElement);
    finally
      LReader.Free;
    end;
  finally
    LWriter.Free;
  end;
  
  // 5. VERIFICAÇÃO FINAL com Navigator
  LNavigator := TJSONNavigator.Create(LUpdatedJson);
  try
    WriteLn('');
    WriteLn('=== Dados Atualizados ===');
    WriteLn('Nome: ' + LNavigator.GetString('usuario.nome'));
    WriteLn('Idade: ' + LNavigator.GetInteger('usuario.idade').ToString);
    WriteLn('Cidade: ' + LNavigator.GetString('usuario.endereco.cidade'));
    WriteLn('CEP: ' + LNavigator.GetString('usuario.endereco.cep'));
    WriteLn('Email: ' + LNavigator.GetString('usuario.email'));
    WriteLn('Telefone: ' + LNavigator.GetString('usuario.telefone'));
    WriteLn('Data Atualização: ' + LNavigator.GetString('dataAtualizacao'));
    WriteLn('Total de notas: ' + LNavigator.GetArray('notas').Count.ToString);
    WriteLn('Última nota: ' + LNavigator.GetFloat('notas[4]').ToString);
    
    // Verificar se campo existe
    if not LNavigator.IsNull('usuario.endereco.complemento') then
      WriteLn('Complemento: ' + LNavigator.GetString('usuario.endereco.complemento'))
    else
      WriteLn('Complemento: não informado');
  finally
    LNavigator.Free;
  end;
  
  WriteLn('');
  WriteLn('JSON Final:');
  WriteLn(LUpdatedJson);
end;
```

### Exemplo com Middleware Customizado

```pascal
uses
  JsonFlow,
  JsonFlow.MiddlewareDatatime,
  JsonFlow.Interfaces;

type
  // Middleware personalizado para criptografia
  TEncryptionMiddleware = class(TInterfacedObject, IEventMiddleware, 
                                IGetValueMiddleware, ISetValueMiddleware)
  public
    procedure GetValue(const AInstance: TObject; const AProperty: TRttiProperty;
                      var AValue: TValue; var AHandled: Boolean);
    procedure SetValue(const AInstance: TObject; const AProperty: TRttiProperty;
                      const AValue: TValue; var AHandled: Boolean);
  end;

  TPessoaSegura = class
  private
    FNome: string;
    FSenha: string;  // Será criptografada pelo middleware
    FDataCriacao: TDateTime;
  public
    property Nome: string read FNome write FNome;
    [Encrypt]  // Atributo customizado
    property Senha: string read FSenha write FSenha;
    property DataCriacao: TDateTime read FDataCriacao write FDataCriacao;
  end;

var
  LPessoa: TPessoaSegura;
  LJson: string;
begin
  // Registrar middlewares
  TJsonFlow.AddMiddleware(TMiddlewareDateTime.Create(TJsonFlow.FormatSettings));
  TJsonFlow.AddMiddleware(TEncryptionMiddleware.Create);
  
  try
    LPessoa := TPessoaSegura.Create;
    LPessoa.Nome := 'João Silva';
    LPessoa.Senha := 'minhasenha123';  // Será criptografada
    LPessoa.DataCriacao := Now;
    
    // Serializar com middleware ativo
    LJson := TJsonFlow.ObjectToJsonString(LPessoa);
    WriteLn('📤 JSON com middleware aplicado:');
    WriteLn(LJson);
    
    // Deserializar (descriptografia automática)
    LPessoa := TJsonFlow.JsonToObject<TPessoaSegura>(LJson);
    WriteLn(Format('🔓 Senha descriptografada: %s', [LPessoa.Senha]));
    
  finally
    TJsonFlow.ClearMiddlewares;
    LPessoa.Free;
  end;
end;
```

### Exemplo com Formatos Customizados

```pascal
uses
  JsonFlow.SchemaValidator,
  JsonFlow.FormatRegistry,
  JsonFlow.FormatValidators;

type
  // Validador customizado para CPF
  TCPFFormatValidator = class(TInterfacedObject, IFormatValidator)
  public
    function Validate(const AValue: string): Boolean;
    function GetErrorMessage: string;
    function GetCustomErrorMessage(const AValue: string): string;
  end;

var
  LValidator: TSchemaValidator;
  LSchema, LData: IJSONElement;
  LErrors: TList<TValidationError>;
begin
  // Registrar formato customizado
  TFormatRegistry.RegisterValidator('cpf', TCPFFormatValidator.Create);
  TFormatRegistry.RegisterValidator('cep', TCEPFormatValidator.Create);
  
  LValidator := TSchemaValidator.Create;
  try
    // Schema com formatos customizados
    LSchema := TJSONElement.ParseFromString('{
      "type": "object",
      "properties": {
        "cpf": {"type": "string", "format": "cpf"},
        "cep": {"type": "string", "format": "cep"},
        "email": {"type": "string", "format": "email"}
      },
      "required": ["cpf", "cep"]
    }');
    
    LValidator.Schema := LSchema;
    
    // Validar dados com formatos customizados
    LData := TJSONElement.ParseFromString('{
      "cpf": "123.456.789-00",
      "cep": "01234-567",
      "email": "usuario@email.com"
    }');
    
    LErrors := LValidator.Validate(LData);
    
    if LErrors.Count = 0 then
      WriteLn('✓ Todos os formatos customizados são válidos!')
    else
    begin
      WriteLn('✗ Erros de formato encontrados:');
      for var LError in LErrors do
        WriteLn(Format('  - %s: %s', [LError.Path, LError.Message]));
    end;
      
  finally
    LValidator.Free;
    LErrors.Free;
  end;
end;
```

### Exemplo com Métricas

```pascal
uses
  JsonFlow.SchemaValidator,
  JsonFlow.Metrics;

var
  LValidator: TSchemaValidator;
  LMetrics: TValidationMetrics;
begin
  LValidator := TSchemaValidator.Create;
  try
    // Habilitar coleta de métricas
    LValidator.MetricsEnabled := True;
    
    // ... realizar validações ...
    
    // Obter relatório de performance
    LMetrics := TValidationMetrics.GlobalInstance;
    WriteLn('📊 Relatório de Performance:');
    WriteLn(LMetrics.GenerateTextReport);
    
  finally
    LValidator.Free;
  end;
end;
```

### Exemplo com Cache Persistente

```pascal
uses
  JsonFlow.PersistentCache;

var
  LCache: TPersistentCache;
  LConfig: TCacheConfig;
begin
  // Configurar cache persistente
  LConfig.MaxEntries := 10000;
  LConfig.ExpirationDays := 30;
  LConfig.CacheFilePath := 'validation_cache.json';
  LConfig.AutoSave := True;
  
  LCache := TPersistentCache.Create(LConfig);
  try
    // Cache é usado automaticamente pelo validador
    WriteLn(Format('📦 Cache: %d entradas, %.1f%% hit rate', 
                  [LCache.GetCacheSize, LCache.GetHitRate * 100]));
  finally
    LCache.Free;
  end;
end;
```

### Exemplo com Validação Assíncrona

```pascal
uses
  JsonFlow.AsyncValidator;

var
  LAsyncValidator: TAsyncValidator;
  LConfig: TAsyncValidatorConfig;
  LTaskId: string;
begin
  // Configurar validador assíncrono
  LConfig.MaxThreads := 4;
  LConfig.QueueCapacity := 1000;
  
  LAsyncValidator := TAsyncValidator.Create(LConfig);
  try
    LAsyncValidator.Start;
    
    // Submeter validação assíncrona
    LTaskId := LAsyncValidator.SubmitValidation(
      LJsonData,
      LSchema,
      vpHigh, // prioridade alta
      nil,    // callback de progresso
      procedure(const AResult: TAsyncValidationResult)
      begin
        WriteLn(Format('🔄 Validação concluída: %s', 
                      [BoolToStr(AResult.IsValid, 'Válida', 'Inválida')]));
      end);
    
    // Aguardar resultado
    LAsyncValidator.WaitForTask(LTaskId, 5000);
    
  finally
    LAsyncValidator.Free;
  end;
end;
```

## 📊 Funcionalidades Avançadas

### 🔄 Leitura e Atualização Dinâmica de JSON (Recurso Inovador)

**Como as Units Trabalham em Conjunto:**

#### 📖 **TJSONReader** - Leitura Inteligente
- Parse otimizado de strings e streams JSON
- Suporte a encoding UTF-8 e configurações personalizadas
- Validação automática durante a leitura
- Interface `IJSONReader` para máxima flexibilidade

#### ✏️ **TJSONWriter** - Escrita Formatada
- Serialização eficiente de elementos JSON
- Controle total sobre formatação (indentação, quebras de linha)
- Suporte a diferentes formatos de data/hora e decimais
- Otimização para streams e strings

#### 🧭 **TJSONNavigator** - Navegação Avançada
- Navegação por paths intuitivos (`usuario.endereco.cep`, `notas[0]`)
- Extração tipada de valores (String, Integer, Float, Boolean)
- Verificação de existência e nulidade
- Acesso direto a objetos e arrays aninhados

#### 🎼 **TJSONComposer** - Orquestração Completa
- Integra Reader, Writer e Navigator em uma API unificada
- Carregamento de JSON existente com `LoadJSON()`
- Modificação in-place sem reconstrução completa
- Operações fluentes: `SetValue()`, `AddToArray()`, `MergeArray()`
- Geração do JSON atualizado preservando estrutura original

**Características do Recurso:**
- **Edição In-Place**: Modificação eficiente sem reconstrução completa
- **API Fluente**: Carregue, edite e salve JSON em uma única cadeia de operações
- **Preservação de Dados**: Mantém integridade dos dados não modificados
- **Performance Otimizada**: Atualizações incrementais sem parsing completo
- **Operações Complexas**: AddToArray, MergeArray, SetValue, RemoveFromArray
- **Navegação Intuitiva**: Paths como 'usuario.endereco.cep' ou 'notas[0]'

### Sistema de Métricas

- **Coleta automática** de métricas de validação
- **Análise de performance** em tempo real
- **Relatórios detalhados** em múltiplos formatos
- **Monitoramento de cache** e hit rates
- **Estatísticas de throughput** e latência

### Cache Persistente

- **Persistência automática** de resultados
- **Expiração configurável** de entradas
- **Compressão opcional** para economia de espaço
- **Thread-safety** para aplicações multi-thread
- **Limpeza automática** de entradas antigas

### Validação Assíncrona

- **Multi-threading** para alta performance
- **Pool de threads** configurável
- **Priorização de tarefas** (Low, Normal, High, Critical)
- **Callbacks de progresso** e conclusão
- **Cancelamento** de operações
- **Balanceamento de carga** automático

### Sistema de Relatórios

- **Relatórios de validação** com estatísticas
- **Análise de performance** detalhada
- **Relatórios de cache** e otimização
- **Análise de erros** e tendências
- **Agendamento automático** de relatórios
- **Múltiplos formatos** de saída

## 📚 Documentação

### Guias Principais
- **[🚀 Guia de Início Rápido](Documentation/QUICK_START.md)** - Primeiros passos
- **[🔄 Guia de Serialização](Documentation/SERIALIZATION_GUIDE.md)** - Conversão objeto ↔ JSON
- **[🎨 Guia das APIs Fluentes](Documentation/COMPOSER_FLUENT_API_GUIDE.md)** - TJSONComposer e TJSONSchemaComposer
- **[⚡ Guia de Performance Nativa](Documentation/NATIVE_PERFORMANCE_GUIDE.md)** - Cache, Lote e Pool integrados nativamente
- **[⚡ Guia de Melhorias (Legado)](Documentation/COMPOSER_ENHANCEMENTS_GUIDE.md)** - Classes separadas (descontinuado)
- **[✅ Guia do Validador](Documentation/SCHEMA_VALIDATOR_GUIDE.md)** - Validação de JSON Schema
- **[🔧 Guia de Middleware](Documentation/MIDDLEWARE_GUIDE.md)** - Sistema de middleware customizado
- **[🎯 Guia de Formatos Customizados](Documentation/CUSTOM_FORMATS_GUIDE.md)** - Validadores personalizados
- **[⚡ Recursos Avançados](Documentation/ADVANCED_FEATURES_REFERENCE.md)** - Performance e otimizações
- **[💡 Exemplos Práticos](Examples/)** - Casos de uso reais

### Exemplos Inclusos

- **[BasicUsage.dpr](Examples/BasicUsage.dpr)** - Uso básico
- **[BasicValidation.dpr](Examples/BasicValidation.dpr)** - Validação básica
- **[AdvancedFeaturesDemo.dpr](Examples/AdvancedFeaturesDemo.dpr)** - Funcionalidades avançadas
- **[NativePerformanceConsole.dpr](Examples/NativePerformanceConsole.dpr)** - Performance nativa integrada
- **[NativePerformanceDemo.pas](Examples/NativePerformanceDemo.pas)** - Demo das otimizações nativas
- **[ComposerEnhancementsConsole.dpr](Examples/ComposerEnhancementsConsole.dpr)** - Melhorias (legado)
- **[ComposerEnhancementsDemo.pas](Examples/ComposerEnhancementsDemo.pas)** - Demo das otimizações (legado)
- **[JsonFlow.TestsPerformanceRunner.dpr](Test Delphi/JsonFlow.TestsPerformanceRunner.dpr)** - Testes de performance
- **[JsonFlow.TestsSimplePerformance.dpr](Test Delphi/JsonFlow.TestsSimplePerformance.dpr)** - Teste simples de otimizações

## 🏗️ Arquitetura

### Estrutura do Projeto

```
JsonFlow4D/
├── Source/
│   ├── Core/                 # Classes fundamentais
│   │   ├── JsonFlow.Interfaces.pas
│   │   ├── JsonFlow.Objects.pas
│   │   ├── JsonFlow.Serializer.pas    # Serialização/Deserialização
│   │   ├── JsonFlow.Attributes.pas    # Atributos de serialização
│   │   ├── JsonFlow.Composer.pas      # Criação fluente de JSON
│   │   ├── JsonFlow.Composer.Pool.pas # Pool de objetos (opcional)
│   │   └── JsonFlow.Utils.pas
│   ├── Schema/               # Validação de schema
│   │   ├── JsonFlow.SchemaValidator.pas
│   │   ├── JsonFlow.SchemaComposer.pas # Criação fluente de Schema
│   │   ├── JsonFlow.Metrics.pas
│   │   ├── JsonFlow.PersistentCache.pas
│   │   ├── JsonFlow.AsyncValidator.pas
│   │   └── JsonFlow.Reports.pas
│   ├── Middleware/           # Sistema de middleware
│   │   ├── JsonFlow.MiddlewareDatatime.pas  # Middleware de data/hora
│   │   └── JsonFlow.MiddlewareBase.pas      # Base para middlewares customizados
│   └── JsonFlow.pas          # Arquivo principal
├── Examples/                 # Exemplos de uso
│   ├── NativePerformanceDemo.pas        # Demo das melhorias nativas integradas
│   ├── NativePerformanceConsole.dpr     # Console app com performance nativa
│   ├── ComposerEnhancementsDemo.pas     # Demo das melhorias (legado)
│   └── ComposerEnhancementsConsole.dpr  # Console app demonstrando otimizações (legado)
├── Documentation/            # Documentação completa
│   ├── QUICK_START.md        # Guia de início rápido
│   ├── COMPOSER_FLUENT_API_GUIDE.md # Guia das APIs fluentes
│   ├── COMPOSER_ENHANCEMENTS_GUIDE.md # Guia das melhorias do TJSONComposer
│   ├── SCHEMA_VALIDATOR_GUIDE.md    # Guia do validador
│   ├── MIDDLEWARE_GUIDE.md   # Guia de middleware customizado
│   ├── CUSTOM_FORMATS_GUIDE.md      # Guia de formatos customizados
│   ├── ADVANCED_FEATURES_REFERENCE.md # Recursos avançados
│   ├── CHANGELOG.md          # Histórico de versões
│   ├── CONTRIBUTING.md       # Guia de contribuição
│   ├── RELEASE_NOTES.md      # Notas de lançamento
│   └── README.md             # Índice da documentação
├── Test Delphi/              # Testes unitários
├── boss.json                 # Configuração Boss Package Manager
└── README.md                 # Este arquivo
```

### Componentes Principais

1. **Core Engine** - Parsing e manipulação de JSON
2. **Serialization Engine** - Conversão automática entre objetos e JSON
3. **Schema Validator** - Validação de JSON Schema
4. **Performance Layer** - Cache e otimizações
5. **Metrics System** - Coleta e análise de métricas
6. **Async Engine** - Validação assíncrona
7. **Report Generator** - Geração de relatórios

## ⚡ Performance

### Benchmarks

#### Validação de Schema
| Operação | Sem Otimização | Com Cache | Com Pool | Melhoria |
|----------|----------------|-----------|----------|----------|
| Validação simples | 1.2ms | 0.1ms | 0.08ms | **15x** |
| Validação complexa | 5.8ms | 0.3ms | 0.25ms | **23x** |
| Lote (1000 itens) | 1.2s | 0.15s | 0.12s | **10x** |

#### TJSONComposer com Otimizações Nativas
| Operação | Padrão | Com Cache | Com Lote | Pool Automático | Melhoria |
|----------|--------|-----------|----------|-----------------|----------|
| Criação simples | 0.8ms | 0.8ms | 0.8ms | 0.27ms | **3.0x** |
| Navegação complexa | 2.1ms | 0.84ms | 2.1ms | 2.1ms | **2.5x** |
| Operações múltiplas | 15.2ms | 15.2ms | 4.47ms | 15.2ms | **3.4x** |
| Cenário otimizado | 18.1ms | 16.04ms | 12.27ms | 17.37ms | **1.5x** |

### Otimizações Implementadas

#### Validação de Schema
- ✅ **Cache de nós** com hash otimizado
- ✅ **Pool de listas de erro** (99.9% reutilização)
- ✅ **Logging condicional** para reduzir overhead
- ✅ **Cache de validação** para schemas reutilizados
- ✅ **Algoritmos otimizados** de hash e comparação

#### TJSONComposer (Otimizações Nativas)
- ✅ **Cache de navegação nativo** ativado com `EnableCache()` (2.5x mais rápido)
- ✅ **Operações em lote nativas** com `BeginBatch()`/`EndBatch()` (3.4x mais rápido)
- ✅ **Pool automático** via `TPooledJSONComposer` (3x mais rápido)
- ✅ **Métodos Fast integrados** para operações críticas
- ✅ **Operações avançadas nativas** sem dependências externas
- ✅ **Otimizações predefinidas** com `OptimizeForReading()`/`OptimizeForWriting()`

## 🔧 Configuração

### Para Desenvolvimento

```pascal
LValidator.LogLevel := llDebug;      // Logs detalhados
LValidator.MetricsEnabled := True;   // Monitorar performance
```

### Para Produção

```pascal
LValidator.LogLevel := llWarning;    // Apenas warnings
LValidator.MetricsEnabled := False;  // Melhor performance

// Cache persistente
LCacheConfig.MaxEntries := 50000;
LCacheConfig.ExpirationDays := 30;
```

## 🤝 Contribuindo

1. **Fork** o projeto
2. **Crie** uma branch para sua feature (`git checkout -b feature/nova-funcionalidade`)
3. **Commit** suas mudanças (`git commit -am 'Adiciona nova funcionalidade'`)
4. **Push** para a branch (`git push origin feature/nova-funcionalidade`)
5. **Abra** um Pull Request

### Diretrizes

- Siga as convenções de código existentes
- Adicione testes para novas funcionalidades
- Atualize a documentação quando necessário
- Mantenha compatibilidade com versões anteriores

## 📄 Licença

Este projeto está licenciado sob a **MIT License** - veja o arquivo [LICENSE](LICENSE) para detalhes.

## 🆘 Suporte

- **📖 Documentação**: [API Reference](Documentation/API_REFERENCE.md)
- **💬 Discussões**: GitHub Discussions
- **🐛 Issues**: GitHub Issues
- **📧 Email**: suporte@jsonflow4d.com

## 🏆 Reconhecimentos

- Comunidade Delphi/Object Pascal
- Contribuidores do projeto
- Especificação JSON Schema Draft 7

---

**JsonFlow4D** - *Validação de JSON Schema rápida, confiável e extensível para Delphi* 🚀

### Método 1: Clone do Repositório

```bash
git clone https://github.com/seu-usuario/JsonFlow4D.git
cd JsonFlow4D
```

### Método 2: Download Direto

Baixe o ZIP do projeto e extraia em sua pasta de projetos.

### Configuração no Delphi

Adicione os seguintes caminhos ao **Library Path** do seu projeto:

```
$(ProjectDir)\Source\Core
$(ProjectDir)\Source\Schema
$(ProjectDir)\Source\Validation
$(ProjectDir)\Source\Performance
```

## 🎯 Início Rápido

### Exemplo de Serialização/Deserialização

```pascal
uses
  JsonFlow.Serializer,
  JsonFlow.Interfaces;

type
  TPessoa = class
  private
    FNome: string;
    FIdade: Integer;
    FEmail: string;
  public
    property Nome: string read FNome write FNome;
    property Idade: Integer read FIdade write FIdade;
    property Email: string read FEmail write FEmail;
  end;

var
  LPessoa: TPessoa;
  LSerializer: TJSONSerializer;
  LJson: string;
  LPessoaDeserializada: TPessoa;
begin
  LSerializer := TJSONSerializer.Create;
  try
    // Criar objeto
    LPessoa := TPessoa.Create;
    LPessoa.Nome := 'João Silva';
    LPessoa.Idade := 30;
    LPessoa.Email := 'joao@email.com';
    
    // Serializar para JSON
    LJson := LSerializer.ObjectToJSON(LPessoa);
    WriteLn('📤 JSON gerado: ' + LJson);
    
    // Deserializar de volta para objeto
    LPessoaDeserializada := LSerializer.JSONToObject<TPessoa>(LJson);
    WriteLn(Format('📥 Objeto deserializado: %s, %d anos', 
                  [LPessoaDeserializada.Nome, LPessoaDeserializada.Idade]));
    
  finally
    LSerializer.Free;
    LPessoa.Free;
    LPessoaDeserializada.Free;
  end;
end;
```

### Exemplo de Validação Básica

```pascal
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
    // Carregar schema
    LSchema := TJSONElement.ParseFromString('{
      "type": "object",
      "properties": {
        "name": {"type": "string", "minLength": 2},
        "age": {"type": "number", "minimum": 0}
      },
      "required": ["name"]
    }');
    
    LValidator.Schema := LSchema;
    
    // Validar dados
    LData := TJSONElement.ParseFromString('{
      "name": "João Silva",
      "age": 30
    }');
    
    LErrors := LValidator.Validate(LData);
    
    if LErrors.Count = 0 then
      WriteLn('✓ JSON válido!')
    else
    begin
      WriteLn(Format('✗ Encontrados %d erros:', [LErrors.Count]));
      for var LError in LErrors do
        WriteLn(Format('  - %s: %s', [LError.Path, LError.Message]));
    end;
      
  finally
    LValidator.Free;
    LErrors.Free;
  end;
end;
```

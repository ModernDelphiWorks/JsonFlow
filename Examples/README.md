# JsonFlow4D - Exemplos e Demonstrações

Esta pasta contém exemplos e demonstrações organizados por categoria do JsonFlow4D, incluindo a **Interface Unificada de Conversores** e a **Facade Centralizada TJsonFlow**.

## 🆕 **NOVO: TJsonFlow Centralizado**

O JsonFlow4D agora oferece acesso centralizado a **TODAS** as funcionalidades através da classe `TJsonFlow`. Não é mais necessário conhecer tipos específicos de conversores!

### ✨ Uso Super Simples

```pascal
uses JsonFlow;

// XML ↔ JSON
LJSON := TJsonFlow4D.XMLToJSON('<root><name>João</name></root>');
LXML := TJsonFlow4D.JSONToXML(LJSON);

// DataSet ↔ JSON  
LJSON := TJsonFlow4D.DataSetToJSON(LDataSet);
TJsonFlow4D.JSONToDataSet(LJSON, LDataSet);

// Object ↔ JSON (já existia)
LJSON := TJsonFlow4D.ObjectToJsonString(LObject);
LObject := TJsonFlow4D.JsonToObject<TMyClass>(LJSON);

// Utilitários
if TJsonFlow4D.IsValidJSON(LJSON) then
  ShowMessage('JSON válido!');
```

---

## 📁 Estrutura Organizada por Categoria

### 🔄 **Converters/** - Conversores Unificados
- **CentralizedJsonFlowDemo** (RECOMENDADO) - Facade centralizada `TJsonFlow`
- **UnifiedConvertersDemo** - Interface `IJsonFlowConverters`
- Scripts de compilação incluídos

### 🎼 **Composer/** - Composição JSON
- **ComposerEnhancementsConsole** - Melhorias do Composer
- **TestComposerFluentDemo** - API Fluente do Composer
- **TestComposerPhases1to4** - Fases de desenvolvimento

### ⚡ **Performance/** - Otimização e Performance
- **NativePerformanceConsole** - Testes de performance nativa
- Demonstrações de otimização

### ✅ **Validators/** - Validadores Customizados
- **BrazilianValidatorsExample** - Validadores brasileiros
- **CustomFormatValidators** - Formatos personalizados

### 🧾 **SchemaValidation/** - JSON Schema (diagnósticos e refs)
- **SchemaRefAndSchemaPathDemo** - Demonstra `$ref` por arquivo e `SchemaPath`

### 🌊 **FluentSyntax/** - Sintaxe Fluente
- **FluentSyntaxComparison** - Comparação de sintaxes
- **FluentSyntaxDemo** - Demonstração da API fluente
- **ComposerFluentSyntaxDemo** - Composer com sintaxe fluente

### 🚀 **Advanced/** - Recursos Avançados
- **AdvancedFeaturesDemo** - Funcionalidades avançadas
- **SmartModeEnhancedExample** - Modo inteligente aprimorado
- **TestSmartModeEnhanced** - Testes do modo inteligente

---

## 🚀 Interface Unificada de Conversores (Alternativa)

Para casos onde você precisa de mais controle, ainda pode usar a interface unificada diretamente:

## 🎯 Objetivo

A interface unificada resolve o problema de ter que conhecer e instanciar diferentes tipos de conversores para cada funcionalidade. Agora você pode usar uma única interface para:

- ✅ **XMLToJSON** / **JSONToXML**
- ✅ **DataSetToJSON** / **JSONToDataSet** 
- ✅ **ObjectToJSON** / **JSONToObject**
- ✅ **Métodos utilitários** (validação, formatação)
- ✅ **Configurações flexíveis**

## 🚀 Como Usar

### Uso Básico

```pascal
uses
  JsonFlow4D.Converters;

var
  LConverters: IJsonFlowConverters;
  LJSON, LXML: string;
  LDataSet: TDataSet;
  LObject: TMyClass;
begin
  // Criar instância dos conversores unificados
  LConverters := TJsonFlowConvertersFactory.CreateDefault;
  
  // XML ↔ JSON
  LJSON := LConverters.XMLToJSON('<root><name>João</name></root>');
  LXML := LConverters.JSONToXML(LJSON);
  
  // DataSet ↔ JSON
  LJSON := LConverters.DataSetToJSON(LDataSet);
  LConverters.JSONToDataSet(LJSON, LDataSet);
  
  // Object ↔ JSON
  LJSON := LConverters.ObjectToJSON(LObject);
  LObject := LConverters.JSONToObject(LJSON, TMyClass) as TMyClass;
  
  // Utilitários
  if LConverters.IsValidJSON(LJSON) then
    ShowMessage('JSON válido!');
end;
```

### Configurações Avançadas

```pascal
// Conversor otimizado (melhor performance)
LConverters := TJsonFlowConvertersFactory.CreateOptimized;

// Conversor completo (todas as funcionalidades)
LConverters := TJsonFlowConvertersFactory.CreateFull;

// Conversor customizado
LConverters := TJsonFlowConvertersFactory.CreateCustom(
  'xml_preserve_attributes=true',
  'dataset_include_metadata=false', 
  'object_serialize_private=true'
);

// Configuração dinâmica
LConverters.ConfigureXMLConverter('preserve_cdata=true');
LConverters.ConfigureDataSetConverter('null_handling=exclude');
LConverters.ConfigureObjectConverter('date_format=iso8601');
```

### Tratamento de Erros

```pascal
LJSON := LConverters.XMLToJSON(LXML);
if not LConverters.GetLastError.IsEmpty then
begin
  ShowMessage('Erro: ' + LConverters.GetLastError);
  LConverters.ClearError;
end;
```

## 📁 Estrutura dos Arquivos

- **`JsonFlow4D.Converters.pas`** - Interface unificada e factory
- **`UnifiedConvertersDemo.pas`** - Classe de demonstração
- **`UnifiedConvertersDemo.dpr`** - Programa de exemplo
- **`README.md`** - Esta documentação

## 🏃‍♂️ Executando o Exemplo

1. Compile o projeto `UnifiedConvertersDemo.dpr`
2. Execute o programa para ver todas as demonstrações
3. Analise o código fonte para entender o uso

```bash
dcc32 UnifiedConvertersDemo.dpr
UnifiedConvertersDemo.exe
```

## 🔧 Funcionalidades Demonstradas

### 1. Conversões XML
- XML → JSON com preservação de atributos
- JSON → XML com formatação
- Configurações personalizadas

### 2. Conversões DataSet
- DataSet → JSON com metadados
- JSON → DataSet com criação automática de campos
- Tratamento de valores nulos

### 3. Conversões de Objetos
- Object → JSON com serialização de propriedades privadas
- JSON → Object (criação de nova instância)
- JSON → Object (população de instância existente)

### 4. Métodos Utilitários
- Validação de JSON
- Validação de XML
- Formatação e prettify

### 5. Configurações
- Factory patterns para diferentes cenários
- Configuração dinâmica de conversores
- Opções personalizadas por tipo

## ✨ Vantagens da Interface Unificada

| Vantagem | Descrição |
|----------|----------|
| **Simplicidade** | Uma única interface para todas as conversões |
| **Consistência** | API uniforme e previsível |
| **Flexibilidade** | Configurações por conversor ou globais |
| **Manutenibilidade** | Código mais limpo e fácil de manter |
| **Extensibilidade** | Fácil adição de novos conversores |
| **Compatibilidade** | Units independentes ainda disponíveis |

## 🔄 Compatibilidade com Units Independentes

A interface unificada **NÃO substitui** as units independentes. Você ainda pode usar:

```pascal
// Uso independente (como antes)
uses
  JsonFlow4D.Converter.XML,
  JsonFlow4D.Converter.Dataset,
  JsonFlow4D.Serializer;

var
  LXMLConverter: IJsonFlowXMLConverter;
  LDataSetConverter: IJsonFlowDataSetConverter;
begin
  LXMLConverter := TJsonFlowXMLConverter.Create;
  LDataSetConverter := TJsonFlowDataSetConverter.Create;
  // ... uso específico
end;
```

## 📋 Requisitos

- Delphi 10.3 Rio ou superior
- JsonFlow4D Core units
- System.JSON (para funcionalidades básicas)

## 🤝 Contribuindo

Este exemplo pode ser estendido com:
- Novos tipos de conversores
- Configurações adicionais
- Métodos utilitários extras
- Testes unitários

---

**JsonFlow4D** - Conversões JSON simplificadas para Delphi 🚀

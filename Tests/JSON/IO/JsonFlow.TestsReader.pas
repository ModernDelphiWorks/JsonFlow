unit JsonFlow.TestsReader;

interface

uses
  System.SysUtils,
  System.Classes,
  DUnitX.TestFramework,
  JsonFlow.Reader,
  JsonFlow.Interfaces;

type
  [TestFixture]
  TJSONReaderTests = class
  public
    [Test]
    procedure TestReadFloat;
    [Test]
    procedure TestReadArrayNested;
    [Test]
    procedure TestReadInvalidNumber;
    [Test]
    procedure TestReadSimpleObject;
//    [Test]
//    procedure TestReadSimpleArray;
    [Test]
    procedure TestReadString;
    [Test]
    procedure TestReadNumber;
    [Test]
    procedure TestReadBoolean;
    [Test]
    procedure TestReadNull;
    [Test]
    procedure TestReadEmptyString;
  end;

implementation

procedure TJSONReaderTests.TestReadFloat;
var
  LReader: TJSONReader;
  LElement: IJSONElement;
begin
  LReader := TJSONReader.Create(TFormatSettings.Create('en_US'));
  try
    LElement := LReader.Read('95.5');
    Assert.IsTrue(Supports(LElement, IJSONValue), 'Tipo deve ser float');
    Assert.AreEqual(Double(95.5), (LElement as IJSONValue).AsFloat, 'Valor float incorreto');
  finally
    LReader.Free;
  end;
end;

procedure TJSONReaderTests.TestReadArrayNested;
var
  LReader: TJSONReader;
  LElement: IJSONElement;
  LArray: IJSONArray;
begin
  LReader := TJSONReader.Create(TFormatSettings.Create('en_US'));
  try
    LElement := LReader.Read('[[95.5, 88.0], [75.0, 82.5]]');
    Assert.IsTrue(Supports(LElement, IJSONArray), 'Tipo deve ser array');
    LArray := LElement as IJSONArray;
    Assert.AreEqual(2, LArray.Count, 'Tamanho do array externo incorreto');
    Assert.AreEqual(Double(95.5), ((LArray.GetItem(0) as IJSONArray).GetItem(0) as IJSONValue).AsFloat, 'Valor [0][0] incorreto');
  finally
    LReader.Free;
  end;
end;

procedure TJSONReaderTests.TestReadInvalidNumber;
var
  LReader: TJSONReader;
begin
  LReader := TJSONReader.Create(TFormatSettings.Create('en_US'));
  try
    Assert.WillRaise(
      procedure
      begin
        LReader.Read('95,5');
      end,
      EJsonFlowParseError,
      'Deve falhar com n?mero inv?lido'
    );
  finally
    LReader.Free;
  end;
end;

procedure TJSONReaderTests.TestReadSimpleObject;
var
  LReader: TJSONReader;
  LElement: IJSONElement;
begin
  LReader := TJSONReader.Create(TFormatSettings.Create('en_US'));
  try
    LElement := LReader.Read('{"name": "Isaque"}');
    Assert.IsNotNull(LElement, 'Objeto n?o deve ser nulo');
    Assert.AreEqual('Isaque', ((LElement as IJSONObject).GetValue('name') as IJSONVALUE).AsString, 'Valor de "name" incorreto');
  finally
    LReader.Free;
  end;
end;

//procedure TJSONReaderTests.TestReadSimpleArray;
//var
//  LReader: TJSONReader;
//  LElement: IJSONElement;
//begin
//  LReader := TJSONReader.Create(TFormatSettings.Create('en_US'));
//  try
//    LElement := LReader.Read('["a", "b", "c"]');
//    Assert.IsNotNull(LElement, 'Array n?o deve ser nulo');
//    Assert.AreEqual(3, (LElement as IJSONArray).Count, 'Tamanho do array incorreto');
//    Assert.AreEqual('a', ((LElement as IJSONArray)[0] as IJSONValue).AsString, 'Primeiro elemento incorreto');
//  finally
//    LReader.Free;
//  end;
//end;

procedure TJSONReaderTests.TestReadString;
var
  LReader: TJSONReader;
  LElement: IJSONElement;
begin
  LReader := TJSONReader.Create(TFormatSettings.Create('en_US'));
  try
    LElement := LReader.Read('"teste"');
    Assert.IsNotNull(LElement, 'String n?o deve ser nula');
    Assert.AreEqual('teste', (LElement as IJSONValue).AsString, 'Valor da string incorreto');
  finally
    LReader.Free;
  end;
end;

procedure TJSONReaderTests.TestReadNumber;
var
  LReader: TJSONReader;
  LElement: IJSONElement;
begin
  LReader := TJSONReader.Create(TFormatSettings.Create('en_US'));
  try
    LElement := LReader.Read('42');
    Assert.IsNotNull(LElement, 'N?mero n?o deve ser nulo');
    Assert.AreEqual(Int64(42), (LElement as IJSONValue).AsInteger, 'Valor do n?mero incorreto');
  finally
    LReader.Free;
  end;
end;

procedure TJSONReaderTests.TestReadBoolean;
var
  LReader: TJSONReader;
  LElement: IJSONElement;
begin
  LReader := TJSONReader.Create(TFormatSettings.Create('en_US'));
  try
    LElement := LReader.Read('true');
    Assert.IsNotNull(LElement, 'Booleano n?o deve ser nulo');
    Assert.IsTrue((LElement as IJSONValue).AsBoolean, 'Valor do booleano incorreto');
  finally
    LReader.Free;
  end;
end;

procedure TJSONReaderTests.TestReadNull;
var
  LReader: TJSONReader;
  LElement: IJSONElement;
begin
  LReader := TJSONReader.Create(TFormatSettings.Create('en_US'));
  try
    LElement := LReader.Read('null');
    Assert.IsNotNull(LElement, 'Null n?o deve ser nulo');
    Assert.IsTrue((LElement as IJSONValue).AsString = 'null', 'Valor n?o ? null');
  finally
    LReader.Free;
  end;
end;

procedure TJSONReaderTests.TestReadEmptyString;
var
  LReader: TJSONReader;
begin
  LReader := TJSONReader.Create(TFormatSettings.Create('en_US'));
  try
    Assert.WillRaise(
      procedure
      begin
        LReader.Read('');
      end,
      EJsonFlowParseError,
      'Deve falhar com string vazia'
    );
  finally
    LReader.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TJSONReaderTests);

end.


program DirectStreamTest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.JSON,
  REST.Json,
  JsonFlow.Serializer,
  JsonFlow.Reader,
  JsonFlow.Interfaces,
  Benchmark.Entities in '..\Examples\VCL\JsonFlowBenchmark\Benchmark.Entities.pas',
  Benchmark.Forms.Main in '..\Examples\VCL\JsonFlowBenchmark\Benchmark.Forms.Main.pas';

var
  LDataPath: string;
  LJsonStr: string;
  LWrapped: string;
  LEnvelope: TCustomersEnvelope;
  LJFSer: TJSONSerializer;
  LJFResult: string;
  LTJResult: string;
begin
  try
    Writeln('Starting integrity verification...');
    
    // Caminho relativo para pegar o 1K de customers
    LDataPath := '..\Examples\VCL\JsonFlowBenchmark\Data\Benchmarks\customers-1k.json';
    if not TFile.Exists(LDataPath) then
    begin
      Writeln('Error: customers-1k.json not found at ' + ExpandFileName(LDataPath));
      Exit;
    end;

    Writeln('Reading source JSON...');
    LJsonStr := TFile.ReadAllText(LDataPath);
    LWrapped := '{"Items":' + LJsonStr + '}';

    Writeln('Deserializing using JsonFlow...');
    LEnvelope := TCustomersEnvelope.Create;
    LJFSer := TJSONSerializer.Create;
    try
      var LReader := TJSONReader.Create;
      var LJFElem := LReader.Read(LWrapped);
      LJFSer.ToObject(LJFElem, LEnvelope);

      Writeln('Direct Stream Serializing using JsonFlow...');
      LJFResult := LJFSer.SerializeToString(LEnvelope);

      Writeln('Serializing using TJSON...');
      LTJResult := TJson.ObjectToJsonString(LEnvelope);

      Writeln('Verifying sizes...');
      Writeln('JsonFlow Direct output size: ' + IntToStr(Length(LJFResult)) + ' chars');
      Writeln('TJSON output size:           ' + IntToStr(Length(LTJResult)) + ' chars');
      
      Writeln('');
      Writeln('First 300 characters comparison:');
      Writeln('--- JsonFlow ---');
      Writeln(Copy(LJFResult, 1, 300));
      Writeln('--- TJSON ---');
      Writeln(Copy(LTJResult, 1, 300));

    finally
      LJFSer.Free;
      LEnvelope.Free;
    end;

  except
    on E: Exception do
      Writeln('Exception occurred: ' + E.ClassName + ': ' + E.Message);
  end;
end.

program JsonFlowBenchmark;

uses
  Vcl.Forms,
  Benchmark.Forms.Main in 'Benchmark.Forms.Main.pas' {frmBenchmark},
  Benchmark.Entities in 'Benchmark.Entities.pas';

//{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmBenchmark, frmBenchmark);
  Application.Run;
end.

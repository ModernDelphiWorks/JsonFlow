program JsonFlowMainDemo;

uses
  Vcl.Forms,
  Demo.Forms.Main in 'Demo.Forms.Main.pas' {frmMain},
  Demo.JsonFlow.Entities in 'Demo.JsonFlow.Entities.pas',
  Demo.JsonFlow.Converters in 'Demo.JsonFlow.Converters.pas',
  Demo.JsonFlow.Middlewares in 'Demo.JsonFlow.Middlewares.pas',
  Demo.Frame.Configuration in 'Demo.Frame.Configuration.pas' {frameConfiguration: TFrame};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.

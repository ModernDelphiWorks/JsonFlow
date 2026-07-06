program JsonFlow.JSON.Tests;

{$APPTYPE CONSOLE}

// NOTA: a unit Core\JsonFlow.Tests.Converters.pas foi EXCLUIDA deste projeto:
// nao e uma fixture DUnitX (usa apenas WriteLn) e todos os seus "testes" sao
// simulacoes que nao exercitam o framework JsonFlow.

uses
  System.SysUtils,
  Winapi.Windows,
  DUnitX.TestFramework,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.XML.NUnit,
  JsonFlow.TestsArrays in 'Composition\JsonFlow.TestsArrays.pas',
  JsonFlow.TestsComposer in 'Composition\JsonFlow.TestsComposer.pas',
  JsonFlow.TestsObjects in 'Composition\JsonFlow.TestsObjects.pas',
  JsonFlow.TestsPair in 'Composition\JsonFlow.TestsPair.pas',
  JsonFlow.Tests in 'Core\JsonFlow.Tests.pas',
  JsonFlow.TestsRecursivityFix in 'Core\JsonFlow.TestsRecursivityFix.pas',
  JsonFlow.TestsValue in 'Core\JsonFlow.TestsValue.pas',
  JsonFlow.TestsNavigator in 'IO\JsonFlow.TestsNavigator.pas',
  JsonFlow.TestsReader in 'IO\JsonFlow.TestsReader.pas',
  JsonFlow.TestsSerializer in 'IO\JsonFlow.TestsSerializer.pas';

var
  LRunner: ITestRunner;
  LResults: IRunResults;
begin
  ReportMemoryLeaksOnShutdown := True;
  try
    SetCurrentDir(ExtractFilePath(ParamStr(0)));
    TDUnitX.CheckCommandLine;
    LRunner := TDUnitX.CreateRunner;
    LRunner.UseRTTI := True;
    LRunner.FailsOnNoAsserts := False;
    LRunner.AddLogger(TDUnitXConsoleLogger.Create(True));
    LRunner.AddLogger(TDUnitXXMLNUnitFileLogger.Create);
    LResults := LRunner.Execute;
    if not LResults.AllPassed then
      ExitCode := 1
    else
      ExitCode := 0;

    Writeln('');
    Writeln('ExitCode: ', ExitCode);
    if IsDebuggerPresent or FindCmdLineSwitch('pause', True) then
    begin
      Writeln('');
      Writeln('Pressione ENTER para sair...');
      Readln;
    end;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName + ': ' + E.Message);
      ExitCode := 1;

      if IsDebuggerPresent or FindCmdLineSwitch('pause', True) then
      begin
        Writeln('');
        Writeln('Pressione ENTER para sair...');
        Readln;
      end;
    end;
  end;
end.

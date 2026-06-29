program JsonFlow.Schema.Tests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Winapi.Windows,
  DUnitX.TestFramework,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.XML.NUnit,
  JsonFlow.TestsSchemaNavigator in 'Composition\JsonFlow.TestsSchemaNavigator.pas',
  JsonFlow.TestsSchemaComposer in 'Core\JsonFlow.TestsSchemaComposer.pas',
  JsonFlow.TestsSchemaComposerDuplicate in 'Core\JsonFlow.TestsSchemaComposerDuplicate.pas',
  JsonFlow.TestsShemaComposer in 'Core\JsonFlow.TestsShemaComposer.pas',
  JsonFlow.TestsSchemaReader in 'IO\JsonFlow.TestsSchemaReader.pas',
  JsonFlow.TestsCustomFormats in 'Validators\JsonFlow.TestsCustomFormats.pas',
  JsonFlow.TestsSchemaValidator in 'Validators\JsonFlow.TestsSchemaValidator.pas',
  JsonFlow.TestsSchemaSuiteHelper in 'Validators\JsonFlow.TestsSchemaSuiteHelper.pas',
  JsonFlow.TestsSchemaValidatorNew in 'Validators\JsonFlow.TestsSchemaValidatorNew.pas',
  JsonFlow.TestsSchemaObjectKeywordsDeep in 'Validators\ObjectKeywords\JsonFlow.TestsSchemaObjectKeywordsDeep.pas',
  JsonFlow.TestsSchemaObjectKeywordsLimits in 'Validators\ObjectKeywords\JsonFlow.TestsSchemaObjectKeywordsLimits.pas',
  JsonFlow.TestsSchemaArrayTupleItems in 'Validators\ArrayKeywords\JsonFlow.TestsSchemaArrayTupleItems.pas',
  JsonFlow.TestsSchemaArrayContains in 'Validators\ArrayKeywords\JsonFlow.TestsSchemaArrayContains.pas',
  JsonFlow.TestsSchemaArrayLimitsAndUnique in 'Validators\ArrayKeywords\JsonFlow.TestsSchemaArrayLimitsAndUnique.pas',
  JsonFlow.TestsSchemaCombinatorsAndConditionals in 'Validators\Combinators\JsonFlow.TestsSchemaCombinatorsAndConditionals.pas',
  JsonFlow.TestsSchemaRefs in 'Validators\Refs\JsonFlow.TestsSchemaRefs.pas',
  JsonFlow.TestsSchemaSchemaPath in 'Validators\Diagnostics\JsonFlow.TestsSchemaSchemaPath.pas',
  JsonFlow.TestsSchemaSchemaPathCombinators in 'Validators\Diagnostics\JsonFlow.TestsSchemaSchemaPathCombinators.pas',
  CustomFormatValidators in '..\..\Examples\Validators\CustomFormatValidators.pas',
  JsonFlow.TestsSchemaDeepValidationBaseline in 'Validators\JsonFlow.TestsSchemaDeepValidationBaseline.pas';

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


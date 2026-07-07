{
  ------------------------------------------------------------------------------
  JsonFlow
  High-performance JSON serialization, dynamic manipulation, and Draft 7 Schema validation framework for Delphi.

  SPDX-License-Identifier: MIT
  Copyright (c) 2025-2026 Isaque Pinheiro

  Licensed under the MIT License.
  See the LICENSE file in the project root for full license information.
  ------------------------------------------------------------------------------
}

unit JsonFlow.TestsSchemaSuiteHelper;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  JsonFlow.Interfaces, JsonFlow.SchemaReader;

type
  TJSONSchemaTestSuiteRunner = class
  public
    class procedure RunSuite(const AFilePath: string; const ALogProc: TProc<string> = nil);
  end;

implementation

uses
  JsonFlow.Reader, JsonFlow.Value, DUnitX.TestFramework;

class procedure TJSONSchemaTestSuiteRunner.RunSuite(const AFilePath: string; const ALogProc: TProc<string>);
var
  LReader: TJSONReader;
  LJsonData: IJSONElement;
  LGroupsArray: IJSONArray;
  LGroupObj: IJSONObject;
  LSchemaElement: IJSONElement;
  LSchemaStr: string;
  LTestsArray: IJSONArray;
  LTestObj: IJSONObject;
  LDataElement: IJSONElement;
  LDataStr: string;
  LValidVal: IJSONValue;
  LDescriptionVal: IJSONValue;
  LGroupDescVal: IJSONValue;
  LSchemaReader: TJSONSchemaReader;
  LFileContent: string;
  LFileStream: TStringList;
  I, J: Integer;
  LIsValid: Boolean;
begin
  if not FileExists(AFilePath) then
    raise Exception.CreateFmt('Test suite file not found: %s', [AFilePath]);

  LFileStream := TStringList.Create;
  try
    LFileStream.LoadFromFile(AFilePath, TEncoding.UTF8);
    LFileContent := LFileStream.Text;
  finally
    LFileStream.Free;
  end;

  LReader := TJSONReader.Create;
  try
    LJsonData := LReader.Read(LFileContent);
  finally
    LReader.Free;
  end;

  if not Supports(LJsonData, IJSONArray, LGroupsArray) then
    Exit;

  for I := 0 to LGroupsArray.Count - 1 do
  begin
    if Supports(LGroupsArray.GetItem(I), IJSONObject, LGroupObj) then
    begin
      LGroupDescVal := LGroupObj.GetValue('description') as IJSONValue;
      LSchemaElement := LGroupObj.GetValue('schema');
      LSchemaStr := LSchemaElement.AsJSON;

      LTestsArray := LGroupObj.GetValue('tests') as IJSONArray;
      for J := 0 to LTestsArray.Count - 1 do
      begin
        if Supports(LTestsArray.GetItem(J), IJSONObject, LTestObj) then
        begin
          LDescriptionVal := LTestObj.GetValue('description') as IJSONValue;
          LDataElement := LTestObj.GetValue('data');
          LValidVal := LTestObj.GetValue('valid') as IJSONValue;

          LDataStr := LDataElement.AsJSON;
          LIsValid := LValidVal.AsBoolean;

          LSchemaReader := TJSONSchemaReader.Create;
          try
            LSchemaReader.LoadFromString(LSchemaStr);
            
            if Assigned(ALogProc) then
              ALogProc(Format('Running: %s -> %s', [LGroupDescVal.AsString, LDescriptionVal.AsString]));

            var LResult := LSchemaReader.Validate(LDataStr);
            
            if LResult <> LIsValid then
            begin
              var LErrorsStr := '';
              if not LResult then
              begin
                var LErrors := LSchemaReader.GetErrors;
                for var LErr in LErrors do
                  LErrorsStr := LErrorsStr + Format('Path: %s, Message: %s, SchemaPath: %s; ', [LErr.Path, LErr.Message, LErr.SchemaPath]);
              end;
              
              Assert.AreEqual(LIsValid, LResult, Format('Group: %s, Test: %s. Expected valid=%s, got=%s. Errors: %s', 
                [LGroupDescVal.AsString, LDescriptionVal.AsString, BoolToStr(LIsValid, True), BoolToStr(LResult, True), LErrorsStr]));
            end;
          finally
            LSchemaReader.Free;
          end;
        end;
      end;
    end;
  end;
end;

end.

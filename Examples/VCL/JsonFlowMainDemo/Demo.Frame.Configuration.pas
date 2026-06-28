unit Demo.Frame.Configuration;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  JsonFlow.Serializer;

type
  TframeConfiguration = class(TFrame)
    grpOptions: TGroupBox;
    chkProcessAttributes: TCheckBox;
    chkIgnoreNullValues: TCheckBox;
    chkDetectCircularRefs: TCheckBox;
    lblDateTimeFormat: TLabel;
    edtDateTimeFormat: TEdit;
    lblFloatFormat: TLabel;
    edtFloatFormat: TEdit;
    lblMaxDepth: TLabel;
    edtMaxDepth: TEdit;
  public
    procedure GetOptions(var AOptions: TJSONSerializerOptions);
    procedure SetOptions(const AOptions: TJSONSerializerOptions);
  end;

implementation

{$R *.dfm}

{ TframeConfiguration }

procedure TframeConfiguration.GetOptions(var AOptions: TJSONSerializerOptions);
begin
  AOptions.ProcessAttributes := chkProcessAttributes.Checked;
  AOptions.IgnoreNullValues := chkIgnoreNullValues.Checked;
  AOptions.DetectCircularReferences := chkDetectCircularRefs.Checked;
  AOptions.DateTimeFormat := edtDateTimeFormat.Text;
  AOptions.FloatFormat := edtFloatFormat.Text;
  AOptions.MaxDepth := StrToIntDef(edtMaxDepth.Text, 100);
end;

procedure TframeConfiguration.SetOptions(const AOptions: TJSONSerializerOptions);
begin
  chkProcessAttributes.Checked := AOptions.ProcessAttributes;
  chkIgnoreNullValues.Checked := AOptions.IgnoreNullValues;
  chkDetectCircularRefs.Checked := AOptions.DetectCircularReferences;
  edtDateTimeFormat.Text := AOptions.DateTimeFormat;
  edtFloatFormat.Text := AOptions.FloatFormat;
  edtMaxDepth.Text := IntToStr(AOptions.MaxDepth);
end;

end.

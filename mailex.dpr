program mailex;

uses
  Vcl.Forms,
  uFrmMain in 'src\frm\uFrmMain.pas' {frmMain},
  uSMTPUtils in 'src\utils\uSMTPUtils.pas',
  uFormIniFiles in 'src\utils\uFormIniFiles.pas',
  uFileUtils in 'src\utils\uFileUtils.pas',
  uJsonFUtils in 'src\utils\uJsonFUtils.pas',
  uJsonSUtils in 'src\utils\uJsonSUtils.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.

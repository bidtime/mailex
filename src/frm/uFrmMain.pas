unit uFrmMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls, Vcl.Buttons;

type
  TfrmMain = class(TForm)
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    LabelPass: TLabel;
    EdtHost: TEdit;
    EdtPort: TEdit;
    EdtUsername: TEdit;
    EdtPassword: TEdit;
    CbSSL: TCheckBox;
    CbTLS: TCheckBox;
    CbAuth: TCheckBox;
    GroupBox2: TGroupBox;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    SpeedButton1: TSpeedButton;
    BtnSendEmail: TSpeedButton;
    EdtFromName: TEdit;
    EdtFromAddress: TEdit;
    MnmTo: TMemo;
    MnmCc: TMemo;
    MnmBcc: TMemo;
    CbConfirmation: TCheckBox;
    EdtSubject: TEdit;
    MnmMessage: TMemo;
    CbHtml: TCheckBox;
    MnmAttachment: TMemo;
    OdAttachment: TOpenDialog;
    StatusBar1: TStatusBar;
    procedure BtnSendEmailClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    function paramsToCtrls(const toCtrls: boolean): boolean;
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

uses uSMTPUtils, uFormIniFiles;

{$R *.dfm}

procedure TfrmMain.BtnSendEmailClick(Sender: TObject);
var par: TSMTPParms;
begin
  par.Host := edtHost.Text;
  par.Port := StrToInt(self.EdtPort.Text);
  par.Username := self.EdtUsername.Text;
  par.Password := self.EdtPassword.text;
  par.ConnectTimeout := 30000;
  par.Authenticate := self.CbAuth.Checked;
  par.UseSSL := self.CbSSL.Checked;
  TSMTPUtils.SendMail(par, self.MnmTo.Text, self.EdtSubject.Text, self.MnmMessage.Text,
    self.MnmCc.Text, self.mnmBCC.text);
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  TFormIniFiles.rwIni(self, false);
  paramsToCtrls(true);
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  paramsToCtrls(false);
  TFormIniFiles.rwIni(self, true);
end;

function TfrmMain.paramsToCtrls(const toCtrls: boolean): boolean;
begin
  if toCtrls then begin
    self.edtHost.Text := TSMTPUtils.SMTPParmClass.Host;
    self.EdtPort.Text := IntToStr(TSMTPUtils.SMTPParmClass.Port);
    self.EdtUsername.Text := TSMTPUtils.SMTPParmClass.Username;
    self.EdtPassword.text := TSMTPUtils.SMTPParmClass.Password;
    self.CbAuth.Checked := TSMTPUtils.SMTPParmClass.Authenticate;
    self.CbSSL.Checked := TSMTPUtils.SMTPParmClass.UseSSL;
    self.EdtSubject.Text:=TSMTPUtils.SMTPParmClass.subject;
    self.MnmTo.Text:=TSMTPUtils.SMTPParmClass.toUser;
    self.MnmCc.Text := TSMTPUtils.SMTPParmClass.toCC;
    self.MnmBCc.Text:=TSMTPUtils.SMTPParmClass.toBCC;
    Result := true;
  end else begin
    TSMTPUtils.SMTPParmClass.Host := self.edtHost.Text;
    TSMTPUtils.SMTPParmClass.Port := StrToInt(self.EdtPort.Text);
    TSMTPUtils.SMTPParmClass.Username := self.EdtUsername.Text;
    TSMTPUtils.SMTPParmClass.Password := self.EdtPassword.text;
    TSMTPUtils.SMTPParmClass.Authenticate := self.CbAuth.Checked;
    TSMTPUtils.SMTPParmClass.UseSSL := self.CbSSL.Checked;
    TSMTPUtils.SMTPParmClass.subject := self.EdtSubject.Text;
    TSMTPUtils.SMTPParmClass.toUser := self.MnmTo.Text;
    TSMTPUtils.SMTPParmClass.toCC := self.MnmCc.Text;
    TSMTPUtils.SMTPParmClass.toBCC := self.MnmBCc.Text;
    Result := true;
  end;
end;

end.

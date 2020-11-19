unit uSMTPUtils;

{
2020.11.17 ������������ 465 ssl �ʼ���֮ǰ�����㣬��Ҫע�⣺
  1. idSMTP1.UseTLS := utUseImplicitTLS;
  2. idSMTP1.password := authCode;
}

interface

uses classes;

type
  TSMTPParms = record
    Username: string; //���õ�½�ʺ�
    Password: string; //���õ�¼password
    Host: string; //����SMTP��ַ
    Port: integer; //����port   ����ת��Ϊ����
    Authenticate: boolean;   // ��Ҫ��½��֤
    ConnectTimeout: integer;
    UseSSL: boolean;
  end;
  TSMTPParmClass = record
    Username: string; //���õ�½�ʺ�
    Password: string; //���õ�¼password
    Host: string; //����SMTP��ַ
    Port: integer; //����port   ����ת��Ϊ����
    Authenticate: boolean;   // ��Ҫ��½��֤
    ConnectTimeout: integer;
    UseSSL: boolean;
    //
    subject: string;
    bodyText: string;
    toCC: string;
    toUser: string;
    toBcc: string;
    author: string;
  end;
  TSMTPUtils = class
  private
    class var FLogsEv: TGetStrProc;
    class var FErrorEv: TGetStrProc;
    class procedure showLogs(const S: string);
    class procedure showError(const S: string);
  protected
    class function readWriteIni(const bWrite: boolean): boolean; static;
  public
    class var SMTPParmClass: TSMTPParmClass;
    class function SendMail(const par: TSMTPParms; const toUser, subject, bodyText: string;
      const toCC: string=''; const toBCC: string=''): boolean; static;
    class property LogsEv: TGetStrProc read FLogsEv write FLogsEv;
    class property ErrorEv: TGetStrProc read FErrorEv write FErrorEv;
    class constructor Create();
    class destructor Destroy();
  end;

implementation

uses SysUtils, IdBaseComponent, IdMessage, IdComponent, IdTCPConnection,
  IdTCPClient, IdExplicitTLSClientServerBase, IdMessageClient, IdAttachment,
  IdSMTPBase, IdSMTP, IdIOHandlerSocket, IdIOHandlerStack, IdSSL, IdSSLOpenSSL,
  IdSASL, IdSASLUserPass, IdSASLLogin, IdSASL_CRAM_SHA1, IdText,
  IdSASL_CRAMBase, IdSASL_CRAM_MD5, IdSASLSKey, IdSASLPlain, IdSASLOTP,
  IdSASLExternal, IdSASLDigest, IdSASLAnonymous, IdUserPassProvider,
  uFileUtils, uJsonFUtils;

class constructor TSMTPUtils.Create;
begin
  readWriteIni(false);
end;

class destructor TSMTPUtils.Destroy;
begin
  inherited;
  readWriteIni(true);
end;

class function TSMTPUtils.readWriteIni(const bWrite: boolean): boolean;
var fileName: string;
begin
  fileName := TFileUtils.appFile('smtpParam.json');
  if not bWrite then begin
    SMTPParmClass := TJsonFUtils.DeserializeNF<TSMTPParmClass>(fileName);
    Result := true;
  end else begin
    TJsonFUtils.SerializeF<TSMTPParmClass>(SMTPParmClass, fileName);
    Result := true;
  end;
end;

class function TSMTPUtils.SendMail(const par: TSMTPParms;
  const toUser, subject, bodyText: string;
    const toCC: string; const toBCC: string): boolean;

  function sendMessage(IdSMTP1: TIdSMTP): boolean;
  var IdMessage1: TIdMessage;
  begin
    IdMessage1 := TIdMessage.Create(nil);
    try
      IdMessage1.Body.Clear;   //������ϴη��͵�����
      IdMessage1.CharSet := 'UTF-8';
      IdMessage1.Subject := subject;               //�����ʼ����͵ı���
      IdMessage1.Body.Text := bodyText;            //�����ʼ����͵�����
      //filename := 'C:\�ļ�.txt';   //��Ҫ��ӵĸ����ļ�
      //TIdAttachment.Create(IdMessage1.MessageParts, filename);  //��Ӹ���
      IdMessage1.From.Address := IdSMTP1.Username;       //�����ʼ��ķ�����
      IdMessage1.Recipients.EMailAddresses := toUser;    //�ռ��˵ĵ�ַ
      IdMessage1.CCList.EMailAddresses:=toCC; //����
      IdMessage1.BccList.EmailAddresses:=toBCC; //����
      IdMessage1.Priority:= TIdMessagePriority.mpNormal; //�ʼ���Ҫ��
      try
        idSMTP1.Send(IdMessage1);
        Result := true;
        showLogs(format('send: [%s]-%s, %s', [subject, bodyText, boolToStr(Result, true)]));
      except
        on E: Exception do begin
          showError(format('send error, %s', [E.Message]));
          raise Exception.create(e.message);
        end;
      end;
    finally
      IdMessage1.Free;
    end;
  end;

  function doConnect(IdSMTP1: TIdSMTP): boolean;
  begin
    Result := false;
    try
      IdSMTP1.ConnectTimeout := par.ConnectTimeout;
      IdSMTP1.UseEhlo := True;
      IdSMTP1.Connect;
      if par.Authenticate then begin
        if IdSMTP1.Authenticate then begin   // autenticate
          Result := sendMessage(IdSMTP1);
        end;
      end else begin
        Result := sendMessage(IdSMTP1);
      end;
    except
      on E:Exception do begin
        showError(format('SMTP connect error, %s', [E.Message]));
        raise Exception.create(e.message);
      end;
    end;
  end;

  function InitSASL(SMTP: TIdSMTP): boolean;
  var
    IdUserPassProvider: TIdUserPassProvider;
    IdSASLCRAMMD5: TIdSASLCRAMMD5;
    IdSASLCRAMSHA1: TIdSASLCRAMSHA1;
    IdSASLPlain: TIdSASLPlain;
    IdSASLLogin: TIdSASLLogin;
    IdSASLSKey: TIdSASLSKey;
    IdSASLOTP: TIdSASLOTP;
    IdSASLAnonymous: TIdSASLAnonymous;
    IdSASLExternal: TIdSASLExternal;
  begin
    IdUserPassProvider := TIdUserPassProvider.Create(SMTP);
    IdSASLCRAMSHA1 := TIdSASLCRAMSHA1.Create(SMTP);
    IdSASLCRAMSHA1.UserPassProvider := IdUserPassProvider;
    IdSASLCRAMMD5 := TIdSASLCRAMMD5.Create(SMTP);
    IdSASLCRAMMD5.UserPassProvider := IdUserPassProvider;
    IdSASLSKey := TIdSASLSKey.Create(SMTP);
    IdSASLSKey.UserPassProvider := IdUserPassProvider;
    IdSASLOTP := TIdSASLOTP.Create(SMTP);
    IdSASLOTP.UserPassProvider := IdUserPassProvider;
    IdSASLAnonymous := TIdSASLAnonymous.Create(SMTP);
    IdSASLExternal := TIdSASLExternal.Create(SMTP);
    //
    IdSASLLogin := TIdSASLLogin.Create(SMTP);
    IdSASLLogin.UserPassProvider := IdUserPassProvider;
    //
    IdSASLPlain := TIdSASLPlain.Create(SMTP);
    IdSASLPlain.UserPassProvider := IdUserPassProvider;
    try
      IdUserPassProvider.Username := SMTP.Username;
      IdUserPassProvider.Password := SMTP.Password;
      SMTP.SASLMechanisms.Add.SASL := IdSASLCRAMSHA1;
      SMTP.SASLMechanisms.Add.SASL := IdSASLCRAMMD5;
      SMTP.SASLMechanisms.Add.SASL := IdSASLSKey;
      SMTP.SASLMechanisms.Add.SASL := IdSASLOTP;
      SMTP.SASLMechanisms.Add.SASL := IdSASLAnonymous;
      SMTP.SASLMechanisms.Add.SASL := IdSASLExternal;
      SMTP.SASLMechanisms.Add.SASL := IdSASLLogin;
      SMTP.SASLMechanisms.Add.SASL := IdSASLPlain;
      //
      Result := doConnect(SMTP);
    finally
      IdUserPassProvider.Free;
      IdSASLCRAMMD5.Free;
      IdSASLCRAMSHA1.Free;
      IdSASLPlain.Free;
      IdSASLLogin.Free;
      IdSASLSKey.Free;
      IdSASLOTP.Free;
      IdSASLAnonymous.Free;
      IdSASLExternal.Free;
    end;
  end;

  procedure InitAccount(IdSMTP1: TIdSMTP; const user, pwd, host: string; const port: integer);
  begin
    IdSMTP1.Host:=host; //����SMTP��ַ
    IdSMTP1.Username:=user; //���õ�½�ʺ�
    IdSMTP1.Password := pwd;
    //IdSMTP1.ValidateAuthLoginCapability := p.AuthLogin;//true;
    IdSMTP1.Port := Port;          //25 or 465; //����port   ����ת��Ϊ����
  end;

  function InitSSL(IdSMTP1: TIdSMTP): boolean;
  const SMTP_PORT_EXPLICIT_TLS = 587;
  var SSLHandler: TIdSSLIOHandlerSocketOpenSSL;
  begin
    SSLHandler := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
    try
      // SSL/TLS handshake determines the highest available SSL/TLS version dynamically SSLHandler.SSLOptions.Method := sslvSSLv23;
      SSLHandler.SSLOptions.Method:=sslvSSLv23;  //sslvSSLv23  sslvSSLv3
      SSLHandler.SSLOptions.Mode := sslmClient;  //(sslmUnassigned, sslmClient, sslmServer, sslmBoth);
      SSLHandler.SSLOptions.VerifyMode := [];
      SSLHandler.SSLOptions.VerifyDepth := 0;
      IdSMTP1.IOHandler:= SSLHandler;  //���������Ӵ
      //UseTLS: utUseExplicitTLS,  utUseImplicitTLS
      if IdSMTP1.Port = SMTP_PORT_EXPLICIT_TLS then begin
        IdSMTP1.UseTLS := utUseExplicitTLS;
      end else begin
        IdSMTP1.UseTLS := utUseImplicitTLS;
      end;
      if (idSMTP1.Username <> '') or (idSMTP1.Password <> '') then begin
        IdSMTP1.AuthType := satSASL;  //���õ�½����  (satNone, satDefault, satSASL);
        Result := InitSASL(IdSMTP1);
      end else begin
        IdSMTP1.AuthType := satNone;
        Result := doConnect(IdSMTP1);
      end;
    finally
      FreeAndNil(SSLHandler);
    end;
  end;

var IdSMTP1: TIdSMTP;
begin
  IdSMTP1 := TIdSMTP.Create(nil);
  try
    InitAccount(IdSMTP1, par.Username, par.Password, par.Host, par.Port);
    if par.UseSSL then begin
      Result := InitSSL(IdSMTP1);
    end else begin
      IdSMTP1.AuthType := satNone;
      Result := doConnect(IdSMTP1);
    end;
  finally
    IdSmtp1.Disconnect;
    IdSmtp1.Free;
  end;
end;

class procedure TSMTPUtils.showError(const S: string);
begin
  if Assigned(self.FErrorEv) then begin
    FErrorEv(S);
  end;
end;

class procedure TSMTPUtils.showLogs(const S: string);
begin
  if Assigned(self.FLogsEv) then begin
    FLogsEv(S);
  end;
end;

end.

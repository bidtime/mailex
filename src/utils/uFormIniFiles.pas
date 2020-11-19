unit uFormIniFiles;

interface

uses
  Forms;

type
  TFormIniFiles = class
  private
  protected
  public
    { Public declarations }
    class function rwIni(frm: TCustomForm; const bWrite: boolean): boolean;
  end;

implementation

uses IniFiles, SysUtils, StrUtils;

{ TdmTableTypeInf }

class function TFormIniFiles.rwIni(frm: TCustomForm; const bWrite: boolean): boolean;
var fileName: string;
  iniFile: TIniFile;
  S: string;
begin
  fileName := ExtractFilePath(ParamStr(0)) + frm.Name + '.ini';
  iniFile := Tinifile.Create(fileName);
  try
    if not bWrite then begin
      frm.top := iniFile.ReadInteger('mainform', 'top', frm.top);
      frm.left := iniFile.ReadInteger('mainform', 'left', frm.left);
      frm.height := iniFile.ReadInteger('mainform', 'height', frm.height);
      frm.width := iniFile.ReadInteger('mainform', 'width', frm.width);
      // (wsNormal, wsMinimized, wsMaximized);
      S := iniFile.ReadString('mainform', 'windowState', '0');
      if S.Equals('1') then begin
        frm.WindowState := wsMaximized;
      end else begin
        frm.WindowState := wsNormal;
      end;
      Result := true;
    end else begin
      iniFile.WriteInteger('mainform', 'top', frm.top);
      iniFile.WriteInteger('mainform', 'left', frm.left);
      iniFile.WriteInteger('mainform', 'height', frm.height);
      iniFile.WriteInteger('mainform', 'width', frm.width);
      // (wsNormal, wsMinimized, wsMaximized);
      iniFile.WriteString('mainform', 'windowState',
        IfThen(frm.WindowState=wsMaximized, '1', '0'));
      Result := true;
    end;
  finally
    iniFile.Free;
  end;
end;

end.

unit SomaCapsulas.Email.Source.Strategy.ACBrMail;

interface

uses
  System.Classes, System.SysUtils, SomaCapsulas.Email.Interfaces, ACBrMail,
  UrlMon;

type
  TEmailStrategyACBrMail = class(TInterfacedObject, IEmailStrategy)
  private
    FComponent: TACBrMail;
    function GetTempDirForAttachments: string;
    function GetAttachmentNameByUrl(AUrl: string; ADelimiter: string = '/'): string;
    function UrlDecode(AEncodedStr: string): string;
    function HexToInt(AHexStr: string): Int64;
    function GenerateUUID: string;
    function DownloadAttachment(AUrlToDownload, AAttachmentDirectory, AAttachmentName: string): string;
    procedure CleanAttachment(AAttachmentTemporaryLocation: string);
  public
    function Send(AEmail: IEmail): Boolean;
    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  SomaCapsulas.Email.Types, SomaCapsulas.Email.Exception, SomaCapsulas.Email.Message,
  Winapi.Windows, Math, System.IOUtils;

{ TEmailStrategyACBrMail }

constructor TEmailStrategyACBrMail.Create;
begin
  Self.FComponent := TACBrMail.Create(nil);
end;

destructor TEmailStrategyACBrMail.Destroy;
begin
  Self.FComponent.Free;
  inherited;
end;

function TEmailStrategyACBrMail.GenerateUUID: string;
var
  LID: TGUID;
begin
  Result := StringReplace(TGUID.NewGuid.ToString, '{', EmptyStr, []);
  Result := StringReplace(Result, '}', EmptyStr, []);
end;

function TEmailStrategyACBrMail.GetTempDirForAttachments: string;
var
  LBufDirWin: array[0..256] of Char;
  LTempDir, LTempDirQMail: string;
begin
  GetTempPath(256, LBufDirWin);
  LTempDir := IncludeTrailingPathDelimiter(StrPas(LBufDirWin));
  LTempDirQMail :=
    IncludeTrailingPathDelimiter(Format('%s%s%s', [LTempDir,
                                                   IncludeTrailingPathDelimiter('SOMA Gestão - QMail'),
                                                   GenerateUUID]));
  if not DirectoryExists(LTempDirQMail) then
    ForceDirectories(LTempDirQMail);
  Result := LTempDirQMail;
end;

function TEmailStrategyACBrMail.DownloadAttachment(AUrlToDownload, AAttachmentDirectory,
  AAttachmentName: string): string;
var
  LAttachmentName, LAttachmentExtension, LDestinationPath: string;
  LDownloadedResult: HRESULT;
begin
  LAttachmentName := GetAttachmentNameByUrl(AUrlToDownload);
  LAttachmentExtension := ExtractFileExt(AAttachmentName);
  LDestinationPath := Format('%s%s%s', [AAttachmentDirectory,
                                        TPath.GetFileNameWithoutExtension(AAttachmentName),
                                        LAttachmentExtension]);
  LDownloadedResult :=
    URLDownloadToFile(nil,
                      PWideChar(AUrlToDownload),
                      PWideChar(LDestinationPath),
                      ZeroValue,
                      nil);
  if (LDownloadedResult <> S_OK) then
    raise ESomaCapsulasEmail.Create(Format(E_SCE_0001, [AUrlToDownload, LDestinationPath]));
  Result := LDestinationPath;
end;

function TEmailStrategyACBrMail.GetAttachmentNameByUrl(AUrl,
  ADelimiter: string): string;
var
  LLastUrlDelimiter, LCharsUntilQueryParam: Integer;
begin
  LLastUrlDelimiter := LastDelimiter(ADelimiter, AUrl);
  LCharsUntilQueryParam := Max(Pred(Pos('?', AUrl) - LLastUrlDelimiter), ZeroValue);
  Result := Copy(AUrl, Succ(LLastUrlDelimiter), IfThen(LCharsUntilQueryParam > ZeroValue,
                                                       LCharsUntilQueryParam,
                                                       MaxInt));
  Result := UrlDecode(Result);
end;

function TEmailStrategyACBrMail.UrlDecode(AEncodedStr: string): string;
var
  I: Integer;
begin
  Result := EmptyStr;
  if Length(AEncodedStr) > 0 then
  begin
    I := 1;
    while I <= Length(AEncodedStr) do
    begin
      if AEncodedStr[I] = '%' then
      begin
        Result := Result + Chr(HexToInt(AEncodedStr[I+1] + AEncodedStr[I+2]));
        I := Succ(Succ(I));
      end
      else if AEncodedStr[I] = '+' then
        Result := Result + ' '
      else
        Result := Result + AEncodedStr[I];

      I := Succ(I);
    end;
  end;
end;

function TEmailStrategyACBrMail.HexToInt(AHexStr: string): Int64;
var
  RetVar: Int64;
  I: Byte;
begin
  AHexStr := UpperCase(AHexStr);
  if AHexStr[length(AHexStr)] = 'H' then
     Delete(AHexStr,length(AHexStr),1);
  RetVar := 0;
  for I := 1 to length(AHexStr) do
  begin
    RetVar := RetVar shl 4;
    if AHexStr[I] in ['0'..'9'] then
      RetVar := RetVar + (byte(AHexStr[I]) - 48)
    else
    begin
      if AHexStr[I] in ['A'..'F'] then
        RetVar := RetVar + (byte(AHexStr[I]) - 55)
      else
      begin
        Retvar := 0;
        break;
      end;
    end;
  end;
  Result := RetVar;
end;


procedure TEmailStrategyACBrMail.CleanAttachment(AAttachmentTemporaryLocation: string);
begin
  if TFile.Exists(AAttachmentTemporaryLocation) then
    TFile.Delete(PWideChar(AAttachmentTemporaryLocation));
end;

function TEmailStrategyACBrMail.Send(AEmail: IEmail): Boolean;
var
  LRecipientEmails, LCarbonCopies: TArray<string>;
  LRecipientEmail, LRecipientEmailTrimmed, LCarbonCopy, LCarbonCopyTrimmed: string;
  LEmailAttachment: IEmailAttachment;
  LAttachmentTemporaryDirectory, LAttachmentTemporaryLocation: string;
begin
  with Self.FComponent do
  begin
    DefaultCharset := TMailCharset(27); // Corresponde a UTF_8
    IDECharset := TMailCharset(15); // Corresponde a CP1252'
    IsHTML := True;

    Host := AEmail.SMTP.Host;
    Port := AEmail.SMTP.Port.ToString;
    Username := AEmail.SMTP.Username;
    Password := AEmail.SMTP.Password;
    SetSSL := AEmail.SMTP.UseSSL;
    SetTLS := AEmail.SMTP.UseTLS;

    From := AEmail.Sender.Email;
    FromName := AEmail.Sender.Name;

    Subject := AEmail.Subject;

    LRecipientEmails := AEmail.RecipientEmail.Split([';', ',']);
    for LRecipientEmail in LRecipientEmails do
    begin
      LRecipientEmailTrimmed := Trim(LRecipientEmail);
      if not LRecipientEmailTrimmed.IsEmpty then
        AddAddress(LRecipientEmailTrimmed, LRecipientEmailTrimmed);
    end;

    LCarbonCopies := AEmail.CarbonCopy.Split([';', ',']);
    for LCarbonCopy in LCarbonCopies do
    begin
      LCarbonCopyTrimmed := Trim(LCarbonCopy);
      if not LCarbonCopyTrimmed.IsEmpty then
        AddCC(LCarbonCopyTrimmed);
    end;

    Body.Add(AEmail.Body);

    LAttachmentTemporaryDirectory := GetTempDirForAttachments;
    for LEmailAttachment in AEmail.Attachments do
    begin
      LAttachmentTemporaryLocation :=
        DownloadAttachment(LEmailAttachment.Location,
                           LAttachmentTemporaryDirectory,
                           LEmailAttachment.Name);
      AddAttachment(LAttachmentTemporaryLocation);
      CleanAttachment(LAttachmentTemporaryLocation);
    end;
    if (TDirectory.Exists(LAttachmentTemporaryDirectory)) then
      TDirectory.Delete(LAttachmentTemporaryDirectory);

    Send(False);
  end;
end;

end.

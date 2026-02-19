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
    function PrepareUrlToDownload(AUrl: string): string;
    function DownloadAttachment(AUrlToDownload, AAttachmentDirectory, AAttachmentName: string): string;
    procedure CleanAttachment(AAttachmentTemporaryLocation: string);
  public
    function Send(AEmail: IEmail): Boolean;
    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  SomaCapsulas.Email.Types,
  SomaCapsulas.Email.Exception,
  SomaCapsulas.Email.Message,
  Winapi.Windows,
  Winapi.ShlObj,
  Winapi.ActiveX,
  Math,
  System.IOUtils,
  System.RegularExpressions,
  System.StrUtils,
  IdHTTP,
  IdSSLOpenSSL;

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
  LKnownFolderPathPointer: PWideChar;
  LHandlerResult: HRESULT;
  LAttachmentTemporaryDirectory, LUserTempFolder: string;
const
  FOLDER_ID_LOCALAPPDATA: TGUID = '{F1B32785-6FBA-4FCF-9D55-7B8E7F157091}';
begin
  LUserTempFolder := GetEnvironmentVariable('TEMP');
  if LUserTempFolder.IsEmpty then
    LUserTempFolder := GetEnvironmentVariable('TMP');

  if LUserTempFolder.IsEmpty then
  begin
    LKnownFolderPathPointer := nil;
    LHandlerResult := SHGetKnownFolderPath(FOLDER_ID_LOCALAPPDATA,
                                           ZeroValue,
                                           ZeroValue,
                                           LKnownFolderPathPointer);

    if Succeeded(LHandlerResult) and (LKnownFolderPathPointer <> nil) then
    begin
      try
        LUserTempFolder := TPath.Combine(string(LKnownFolderPathPointer), 'Temp');
      finally
        CoTaskMemFree(LKnownFolderPathPointer);
      end;
    end;
  end;

  if LUserTempFolder.IsEmpty then
    LUserTempFolder := TPath.GetTempPath;

  LAttachmentTemporaryDirectory :=
    IncludeTrailingPathDelimiter(
      TPath.Combine(LUserTempFolder, 'SOMA Gestão - QMail', GenerateUUID)
    );

  if not TDirectory.Exists(LAttachmentTemporaryDirectory) then
    TDirectory.CreateDirectory(LAttachmentTemporaryDirectory);

  Result := LAttachmentTemporaryDirectory;
end;

function TEmailStrategyACBrMail.DownloadAttachment(AUrlToDownload, AAttachmentDirectory,
  AAttachmentName: string): string;
var
  LAttachmentName, LDestinationFilePath: string;
  LHttpClient: TIdHTTP;
  LSSLIOHandler: TIdSSLIOHandlerSocketOpenSSL;
  LFileStream: TFileStream;
begin
  Result := EmptyStr;
  LAttachmentName := GetAttachmentNameByUrl(AUrlToDownload);
  LDestinationFilePath := TPath.Combine(AAttachmentDirectory, AAttachmentName);

  LHttpClient := nil;
  LSSLIOHandler := nil;
  LFileStream := nil;                                      
  try
    LHttpClient := TIdHTTP.Create(nil);

    LSSLIOHandler := TIdSSLIOHandlerSocketOpenSSL.Create(LHttpClient);
    LSSLIOHandler.SSLOptions.Method := sslvTLSv1_2;

    LHttpClient.IOHandler := LSSLIOHandler;
    LHttpClient.HandleRedirects := True;
    LHttpClient.ConnectTimeout := 30000;
    LHttpClient.ReadTimeout := 120000;
    LHttpClient.Request.UserAgent := 'SOMA Gestão QMail';
    LHttpClient.Request.Accept := '*/*';

    LFileStream := TFileStream.Create(LDestinationFilePath, fmCreate);
    LHttpClient.Get(AUrlToDownload, LFileStream);

    Result := LDestinationFilePath;
  finally
    LHttpClient.Free;
    LFileStream.Free;
  end;
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

function TEmailStrategyACBrMail.PrepareUrlToDownload(AUrl: string): string;
var
  LNoCacheQueryParam: string;
begin
  LNoCacheQueryParam := AnsiLowerCase(StringReplace(GenerateUUID, '-', '', [rfReplaceAll]));
  Result := TRegEx.Replace(AUrl, '\?.*',  '');
  Result := Format('%s?t=%s', [Result, LNoCacheQueryParam]);
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
      TDirectory.Delete(LAttachmentTemporaryDirectory, True);

    Send(False);
  end;
end;

end.

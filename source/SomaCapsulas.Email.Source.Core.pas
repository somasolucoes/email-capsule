unit SomaCapsulas.Email.Source.Core;

interface

uses
  System.SysUtils, System.Classes, SomaCapsulas.Email.Interfaces,
  SomaCapsulas.Email.Source.Builder.Core, SomaCapsulas.Email.Types,
  System.Generics.Collections;

type
  TEmailSMTP = class(TInterfacedObject, IEmailSMTP)
  private
    FCrypto: TEmailSMTPCrypto;
    FPort: Integer;
    FHost: string;
    FPassword: string;
    FUsername: string;
    function GetCrypto: TEmailSMTPCrypto;
    function GetHost: string;
    function GetPort: Integer;
    function GetPassword: string;
    function GetUsername: string;
    function GetUseSSL: Boolean;
    function GetUseTLS: Boolean;
    procedure SetCrypto(const Value: TEmailSMTPCrypto);
    procedure SetHost(const Value: string);
    procedure SetPort(const Value: Integer);
    procedure SetPassword(const Value: string);
    procedure SetUsername(const Value: string);
  public
    class function CryptoToString(ACrypto: TEmailSMTPCrypto): string; static;
    class function StringToCrypto(ACryptoString: string): TEmailSMTPCrypto; static;
    property Host: string read GetHost write SetHost;
    property Port: Integer read GetPort write SetPort;
    property Crypto: TEmailSMTPCrypto read GetCrypto write SetCrypto;
    property Username: string read GetUsername write SetUsername;
    property Password: string read GetPassword write SetPassword;
    property UseSSL: Boolean read GetUseSSL;
    property UseTLS: Boolean read GetUseTLS;
    constructor Create(AHost: string; APort: Integer; ACrypto: TEmailSMTPCrypto; AUsername, APassword: string);
  end;

  TEmailSender = class(TInterfacedObject, IEmailSender)
  private
    FName: string;
    FEmail: string;
    function GetEmail: string;
    function GetName: string;
    procedure SetEmail(const Value: string);
    procedure SetName(const Value: string);
  public
    property Name: string read GetName write SetName;
    property Email: string read GetEmail write SetEmail;
    constructor Create(AEmail: string; AName: string = '');
  end;

  TEmailAttachment = class(TInterfacedObject, IEmailAttachment)
  private
    FLocation: string;
    FName: string;
    function GetLocation: string;
    function GetName: string;
    procedure SetLocation(const Value: string);
    procedure SetName(const Value: string);
  public
    constructor Create(ALocation, AName: string);
    property Name: string read GetName write SetName;
    property Location: string read GetLocation write SetLocation;
  end;

  TEmail = class(TInterfacedObject, IEmail)
  private
    FBody: string;
    FCarbonCopy: string;
    FSubject: string;
    FSMTP: IEmailSMTP;
    FSender: IEmailSender;
    FRecipientEmail: string;
    FAttachments: TList<IEmailAttachment>;
    function GetBody: string;
    function GetCarbonCopy: string;
    function GetRecipientEmail: string;
    function GetSender: IEmailSender;
    function GetSMTP: IEmailSMTP;
    function GetSubject: string;
    function GetAttachments: TList<IEmailAttachment>;
    procedure SetBody(const Value: string);
    procedure SetCarbonCopy(const Value: string);
    procedure SetRecipientEmail(const Value: string);
    procedure SetSender(const Value: IEmailSender);
    procedure SetSMTP(const Value: IEmailSMTP);
    procedure SetSubject(const Value: string);
    procedure SetAttachments(const Value: TList<IEmailAttachment>);
  public
    type Builder = TEmailBuilder;
    property SMTP: IEmailSMTP read GetSMTP write SetSMTP;
    property Sender: IEmailSender read GetSender write SetSender;
    property RecipientEmail: string read GetRecipientEmail write SetRecipientEmail;
    property CarbonCopy: string read GetCarbonCopy write SetCarbonCopy;
    property Subject: string read GetSubject write SetSubject;
    property Body: string read GetBody write SetBody;
    property Attachments: TList<IEmailAttachment> read GetAttachments write SetAttachments;
    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  System.StrUtils, SomaCapsulas.Email.Constants;

{ TEmailSMTP }

constructor TEmailSMTP.Create(AHost: string; APort: Integer; ACrypto: TEmailSMTPCrypto; AUsername, APassword: string);
begin
  Self.FHost := AHost;
  Self.FPort := APort;
  Self.FCrypto := ACrypto;
  Self.FUsername := AUsername;
  Self.FPassword := APassword;
end;

class function TEmailSMTP.StringToCrypto(ACryptoString: string): TEmailSMTPCrypto;
begin
  case AnsiIndexStr(ACryptoString, [EMAIL_SMTP_CRYPTO_SSL,
                                    EMAIL_SMTP_CRYPTO_TLS]) of
    0: Result := escSSL;
    1: Result := escTLS;
    else
      Result := escNone;
  end;
end;

class function TEmailSMTP.CryptoToString(ACrypto: TEmailSMTPCrypto): string;
begin
  case ACrypto of
    escSSL:
      Result := EMAIL_SMTP_CRYPTO_SSL;
    escTLS:
      Result := EMAIL_SMTP_CRYPTO_TLS;
    else
      Result := EmptyStr;
  end;
end;

function TEmailSMTP.GetCrypto: TEmailSMTPCrypto;
begin
  Result := Self.FCrypto;
end;

function TEmailSMTP.GetHost: string;
begin
  Result := Self.FHost;
end;

function TEmailSMTP.GetPassword: string;
begin
  Result := Self.FPassword;
end;

function TEmailSMTP.GetPort: Integer;
begin
  Result := Self.FPort;
end;

function TEmailSMTP.GetUsername: string;
begin
  Result := Self.FUsername;
end;

function TEmailSMTP.GetUseSSL: Boolean;
begin
  Result := (Self.FCrypto = escSSL);
end;

function TEmailSMTP.GetUseTLS: Boolean;
begin
  Result := (Self.FCrypto = escTLS);
end;

procedure TEmailSMTP.SetCrypto(const Value: TEmailSMTPCrypto);
begin
  FCrypto := Value;
end;

procedure TEmailSMTP.SetHost(const Value: string);
begin
  FHost := Value;
end;

procedure TEmailSMTP.SetPassword(const Value: string);
begin
  FPassword := Value;
end;

procedure TEmailSMTP.SetPort(const Value: Integer);
begin
  FPort := Value;
end;

procedure TEmailSMTP.SetUsername(const Value: string);
begin
  FUsername := Value;
end;

{ TEmailSender }

constructor TEmailSender.Create(AEmail, AName: string);
begin
  Self.FEmail := AEmail;
  Self.FName := AName;
end;

function TEmailSender.GetEmail: string;
begin
  Result := Self.FEmail;
end;

function TEmailSender.GetName: string;
begin
  Result := Self.FName;
end;

procedure TEmailSender.SetEmail(const Value: string);
begin
  FEmail := Value;
end;

procedure TEmailSender.SetName(const Value: string);
begin
  FName := Value;
end;

{ TEmailAttachment }

constructor TEmailAttachment.Create(ALocation, AName: string);
begin
  Self.FLocation := ALocation;
  Self.FName := AName;
end;

function TEmailAttachment.GetLocation: string;
begin
  Result := Self.FLocation;
end;

function TEmailAttachment.GetName: string;
begin
  Result := Self.FName;
end;

procedure TEmailAttachment.SetLocation(const Value: string);
begin
  FLocation := Value;
end;

procedure TEmailAttachment.SetName(const Value: string);
begin
  FName := Value;
end;

{ TEmail }

constructor TEmail.Create;
begin
  Self.FAttachments := TList<IEmailAttachment>.Create;
end;

destructor TEmail.Destroy;
begin
  Self.FAttachments.Free;
  inherited;
end;

function TEmail.GetAttachments: TList<IEmailAttachment>;
begin
  Result := Self.FAttachments;
end;

function TEmail.GetBody: string;
begin
  Result := Self.FBody;
end;

function TEmail.GetCarbonCopy: string;
begin
  Result := Self.FCarbonCopy;
end;

function TEmail.GetRecipientEmail: string;
begin
  Result := Self.FRecipientEmail;
end;

function TEmail.GetSender: IEmailSender;
begin
  Result := Self.FSender;
end;

function TEmail.GetSMTP: IEmailSMTP;
begin
  Result := Self.FSMTP;
end;

function TEmail.GetSubject: string;
begin
  Result := Self.FSubject;
end;

procedure TEmail.SetAttachments(const Value: TList<IEmailAttachment>);
begin
  FAttachments := Value;
end;

procedure TEmail.SetBody(const Value: string);
begin
  FBody := Value;
end;

procedure TEmail.SetCarbonCopy(const Value: string);
begin
  FCarbonCopy := Value;
end;

procedure TEmail.SetRecipientEmail(const Value: string);
begin
  FRecipientEmail := Value;
end;

procedure TEmail.SetSender(const Value: IEmailSender);
begin
  FSender := Value;
end;

procedure TEmail.SetSMTP(const Value: IEmailSMTP);
begin
  FSMTP := Value;
end;

procedure TEmail.SetSubject(const Value: string);
begin
  FSubject := Value;
end;

end.

unit SomaCapsulas.Email.Interfaces;

interface

uses
  SomaCapsulas.Email.Types, System.Generics.Collections;

type
  IEmailSMTP = interface
  ['{97D64D42-F3C0-48C0-89B2-44EB731AC894}']
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
    property Host: string read GetHost write SetHost;
    property Port: Integer read GetPort write SetPort;
    property Crypto: TEmailSMTPCrypto read GetCrypto write SetCrypto;
    property Username: string read GetUsername write SetUsername;
    property Password: string read GetPassword write SetPassword;
    property UseSSL: Boolean read GetUseSSL;
    property UseTLS: Boolean read GetUseTLS;
    end;

  IEmailSender = interface
  ['{CA8EA3C9-0B02-4750-A984-B6E63C854E57}']
    function GetEmail: string;
    function GetName: string;
    procedure SetEmail(const Value: string);
    procedure SetName(const Value: string);
    property Name: string read GetName write SetName;
    property Email: string read GetEmail write SetEmail;
  end;

  IEmailAttachment = interface
  ['{BB7A7457-D05F-4174-AE57-134FE38E012C}']
    function GetLocation: string;
    function GetName: string;
    procedure SetLocation(const Value: string);
    procedure SetName(const Value: string);
    property Name: string read GetName write SetName;
    property Location: string read GetLocation write SetLocation;
  end;

  IEmail = interface
  ['{C1B42EEB-D428-4127-941F-129BDF04F004}']
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
    property SMTP: IEmailSMTP read GetSMTP write SetSMTP;
    property Sender: IEmailSender read GetSender write SetSender;
    property RecipientEmail: string read GetRecipientEmail write SetRecipientEmail;
    property CarbonCopy: string read GetCarbonCopy write SetCarbonCopy;
    property Subject: string read GetSubject write SetSubject;
    property Body: string read GetBody write SetBody;
    property Attachments: TList<IEmailAttachment> read GetAttachments write SetAttachments;
  end;

  IEmailBuilder = interface
  ['{E24AD360-37EB-4937-87C7-BF6DA7DA44CA}']
    function UsingSMTP(ASMTP: IEmailSMTP): IEmailBuilder;
    function FromSender(ASender: IEmailSender): IEmailBuilder;
    function ToRecipientEmail(ARecipientEmail: string): IEmailBuilder;
    function WithCarbonCopy(ACarbonCopy: string): IEmailBuilder;
    function WithSubject(ASubject: string): IEmailBuilder;
    function WithBody(ABody: string): IEmailBuilder;
    function Build: IEmail;
  end;

  IEmailStrategy = interface
  ['{D4CB541D-2EC2-44AA-AAFF-EEC1DFB975AC}']
    function Send(AEmail: IEmail): Boolean;
  end;

implementation end.

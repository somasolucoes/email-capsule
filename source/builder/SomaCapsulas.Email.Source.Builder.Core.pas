unit SomaCapsulas.Email.Source.Builder.Core;

interface

uses
  System.Classes, System.SysUtils, SomaCapsulas.Email.Interfaces,
  SomaCapsulas.Email.Types, System.Generics.Collections;

type
  TEmailBuilder = class(TInterfacedObject, IEmailBuilder)
  private
    FEmail: IEmail;
  public
    function UsingSMTP(ASMTP: IEmailSMTP): IEmailBuilder;
    function FromSender(ASender: IEmailSender): IEmailBuilder;
    function ToRecipientEmail(ARecipientEmail: string): IEmailBuilder;
    function WithCarbonCopy(ACarbonCopy: string): IEmailBuilder;
    function WithSubject(ASubject: string): IEmailBuilder;
    function WithBody(ABody: string): IEmailBuilder;
    function WithAttachments(AAttachments: TList<IEmailAttachment>): IEmailBuilder;
    function Build: IEmail;
    constructor Create;
  end;

implementation

uses
  SomaCapsulas.Email.Source.Core;

{ TEmailBuilder }

constructor TEmailBuilder.Create;
begin
  Self.FEmail := TEmail.Create;
end;

function TEmailBuilder.Build: IEmail;
begin
  Result := Self.FEmail;
end;

function TEmailBuilder.WithAttachments(
  AAttachments: TList<IEmailAttachment>): IEmailBuilder;
begin
  Self.FEmail.Attachments := AAttachments;
  Result := Self;
end;

function TEmailBuilder.WithBody(ABody: string): IEmailBuilder;
begin
  Self.FEmail.Body := ABody;
  Result := Self;
end;

function TEmailBuilder.WithCarbonCopy(ACarbonCopy: string): IEmailBuilder;
begin
  Self.FEmail.CarbonCopy := ACarbonCopy;
  Result := Self;
end;

function TEmailBuilder.ToRecipientEmail(ARecipientEmail: string): IEmailBuilder;
begin
  Self.FEmail.RecipientEmail := ARecipientEmail;
  Result := Self;
end;

function TEmailBuilder.FromSender(ASender: IEmailSender): IEmailBuilder;
begin
  Self.FEmail.Sender := ASender;
  Result := Self;
end;

function TEmailBuilder.UsingSMTP(ASMTP: IEmailSMTP): IEmailBuilder;
begin
  Self.FEmail.SMTP := ASMTP;
  Result := Self;
end;

function TEmailBuilder.WithSubject(ASubject: string): IEmailBuilder;
begin
  Self.FEmail.Subject := ASubject;
  Result := Self;
end;

end.

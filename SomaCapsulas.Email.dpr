program SomaCapsulas.Email;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Generics.Collections,
  SomaCapsulas.Email.Source.Strategy.ACBrMail in 'source\strategy\SomaCapsulas.Email.Source.Strategy.ACBrMail.pas',
  SomaCapsulas.Email.Interfaces in 'SomaCapsulas.Email.Interfaces.pas',
  SomaCapsulas.Email.Source.Core in 'source\SomaCapsulas.Email.Source.Core.pas',
  SomaCapsulas.Email.Source.Builder.Core in 'source\builder\SomaCapsulas.Email.Source.Builder.Core.pas',
  SomaCapsulas.Email.Types in 'SomaCapsulas.Email.Types.pas',
  SomaCapsulas.Email.Constants in 'SomaCapsulas.Email.Constants.pas',
  SomaCapsulas.Email.Exception in 'SomaCapsulas.Email.Exception.pas',
  SomaCapsulas.Email.Message in 'SomaCapsulas.Email.Message.pas';

var
  LReadLnToWait: string;
begin
  try
    Writeln('SOMA Cápsulas - Email');
    Writeln(EmptyStr);
    Writeln('            _.-.                      ');
    Writeln('        .-.  `) |  .-.                ');
    Writeln('    _.''`. .~./  \.~. .`''._          ');
    Writeln('.-''`.''-''.''.-:    ;-.''.''-''.`''-.');
    Writeln(' `''`''`''`''`   \  /   `''`''`''`''` ');
    Writeln('             /||\                     ');
    Writeln('  jgs       / ^^ \                    ');
    Writeln('            `''``''`                  ');
    Read(LReadLnToWait);
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.

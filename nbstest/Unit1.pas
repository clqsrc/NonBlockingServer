unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  WinSock,
  Dialogs, StdCtrls, ExtCtrls;

type
  TForm1 = class(TForm)
    btnStart: TButton;
    Timer1: TTimer;
    procedure btnStartClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    procedure OnExecute(Socket: TSocket; ConnectID:Integer);
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses uSocketFunction, uNBServer;

{$R *.dfm}
var
  //ls:TSocket;
  server:TNBServer;

procedure TForm1.OnExecute(Socket:TSocket; ConnectID:Integer);
var
  c:Char;
  s:string;
begin
  //_send(Socket, 'bbb', 2, 0);
//  server.SendBuffer('abc', 2, Socket, ConnectID);
//
//  server.ReadBuffer(c, 1, Socket, ConnectID);
//  
//  server.SendBuffer(c, 1, Socket, ConnectID);
//  server.SendBuffer(c, 1, Socket, ConnectID);
//  server.SendBuffer(c, 1, Socket, ConnectID);

  server.timeOut := 15;

  if server.ReadLine(s, Socket, ConnectID) then //读取到一行后开始工作,目前的做法是在这一行中按 "|" 号分割取第几个的形式,实际上应该按 key=value 的形式更安全
  begin
    //server.SendString(s, Socket, ConnectID);
    server.SendLine(s, Socket, ConnectID);

  end;

//  server.ClearReadData(Socket, ConnectID); //读取到完整包后应当清除读取的数据,否则下次又读取到旧数据了

end;

procedure TForm1.btnStartClick(Sender: TObject);
begin
  if server = nil
  then server := TNBServer.Create(self);

  server.port := 30136;
  if server.Active = False then
  begin
    ShowMessage('端口被占用');
    Exit;
  end;

  server.OnExecute := self.OnExecute;

  btnStart.Enabled := False;

end;

procedure TForm1.Timer1Timer(Sender: TObject);
var
  so:TSocket;
begin
//  AcceptSocket(ls, so);
//  SetNoBlock(so);
//
//  _send(so, 'aaa', 2, 0);

end;

end.

unit uSocketFunction;

//针对 delphi 语言特点的 socket 函数封装

interface

uses
  Windows, WinSock, SysUtils;

function SetNoBlock(so: TSocket):Boolean;
//监听端口//简化接口,包括初始化环境和创建 socket
function ListenPort(var Listensc:TSocket; port:Integer):Boolean;
//接收一个连接
function AcceptSocket(Listensc:TSocket; var Acceptsc:TSocket):Boolean;

//测试函数
function _send(s: TSocket; buf:AnsiString; len, flags: Integer): Integer;
//测试函数
function _recv(s: TSocket; var buf:AnsiString; len, flags: Integer): Integer;


implementation

var
  g_InitSocket:Boolean = False;

//初始化 socket 环境
procedure InitSock;
var
  wsData: TWSAData;
begin
  if WSAStartUp($202, wsData) <> 0 then
  begin
      WSACleanup();
  end;

end;


//创建 socket
function CreateSocket: TSocket;
var
  errno:Integer;
  err: string;

begin
  Result := socket(AF_INET, SOCK_STREAM, IPPROTO_IP);//一个客户端 tcp socket

  if SOCKET_ERROR = Result then
  begin
    errno := WSAGetLastError;
    err := SysErrorMessage(errno);
    //Result := False;//不一定,有可能是非阻塞 socket 未能立即完成//10035(WSAEWOULDBLOCK) 时
    //Exit;

    //未调用 TThreadSafeSocket.InitSocket;
  end;
end;


//监听端口//简化接口,包括初始化环境和创建 socket
function ListenPort(var Listensc:TSocket; port:Integer):Boolean;
var
  sto:sockaddr_in;
begin
  Result := False;

  if g_InitSocket = False then InitSock();

  //创建一个套接字，将此套接字和一个端口绑定并监听此端口。
  Listensc := CreateSocket();//Socket(AF_INET,SOCK_STREAM,0,Nil,0,WSA_FLAG_OVERLAPPED);
  if Listensc=SOCKET_ERROR then
  begin
    closesocket(Listensc);
    //WSACleanup();
    Exit;
  end;

  sto.sin_family:=AF_INET;
  sto.sin_port := htons(port);//htons(5500);
  sto.sin_addr.s_addr:=htonl(INADDR_ANY);

  if WinSock.bind(Listensc, sto, sizeof(sto))=SOCKET_ERROR then //这个函数的声明和某些 winsocket2 的是不同的
  begin
    closesocket(Listensc);
    Exit;
  end;

  //listen(Listensc,20);         SOMAXCONN
  //listen(Listensc, SOMAXCONN);
  //listen(Listensc, $7fffffff);//WinSock2.SOMAXCONN);
  listen(Listensc, 1);//WinSock2.SOMAXCONN);// 2015/4/3 15:03:26 太大的话其实也是有问题的,会导致程序停止响应时客户端仍然可以连接上,并且大量的占用

  Result := True;
end;

//接收一个连接
function AcceptSocket(Listensc:TSocket; var Acceptsc:TSocket):Boolean;
begin
  Result := False;

  Acceptsc := Accept(Listensc, nil, nil);

  //判断Acceptsc套接字创建是否成功，如果不成功则退出。
 if (Acceptsc= SOCKET_ERROR) then Exit;


  Result := True;
end;



function SetNoBlock(so: TSocket):Boolean;
var
  errno:Integer;
  err: string;
  arg:Integer;
begin
  Result := True;
  //--------------------------------------------------

  //首先，设置通讯为非阻塞模式
  arg := 1;
  ioctlsocket(so, FIONBIO, arg);

  //if SOCKET_ERROR = Connect(so, addr, Sizeof(TSockAddrIn)) then
  begin
    errno := WSAGetLastError;
    err := SysErrorMessage(errno);
    //Result := False;//不一定,有可能是非阻塞 socket 未能立即完成//10035(WSAEWOULDBLOCK) 时
    //Exit;

    if errno <> WSAEWOULDBLOCK then //WSAEISCONN(10056) The socket is already connected
    begin
      //多次调试都是返回 WSAEWOULDBLOCK 的多,到这里来的可能性很小
      Result := False;
      Exit;
    end;

  end;

end;


//send 函数的 delphi 特性封装,因为某些 delphi send 函数声明为 var 如果使用 string 实际上是会出错的,必须要取 string 有实际地址
//如果不明就里,直接把 string 的内容放到一个 ansichar 数据也行
//d7  WinSock.pas  的原声明为  function send(s: TSocket; var Buf; len, flags: Integer): Integer; stdcall;
function _send(s: TSocket; buf:AnsiString; len, flags: Integer): Integer;
begin
  //注意,用这句是不对的,虽然能编译//Result := send(s, buf, len, flags);
  //这是 delphi 的语言及 string 类型造成的特别语法,不用管它
  Result := send(s, (@buf[1])^, len, flags);
end;

//方便字符应答式操作的函数
function _recv(s: TSocket; var buf:AnsiString; len, flags: Integer): Integer;
//d7  WinSock.pas  的原声明为  function recv(s: TSocket; var Buf; len, flags: Integer): Integer; stdcall;
begin
  SetLength(buf, len);
  FillChar((@buf[1])^, len, 0);

  //应该也是不能这样用的//Result :=recv(s, buf, len, flags);
  //这是 delphi 的语言及 string 类型造成的特别语法,不用管它
  Result :=recv(s, (@buf[1])^, len, flags);
end;



end.

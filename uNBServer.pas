unit uNBServer;

//非阻塞的线程安全服务器框架,尽量的简单
//将来要做的:
//1.限制发送包的大小,每个连接的和总的都应该限制.
//2.限制接收包的决大小,目前只限制了每个连接的.

interface

uses
  Windows, WinSock, SysUtils, Classes, ExtCtrls, DateUtils,
  uSocketFunction;

const
  NBS_MAX_CONNECT = 2000;//最大连接数,目前支持 2000 就可以了

type
  TSocket = WinSock.TSocket;//Cardinal;//u_int;//clq //c 语言原型里的确是无符号的//TSocket 兼容性修正//IdWinSock2 中有误// 2015/4/10 14:42:46 这里只用 WinSock 的函数就行了

type
  //尽量与 TIdTCPServer 的接口相同//ConnectID 等同于其在数组中的位置
  TOnExecute = procedure (Socket:TSocket; ConnectID:Integer) of object;

  //以下类似 iocp 的接口,可以不实现//另外实现一个伪装类好了
  //连接到达
  //TOnSocketConnectProc = procedure (Socket: TSocket; var OuterFlag:Integer{供外部设置连接标志}) of object;

type
  NBSConnect = record
    Socket:TSocket;
    //ConnectTime:DWORD;//GetTickCount 数
    ConnectTime:Int64;//UnixToDateTime 数,用 C 风格秒数比较好, GetTickCount 会为负
    LastActive:Int64;//最后一次活动时间,当连接全满时应当删除掉最老不活动的连接//值含义同上
    Connected:Boolean;//是否连接了
    ShutDown:Boolean;//是否 shutdown 要求发送完数据后关闭 socket
    IsSet:Boolean;//没用到的节点

    //下面是接收数据的标志,不要用在其他地方
    //RECV_lastLen
    //从目前的已有代码来看仍然不得不用流,以后新增加的代码可以尽量避开
    RecvStream:TMemoryStream;
    SendStream:TMemoryStream;


  end;

type
  //封装 iocp 的类
  TNBServer = class(TComponent)//(TObject)
  private
    listenso:TSocket;

    //全部用定时器实现,不用线程
    workTimer:TTimer;
    //为了尽量减少内存操作使用数组保存连接数并实现属性函数来操作,以检测边界//实际上占不了多少内存
    Conncts:array[0..NBS_MAX_CONNECT-1] of NBSConnect;

    procedure OnWorkTimer(Sender: TObject);
    procedure DoAccept;
    function GetBlankConnect: Integer;
    function CanRecv(so: TSocket): Boolean;
    function CanSend(so: TSocket): Boolean;
    procedure InitConncts;
    class procedure ClearData_Fun(var Memory: TMemoryStream;
      dataLen: Integer);
    function ReadData(Socket: TSocket; ConnectID:Integer):Integer;
    function GetConnect(ConnectID: Integer;
      var Connect: NBSConnect): Boolean;
    function SendData(Socket: TSocket; ConnectID: Integer): Integer;

  public
    port:Integer;

    //不太准确的连接数
    ConnectedCount:Integer;

    //尽量与 TIdTCPServer 的接口相同
    OnExecute:TOnExecute;

    //多少秒没有数据算超时//默认为 10 秒
    timeOut:Integer;

    //与 indy OnExecute 中 ReadBuffer 类似的接口//indy 是一定会读取完的,这个接口则要读取多次,返回成功时才表示完成了
    //procedure TIdTCPConnection.ReadBuffer(var ABuffer; const AByteCount: Integer);
    procedure ReadBuffer(var ABuffer; const AByteCount: Integer; Socket: TSocket; ConnectID:Integer);

    //不抛出异常的
    function Read(var Buffer; Count: Integer; Socket: TSocket; ConnectID:Integer): Longint;

    //发送一个缓冲区 //接口同流的 WriteBuffer
    procedure SendBuffer(const Buffer; Count: Longint; Socket: TSocket; ConnectID:Integer);
    //发送一个流 //接口同流的 WriteStream
    procedure SendStream(AStream: TMemoryStream; Socket: TSocket; ConnectID:Integer);


    //与 indy 不同的是 ReadBuffer,Read 之后的数据不需要的话要手工清理//似乎不太好,最好加个标志让用户选择是否手工清理
    procedure ClearReadData(Socket: TSocket; ConnectID:Integer);

    //关闭一个连接
    procedure CloseConnect(Socket:TSocket; ConnectID:Integer);
    //全部发送完成后自动关闭,类似于原始 shutdown api 函数
    procedure ShutDownConnect(Socket: TSocket; ConnectID: Integer);

    //代替 OnExcute 中的 TIdTCPConnection.RecvBufferSize
    function RecvBufferSize(Socket:TSocket; ConnectID:Integer):Integer;

    function Active:Boolean;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

  end;

var
  //按道理说已经有定时器在工作了就要等待下一次,否则没有 sleep 会类似于死循环
  g_atWorkTimer:Boolean = False;  

implementation

uses
  uLogFile;

{ TNBServer }

function TNBServer.Active: Boolean;
begin
  Result := False;

  if not ListenPort(self.listenso, port) then Exit;

  SetNoBlock(self.listenso);

  workTimer.Interval := 1;//没多大用,其实和 10 差不多
  workTimer.Enabled := True;

  Result := True;
end;

constructor TNBServer.Create(AOwner: TComponent);
begin
  //inherited;
  inherited Create(AOwner);

  //多少秒没有数据算超时//默认为 10 秒
  timeOut := 10;


  //初始化连接数组
  Self.InitConncts;

  workTimer := TTimer.Create(Self);
  workTimer.OnTimer := Self.OnWorkTimer;

end;

destructor TNBServer.Destroy;
begin
  workTimer.Enabled := False;
  OnExecute := nil;

  inherited Destroy;
end;

//取一个没用过的数组索引号//简单一点,不用太考虑性能
function TNBServer.GetBlankConnect:Integer;
var
  i:Integer;
begin
  Result := -1;

  for i := 0 to NBS_MAX_CONNECT-1 do
  begin
    if Conncts[i].IsSet = False then
    begin
      Result := i;
      Break;
    end;

  end;

end;


//初始化连接数组
procedure TNBServer.InitConncts;
var
  i:Integer;
begin
  for i := 0 to NBS_MAX_CONNECT-1 do
  begin
    Conncts[i].RecvStream := TMemoryStream.Create;
    Conncts[i].SendStream := TMemoryStream.Create;

  end;

end;


//接受连接的过程
procedure TNBServer.DoAccept;
var
  so:TSocket;
  index:Integer;
begin
  if not AcceptSocket(listenso, so) then Exit;
  SetNoBlock(so);

  index := GetBlankConnect;
  if index = -1 then
  begin
    closesocket(so);//没办法,没有空位置了
    Exit;
  end;

  Conncts[index].IsSet := True;
  Conncts[index].Socket := so;
  Conncts[index].ConnectTime := DateTimeToUnix(now);
  Conncts[index].Connected := True;
  Conncts[index].ShutDown := False;//是否 shutdown 要求发送完数据后关闭 socket
  Conncts[index].LastActive := DateTimeToUnix(now);

  //_send(so, 'aaa', 2, 0);//test

end;

function TNBServer.CanRecv(so: TSocket):Boolean;
var
  addr:sockaddr_in;//TInAddr;//TSockAddrIn
  arg:Integer;
  recvSet:TFDSet;
  r:Integer;
  tmOut:TTimeVal;
  SctTimeOut:Integer;
  errno:Integer;
  err: string;

begin
  Result := False;
  //if Connect.ShutDown=True then Exit;//不好,应该放到 canread 中

  tmOut.tv_sec := 0;//20;//2;
  tmOut.tv_usec := 0;
  FD_ZERO(recvSet);
  FD_SET(so, recvSet);

  //大部分代码只设置判断是否可读,但也有认为必须判断可写
  //r := select(0, @recvSet, @recvSet, nil, @tmOut);
  r := select(0, @recvSet, 0,  nil, @tmOut);//只判断可读
  if (r = 0) or (r = SOCKET_ERROR) then
  begin
    //ErrMsg := '连接服务器失败！';
    Result := False;
    exit;
  end;

  Result := True;

end;

function TNBServer.CanSend(so: TSocket):Boolean;
var
  addr:sockaddr_in;//TInAddr;//TSockAddrIn
  arg:Integer;
  recvSet:TFDSet;
  r:Integer;
  tmOut:TTimeVal;
  SctTimeOut:Integer;
  errno:Integer;
  err: string;

begin

  tmOut.tv_sec := 0;//20;//2;
  tmOut.tv_usec := 0;
  FD_ZERO(recvSet);
  FD_SET(so, recvSet);

  //大部分代码只设置判断是否可读,但也有认为必须判断可写
  //r := select(0, @recvSet, @recvSet, nil, @tmOut);
  //r := select(0, @recvSet, 0, nil, @tmOut);//只判断可读
  r := select(0, 0, @recvSet, nil,  @tmOut);//只判断可读//这里是可写
  if (r = 0) or (r = SOCKET_ERROR) then
  begin
    //ErrMsg := '连接服务器失败！';
    Result := False;
    exit;
  end;

  Result := True;

end;


function TNBServer.GetConnect(ConnectID:Integer; var Connect:NBSConnect):Boolean;
begin
  Result := False;

  if ConnectID<0 then Exit;
  if ConnectID>=NBS_MAX_CONNECT then Exit;

  Connect := self.Conncts[ConnectID];

  Result := True;
end;

//closesocket(Socket); //新接口和 iocp 不一样,尽量不要调用原始 socket 关闭,因为没法检测到关闭信号
//关闭一个连接,但等待发送完全部数据
procedure TNBServer.ShutDownConnect(Socket:TSocket; ConnectID:Integer);
var
  //s:TMemoryStream;

  r:Integer;

  Connect:NBSConnect;

begin
  if GetConnect(ConnectID, Connect)=False then Exit;

  //closesocket(Connect.Socket);
  //shutdown(Socket, 0); //0 不能再读，1不能再写，2 读写都不能//实际上也不能 shutdown 因为发送数据是分片的,有些分片数据这里还没能进入缓冲区,
  //应当在发送过程中判断全部发送后才 shutdown

  //s := self.Conncts[ConnectID].RecvStream;
  //s.Clear;

  Connect.RecvStream.Clear;
//  Connect.SendStream.Clear;//发送区可不能清空

  //--------------------------------------------------
  //与 TNBServer.DoAccept 中的工作相反
//  Conncts[ConnectID].IsSet := False;
  //Conncts[index].Socket := so;
  //Conncts[index].ConnectTime := DateTimeToUnix(now);
//  Conncts[ConnectID].Connected := False;
  Conncts[ConnectID].ShutDown := True;
  //Conncts[index].LastActive := DateTimeToUnix(now);


end;


//关闭一个连接
procedure TNBServer.CloseConnect(Socket:TSocket; ConnectID:Integer);
var
  //s:TMemoryStream;

  r:Integer;

  Connect:NBSConnect;

begin
  if GetConnect(ConnectID, Connect)=False then Exit;

  if Connect.ShutDown=False then //已经 shutdown 的不要再 closesocket 因为缓冲区不一定发送完毕了
  closesocket(Connect.Socket);

  //s := self.Conncts[ConnectID].RecvStream;
  //s.Clear;

  Connect.RecvStream.Clear;
  Connect.SendStream.Clear;

  //--------------------------------------------------
  //与 TNBServer.DoAccept 中的工作相反
  Conncts[ConnectID].IsSet := False;
  //Conncts[index].Socket := so;
  //Conncts[index].ConnectTime := DateTimeToUnix(now);
  Conncts[ConnectID].Connected := False;
  //Conncts[index].LastActive := DateTimeToUnix(now);


end;


procedure TNBServer.OnWorkTimer(Sender: TObject);
var
  i:Integer;
  count:Integer;
  r:Integer;
  now_sec:Int64;
begin

  try
    //按道理说已经有定时器在工作了就要等待下一次,否则没有 sleep 会类似于死循环
    if g_atWorkTimer=True then Exit;
    g_atWorkTimer := True;
    Sleep(1);//这几个选项对降低 cpu 占用还是很有帮助的,但测试极端情况时就好当打开进行测试

    //--------------------------------------------------

    count := 0;

    //接受连接
    DoAccept;

    now_sec := DateTimeToUnix(now);


    for i := 0 to NBS_MAX_CONNECT-1 do
    begin
      if Conncts[i].IsSet = False then Continue;

      if Conncts[i].Connected then Inc(count);

      //读取
      //if CanRecv(Conncts[i].Socket) then
      if (Conncts[i].ShutDown=False)and(CanRecv(Conncts[i].Socket)) then //shutdown 的情况下就不管了
      begin
        r := ReadData(Conncts[i].Socket, i);

        if r = 0 then //select 有效之后仍然读取为 0 那就是断开连接了//自己 shutdown 或者 close 是到不了这里的
        begin

          //closesocket(Conncts[i].Socket);
          CloseConnect(Conncts[i].Socket, i);
        end;

        Conncts[i].LastActive := now_sec;//要重置活动时间,发送时要不要呢?

        Conncts[i].RecvStream.Seek(0, soFromBeginning);//要移动读取位置到最前,否则事件中调用会异常失败

        if Assigned(Self.OnExecute) then Self.OnExecute(Conncts[i].Socket, i);
      end;

      //select 判断的断开事件是正常关闭,非正常的,还要判断超时
      if (Conncts[i].Connected)and(now_sec - Conncts[i].LastActive > timeOut) then
      begin
        CloseConnect(Conncts[i].Socket, i);
      end;

      //发送
      if CanSend(Conncts[i].Socket) then
      begin
        //读取是先收数据再触发事件,发送是先触发事件再发送数据//或者是它应该触发另外一个自己的事件
        //if Assigned(Self.OnExecute) then Self.OnExecute(Conncts[i].Socket, i);

        r := SendData(Conncts[i].Socket, i);


        //其实第一次能发送数据的时候就是刚连接上,可以作为连接的事件

      end;


    end;

    Self.ConnectedCount := count;

  finally
    //Sleep(1);//不要放在这里
    g_atWorkTimer := False;
  end;
end;


//辅助函数,清空用掉的部分数据,和服务器端的代码是一样的
class procedure TNBServer.ClearData_Fun(var Memory:TMemoryStream; dataLen:Integer);
var
  tmp:TMemoryStream;
  p:PAnsiChar;
  clearSize:Integer;
begin

  if (dataLen<=0) or (dataLen>Memory.Size) then Exit;

  if (dataLen = Memory.Size) then//全部用完的话清空就行了
  begin
    Memory.Clear;
    Exit;
  end;

  clearSize := Memory.Size - dataLen;
  if (clearSize > 200 * 1024 * 1024) then
  begin
    MessageBox(0, PChar('释放长度异常 [' + IntToStr(dataLen) + ']'), '', 0);
    Memory.Clear;
    Exit;
  end;

  tmp := TMemoryStream.Create;


//  helper.FMemory.Seek(dataLen, soBeginning);//没用这样仍是保存全部
  Memory.SaveToStream(tmp);

  //p := PAnsiChar(FMemory.Memory);
  p := PAnsiChar(tmp.Memory);
  p := p + dataLen;

  //tmp.WriteBuffer(p, helper.FMemory.Size - dataLen);//奇怪有异常
  //tmp.WriteBuffer(p^, FMemory.Size - dataLen);//注意这里 指针的用法

  Memory.Clear;
  Memory.WriteBuffer(p^, tmp.Size - dataLen);//注意这里 指针的用法


//  FMemory.Free;
//  FMemory := tmp;
  tmp.Free;


end;

//自己读取数据
function TNBServer.ReadData(Socket: TSocket; ConnectID:Integer):Integer;
var
  s:TMemoryStream;

  buf:array[0..4096-1] of AnsiChar;
  r:Integer;
  Connect:NBSConnect;

begin
  //Result := 0;//为 0 表示连接关闭了,所以另外取个默认值
  Result := -1;//为 0 表示连接关闭了,所以另外取个默认值

  if GetConnect(ConnectID, Connect)=False then Exit;
  //if Connect.ShutDown=True then Exit;//不好,应该放到 canread 中

  s := self.Conncts[ConnectID].RecvStream;

  r := WinSock.recv(Socket, buf, SizeOf(buf), 0);
  //r := recv(FSocket, buf, 8, 0);//test
  if r>0 then
  begin
    s.Seek(0, soFromEnd);//确保跳到缓冲区最末尾

    //注意不能是 FMemory.WriteBuffer(buf, bufLen); 就是说参数不能是指针,也许内部又转了一次指针?
    s.WriteBuffer(buf, r);
    s.Seek(0, soFromBeginning);//要移动读取位置到最前


    //if FMemory.Size > 1024 * 1024 * 2 then
    if s.Size > 1024 * 1024 * 100 then
    begin
      //MessageBox(0, '单个连接从服务器接收了太多数据而未处理', '内部错误', 0);
      LogFile('单个连接从服务器接收了太多数据而未处理');
    end;
  end;

  Result := r;

end;


//自己发数据
function TNBServer.SendData(Socket: TSocket; ConnectID:Integer):Integer;
var
  //s:TMemoryStream;

  //buf:array[0..4096-1] of AnsiChar;
  r:Integer;
  Connect:NBSConnect;

begin
  //Result := 0;//为 0 表示连接关闭了,所以另外取个默认值
  Result := -1;//为 0 表示连接关闭了,所以另外取个默认值

  if GetConnect(ConnectID, Connect)=False then Exit;

  if Connect.SendStream.Size>0 then
  begin

    r := WinSock.send(Socket, Connect.SendStream.Memory^, Connect.SendStream.Size, 0);//这个动作即使失败对 cpu 的消耗也非常大,所以要限制发送缓冲大小

    if r>0 then
    begin
      ClearData_Fun(Connect.SendStream, r);
      Connect.SendStream.Seek(0, soFromBeginning);//要移动读取位置到最前

    end;
    Result := r;
  end;

  //发送完数据后,如果有 shutdown 请求,则主动关闭//接收的时候有 shutdown 也表示不能再收了
  if (Connect.SendStream.Size=0) and (Connect.ShutDown=True) then
  begin
    shutdown(Connect.Socket, 0);//shutdown(Socket, 0); //0 不能再读，1不能再写，2 读写都不能
    CloseConnect(Socket, ConnectID);//调用 socket api shutdown 后才能关闭
  end;


  //Result := r;

end;


//与 indy 不同的是 ReadBuffer,Read 之后的数据不需要的话要手工清理//似乎不太好,最好加个标志让用户选择是否手工清理
procedure TNBServer.ClearReadData(Socket: TSocket; ConnectID:Integer);
var
  s:TMemoryStream;

  buf:array[0..4096-1] of AnsiChar;
  r:Integer;

  Connect:NBSConnect;

begin
  if GetConnect(ConnectID, Connect)=False then Exit;

  s := self.Conncts[ConnectID].RecvStream;

  ClearData_Fun(s, s.Position);

end;


//用户读取数据
//与 indy OnExecute 中 ReadBuffer 类似的接口//indy 是一定会读取完的,这个接口则要读取多次,返回成功时才表示完成了
//procedure TIdTCPConnection.ReadBuffer(var ABuffer; const AByteCount: Integer);

procedure TNBServer.ReadBuffer(var ABuffer; const AByteCount: Integer; Socket: TSocket; ConnectID:Integer);
var
  s:TMemoryStream;

  buf:array[0..4096-1] of AnsiChar;
  r:Integer;

  Connect:NBSConnect;

begin
  if GetConnect(ConnectID, Connect)=False then Exit;

  s := self.Conncts[ConnectID].RecvStream;

  //真实读取数据是在 ReadData 中
  //--------------------------------------------------
  //以上是接收,下面判断,如果收到用户需要的长度则给用户

  //从 TIdTCPConnection.ReadBuffer 的原意上看这里可以抛出异常告诉用户数据不足,不用 try//不抛出异常的,要看 Read 函数
  s.ReadBuffer(ABuffer, AByteCount);

end;

//直接来自 TCustomMemoryStream.Read
function TNBServer.Read(var Buffer; Count: Longint; Socket: TSocket; ConnectID:Integer): Longint;
var
  s:TMemoryStream;

  r:Integer;

  Connect:NBSConnect;

begin
  if GetConnect(ConnectID, Connect)=False then Exit;

  s := self.Conncts[ConnectID].RecvStream;

  Result := s.Read(Buffer, Count);

end;

//发送一个缓冲区
procedure TNBServer.SendBuffer(const Buffer; Count: Longint; Socket: TSocket; ConnectID:Integer);
var
  //s:TMemoryStream;

  r:Integer;

  Connect:NBSConnect;

begin
  if GetConnect(ConnectID, Connect)=False then Exit;

  Connect.SendStream.Seek(0, soFromEnd);//确保跳到缓冲区最末尾
  Connect.SendStream.WriteBuffer(Buffer, Count);

end;

//发送一个流 //接口同流的 WriteStream
procedure TNBServer.SendStream(AStream: TMemoryStream; Socket: TSocket; ConnectID:Integer);
var
  //s:TMemoryStream;

  r:Integer;

  Connect:NBSConnect;

begin
  if GetConnect(ConnectID, Connect)=False then Exit;

  Connect.SendStream.Seek(0, soFromEnd);//确保跳到缓冲区最末尾
  Connect.SendStream.WriteBuffer(AStream.Memory^, AStream.Size);

end;


function TNBServer.RecvBufferSize(Socket: TSocket;
  ConnectID: Integer): Integer;
var
  //s:TMemoryStream;

  r:Integer;

  Connect:NBSConnect;

begin
  Result := 0;
  
  if GetConnect(ConnectID, Connect)=False then Exit;

  Result := Connect.RecvStream.Size;

end;

end.

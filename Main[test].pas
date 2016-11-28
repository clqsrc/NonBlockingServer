unit Main;

//来自  D:\gs_d\fy\src\3.0\ServerV3.0加LOG[线程同步版]\ServerV3.0 
//的实用示例

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs,MarketInput_UDP, StdCtrls,ZLib,DataStructure_FYV30,CodeTableProcessing,
  DataProcessing,CommonFunc,CoolIOCPTCP,NewPkgDef,Queue,JYTCP_Interface,IniFiles,QuoteDefV3,
  UserProcessing, ExtCtrls,TcpAndUdp,FileProcessing,
  StockHQProcessing, ComCtrls, Spin,Comparison_UDP,DESCrypt,SZCodeBaseX,strFunc,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient,WinSock,Math,
  uNBServer, 
  IdTCPServer,IdSocketHandle, AppEvnts;




type
  TForm_Main = class(TForm)
    btn3: TButton;
    StatusBar1: TStatusBar;
    Timer1: TTimer;
    pgc1: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    grp1: TGroupBox;
    Label2: TLabel;
    Button1: TButton;
    CheckBox_Clear: TCheckBox;
    CheckBox_Hisreq: TCheckBox;
    CBox_del0: TCheckBox;
    CBox_noRev: TCheckBox;
    Button3: TButton;
    RadioGroup1: TRadioGroup;
    Button2: TButton;
    RadioButton_BuDeng: TRadioButton;
    RadioButton_DaYu: TRadioButton;
    grp2: TGroupBox;
    CBox_Yhq: TCheckBox;
    CBox_YpriceTable: TCheckBox;
    CBox_ModifyHq: TCheckBox;
    SpinEdit_intHq: TSpinEdit;
    CBox_Comp: TCheckBox;
    CheckBox_DelNoName: TCheckBox;
    grp3: TGroupBox;
    CheckBox_CMoney: TCheckBox;
    CheckBox_NoForePrice: TCheckBox;
    Panel1: TPanel;
    Button_Run: TButton;
    Button_Stop: TButton;
    CBox_AutoStart: TCheckBox;
    grp_EndDate: TGroupBox;
    Label4: TLabel;
    Label_PCNumNOT: TLabel;
    Edit_EndDate_Pass: TEdit;
    Panel3: TPanel;
    Label_EndDate: TLabel;
    Label6: TLabel;
    Button_SaveNewEndDate: TButton;
    Panel4: TPanel;
    Label9: TLabel;
    Memo_PCNum: TMemo;
    Timer2: TTimer;
    CheckBox_ClearNoVol: TCheckBox;
    TabSheet3: TTabSheet;
    Panel2: TPanel;
    Label3: TLabel;
    Edit_Title: TEdit;
    Memo_msg: TMemo;
    Button4: TButton;
    Label_hit: TLabel;
    IdTCPServer1: TIdTCPServer;
    Timer3: TTimer;
    Panel5: TPanel;
    Label1: TLabel;
    Label5: TLabel;
    ApplicationEvents1: TApplicationEvents;
    CheckBox_NoSendZZ: TCheckBox;
    TabSheet_ConLenShow: TTabSheet;
    Panel6: TPanel;
    ListView_LenConShow: TListView;
    Button_TcpLenShow: TButton;
    Button_TcpLenLogCLS: TButton;
    Button_TcpLenLogSave: TButton;
    Timer_UserIPConsMath: TTimer;
    Timer_Log: TTimer;
    TabSheet_LOG: TTabSheet;
    Panel7: TPanel;
    CheckBox_TCPLENLOG: TCheckBox;




    procedure Button_RunClick(Sender: TObject);
    procedure Button_StopClick(Sender: TObject);
    procedure btn3Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure CheckBox_ClearClick(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure CheckBox_HisreqClick(Sender: TObject);
    procedure CBox_del0Click(Sender: TObject);
    procedure CBox_noRevClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure CBox_AutoStartClick(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure RadioButton_BuDengClick(Sender: TObject);
    procedure RadioButton_DaYuClick(Sender: TObject);
    procedure CBox_YhqClick(Sender: TObject);
    procedure CBox_YpriceTableClick(Sender: TObject);
    procedure CBox_ModifyHqClick(Sender: TObject);
    procedure CBox_CompClick(Sender: TObject);
    procedure CheckBox_DelNoNameClick(Sender: TObject);
    procedure CheckBox_CMoneyClick(Sender: TObject);
    procedure CheckBox_NoForePriceClick(Sender: TObject);
    procedure Button_SaveNewEndDateClick(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure CheckBox_ClearNoVolClick(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure IdTCPServer1Execute(AThread: TIdPeerThread);
    procedure Timer3Timer(Sender: TObject);
    procedure ApplicationEvents1Exception(Sender: TObject; E: Exception);
    procedure Button_TcpLenShowClick(Sender: TObject);
    procedure Button_TcpLenLogCLSClick(Sender: TObject);
    procedure Button_TcpLenLogSaveClick(Sender: TObject);
    procedure Timer_UserIPConsMathTimer(Sender: TObject);
    procedure Timer_LogTimer(Sender: TObject);
    procedure CheckBox_TCPLENLOGClick(Sender: TObject);


  private
    { Private declarations }
    TimingProHQTimer: TTimer;//定时处理行情
    TimingProHQBegin: Boolean;
    ProcCodeIndexPos: Integer;

    ShortTcpServer:TNBServer;//短连接服务器//代替 TIdTCPServer 的非线程同步服务器接口,其接口各操作可在各定时器安全调用无需加锁

    procedure TimingProHQTimerProcessing(Sender: TObject);
    procedure WriteUserMaxNub(iMaxUser: Integer);
    procedure OnShortTcpServerExecute(Socket: TSocket; ConnectID: Integer);
    procedure DoShortTcpServerExecute(AStream: TMemoryStream;
      NewPkgHead: TNewPkgHead; buf: PChar);//写历史最大用户数
  public
    { Public declarations }
    FiShortTcpCount: Integer;
    EXEBindIP: string;
    FbVisible_ZZ: Boolean; //界面上 不发郑州 按钮
    Procedure Run;
    Procedure Stop;
    procedure LoadConfig;
    procedure GetRunTime;
  end;

var
  Form_Main: TForm_Main;
  C_LimitTime:integer= 20190501;
//  C_LimitTime:integer= 20161101;
  Company_Name:STRING='';//使用此服务器的公司名称
  FiRevDataCout: int64=0;  //接收到数据量
  procedure UDPDataInput(IP:String;Len:LongWord;Buf:TBuf);stdcall;//处理行情包
implementation
uses
  HQStrmProcessing,Unit_Price, Unit_AutoAcceptVol,Unit_Users,DataInput_TCP,ShortTcpReq;

{$R *.dfm}

procedure writelog(str: string;fileName: string);
var
  F: TextFile;
  S,FilePath: String;
  qFileStream:   TFileStream;
begin
  FilePath := ExtractFilePath(ParamStr(0)) +fileName;
  If  not FileExists(FilePath)   then
  begin
    qFileStream   :=   TFileStream.Create(FilePath,   fmCreate);//这里用打开写方式。可设其他常量值看帮助。
    qFileStream.Seek(0,   sofromEnd);
    qFileStream.Free;
  end;                    
  AssignFile(F,   FilePath);
  Append (F);
  str := str + '      ' + FormatDateTime('yyyy-mm-dd hh:mm:ss',Now);
  Writeln(F,str);
  CloseFile(F);
end;

function HostToIP(Name: string; var Ip: string): Boolean;
var
  wsdata : TWSAData;
  hostName : array [0..255] of char;
  hostEnt : PHostEnt;
  addr : PChar;
begin
  WSAStartup ($0101, wsdata);
  try
    gethostname (hostName, sizeof (hostName));
    StrPCopy(hostName, Name);
    hostEnt := gethostbyname (hostName);
    if Assigned (hostEnt) then
      if Assigned (hostEnt^.h_addr_list) then begin
        addr := hostEnt^.h_addr_list^;
        if Assigned (addr) then begin
          IP := Format ('%d.%d.%d.%d', [byte (addr [0]),
          byte (addr [1]), byte (addr [2]), byte (addr [3])]);
          Result := True;
        end
        else
          Result := False;
      end
      else
        Result := False
    else begin
      Result := False;
    end;
  finally
    WSACleanup;
  end
end;

procedure UDPDataInput(IP:String;Len:LongWord;Buf:TBuf);//处理行情包
var
  TempIP:STRING;
  TempLen:LongWord;
  TempBuf:TBuf;
  iType: Integer;
  QuoteHeadV3: TQuoteHeadV3;
  PHQ: PRealDataV3;
  pItem: PCodeItem;
  pCurr: PShortRealV3;
  i,j,k :Integer;
  Hour,Min,Sec:Byte;
  DailyHQ: TDailyHQ;
  DailyHQList,DailyHQList2:TDailyHQList;
  HQ: TServerDailyHQ;
  PTrade: PUDPTrade;
  PreValue: Integer;
  PreType: Byte;
  pUpdate: PUpdateCode;
  pSrvpackage: PFyServerPackage;
  pBuf: PChar;
  ini: TIniFile;
  Week,CodeIndex:word;
  ZoneDateTime:TDateTime;
  tmpRegCode: PRegCode;
  tmpPNews,theNew: PNews;
begin
  Inc(FiRevDataCout);
  PreValue := 0;
  PreType := 0;
  TempIP:=IP;
  TempLen:=Len;
  fillchar(TempBuf,sizeof(TempBuf),#0);
  Move(Buf[0], TempBuf[0], TempLen);

  pBuf := @TempBuf;
  pSrvpackage := PFyServerPackage(pBuf);
  if (pSrvpackage.PackageSign[0] <> 'F') and (pSrvpackage.PackageSign[1] <> 'Y')  then
  begin
    WriteRunLog('UDPDataInput','数据结构错误，来至：' + IP + ' 长度：' + IntToStr(Len) + ' from:Main.pas');
    Exit;
  end;
  if TempLen < SizeOf(TFyServerPackage) then
  begin
    WriteRunLog('UDPDataInput','数据长度小于SizeOf(TFyServerPackage)，来至：' + IP + ' 长度：' + IntToStr(Len) + ' from:Main.pas');
    Exit;
  end;


  DailyHQList.HQNum := 0;


  if FbIsUpdate then Exit;
  //更新操作

  case pSrvpackage.PackageType of
    Rev_UDPHQ_Terminate:
    begin
    //  Application.Terminate;
      Exit;
    end;

    Rev_UDPHQ_FUTURES:
    begin
  //    if (not Form_Main.RadioButton_QH.Checked)  then Exit;
      if (FServerType <> 0) and  (( (FServerType mod 1000) div 100 <> 1 )) then Exit;
      //判断数据是否丢失，若丢失就全部遗弃
      if (TempLen - (SizeOf(TFyServerPackage) + SizeOf(TRealDataV3) - SizeOf(TShortRealV3))) mod SizeOf(TShortRealV3) <> 0 then
      begin
        WriteRunLog('UDPDataInput','数据丢失，来至：' + IP  + ' from:Main.pas');
        exit;
      end;

      Inc(pBuf,SizeOf(TFyServerPackage));
      PHQ := PRealDataV3(pBuf);
      case PHQ.Head.iType of
        C_SendRealHq:
        begin
          if PHQ.Head.PkgType = 0 then
          begin
            Inc(pBuf,SizeOf(TRealDataV3) - SizeOf(TShortRealV3));
            for i := 0 to PHQ.Head.iLen - 1  do
            begin
              if i > 0 then
                Inc(pBuf,SizeOf(TShortRealV3));
              pCurr := PShortRealV3(pBuf);

              RecoverHMSFrom1900Sec(PHQ.Head.HQTime,Hour,Min,Sec);

              DailyHQ.CodeIndex := pCurr.CodeIndex;
              if DailyHQ.CodeIndex < 0 then
                Continue;
              if DailyHQ.CodeIndex > C_MAXCodeNum then  //收到行情合约不能大于最大代码
                Continue;
              if Form_Main.CBox_del0.Checked then    //过滤0值
                if pCurr.Value = 0 then
                  Continue;

              if Form_Main.CBox_noRev.Checked then   //收盘于开盘前5分钟不收行情
              begin
                //非交易日判断
                ZoneDateTime := CodeTablePro.GetCodeZoneDateTime(pCurr.CodeIndex);
                Week :=DayOfWeek(ZoneDateTime)-1;
                if Week=0 then Week :=7 ;
                if not ServerALLCodeTypeTable[pCurr.CodeIndex].TradeWeek[Week] then
                  Continue;
                //收盘于开盘前5分钟
                if not CodeTablePro.BeginTimeDce5EndTimeAdd5(pCurr.CodeIndex) then
                  Continue;
              end;

              //测试看看
           {   if (pCurr.HQType = C_Close_Price) and (pCurr.CodeIndex <> 662) then
              begin
                ini := TIniFile.Create(AppPath + 'ClosePrice.ini');
                try
                  ini.WriteInteger(trim(ServerALLCodeTypeTable[DailyHQ.CodeIndex].Alias2),'Market',ServerALLCodeTypeTable[pCurr.CodeIndex].Market);
                  ini.WriteInteger(trim(ServerALLCodeTypeTable[DailyHQ.CodeIndex].Alias2),'Value',pCurr.Value);
                finally
                  ini.Free;
                end;
              end;
             }

              if AutoAcceptVolList[pCurr.CodeIndex] then  //这个情况是考虑外盘成交量随最新价驱动+1
              begin
                if pCurr.HQType <> C_Accept_Vol then
                begin
                  DailyHQ.HQType := pCurr.HQType;
                  DailyHQ.Value := pCurr.Value;
                  DailyHQ.Hour := Hour;
                  DailyHQ.Min := Min;
                  DailyHQ.Sec := Sec;

                  //存储数据
                  DailyHQList :=  DataPro.DataRecordComparison(DailyHQ);


                  for k := 0 to DailyHQList.HQNum - 1 do
                  begin
                    HQStrm.AddSendHQ(DailyHQList.HQList[k]);//先加用户流

                    HQ.CodeIndex := DailyHQList.HQList[k].CodeIndex;
                    HQ.HQType := DailyHQList.HQList[k].HQType;
                    HQ.Value := DailyHQList.HQList[k].Value;
                    HQ.DateTime := Now;

                    FilePro.WiteSendHQ(HQ);
                    DataPro.RefreshPriceTab(DailyHQList.HQList[k]);
                  end;

                  if pCurr.HQType = C_Last_Price then
                  begin
                    DailyHQ.HQType := C_Accept_Vol;
                    DailyHQ.Value := HQ0_Temp[pCurr.CodeIndex].Accept_Vol + (Random(20)*2 + 2);//保证自动加的成交量是2的倍数
                    DailyHQ.Hour := Hour;
                    DailyHQ.Min := Min;
                    DailyHQ.Sec := Sec;
                                                
                    //存储数据
                    DailyHQList :=  DataPro.DataRecordComparison(DailyHQ);


                    for k := 0 to DailyHQList.HQNum - 1 do
                    begin
                      HQStrm.AddSendHQ(DailyHQList.HQList[k]);//先加用户流

                      HQ.CodeIndex := DailyHQList.HQList[k].CodeIndex;
                      HQ.HQType := DailyHQList.HQList[k].HQType;
                      HQ.Value := DailyHQList.HQList[k].Value;
                      HQ.DateTime := Now;

                      FilePro.WiteSendHQ(HQ);
                      DataPro.RefreshPriceTab(DailyHQList.HQList[k]);
                    end;
                  end;
                end;
              end
              else
              begin
                DailyHQ.HQType := pCurr.HQType;
                DailyHQ.Value := pCurr.Value;
                DailyHQ.Hour := Hour;
                DailyHQ.Min := Min;
                DailyHQ.Sec := Sec;
                //写或者处理数据

                //---写日志看看
            {    if (pCurr.CodeIndex >= 472) and (pCurr.CodeIndex <= 548) then
                begin
                  if pCurr.HQType = C_Accept_Vol then
                    writelog(IntToStr(pCurr.Value),IntToStr(pCurr.CodeIndex)+'.log');
                end;       }
                //-----------------------

                //存储数据
                DailyHQList :=  DataPro.DataRecordComparison(DailyHQ);


                for k := 0 to DailyHQList.HQNum - 1 do
                begin
                  if Form_Main.CheckBox_NoSendZZ.Checked then
                  begin
                    if not ALLCodeTable[DailyHQList.HQList[k].CodeIndex].Market = 3 then
                      HQStrm.AddSendHQ(DailyHQList.HQList[k]);//先加用户流
                  end
                  else
                    HQStrm.AddSendHQ(DailyHQList.HQList[k]);//先加用户流

                  HQ.CodeIndex := DailyHQList.HQList[k].CodeIndex;
                  HQ.HQType := DailyHQList.HQList[k].HQType;
                  HQ.Value := DailyHQList.HQList[k].Value;
                  HQ.DateTime := Now;

                  FilePro.WiteSendHQ(HQ);
                  DataPro.RefreshPriceTab(DailyHQList.HQList[k]);
                end;
              end;
            end;
          end;

          if PHQ.Head.PkgType = C_ModifyRealHq then  //所有品种通用的
          begin
            if not Form_Main.CBox_ModifyHq.Checked then
              Exit;

            Inc(pBuf,SizeOf(TRealDataV3) - SizeOf(TShortRealV3));

            for i := 0 to PHQ.Head.iLen - 1  do
            begin
              if i > 0 then
                Inc(pBuf,SizeOf(TShortRealV3));
              pCurr := PShortRealV3(pBuf);
              RecoverHMSFrom1900Sec(PHQ.Head.HQTime,Hour,Min,Sec);

              DailyHQ.CodeIndex := pCurr.CodeIndex;
              if DailyHQ.CodeIndex < 0 then
                Continue;
              if DailyHQ.CodeIndex > C_MAXCodeNum then  //收到行情合约不能大于最大代码
                Continue;

              DailyHQ.HQType := pCurr.HQType;
              DailyHQ.Value := pCurr.Value;
              DailyHQ.Hour := Hour;
              DailyHQ.Min := Min;
              DailyHQ.Sec := Sec;
              //写或者处理数据

              //存储数据
              DailyHQList :=  DataPro.DataRecordComparison(DailyHQ);


              for k := 0 to DailyHQList.HQNum - 1 do
              begin
                HQStrm.AddSendHQ(DailyHQList.HQList[k]);//先加用户流
                DataPro.RefreshPriceTab(DailyHQList.HQList[k]);
              end;


            end;
          end;
        end;
      end;
    end;

    Rev_UDPHQ_SPOT:
    begin
    //  if (not Form_Main.RadioButton_XH.Checked) then Exit;
      if (FServerType <> 2) and  (( (FServerType mod 100) div 10 <> 1 )) then Exit;
      //判断数据是否丢失，若丢失就全部遗弃
      if (TempLen - (SizeOf(TFyServerPackage) + SizeOf(TRealDataV3) - SizeOf(TShortRealV3))) mod SizeOf(TShortRealV3) <> 0 then
      begin
        WriteRunLog('UDPDataInput','数据丢失，来至：' + IP  + ' from:Main.pas');
        exit;
      end;

      Inc(pBuf,SizeOf(TFyServerPackage));
      PHQ := PRealDataV3(pBuf);
      case PHQ.Head.iType of
        C_SendRealHq:
        begin
          if PHQ.Head.PkgType = 0 then
          begin
            Inc(pBuf,SizeOf(TRealDataV3) - SizeOf(TShortRealV3));
            for i := 0 to PHQ.Head.iLen - 1  do
            begin
              if i > 0 then
                Inc(pBuf,SizeOf(TShortRealV3));
              pCurr := PShortRealV3(pBuf);

              RecoverHMSFrom1900Sec(PHQ.Head.HQTime,Hour,Min,Sec);

              DailyHQ.CodeIndex := pCurr.CodeIndex;
              if DailyHQ.CodeIndex < 0 then
                Continue;
              if DailyHQ.CodeIndex > C_MAXCodeNum then  //收到行情合约不能大于最大代码
                Continue;
              if Form_Main.CBox_del0.Checked then    //过滤0值
                if pCurr.Value = 0 then
                  Continue;

              if Form_Main.CBox_noRev.Checked then   //收盘于开盘前5分钟不收行情
              begin
                //非交易日判断
                ZoneDateTime := CodeTablePro.GetCodeZoneDateTime(pCurr.CodeIndex);
                Week :=DayOfWeek(ZoneDateTime)-1;
                if Week=0 then Week :=7 ;
                if not ServerALLCodeTypeTable[pCurr.CodeIndex].TradeWeek[Week] then
                  Continue;
                //收盘于开盘前5分钟
                if not CodeTablePro.BeginTimeDce5EndTimeAdd5(pCurr.CodeIndex) then
                  Continue;
              end;

              //测试看看
           {   if (pCurr.HQType = C_Close_Price) and (pCurr.CodeIndex <> 662) then
              begin
                ini := TIniFile.Create(AppPath + 'ClosePrice.ini');
                try
                  ini.WriteInteger(trim(ServerALLCodeTypeTable[DailyHQ.CodeIndex].Alias2),'Market',ServerALLCodeTypeTable[pCurr.CodeIndex].Market);
                  ini.WriteInteger(trim(ServerALLCodeTypeTable[DailyHQ.CodeIndex].Alias2),'Value',pCurr.Value);
                finally
                  ini.Free;
                end;
              end;
             }

              if AutoAcceptVolList[pCurr.CodeIndex] then  //这个情况是考虑外盘成交量随最新价驱动+1
              begin
                if pCurr.HQType <> C_Accept_Vol then
                begin
                  DailyHQ.HQType := pCurr.HQType;
                  DailyHQ.Value := pCurr.Value;
                  DailyHQ.Hour := Hour;
                  DailyHQ.Min := Min;
                  DailyHQ.Sec := Sec;

                  //存储数据
                  DailyHQList :=  DataPro.DataRecordComparison(DailyHQ);


                  for k := 0 to DailyHQList.HQNum - 1 do
                  begin
                    HQStrm.AddSendHQ(DailyHQList.HQList[k]);//先加用户流

                    HQ.CodeIndex := DailyHQList.HQList[k].CodeIndex;
                    HQ.HQType := DailyHQList.HQList[k].HQType;
                    HQ.Value := DailyHQList.HQList[k].Value;
                    HQ.DateTime := Now;

                    FilePro.WiteSendHQ(HQ);
                    DataPro.RefreshPriceTab(DailyHQList.HQList[k]);
                  end;

                  if pCurr.HQType = C_Last_Price then
                  begin
                    DailyHQ.HQType := C_Accept_Vol;
                    DailyHQ.Value := HQ0_Temp[pCurr.CodeIndex].Accept_Vol + (Random(20)*2 + 2);//保证自动加的成交量是2的倍数
                    DailyHQ.Hour := Hour;
                    DailyHQ.Min := Min;
                    DailyHQ.Sec := Sec;

                    //存储数据
                    DailyHQList :=  DataPro.DataRecordComparison(DailyHQ);


                    for k := 0 to DailyHQList.HQNum - 1 do
                    begin
                      HQStrm.AddSendHQ(DailyHQList.HQList[k]);//先加用户流

                      HQ.CodeIndex := DailyHQList.HQList[k].CodeIndex;
                      HQ.HQType := DailyHQList.HQList[k].HQType;
                      HQ.Value := DailyHQList.HQList[k].Value;
                      HQ.DateTime := Now;

                      FilePro.WiteSendHQ(HQ);
                      DataPro.RefreshPriceTab(DailyHQList.HQList[k]);
                    end;
                  end;
                end;
              end
              else
              begin
                DailyHQ.HQType := pCurr.HQType;
                DailyHQ.Value := pCurr.Value;
                DailyHQ.Hour := Hour;
                DailyHQ.Min := Min;
                DailyHQ.Sec := Sec;
                //写或者处理数据

                //---写日志看看
            {    if (pCurr.CodeIndex >= 472) and (pCurr.CodeIndex <= 548) then
                begin
                  if pCurr.HQType = C_Accept_Vol then
                    writelog(IntToStr(pCurr.Value),IntToStr(pCurr.CodeIndex)+'.log');
                end;       }
                //-----------------------
                                                
                //存储数据
                DailyHQList :=  DataPro.DataRecordComparison(DailyHQ);


                for k := 0 to DailyHQList.HQNum - 1 do
                begin
                  HQStrm.AddSendHQ(DailyHQList.HQList[k]);//先加用户流

                  HQ.CodeIndex := DailyHQList.HQList[k].CodeIndex;
                  HQ.HQType := DailyHQList.HQList[k].HQType;
                  HQ.Value := DailyHQList.HQList[k].Value;
                  HQ.DateTime := Now;

                  FilePro.WiteSendHQ(HQ);
                  DataPro.RefreshPriceTab(DailyHQList.HQList[k]);
                end;
              end;
            end;
          end;

          if PHQ.Head.PkgType = C_ModifyRealHq then  //所有品种通用的
          begin
            if not Form_Main.CBox_ModifyHq.Checked then
              Exit;

            Inc(pBuf,SizeOf(TRealDataV3) - SizeOf(TShortRealV3));

            for i := 0 to PHQ.Head.iLen - 1  do
            begin
              if i > 0 then
                Inc(pBuf,SizeOf(TShortRealV3));
              pCurr := PShortRealV3(pBuf);
              RecoverHMSFrom1900Sec(PHQ.Head.HQTime,Hour,Min,Sec);

              DailyHQ.CodeIndex := pCurr.CodeIndex;
              if DailyHQ.CodeIndex < 0 then
                Continue;
              if DailyHQ.CodeIndex > C_MAXCodeNum then  //收到行情合约不能大于最大代码
                Continue;

              DailyHQ.HQType := pCurr.HQType;
              DailyHQ.Value := pCurr.Value;
              DailyHQ.Hour := Hour;
              DailyHQ.Min := Min;
              DailyHQ.Sec := Sec;
              //写或者处理数据

              //存储数据
              DailyHQList :=  DataPro.DataRecordComparison(DailyHQ);


              for k := 0 to DailyHQList.HQNum - 1 do
              begin
                HQStrm.AddSendHQ(DailyHQList.HQList[k]);//先加用户流
                DataPro.RefreshPriceTab(DailyHQList.HQList[k]);
              end;


            end;
          end;
        end;
      end;
    end;

    Rev_UDPHQ_OPTION:
    begin
    //  if (not Form_Main.RadioButton_QQ.Checked) then Exit;
      if (FServerType <> 3) and ( FServerType mod 10 <> 1 ) then Exit;
      //判断数据是否丢失，若丢失就全部遗弃
      if (TempLen - (SizeOf(TFyServerPackage) + SizeOf(TRealDataV3) - SizeOf(TShortRealV3))) mod SizeOf(TShortRealV3) <> 0 then
      begin
        WriteRunLog('UDPDataInput','数据丢失，来至：' + IP  + ' from:Main.pas');
        exit;
      end;

      Inc(pBuf,SizeOf(TFyServerPackage));
      PHQ := PRealDataV3(pBuf);
      case PHQ.Head.iType of
        C_SendRealHq:
        begin
          if PHQ.Head.PkgType = 0 then
          begin
            Inc(pBuf,SizeOf(TRealDataV3) - SizeOf(TShortRealV3));
            for i := 0 to PHQ.Head.iLen - 1  do
            begin
              if i > 0 then
                Inc(pBuf,SizeOf(TShortRealV3));
              pCurr := PShortRealV3(pBuf);

              RecoverHMSFrom1900Sec(PHQ.Head.HQTime,Hour,Min,Sec);

              DailyHQ.CodeIndex := pCurr.CodeIndex;
              if DailyHQ.CodeIndex < 0 then
                Continue;
              if DailyHQ.CodeIndex > C_MAXCodeNum then  //收到行情合约不能大于最大代码
                Continue;
              if Form_Main.CBox_del0.Checked then    //过滤0值
                if pCurr.Value = 0 then
                  Continue;

              if Form_Main.CBox_noRev.Checked then   //收盘于开盘前5分钟不收行情
              begin
                //非交易日判断
                ZoneDateTime := CodeTablePro.GetCodeZoneDateTime(pCurr.CodeIndex);
                Week :=DayOfWeek(ZoneDateTime)-1;
                if Week=0 then Week :=7 ;
                if not ServerALLCodeTypeTable[pCurr.CodeIndex].TradeWeek[Week] then
                  Continue;
                //收盘于开盘前5分钟
                if not CodeTablePro.BeginTimeDce5EndTimeAdd5(pCurr.CodeIndex) then
                  Continue;
              end;


              if AutoAcceptVolList[pCurr.CodeIndex] then  //这个情况是考虑外盘成交量随最新价驱动+1
              begin
                if pCurr.HQType <> C_Accept_Vol then
                begin
                  DailyHQ.HQType := pCurr.HQType;
                  DailyHQ.Value := pCurr.Value;
                  DailyHQ.Hour := Hour;
                  DailyHQ.Min := Min;
                  DailyHQ.Sec := Sec;

                  //存储数据
                  DailyHQList :=  DataPro.DataRecordComparison(DailyHQ);


                  for k := 0 to DailyHQList.HQNum - 1 do
                  begin
                    HQStrm.AddSendHQ(DailyHQList.HQList[k]);//先加用户流

                    HQ.CodeIndex := DailyHQList.HQList[k].CodeIndex;
                    HQ.HQType := DailyHQList.HQList[k].HQType;
                    HQ.Value := DailyHQList.HQList[k].Value;
                    HQ.DateTime := Now;

                    FilePro.WiteSendHQ(HQ);
                    DataPro.RefreshPriceTab(DailyHQList.HQList[k]);
                  end;

                  if pCurr.HQType = C_Last_Price then
                  begin
                    DailyHQ.HQType := C_Accept_Vol;
                    DailyHQ.Value := HQ0_Temp[pCurr.CodeIndex].Accept_Vol + (Random(20)*2 + 2);//保证自动加的成交量是2的倍数
                    DailyHQ.Hour := Hour;
                    DailyHQ.Min := Min;
                    DailyHQ.Sec := Sec;

                    //存储数据
                    DailyHQList :=  DataPro.DataRecordComparison(DailyHQ);


                    for k := 0 to DailyHQList.HQNum - 1 do
                    begin
                      HQStrm.AddSendHQ(DailyHQList.HQList[k]);//先加用户流

                      HQ.CodeIndex := DailyHQList.HQList[k].CodeIndex;
                      HQ.HQType := DailyHQList.HQList[k].HQType;
                      HQ.Value := DailyHQList.HQList[k].Value;
                      HQ.DateTime := Now;

                      FilePro.WiteSendHQ(HQ);
                      DataPro.RefreshPriceTab(DailyHQList.HQList[k]);
                    end;
                  end;
                end;
              end
              else
              begin
                DailyHQ.HQType := pCurr.HQType;
                DailyHQ.Value := pCurr.Value;
                DailyHQ.Hour := Hour;
                DailyHQ.Min := Min;
                DailyHQ.Sec := Sec;
                //写或者处理数据


                //存储数据
                DailyHQList :=  DataPro.DataRecordComparison(DailyHQ);


                for k := 0 to DailyHQList.HQNum - 1 do
                begin
                  HQStrm.AddSendHQ(DailyHQList.HQList[k]);//先加用户流

                  HQ.CodeIndex := DailyHQList.HQList[k].CodeIndex;
                  HQ.HQType := DailyHQList.HQList[k].HQType;
                  HQ.Value := DailyHQList.HQList[k].Value;
                  HQ.DateTime := Now;

                  FilePro.WiteSendHQ(HQ);
                  DataPro.RefreshPriceTab(DailyHQList.HQList[k]);
                end;
              end;
            end;
          end;

          if PHQ.Head.PkgType = C_ModifyRealHq then  //所有品种通用的
          begin
            if not Form_Main.CBox_ModifyHq.Checked then
              Exit;

            Inc(pBuf,SizeOf(TRealDataV3) - SizeOf(TShortRealV3));

            for i := 0 to PHQ.Head.iLen - 1  do
            begin
              if i > 0 then
                Inc(pBuf,SizeOf(TShortRealV3));
              pCurr := PShortRealV3(pBuf);
              RecoverHMSFrom1900Sec(PHQ.Head.HQTime,Hour,Min,Sec);

              DailyHQ.CodeIndex := pCurr.CodeIndex;
              if DailyHQ.CodeIndex < 0 then
                Continue;
              if DailyHQ.CodeIndex > C_MAXCodeNum then  //收到行情合约不能大于最大代码
                Continue;

              DailyHQ.HQType := pCurr.HQType;
              DailyHQ.Value := pCurr.Value;
              DailyHQ.Hour := Hour;
              DailyHQ.Min := Min;
              DailyHQ.Sec := Sec;
              //写或者处理数据

              //存储数据
              DailyHQList :=  DataPro.DataRecordComparison(DailyHQ);


              for k := 0 to DailyHQList.HQNum - 1 do
              begin
                HQStrm.AddSendHQ(DailyHQList.HQList[k]);//先加用户流
                DataPro.RefreshPriceTab(DailyHQList.HQList[k]);
              end;


            end;
          end;
        end;
      end;
    end;

    {$IFDEF STOCK_NEW}
    Rev_UDPHQ_STOCK:
    begin
    //  if (not Form_Main.RadioButton_QQ.Checked) then Exit;
      if (FServerType <> 1) then Exit;
      //判断数据是否丢失，若丢失就全部遗弃
      if (TempLen - (SizeOf(TFyServerPackage) + SizeOf(TRealDataV3) - SizeOf(TShortRealV3))) mod SizeOf(TShortRealV3) <> 0 then
      begin
        WriteRunLog('UDPDataInput','数据丢失，来至：' + IP  + ' from:Main.pas');
        exit;
      end;

      Inc(pBuf,SizeOf(TFyServerPackage));
      PHQ := PRealDataV3(pBuf);
      case PHQ.Head.iType of
        C_SendRealHq:
        begin
          if PHQ.Head.PkgType = 0 then
          begin
            Inc(pBuf,SizeOf(TRealDataV3) - SizeOf(TShortRealV3));
            for i := 0 to PHQ.Head.iLen - 1  do
            begin
              if i > 0 then
                Inc(pBuf,SizeOf(TShortRealV3));
              pCurr := PShortRealV3(pBuf);

              RecoverHMSFrom1900Sec(PHQ.Head.HQTime,Hour,Min,Sec);

              DailyHQ.CodeIndex := pCurr.CodeIndex;
              if DailyHQ.CodeIndex < 0 then
                Continue;
              if DailyHQ.CodeIndex > C_MAXCodeNum then  //收到行情合约不能大于最大代码
                Continue;
              if Form_Main.CBox_del0.Checked then    //过滤0值
                if pCurr.Value = 0 then
                  Continue;

              if Form_Main.CBox_noRev.Checked then   //收盘于开盘前5分钟不收行情
              begin
                //非交易日判断
                ZoneDateTime := CodeTablePro.GetCodeZoneDateTime(pCurr.CodeIndex);
                Week :=DayOfWeek(ZoneDateTime)-1;
                if Week=0 then Week :=7 ;
                if not ServerALLCodeTypeTable[pCurr.CodeIndex].TradeWeek[Week] then
                  Continue;
                //收盘于开盘前5分钟
                if not CodeTablePro.BeginTimeDce5EndTimeAdd5(pCurr.CodeIndex) then
                  Continue;
              end;


              if AutoAcceptVolList[pCurr.CodeIndex] then  //这个情况是考虑外盘成交量随最新价驱动+1
              begin
                if pCurr.HQType <> C_Accept_Vol then
                begin
                  DailyHQ.HQType := pCurr.HQType;
                  DailyHQ.Value := pCurr.Value;
                  DailyHQ.Hour := Hour;
                  DailyHQ.Min := Min;
                  DailyHQ.Sec := Sec;

                  //存储数据
                  DailyHQList :=  DataPro.DataRecordComparison(DailyHQ);


                  for k := 0 to DailyHQList.HQNum - 1 do
                  begin
                    HQStrm.AddSendHQ(DailyHQList.HQList[k]);//先加用户流

                    HQ.CodeIndex := DailyHQList.HQList[k].CodeIndex;
                    HQ.HQType := DailyHQList.HQList[k].HQType;
                    HQ.Value := DailyHQList.HQList[k].Value;
                    HQ.DateTime := Now;

                    FilePro.WiteSendHQ(HQ);
                    DataPro.RefreshPriceTab(DailyHQList.HQList[k]);
                  end;

                  if pCurr.HQType = C_Last_Price then
                  begin
                    DailyHQ.HQType := C_Accept_Vol;
                    DailyHQ.Value := HQ0_Temp[pCurr.CodeIndex].Accept_Vol + (Random(20)*2 + 2);//保证自动加的成交量是2的倍数
                    DailyHQ.Hour := Hour;
                    DailyHQ.Min := Min;
                    DailyHQ.Sec := Sec;

                    //存储数据
                    DailyHQList :=  DataPro.DataRecordComparison(DailyHQ);


                    for k := 0 to DailyHQList.HQNum - 1 do
                    begin
                      HQStrm.AddSendHQ(DailyHQList.HQList[k]);//先加用户流

                      HQ.CodeIndex := DailyHQList.HQList[k].CodeIndex;
                      HQ.HQType := DailyHQList.HQList[k].HQType;
                      HQ.Value := DailyHQList.HQList[k].Value;
                      HQ.DateTime := Now;

                      FilePro.WiteSendHQ(HQ);
                      DataPro.RefreshPriceTab(DailyHQList.HQList[k]);
                    end;
                  end;
                end;
              end
              else
              begin
                DailyHQ.HQType := pCurr.HQType;
                DailyHQ.Value := pCurr.Value;
                DailyHQ.Hour := Hour;
                DailyHQ.Min := Min;
                DailyHQ.Sec := Sec;
                //写或者处理数据


                //存储数据
                DailyHQList :=  DataPro.DataRecordComparison(DailyHQ);


                for k := 0 to DailyHQList.HQNum - 1 do
                begin
                  HQStrm.AddSendHQ(DailyHQList.HQList[k]);//先加用户流

                  HQ.CodeIndex := DailyHQList.HQList[k].CodeIndex;
                  HQ.HQType := DailyHQList.HQList[k].HQType;
                  HQ.Value := DailyHQList.HQList[k].Value;
                  HQ.DateTime := Now;

                  FilePro.WiteSendHQ(HQ);
                  DataPro.RefreshPriceTab(DailyHQList.HQList[k]);
                end;
              end;
            end;
          end;

          if PHQ.Head.PkgType = C_ModifyRealHq then  //所有品种通用的
          begin
            if not Form_Main.CBox_ModifyHq.Checked then
              Exit;

            Inc(pBuf,SizeOf(TRealDataV3) - SizeOf(TShortRealV3));

            for i := 0 to PHQ.Head.iLen - 1  do
            begin
              if i > 0 then
                Inc(pBuf,SizeOf(TShortRealV3));
              pCurr := PShortRealV3(pBuf);
              RecoverHMSFrom1900Sec(PHQ.Head.HQTime,Hour,Min,Sec);

              DailyHQ.CodeIndex := pCurr.CodeIndex;
              if DailyHQ.CodeIndex < 0 then
                Continue;
              if DailyHQ.CodeIndex > C_MAXCodeNum then  //收到行情合约不能大于最大代码
                Continue;

              DailyHQ.HQType := pCurr.HQType;
              DailyHQ.Value := pCurr.Value;
              DailyHQ.Hour := Hour;
              DailyHQ.Min := Min;
              DailyHQ.Sec := Sec;
              //写或者处理数据

              //存储数据
              DailyHQList :=  DataPro.DataRecordComparison(DailyHQ);


              for k := 0 to DailyHQList.HQNum - 1 do
              begin
                HQStrm.AddSendHQ(DailyHQList.HQList[k]);//先加用户流
                DataPro.RefreshPriceTab(DailyHQList.HQList[k]);
              end;


            end;
          end;
        end;
      end;
    end;
    {$ENDIF}

    {$IFNDEF STOCK_NEW}
    Rev_UDPHQ_STOCK:
    begin
    //  if not Form_Main.RadioButton_GP.Checked then Exit;
      if FServerType <> 1 then Exit;
      DailyHQList2 := StockHQPro.PocessStockHQ(TempBuf,TempLen);
      for i := 0 to DailyHQList2.HQNum - 1 do
      begin
        if Form_Main.CBox_del0.Checked then    //过滤0值
          if DailyHQList2.HQList[i].Value = 0 then
            Continue;

        if Form_Main.CBox_noRev.Checked then   //收盘于开盘前5分钟不收行情
        begin
          //非交易日判断
          ZoneDateTime := CodeTablePro.GetCodeZoneDateTime(DailyHQList2.HQList[i].CodeIndex);
          Week :=DayOfWeek(ZoneDateTime)-1;
          if Week=0 then Week :=7 ;
          if not ServerALLCodeTypeTable[DailyHQList2.HQList[i].CodeIndex].TradeWeek[Week] then
            Continue;
          //收盘于开盘前5分钟
          if not CodeTablePro.BeginTimeDce5EndTimeAdd5(DailyHQList2.HQList[i].CodeIndex) then
            Continue;
        end;
    {
        if DailyHQList2.HQList[i].HQType = C_Accept_Vol then
          WriteRunLog('C_Accept_Vol', FormatDateTime('',Now) + '   索引：' + IntToStr(DailyHQList2.HQList[i].CodeIndex) + ' 值：' +
                      IntToStr(DailyHQList2.HQList[i].Value));
     }
        //存储数据
        DataPro.DataRecord(DailyHQList2.HQList[i]);
      end;
    end;
    {$ENDIF}

    Rev_UDP_UPDATEONECODE:  //更新单个代码
    begin
      Inc(pBuf,SizeOf(TFyServerPackage));
      try
        FbIsUpdate := True;
        CodeTablePro.UpdateOneCode(pBuf,len-Sizeof(TFyServerPackage));
      finally
        FbIsUpdate := False;
      end;
    end;

    Rev_UDP_UPDATEONECODE_OPTION:  //更新单个代码 期权专用
    begin
      Inc(pBuf,SizeOf(TFyServerPackage));
      try
        FbIsUpdate := True;
        CodeTablePro.UpdateOneCode_Option(pBuf,len-Sizeof(TFyServerPackage));
      finally
        FbIsUpdate := False;
      end;
    end;

    Rev_UDP_ClearPriceTable_One://某个品种价格表清0
    begin
      Inc(pBuf,SizeOf(TFyServerPackage));
      Move(pbuf^,CodeIndex,SizeOf(word));
      FillChar(HQ0_Temp[CodeIndex],SizeOf(TCurrentHQ),0);
      FillChar(HQ0[CodeIndex],SizeOf(TCurrentHQ),0);
    end;

    Rev_UDP_UpdateKLine: //更新K线
    begin
      Inc(pBuf,SizeOf(TFyServerPackage));
      FilePro.UpdateKLine(pBuf,len-Sizeof(TFyServerPackage));
    end;

    Rev_UDP_DelKLine:  //删除k线
    begin
      Inc(pBuf,SizeOf(TFyServerPackage));
      FilePro.DelKLine(pBuf,len-Sizeof(TFyServerPackage));
    end;

    Rev_UDP_ReGCode://认证服务器发来的注册码信息
    begin
      Inc(pBuf,SizeOf(TFyServerPackage));
      //FilePro.DelKLine(pBuf,len-Sizeof(TFyServerPackage));
      tmpRegCode := PRegCode(pBuf);// + SizeOf(TFyServerPackage));
      FsRegCode := trim(tmpRegCode.RegCode);
    //  ShowMessage(tmpRegCode.RegCode);
    end;
    Rev_UDP_News:
    begin
      Inc(pBuf,SizeOf(TFyServerPackage));
      New(theNew);  //申请内存空间
      tmpPNews := PNews(pBuf);
      StrCopy(theNew.Title,tmpPNews.Title);
      StrCopy(theNew.URL,tmpPNews.URL);
      FTStrNewsList.AddObject(theNew.Title,Pointer(theNew));
      //完善操作
    //  ShowMessage(tmpPNews.URL +  '  ' + tmpPNews.Title);
    end;


  end;

end;

procedure TForm_Main.WriteUserMaxNub(iMaxUser: Integer);
var
  ini: TIniFile;
  iMax,iTmp: Integer;
begin
  ini := TIniFile.Create(AppPath + 'V30Cfg.ini');
  try
    iMax := ini.ReadInteger('server','MaxUser',0);
    iTmp := Max(iMax,iMaxUser);
    ini.WriteInteger('server','MaxUser',iTmp);
  finally
    ini.Free;
  end;
end;

procedure TForm_Main.TimingProHQTimerProcessing(Sender: TObject);
var
  i,k: Integer;
  Count: Integer;
  DailyHQList: TDailyHQList;
  HQ: TServerDailyHQ;
begin    
  Count := 700;
  if TimingProHQBegin then Exit;
  TimingProHQBegin := True;
  try
    for i := 0 to Count - 1 do
    begin
    //  if ProcCodeIndexPos > CodeMaxIndex then
      if ProcCodeIndexPos >= FTableArr[0].Count  then
        ProcCodeIndexPos := 0;
      DailyHQList :=  DataPro.DataComparison(ProcCodeIndexPos);
      Inc(ProcCodeIndexPos);

      for k := 0 to DailyHQList.HQNum - 1 do
      begin
        HQ.CodeIndex := DailyHQList.HQList[k].CodeIndex;
        HQ.HQType := DailyHQList.HQList[k].HQType;
        HQ.Value := DailyHQList.HQList[k].Value;
        HQ.DateTime := Now;
     //   UserPro.AddClientHQStreamForStock(DailyHQList.HQList[k]);
        UserPro.AddClientHQStream(DailyHQList.HQList[k]);
        FilePro.WiteSendHQ(HQ);
        DataPro.RefreshPriceTab(DailyHQList.HQList[k]);
      end;
    end;
  finally
    TimingProHQBegin := False;
  end;
end;

procedure TForm_Main.Run;
begin
  FilePro.Run;
  MarketInput.SetInputDataPr(@UDPDataInput);
  MarketInput.Run ;
  FiRevRegCodePort := MarketInput.InputPort;
  ComparisonInput.SetInputDataPr(@UDPDataInput);
  DataTCPInput.Start;

  // 2015/4/13 13:00:17 用新接口代替有异常的 indy,接口尽量相同
  //IdTCPServer1.DefaultPort := FiShortTcpPort;
  //IdTCPServer1.Active := True;

  if ShortTcpServer=nil then
  begin
    ShortTcpServer := TNBServer.Create(Self);
    ShortTcpServer.port := FiShortTcpPort;
    ShortTcpServer.OnExecute := self.OnShortTcpServerExecute;

    if ShortTcpServer.Active = False then
    begin
      ShowMessage('端口被占用');
      Exit;
    end;

  end;

end;

procedure TForm_Main.Stop;
begin
  MarketInput.Stop ;
  FilePro.Stop;
  ComparisonInput.Stop;
  DataTCPInput.Stop;
  IdTCPServer1.Active := False;
end;


procedure TForm_Main.Button_RunClick(Sender: TObject);
var
  ini: TIniFile;
begin
  Run ;
  CheckRun:=True;
  Button_Run.Enabled := False;
  Button_Stop.Enabled := True;
  Label1.Caption := '运行中...' + FormatDateTime('',Now);
  FbRunning := True;
  SpinEdit_intHq.Enabled := False;
  ini := TIniFile.Create(AppPath + 'V30Cfg.ini');
  try
    FbCompressHQ := CBox_Yhq.Checked;
    FiSendHqTimerInterval := SpinEdit_intHq.Value;
    ini.WriteString('HQ','Interval',IntToStr(FiSendHqTimerInterval));
  finally
    ini.Free;
  end;

//  if RadioButton_QH.Checked or RadioButton_XH.Checked or RadioButton_QQ.Checked then
  if (FServerType = 0) or ( (FServerType mod 1000) div 100 = 1 ) then
  begin
    HQStrm.SetFlagHQ(0);
    FilePro.SetStockDataTimer(False);
    TimingProHQTimer.Enabled := False;
  end
  else
//    if RadioButton_GP.Checked then
    begin
      {$IFNDEF STOCK_NEW}
      HQStrm.SetFlagHQ(1);
      FilePro.SetStockDataTimer(True);
      TimingProHQTimer.Enabled := True;
      {$ELSE}
      HQStrm.SetFlagHQ(0);
      FilePro.SetStockDataTimer(False);
      TimingProHQTimer.Enabled := False;
      {$ENDIF}
    end;
  DataPro.ClearTradeTimer.Enabled := True;
  WriteRunLog('Run','开启服务器  from:Main.pas');
end;


procedure TForm_Main.Button_StopClick(Sender: TObject);
begin
  Stop ;
  CheckRun:=False;
  Button_Run.Enabled := True;
  Button_Stop.Enabled := False;
  Label1.Caption := '休息中...';
  FbRunning := False;
  SpinEdit_intHq.Enabled := True;

  HQStrm.SetFlagHQ(0,True);
  FilePro.SetStockDataTimer(False);
  TimingProHQTimer.Enabled := False;
  DataPro.ClearTradeTimer.Enabled := False;
  WriteRunLog('Run','关闭服务器  from:Main.pas');
end;

type
  pActiveCode= ^TActiveCode;
  TActiveCode= record
    codeIndex:Word;
    SenderCount:Integer;     //看实时行情的对象引用计数
  end;

procedure TForm_Main.btn3Click(Sender: TObject);
var
  FLocalZone: ShortInt;
  zonename: string;
begin

  CodeTablePro.SelfUpdateMarInfo;
  CodeTablePro.SelfUpdateCodeTable(Update_FUTURESTABLE);
//  ShowMessage(IntToStr(SizeOf(TCurrentHQ)));
//  GetTimeZone(FLocalZone,zonename);
//  ShowMessage(IntToStr(FLocalZone)+ '  ' + zonename);
end;

procedure TForm_Main.FormCreate(Sender: TObject);
var
  IDSOCKETHANDLE:TIdSocketHandle;
begin
//  Button_Run.Click;
  TimingProHQTimer := TTimer.Create(nil) ;
  TimingProHQTimer.OnTimer := TimingProHQTimerProcessing;
  TimingProHQTimer.Interval := 100;
  TimingProHQTimer.Enabled := False;
  TimingProHQBegin := False;
  ProcCodeIndexPos := 0;
  LoadConfig;

  if strtoint(formatDatetime('yyyymmdd',date)) > C_LimitTime then
  begin
     application.MessageBox('软件使用期限已到','通知') ;
     Button_Run.Enabled := False;
     Button_Stop.Enabled := False;
     Panel4.Visible := True;
  //   application.Terminate ;
  end;

  CheckBox_NoSendZZ.Visible := FbVisible_ZZ;

                            
  Memo_PCNum.Tag := GetUnEncryptNo;
  Memo_PCNum.Text := inttostr(GetUnEncryptNo) ;
  Label_EndDate.Caption := inttostr(C_LimitTime);

  GetRunTime;
  FiShortTcpCount := 0;

  if EXEBindIP <> '' then
  begin                 
    IDSOCKETHANDLE := IdTCPServer1.Bindings.Add;
    IDSOCKETHANDLE.IP := EXEBindIP ;
    IDSOCKETHANDLE.Port := IdTCPServer1.DefaultPort ;
    IdTCPServer1.MaxConnections := FiMaxCons;
  end;
end;

procedure TForm_Main.GetRunTime;
var
   TCPClient_GetTime:TIdTCPClient ;
   ini:Tinifile;
   URL,IP,SelfIP,GSCAP,GetIP,CodeType,ReadStr,TempPCNum,TempDate,EndDateStr:STRING;
   port: Integer;
begin
   if not fileExists(apppath+'UrlCap.ini') then
   begin
     ini:=Tinifile.Create(apppath+'UrlCap.ini');
     try
        ini.WriteString('GetTime','URL','fyguilin.fuyoo.net');
        ini.WriteString('GetTime','IP','222.73.7.3');
        ini.WriteString('GetTime','Company_Name','X');
        ini.WriteInteger('GetTime','Port',7770);
     finally
        ini.Free ;
     end;
   end;
   ini:=Tinifile.Create(apppath+'UrlCap.ini');
   try
      SelfIP := trim(ini.ReadString('GetTime','SelfIP',''));
      URL:= trim(ini.ReadString('GetTime','URL','fyguilin.fuyoo.net'));
      IP := trim(ini.ReadString('GetTime','IP','222.73.7.3'));
      port := ini.ReadInteger('GetTime','Port',7770);
      GSCAP := trim(ini.ReadString('GetTime','Company_Name',''));
      if GSCAP<>'' then Company_Name :=GSCAP;
   finally
      ini.Free ;
   end;

   if URL<>'' then
   begin
      GetIP :='';
      if HostToIP(URL,GetIP) then
      begin
         if pos('.',GetIP)<2 then GetIP := IP;
      end
      else
      GetIP := IP;
   end;
   if SelfIP<>'' then GetIP := SelfIP;
//   Button_WWWGetRunTime.Hint :=GetIP ;
   if pos('.',GetIP)<2 then exit;
   if Company_Name='' then Company_Name := 'X';
   CodeType :='普通' ;
{   if RadioGroup_UDP_Input.ItemIndex =0 then
      CodeType :='普通'
   else
   if RadioGroup_UDP_Input.ItemIndex =1 then
      CodeType :='特殊'
   else
      CodeType :='错误';
}
   try
   TCPClient_GetTime:=TIdTCPClient.Create(nil) ;
   except
      exit;
   end;
   try
      TCPClient_GetTime.ReadTimeout := 5000;
      TCPClient_GetTime.Host := GetIP;//'127.0.0.1' qzb;
      TCPClient_GetTime.Port := port;
      try
         TCPClient_GetTime.Connect(5000);
      except
         exit;
      end;
      try
         TCPClient_GetTime.WriteLn('GetServerRunTimeInfo|'+
                                   Company_Name+'|'+
                                   CodeType+'|'+
                                   IntToStr(MarketInput.InputPort)+'|'+
                                   inttostr(GetUnEncryptNo)+'|'+
                                   inttostr(C_LimitTime)+'|');
      except
         exit;
      end;
      try
         ReadStr :='';
         try
            ReadStr :=trim(TCPClient_GetTime.ReadLn);
         except
            ReadStr:='';
         end;
         if ReadStr='' then exit;
         if ReadStr='-1' then exit;
         EndDateStr := ReadStr;
         ReadStr := DeCrypt(SZDecodeBase64(ReadStr),'fuyoo');
         if length(ReadStr)>8 then
         begin
            TempPCNum :=copy(ReadStr,9,length(ReadStr));
            if TempPCNum=inttostr(GetUnEncryptNo) then
            begin
               TempDate := copy(ReadStr,1,8);
               if strtointdef(TempDate,-1)<>-1 then
               //if strtointdef(TempDate,-1)>C_LimitTime then//只能加有效期不能减
            //   if strtointdef(TempDate,-1)>STRTOINT(formatdatetime('YYYYMMDD',Date+30)) then//可以到当前时间后一月
               begin
                  C_LimitTime := strtointdef(TempDate,-1);
                  Label_EndDate.Caption := inttostr(C_LimitTime);
                  ini := TInifile.Create (AppPath + 'V30Cfg.ini') ;
                  try
                     ini.WriteString('Config','EndDateStr',EndDateStr);
                  finally
                     ini.free ;
                  end;
               end;
            end;
         end;
      except
         exit;
      end;

   finally
      if TCPClient_GetTime<>nil then
      begin
         if TCPClient_GetTime.Connected then TCPClient_GetTime.Disconnect ;
         TCPClient_GetTime.Free ;
      end;
   end;
end;

procedure TForm_Main.LoadConfig;
var
  ini: TIniFile;
  EndDateStr,TempDate,TempPCNum:string;
  i: Integer;
begin
  ini := TIniFile.Create(AppPath + 'V30Cfg.ini');
  try
    TCPLogCap := ini.ReadBool('server','TCPLogCap_Len',False);
    CheckBox_TCPLENLOG.Checked :=TCPLogCap;

    Self.Caption := ini.ReadString('server','Caption','富远3.0行情服务器'+'20150401-18:21[同步版]');

    FbSaveClearTime := ini.ReadBool('server','SaveClearTimeLog',False);
    CheckBox_Clear.Checked := FbSaveClearTime;
    FbWriteHisReqLog := ini.ReadBool('server','WriteHisReqLog',False);
    CheckBox_Hisreq.Checked := FbWriteHisReqLog;
    CBox_del0.Checked := ini.ReadBool('server','Del_0_Value',False);
    CBox_noRev.Checked := ini.ReadBool('server','noRev',False);

    FbClearNoVol := ini.ReadBool('server','ClearNoVol',False);
    CheckBox_ClearNoVol.Checked := FbClearNoVol;


    FiFlagAccept_Vol := ini.ReadInteger('server','Flag_Accept_Vol',0);
    if FiFlagAccept_Vol = 0 then
      RadioButton_BuDeng.Checked := True
    else
      RadioButton_DaYu.Checked := True;

    FsSelfUpdateHost := ini.ReadString('SelfUpdateCode','ReqHost','127.0.0.1');
    FiSelfUpdatePort := ini.ReadInteger('SelfUpdateCode','ReqPort',9147);
    FiSelfUpdateTime := ini.ReadInteger('SelfUpdateCode','ReqTime',081500);
    FbSelfUpdate := ini.ReadBool('SelfUpdateCode','SelfUpdate',True);

    FbVisible_ZZ := ini.ReadBool('server','NoVisible_ZZ',False);
{
    if UpperCase('FutureTable.dat') = UpperCase(FsCodeTableFileName) then
    begin
      RadioButton_QH.Checked := True;
      Self.Caption := Self.Caption + '(' + RadioButton_QH.Caption + ')';
    end;
    if UpperCase('StockTable.dat') = UpperCase(FsCodeTableFileName) then
    begin
      RadioButton_GP.Checked := True;
      Self.Caption := Self.Caption + '(' + RadioButton_GP.Caption + ')';
    end;
    if UpperCase('SpotTable.dat') = UpperCase(FsCodeTableFileName) then
    begin
      RadioButton_XH.Checked := True;
      Self.Caption := Self.Caption + '(' + RadioButton_XH.Caption + ')';
    end;
    if UpperCase('OptionTable.dat') = UpperCase(FsCodeTableFileName) then
    begin
      RadioButton_QQ.Checked := True;
      Self.Caption := Self.Caption + '(' + RadioButton_QQ.Caption + ')';
    end;
}
    Self.Caption := Self.Caption + ' ' + FsShowHint;

    FbCompressHQ := ini.ReadBool('Compress','CompressHQ',False);
    CBox_Yhq.Checked := FbCompressHQ;
    FbCompressPriceTable := ini.ReadBool('Compress','CompressPriceTable',False);
    CBox_YpriceTable.Checked := FbCompressPriceTable;

    FiSendHqTimerInterval := StrToIntDef(ini.ReadString('HQ','Interval','15'),15);
    SpinEdit_intHq.Value := FiSendHqTimerInterval;

    FbComparisonHq := ini.ReadBool('server','ComparisonHq',False);
    CBox_Comp.Checked := FbComparisonHq;

    FiShortTcpPort := ini.ReadInteger('server','ShortTCPListenPort',30136);
    FiMaxCons := ini.ReadInteger('server','ShortTCPMaxCons',90);
    EXEBindIP := ini.ReadString('server','EXEBindIP','');

    FbDelNoName := ini.ReadBool('server','Del_DelNoName',False);
    CheckBox_DelNoName.Checked := FbDelNoName;

    FbClearAcceptMoney := ini.ReadBool('ClearSet','clearAcceptMoney',False);
    CheckBox_CMoney.Checked := FbClearAcceptMoney;
    FbNoSetForeClosePrice := ini.ReadBool('ClearSet','noSetForeClosePrice',False);
    CheckBox_NoForePrice.Checked := FbNoSetForeClosePrice;

    CBox_AutoStart.Checked := ini.ReadBool('server','AutoStart',False);   //这个应该放在后面
    if CBox_AutoStart.Checked then
      Button_Run.Click;

    Panel4.Visible := False;  
    EndDateStr := ini.ReadString('Config','EndDateStr','');
    if EndDateStr<>'' then
    begin
      EndDateStr := DeCrypt(SZDecodeBase64(EndDateStr),'fuyoo');
      if length(EndDateStr)>8 then
      begin
         TempPCNum :=copy(EndDateStr,9,length(EndDateStr));
         if TempPCNum=inttostr(GetUnEncryptNo) then
         begin
            TempDate := copy(EndDateStr,1,8);
            if strtointdef(TempDate,-1)<>-1 then
            C_LimitTime := strtointdef(TempDate,-1);
         end
         else
           Panel4.Visible := True;
        //    Label_PCNumNOT.Visible := true;
      end;
    end;
  finally
    ini.Free;
  end;

  ini := TIniFile.Create(AppPath + 'ValidUserType.ini');
  try
    for i := Low(UserTypeList) to High(UserTypeList) do
    begin
      UserTypeList[i] := ini.ReadBool('UserType',IntToStr(i),True);
    end;
  finally
    ini.Free;
  end;
end;

procedure TForm_Main.Button1Click(Sender: TObject);
begin
  Form_Price.IniForm;
  Form_Price.Show;
end;

procedure TForm_Main.CheckBox_ClearClick(Sender: TObject);
var
  ini: TIniFile;
begin
  ini := TIniFile.Create(AppPath + 'V30Cfg.ini');
  try
    FbSaveClearTime := CheckBox_Clear.Checked;
    ini.WriteBool('server','SaveClearTimeLog',FbSaveClearTime);
  finally
    ini.Free;
  end;
end;

procedure TForm_Main.Button2Click(Sender: TObject);
begin
  Form_AutoAcceptVol.AddMarkets;
  Form_AutoAcceptVol.Show;
end;

procedure TForm_Main.CheckBox_HisreqClick(Sender: TObject);
var
  ini: TIniFile;
begin
  ini := TIniFile.Create(AppPath + 'V30Cfg.ini');
  try
    FbWriteHisReqLog := CheckBox_Hisreq.Checked;
    ini.WriteBool('server','WriteHisReqLog',FbWriteHisReqLog);
  finally
    ini.Free;
  end;
end;

procedure TForm_Main.CBox_del0Click(Sender: TObject);
var
  ini: TIniFile;
begin
  ini := TIniFile.Create(AppPath + 'V30Cfg.ini');
  try
    ini.WriteBool('server','Del_0_Value',CBox_del0.Checked);
  finally
    ini.Free;
  end;
end;

procedure TForm_Main.CBox_noRevClick(Sender: TObject);
var
  ini: TIniFile;
begin
  ini := TIniFile.Create(AppPath + 'V30Cfg.ini');
  try
    ini.WriteBool('server','noRev',CBox_noRev.Checked);
  finally
    ini.Free;
  end;
end;

procedure TForm_Main.Timer1Timer(Sender: TObject);
var
  i,count: Integer;
begin     //Exit; // 2015/4/3 17:14:55 这样异常
  StatusBar1.Panels[0].Text := '数据包：' + IntToStr(FiRevDataCout);
  StatusBar1.Panels[1].Text := '最大允许：' + IntToStr(FMaxConnNum);

  count := 0;
  for i := Low(UserInfo) to FMaxConnNum do
  begin
    if UserInfo[i].Connected then
      Inc(count);
  end;
  StatusBar1.Panels[2].Text := '在线用户：' + IntToStr(count) + '-' + IntToStr(CommWithClient.GetCurrConnNum);

  StatusBar1.Panels[4].Text := 'LOG：' +IntToStr(LogList_TCP_Len.Count);

  WriteUserMaxNub(count);

  Label5.Caption := IntToStr(FiLogonCount);
end;

procedure TForm_Main.CBox_AutoStartClick(Sender: TObject);
var
  ini: TIniFile;
begin
  ini := TIniFile.Create(AppPath + 'V30Cfg.ini');
  try
    ini.WriteBool('server','AutoStart',CBox_AutoStart.Checked);
  finally
    ini.Free;
  end;
end;

procedure TForm_Main.Button3Click(Sender: TObject);
begin
  Form_Users.N1.Click;
  Form_Users.ShowModal;
end;

procedure TForm_Main.RadioButton_BuDengClick(Sender: TObject);
var
  ini: TIniFile;
begin
  ini := TIniFile.Create(AppPath + 'V30Cfg.ini');
  try
    if RadioButton_BuDeng.Checked then
      FiFlagAccept_Vol := 0
    else
      FiFlagAccept_Vol := 1;
    ini.WriteInteger('server','Flag_Accept_Vol',FiFlagAccept_Vol);
  finally
    ini.Free;
  end;
end;

procedure TForm_Main.RadioButton_DaYuClick(Sender: TObject);
var
  ini: TIniFile;
begin
  ini := TIniFile.Create(AppPath + 'V30Cfg.ini');
  try
    if RadioButton_DaYu.Checked then
      FiFlagAccept_Vol := 1
    else
      FiFlagAccept_Vol := 0;
    ini.WriteInteger('server','Flag_Accept_Vol',FiFlagAccept_Vol);
  finally
    ini.Free;
  end;
end;

procedure TForm_Main.CBox_YhqClick(Sender: TObject);
var
  ini: TIniFile;
begin
  ini := TIniFile.Create(AppPath + 'V30Cfg.ini');
  try
    FbCompressHQ := CBox_Yhq.Checked;
    ini.WriteBool('Compress','CompressHQ',FbCompressHQ);
  finally
    ini.Free;
  end;
end;

procedure TForm_Main.CBox_YpriceTableClick(Sender: TObject);
var
  ini: TIniFile;
begin
  ini := TIniFile.Create(AppPath + 'V30Cfg.ini');
  try
    FbCompressPriceTable := CBox_YpriceTable.Checked;
    ini.WriteBool('Compress','CompressPriceTable',FbCompressPriceTable);
  finally
    ini.Free;
  end;
end;

procedure TForm_Main.CBox_ModifyHqClick(Sender: TObject);
begin
  if CBox_ModifyHq.Checked then
  begin
    WriteRunLog('UDPDataInput','开启休盘期间接收行情'   + ' from:Main.pas');
    exit;
  end;

  if not CBox_ModifyHq.Checked then
  begin
    WriteRunLog('UDPDataInput','关闭休盘期间接收行情'   + ' from:Main.pas');
    exit;
  end;
end;

procedure TForm_Main.CBox_CompClick(Sender: TObject);
begin
  if CBox_Comp.Checked then
  begin
    ComparisonInput.SetInputDataPr(@UDPDataInput);
    ComparisonInput.Run ;
  end;
end;

procedure TForm_Main.CheckBox_DelNoNameClick(Sender: TObject);
var
  ini: TIniFile;
begin
  ini := TIniFile.Create(AppPath + 'V30Cfg.ini');
  try
    ini.WriteBool('server','Del_DelNoName',CheckBox_DelNoName.Checked);
  finally
    ini.Free;
  end;
  FbDelNoName := CheckBox_DelNoName.Checked;
end;

procedure TForm_Main.CheckBox_CMoneyClick(Sender: TObject);
var
  ini: TIniFile;
begin
  ini := TIniFile.Create(AppPath + 'V30Cfg.ini');
  try
    FbClearAcceptMoney := CheckBox_CMoney.Checked;
    ini.WriteBool('ClearSet','clearAcceptMoney',FbClearAcceptMoney);
  finally
    ini.Free;
  end;
end;

procedure TForm_Main.CheckBox_NoForePriceClick(Sender: TObject);
var
  ini: TIniFile;
begin
  ini := TIniFile.Create(AppPath + 'V30Cfg.ini');
  try
    FbNoSetForeClosePrice := CheckBox_NoForePrice.Checked;
    ini.WriteBool('ClearSet','noSetForeClosePrice',FbNoSetForeClosePrice);
  finally
    ini.Free;
  end;
end;

procedure TForm_Main.Button_SaveNewEndDateClick(Sender: TObject);
var
  inifile:TInifile ;
  iTem:integer;
  EndDateStr,TempPCNum,TempDate:string;
begin
   EndDateStr := Edit_EndDate_Pass.Text ;
   if EndDateStr='' then
   begin
      Application.MessageBox('请获取正确的授权码后再确认','错误');
      exit;
   end;                  
   EndDateStr := DeCrypt(SZDecodeBase64(EndDateStr),'fuyoo');
   if length(EndDateStr)<9 then
   begin
      Application.MessageBox('请获取正确的授权码后再确认','错误');
      exit;
   end;
   TempPCNum :=copy(EndDateStr,9,length(EndDateStr));
   if TempPCNum<>inttostr(GetUnEncryptNo) then
   begin
      Application.MessageBox('机器码不匹配，请获取正确的授权码后再确认','错误');
      exit;
   end;

   TempDate := copy(EndDateStr,1,8);
   if strtointdef(TempDate,-1)=-1 then
   begin
      Application.MessageBox('授权日期不正确，请获取正确的授权码后再确认','错误');
      exit;
   end;

   C_LimitTime := strtointdef(TempDate,-1);
   Label_EndDate.Caption := TempDate ;
   Label_PCNumNOT.Visible := false;

   if C_LimitTime < StrToInt(FormatDateTime('yyyymmdd',Now)) then
   begin
     Button_Run.Enabled := False;
     Button_Stop.Enabled := False;
   end
   else
   begin
     if (not Button_Run.Enabled) and (not Button_Stop.Enabled) then
     begin
       Button_Run.Enabled := True;
       Button_Stop.Enabled := False;
     end;
   end;

   inifile := TInifile.Create (AppPath + 'V30Cfg.ini') ;
   try                                         //SZEncodeBase64(GsPassword))
      inifile.WriteString('Config','EndDateStr',Edit_EndDate_Pass.Text);
   finally
     inifile.free ;
   end;

end;

procedure TForm_Main.Timer2Timer(Sender: TObject);
begin
  if formatdatetime('hhnnss',time)= '051010' then
      GetRunTime;

  if formatdatetime('hhnnss',time)= '000010' then
    FiLogonCount := 0;
end;

procedure TForm_Main.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caNone;

  if FbRunning then
  begin
    ShowMessage('请停止服务在关闭！');
    Exit;
  end;

  if MessageDlg('确认要退出系统么？',mtConfirmation,[MBYES,MBNO],0) <> idyes then
  begin
    Exit;
  end;


  Action := caFree;
end;

procedure TForm_Main.CheckBox_ClearNoVolClick(Sender: TObject);
var
  ini: TIniFile;
begin
  ini := TIniFile.Create(AppPath + 'V30Cfg.ini');
  try
    FbClearNoVol := CheckBox_ClearNoVol.Checked;
    ini.WriteBool('server','ClearNoVol',FbClearNoVol);
  finally
    ini.Free;
  end;
end;

procedure TForm_Main.Button4Click(Sender: TObject);
var
  theNew,tmpPNews: PNews;
  tmp: TNews;
  pBuf: PChar;
  len: Integer;
begin
  if Trim(Edit_Title.Text) = '' then
  begin
    Label_hit.Caption := '标题不能为空！';
    Exit;
  end;

  if Length(Trim(Edit_Title.Text)) >  Length(tmp.Title) then
  begin
    Label_hit.Caption := '标题长度不能大于 ' + inttostr(Length(tmp.Title) div 2) + ' 个字符！';
    Exit;
  end;

  if Trim(Memo_msg.Text) = '' then
  begin
    Label_hit.Caption := '内容不能为空！';
    Exit;
  end;
  len := Length(Trim(Memo_msg.Text));
  if len >  Length(tmp.URL) then
  begin
    Label_hit.Caption := '内容长度不能大于 ' + inttostr(Length(tmp.URL) div 2) + ' 个字符！';
    Exit;
  end;

  Label_hit.Caption := '';

  New(theNew);
  StrPCopy(theNew.Title,TrimRight(Edit_Title.Text));
  StrPCopy(theNew.URL,TrimRight(Memo_msg.Text));
  FTStrNewsList.AddObject(TrimRight(theNew.Title),Pointer(theNew));
end;

// 2015/4/13 13:10:06 短连接的与接口无关的统一处理过程//indy 和酋长接口都用这个
procedure TForm_Main.DoShortTcpServerExecute(AStream: TMemoryStream; NewPkgHead: TNewPkgHead; buf: PChar);
var
  //AStream: TMemoryStream;
  //NewPkgHead: TNewPkgHead;
  iRecvLen:integer;
  //revBuf: array[0..1024 * 10] of Char;
  //buf: PChar;
  pHead:pQuoteReqHead;
  PHis: PQuoteHisV3;
  His: TQuoteHisV3;
  pFixFileReq: PQuoteFixFileReq;
  FixFileReq: TQuoteFixFileReq;
  pCTable: PCodeTableReq;
  CTable: TCodeTableReq;
  ReqPriceTable: TReqPriceTable;
  PPriceTable: PQuoteReqPriceTable;
  i: Integer;
begin

    // 2015/4/13 13:19:18 buf 这时候已经是完整的请求包,校验过程都在接口中处理了
    //--------------------------------------------------

    pHead := pQuoteReqHead(buf);

    //AStream := TMemoryStream.Create;//clq 这是请求的结果,在外部创建就行了

    //AStream_Zlib := TMemoryStream.Create;
    
      if NewPkgHead.PkgType = PkgType_RealQuote then
      begin
           //  Disconnect;
            exit;
      end;

      if NewPkgHead.PkgType = PkgType_HisQuote then
      begin
        case pHead.opCode of
          C_Req_HisData:
          begin
            PHis := PQuoteHisV3(buf);
            His.Head.opCode := PHis.Head.opCode;
            His.Head.Version := PHis.Head.Version;
            His.CodeIndex := PHis.CodeIndex;
            His.HisKind := pHis.HisKind;
            His.BeginIndex := pHis.BeginIndex;
            His.EndIndex := pHis.EndIndex;
            His.ReqDate := pHis.ReqDate;
            His.Token := pHis.Token;
            StrCopy(His.UserName,pHis.UserName);

            ProcHisReq(His,AStream);;
          //  CommWithClient.ProcessHisReq_s(His,AStream);
          end;
          C_ReqFixFile:
          begin
            pFixFileReq := PQuoteFixFileReq(buf);
            FixFileReq.Head.opCode := pFixFileReq.Head.opCode ;
            FixFileReq.Head.Version := pFixFileReq.Head.Version;
            FixFileReq.ZipKind := pFixFileReq.ZipKind;
            StrCopy(FixFileReq.FileName,pFixFileReq.FileName);

            ProcFixFileReq(FixFileReq,AStream);
          //  CommWithClient.ProcessFixFileReq_s(FixFileReq,AStream);
          end;
          C_Req_CodeTable:
          begin
            pCTable := PCodeTableReq(buf);
            CTable.Head.opCode := pCTable.Head.opCode;
            CTable.Head.Version := pCTable.Head.Version;
            CTable.ZipKind := pCTable.ZipKind;
            StrCopy(CTable.fileName,pCTable.fileName);
            CTable.Version := pCTable.Version;

            ProcCodeTableReq(CTable,AStream);
          //  CommWithClient.ProcessCodeTableReq_s(CTable,AStream);
          end;
          C_Query_Price:
          begin
            PPriceTable := PQuoteReqPriceTable(buf);
            ReqPriceTable.Head.opCode := PPriceTable.Head.opCode;
            ReqPriceTable.Head.Version := PPriceTable.Head.Version;
            if PPriceTable.CodesNum > C_MaxSetCodeNum then
              ReqPriceTable.CodesNum := C_MaxSetCodeNum
            else
              ReqPriceTable.CodesNum := PPriceTable.CodesNum;

            Inc(buf,SizeOf(TQuoteReqPriceTable) - SizeOf(word));
            for i := 0 to ReqPriceTable.CodesNum - 1 do
            begin
              ReqPriceTable.Codes[i] := Pword(buf)^;
              inc(buf,SizeOf(word));
            end;

            ProcPriceTable(ReqPriceTable,AStream);
          //  CommWithClient.ProcessPriceTable_s(ReqPriceTable,AStream);
          end;
        end;
      end;

      //--------------------------------------------------
      // 2015/4/13 13:18:33 AStream 就是最后服务器处理后的结果,交给接口发送回去

end;


procedure TForm_Main.IdTCPServer1Execute(AThread: TIdPeerThread);
var
  AStream: TMemoryStream;
  NewPkgHead: TNewPkgHead;
  iRecvLen:integer;
  revBuf: array[0..1024 * 10] of Char;
  buf: PChar;
  pHead:pQuoteReqHead;
  PHis: PQuoteHisV3;
  His: TQuoteHisV3;
  pFixFileReq: PQuoteFixFileReq;
  FixFileReq: TQuoteFixFileReq;
  pCTable: PCodeTableReq;
  CTable: TCodeTableReq;
  ReqPriceTable: TReqPriceTable;
  PPriceTable: PQuoteReqPriceTable;
  i: Integer;
begin
  AThread.Connection.ReadTimeout:=3000;
  //Inc(FiShortTcpCount);
  with AThread.Connection  do
  begin
    try
       iRecvLen :=  min(RecvBufferSize,sizeof(TNewPkgHead)) ;
    except
      // Dec(FiShortTcpCount);
       Disconnect;
       exit;
    end;
    if iRecvLen<>sizeof(TNewPkgHead) then
    begin
       //Dec(FiShortTcpCount);
       Disconnect;
       exit;
    end;

    try
      ReadBuffer(NewPkgHead,SizeOf(TNewPkgHead));
      buf := revBuf;
    except
      on E:exception do
         begin
            Disconnect;
            exit;
         end;
     // Dec(FiShortTcpCount);
     //Disconnect;
     // exit;
    end;

    try
      ReadBuffer(revBuf,NewPkgHead.DataLen);
    except
        on E:exception do
         begin
            Disconnect;
            exit;
         end;
      //Dec(FiShortTcpCount);
      //Disconnect;
     // exit;
    end;
    pHead := pQuoteReqHead(buf);

    AStream := TMemoryStream.Create;



    //AStream_Zlib := TMemoryStream.Create;
    try
      Self.DoShortTcpServerExecute(AStream, NewPkgHead, buf);//划出统一的处理过程
      {
      if NewPkgHead.PkgType = PkgType_RealQuote then
      begin
           //  Disconnect;
            exit;
      end;

      if NewPkgHead.PkgType = PkgType_HisQuote then
      begin
        case pHead.opCode of
          C_Req_HisData:
          begin
            PHis := PQuoteHisV3(buf);
            His.Head.opCode := PHis.Head.opCode;
            His.Head.Version := PHis.Head.Version;
            His.CodeIndex := PHis.CodeIndex;
            His.HisKind := pHis.HisKind;
            His.BeginIndex := pHis.BeginIndex;
            His.EndIndex := pHis.EndIndex;
            His.ReqDate := pHis.ReqDate;
            His.Token := pHis.Token;
            StrCopy(His.UserName,pHis.UserName);

            ProcHisReq(His,AStream);;
          //  CommWithClient.ProcessHisReq_s(His,AStream);
          end;
          C_ReqFixFile:
          begin
            pFixFileReq := PQuoteFixFileReq(buf);
            FixFileReq.Head.opCode := pFixFileReq.Head.opCode ;
            FixFileReq.Head.Version := pFixFileReq.Head.Version;
            FixFileReq.ZipKind := pFixFileReq.ZipKind;
            StrCopy(FixFileReq.FileName,pFixFileReq.FileName);

            ProcFixFileReq(FixFileReq,AStream);
          //  CommWithClient.ProcessFixFileReq_s(FixFileReq,AStream);
          end;
          C_Req_CodeTable:
          begin
            pCTable := PCodeTableReq(buf);
            CTable.Head.opCode := pCTable.Head.opCode;
            CTable.Head.Version := pCTable.Head.Version;
            CTable.ZipKind := pCTable.ZipKind;
            StrCopy(CTable.fileName,pCTable.fileName);
            CTable.Version := pCTable.Version;

            ProcCodeTableReq(CTable,AStream);
          //  CommWithClient.ProcessCodeTableReq_s(CTable,AStream);
          end;
          C_Query_Price:
          begin
            PPriceTable := PQuoteReqPriceTable(buf);
            ReqPriceTable.Head.opCode := PPriceTable.Head.opCode;
            ReqPriceTable.Head.Version := PPriceTable.Head.Version;
            if PPriceTable.CodesNum > C_MaxSetCodeNum then
              ReqPriceTable.CodesNum := C_MaxSetCodeNum
            else
              ReqPriceTable.CodesNum := PPriceTable.CodesNum;

            Inc(buf,SizeOf(TQuoteReqPriceTable) - SizeOf(word));
            for i := 0 to ReqPriceTable.CodesNum - 1 do
            begin
              ReqPriceTable.Codes[i] := Pword(buf)^;
              inc(buf,SizeOf(word));
            end;

            ProcPriceTable(ReqPriceTable,AStream);
          //  CommWithClient.ProcessPriceTable_s(ReqPriceTable,AStream);
          end;
        end;
      end;
      }// 2015/4/13 13:25:02 放到统一处理过程中

      if AStream.Size > 0 then
      begin
        try
          NewPkgHead.DataLen := AStream.Size;
          AStream.Position := 0;
          OpenWriteBuffer;
          WriteBuffer(NewPkgHead,SizeOf(TNewPkgHead));
          WriteStream(AStream);
          CloseWriteBuffer;
        except
          on E:exception do
          begin
            exit;
          end;
        end;
      end;
    finally
      AStream.Free;
      //AStream_Zlib.Free;
      //Dec(FiShortTcpCount);
      Disconnect;
    end;
  end;
end;

procedure TForm_Main.OnShortTcpServerExecute(Socket:TSocket; ConnectID:Integer);
var
  AStream: TMemoryStream;
  NewPkgHead: TNewPkgHead;
  iRecvLen:integer;
  revBuf: array[0..1024 * 10] of Char;
  buf: PChar;
  pHead:pQuoteReqHead;
  PHis: PQuoteHisV3;
  His: TQuoteHisV3;
  pFixFileReq: PQuoteFixFileReq;
  FixFileReq: TQuoteFixFileReq;
  pCTable: PCodeTableReq;
  CTable: TCodeTableReq;
  ReqPriceTable: TReqPriceTable;
  PPriceTable: PQuoteReqPriceTable;
  i: Integer;
begin
  //shutdown(Socket, 0); //0
  //closesocket(Socket); //新接口和 iocp 不一样,尽量不要调用原始 socket 关闭,因为没法检测到关闭信号
  //ShortTcpServer.ShutDownConnect(Socket, ConnectID);

    try
       iRecvLen :=  min(ShortTcpServer.RecvBufferSize(Socket, ConnectID), sizeof(TNewPkgHead)) ;
    except
       //Disconnect;//新接口会超时关闭
       exit;
    end;

    if iRecvLen<>sizeof(TNewPkgHead) then
    begin
       //Dec(FiShortTcpCount);
       //Disconnect;//新接口会超时关闭
       exit;
    end;

    try
      ShortTcpServer.ReadBuffer(NewPkgHead,SizeOf(TNewPkgHead), Socket, ConnectID);
      buf := revBuf;
    except
      on E:exception do
         begin
            //Disconnect;//新接口会超时关闭
            exit;
         end;
     // Dec(FiShortTcpCount);
     //Disconnect;
     // exit;
    end;

    //包长度至少为包头加包体的大小
    if ShortTcpServer.RecvBufferSize(Socket, ConnectID) < (sizeof(TNewPkgHead) + NewPkgHead.DataLen) then Exit;//新接口不能保证一定要完整包,所以要判断是否读取完了

    try
      ShortTcpServer.ReadBuffer(revBuf,NewPkgHead.DataLen, Socket, ConnectID);
    except
        on E:exception do
         begin
            //Disconnect;//新接口会超时关闭
            exit;
         end;
      //Dec(FiShortTcpCount);
      //Disconnect;
     // exit;
    end;
    pHead := pQuoteReqHead(buf);

    AStream := TMemoryStream.Create;

    try
      Self.DoShortTcpServerExecute(AStream, NewPkgHead, buf);//划出统一的处理过程
      {
      if NewPkgHead.PkgType = PkgType_RealQuote then
      ...
      }// 2015/4/13 13:25:02 放到统一处理过程中

      if AStream.Size > 0 then
      begin
        try
          NewPkgHead.DataLen := AStream.Size;
          AStream.Position := 0;
          //OpenWriteBuffer;
          ShortTcpServer.SendBuffer(NewPkgHead,SizeOf(TNewPkgHead), Socket, ConnectID);
          ShortTcpServer.SendStream(AStream, Socket, ConnectID);
          //CloseWriteBuffer;
        except
          on E:exception do
          begin
            exit;
          end;
        end;
      end;
    finally
      AStream.Free;
      //AStream_Zlib.Free;
      //Dec(FiShortTcpCount);
      //Disconnect;//新接口会超时关闭

      ShortTcpServer.ClearReadData(Socket, ConnectID); //读取到完整包后应当清除读取的数据,否则下次又读取到旧数据了//这里不用也可以,因为后面马上关闭了
      //shutdown(Socket, 0); //0 不能再读，1不能再写，2 读写都不能
      //ShortTcpServer.CloseConnect(Socket, ConnectID);
      ShortTcpServer.ShutDownConnect(Socket, ConnectID);//按原意,短连接发送完数据后就关闭了

    end;



end;

procedure TForm_Main.Timer3Timer(Sender: TObject);
var
   list:tlist;
begin
  if IdTCPServer1=nil then exit;
  if not IdTCPServer1.Active then exit;

  List := IdTCPServer1.Threads.LockList;
try

  StatusBar1.Panels[3].Text := '短连接：' +  IntToStr(List.Count);
  {
    for Count := 0 to List.Count -1 do
    try
      TIdPeerThread(List.Items[Count]).Connection.WriteLn(Msg);
    except
      TIdPeerThread(List.Items[Count]).Stop;
    end;
    }
finally
    IdTCPServer1.Threads.UnlockList;
end;
end;

procedure TForm_Main.ApplicationEvents1Exception(Sender: TObject;
  E: Exception);
begin
  WriteRunLog('AppError',E.Message);
end;

procedure TForm_Main.Button_TcpLenShowClick(Sender: TObject);
var
  StrL:TStringList;
  ListItem:TListItem;
  iCount,ID:integer;
  userIP:STRING;
  Port:WORD;
begin
  StrL:=TStringList.Create ;
  try



  StrL.Clear ;
  ListView_LenConShow.Items.Clear ;

  INI_TCPCON_LEN.ReadSection('ConLog',StrL);
  for iCount:=0 TO StrL.Count-1 DO
  BEGIN
    ListItem :=ListView_LenConShow.Items.Add ;
    ListItem.Caption := StrL[iCount] ;
    ListItem.SubItems.Add(inttostr(INI_TCPCON_LEN.ReadInteger('ConLog',ListItem.Caption,0)) );
    ListItem.SubItems.Add(inttostr(INI_TCPCON_LEN.ReadInteger('NowTIME',ListItem.Caption,0)) );

    ListItem.SubItems.Add(inttostr(INI_UserIPCons.ReadInteger('NowCons',ListItem.Caption,0)) );

    ListItem.SubItems.Add(inttostr(INI_TCPCON_LEN.ReadInteger('ArriveLog',ListItem.Caption,0)) );

    Application.ProcessMessages ;
  END;


  finally
    StrL.Free ;
  end;
end;

procedure TForm_Main.Button_TcpLenLogCLSClick(Sender: TObject);
begin
  INI_TCPCON_LEN.Clear ;
end;

procedure TForm_Main.Button_TcpLenLogSaveClick(Sender: TObject);
begin
  INI_TCPCON_LEN.UpdateFile ;
  INI_UserIPCons.UpdateFile ;
end;

procedure TForm_Main.Timer_UserIPConsMathTimer(Sender: TObject);
var
  userIP:STRING;
  Port,ID:WORD;
begin
  if INI_UserIPCons=nil then exit;
  INI_UserIPCons.Clear ;
  for ID:=1 TO FMaxConnNum do
  begin
    if UserInfo[ID].Connected then
    begin
      CommWithClient.GetIPPort(UserInfo[ID].ConnFlag, userIP, Port);
      INI_UserIPCons.WriteInteger('NowCons',userIP,INI_UserIPCons.ReadInteger('NowCons',userIP,0)+1);
    end;
  end;

end;

procedure TForm_Main.Timer_LogTimer(Sender: TObject);
begin
  IF CommWithClient=NIL THEN EXIT;
  IF LogList_TCP_Len.Count <1 THEN EXIT ;

  CommWithClient.WriteLog;
end;

procedure TForm_Main.CheckBox_TCPLENLOGClick(Sender: TObject);
var
  ini:Tinifile;
begin
  TCPLogCap := CheckBox_TCPLENLOG.Checked ;

  ini := TIniFile.Create(AppPath + 'V30Cfg.ini');
  try
    ini.WriteBool  ('server','TCPLogCap_Len',TCPLogCap);
  finally
    ini.Free ;
  end;
end;

end.

CON
  BUFFER_2K                     = $800

  'MACRAW and PPPOE can only be used with socket 0
  #0, CLOSED, TCP, UDP, IPRAW, MACRAW, PPPOE

  UPD_HEADER_IP     = $00
  UDP_HEADER_PORT   = $04
  UDP_HEADER_LENGTH = $06
  UPD_DATA          = $08
  
  
  CR    = $0D
  LF    = $0A
  NULL  = $00 
       
VAR
  byte  _sock
  byte  _protocol
  byte  _ip[4]
  word  _port
  long bytesToRead
  long bytesToWrite

DAT


OBJ
  wiz           : "W5200"

'----------------------------------------------------
' Initialize
'----------------------------------------------------
PUB Init(socketId, protocol, portNum)

  _sock := socketId
  _protocol := protocol
  
  wiz.Init
  wiz.InitSocket(socketId, protocol, portNum)

  'return buffer

{
PUB GetIp
  return @_ip
PUB GetPort
  return _port
PUB GetbytesToRead
  return bytesToRead
PUB GetBytesToWrite
  return bytesToWrite
}
  
PUB Mac(octet5, octet4, octet3, octet2, octet1, octet0)
  wiz.Mac(octet5, octet4, octet3, octet2, octet1, octet0)

PUB Ip(octet3, octet2, octet1, octet0)
  wiz.Ip(octet3, octet2, octet1, octet0)

PUB RemoteIp(octet3, octet2, octet1, octet0)
  _ip[0] := octet3
  _ip[1] := octet2
  _ip[2] := octet1
  _ip[3] := octet0
  wiz.RemoteIp(_sock, octet3, octet2, octet1, octet0)
  
PUB RemotePort(port)
  _port := port
  wiz.RemotePort(_sock, port)

{
PUB DebugRead(register, buffer, length)
  wiz.DebugRead(_sock, register, buffer, length)
}  
'----------------------------------------------------
'
'----------------------------------------------------

PUB Open
  wiz.OpenSocket(_sock)

PUB Listen
  wiz.StartListener(_sock)

PUB Connect
  wiz.OpenRemoteSocket(_sock)

PUB Connected
  return wiz.IsEstablished(_sock)

PUB Available | i
  bytesToRead := i := 0
  repeat until bytesToRead := wiz.GetRxBytesToRead(_sock)
    if(i++ > 100)
      pause(1)
      return -1
  return bytesToRead

PUB Receive(buffer) | ptr

  ptr := buffer
  wiz.Rx(_sock, buffer, bytesToRead)
  byte[buffer][bytesToRead] := NULL
  
  if(_protocol == UDP)
    ParseHeader(buffer)
    ptr += UPD_DATA

  return ptr
      
PUB Send(buffer, len) | before, after

  before := after := 0  
  wiz.Tx(_sock, buffer, len)

  repeat until ((after - before) == len)
    before :=  wiz.GetTxReadPointer(_sock)
    wiz.FlushSocket(_sock)
    after :=  wiz.GetTxReadPointer(_sock)

  return  len


PUB Disconnect | i
  i := 0
  
  wiz.DisconnectSocket(_sock)
  repeat until wiz.IsClosed(_sock)
    if(i++ > 500)
      wiz.CloseSocket(_sock)
    

PRI ParseHeader(header)
  if(bytesToRead > 8)
    UpdHeaderIp(header)
    UdpHeaderPort(header)

PRI UpdHeaderIp(header)
  RemoteIp(byte[header][UPD_HEADER_IP], byte[header][UPD_HEADER_IP+1], byte[header][UPD_HEADER_IP+2], byte[header][UPD_HEADER_IP+3])

PRI UdpHeaderPort(header)
  RemotePort(DeserializeWord(header + UDP_HEADER_PORT))

PRI DeserializeWord(buffer) | value
  value := byte[buffer++] << 8
  value += byte[buffer]
  return value
{
PRI ClearBuffer
  bytefill(@buff, 0, BUFFER_2K)
 } 
PRI pause(Duration)  
  waitcnt(((clkfreq / 1_000 * Duration - 3932) #> 381) + cnt)
  return
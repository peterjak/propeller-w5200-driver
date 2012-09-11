'*********************************************************************************************
{
 AUTHOR: Mike Gebhard
 COPYRIGHT: Parallax Inc.
 LAST MODIFIED: 8/12/2012
 VERSION 1.0
 LICENSE: MIT (see end of file)
}
'*********************************************************************************************
CON
  'MACRAW and PPPOE can only be used with socket 0
  #0, CLOSED, TCP, UDP, IPRAW, MACRAW, PPPOE

  UPD_HEADER_IP     = $00
  UDP_HEADER_PORT   = $04
  UDP_HEADER_LENGTH = $06
  UPD_DATA          = $08
  TIMEOUT           = 10000

  CR    = $0D
  LF    = $0A
  NULL  = $00

  
       
VAR
  byte  _sock
  byte  _protocol
  byte  _remoteIp[4]
  byte  readCount
  word  _remotePort

DAT
  _port       byte  $2710

OBJ
  wiz           : "W5200"

'----------------------------------------------------
' Initialize
'----------------------------------------------------
PUB Init(socketId, protocol, portNum)
{{
DESCRIPTION:

PARMS:
  
RETURNS:
  
}}
  _sock := socketId
  _protocol := protocol

  'Increment port numbers stating at 10,000
  if(portNum == -1)
    portNum := _port++
    
  'wiz.Init
  wiz.InitSocket(socketId, protocol, portNum)
  wiz.SetSocketIR(_sock, $FF)

  readCount := 0


PUB RemoteIp(octet3, octet2, octet1, octet0)
  _remoteIp[0] := octet3
  _remoteIp[1] := octet2
  _remoteIp[2] := octet1
  _remoteIp[3] := octet0
  wiz.RemoteIp(_sock, octet3, octet2, octet1, octet0)
  
PUB RemotePort(port)
{{
DESCRIPTION:

PARMS:
  
RETURNS:
  
}}
  _remotePort := port
  wiz.SetRemotePort(_sock, port)

{
PUB DebugRead(register, buffer, length)
  wiz.DebugRead(_sock, register, buffer, length)
}  
'----------------------------------------------------
'
'----------------------------------------------------

PUB Open
{{
DESCRIPTION:

PARMS:
  
RETURNS:
  
}}
  wiz.OpenSocket(_sock)

PUB Listen
{{
DESCRIPTION:

PARMS:
  
RETURNS:
  
}}
  if(wiz.IsInit(_sock))
    wiz.StartListener(_sock)
    return true
  return false

PUB Connect
{{
DESCRIPTION:

PARMS:
  
RETURNS:
  
}}
  wiz.OpenRemoteSocket(_sock)

PUB Connected
{{
DESCRIPTION:

PARMS:
  
RETURNS:
  
}}
  return wiz.IsEstablished(_sock)

PUB Close
{{
DESCRIPTION:

PARMS:
  
RETURNS:
  
}}
  return wiz.CloseSocket(_sock)

PUB IsClosed
{{
DESCRIPTION:

PARMS:
  
RETURNS:
  
}}
  return wiz.IsClosed(_sock)

PUB Available | i, bytesToRead
{{
DESCRIPTION:

PARMS:
  
RETURNS:
  
}}
  bytesToRead := i := 0

  if(readCount++ == 0)
    repeat until NULL < bytesToRead := wiz.GetRxBytesToRead(_sock) 
      if(i++ > TIMEOUT)
        waitcnt(((clkfreq / 1_000 * 1 - 3932) #> 381) + cnt)
        return -1
  else
    bytesToRead := wiz.GetRxBytesToRead(_sock)
   
  return bytesToRead
  
PUB Receive(buffer, bytesToRead) | ptr
{{
DESCRIPTION:

PARMS:
  
RETURNS:
  
}}
  ptr := buffer
  wiz.Rx(_sock, buffer, bytesToRead)
  byte[buffer][bytesToRead] := NULL
  
  if(_protocol == UDP)
    ParseHeader(buffer, bytesToRead)
    ptr += UPD_DATA

  return ptr
      
PUB Send(buffer, len) | bytesToWrite
{{
DESCRIPTION:

PARMS:
  
RETURNS:
  
}}   
  'Validate max Rx length in bytes
  bytesToWrite := len
  if(bytesToWrite > wiz.SocketTxSize(_sock))
    bytesToWrite := wiz.SocketTxSize(_sock)

  wiz.Tx(_sock, buffer, bytesToWrite)
  wiz.FlushSocket(_sock)
  return  bytesToWrite
 


PUB Disconnect : i
{{
DESCRIPTION:

PARMS:
  
RETURNS:
  
}}
  i := readCount := 0
  wiz.DisconnectSocket(_sock)
  repeat until wiz.IsClosed(_sock)
    if(i++ > 500)
      wiz.CloseSocket(_sock)
      return false

  return true  

PUB IsCloseWait
  return wiz.IsCloseWait(_sock)

PUB GetSocketIR
  return wiz.GetSocketIR(_sock)
  
PUB SetSocketIR(value)
  wiz.SetSocketIR(_sock, value)

PRI ParseHeader(header, bytesToRead)
{{
DESCRIPTION:

PARMS:
  
RETURNS:
  
}}
  if(bytesToRead > 8)
    UpdHeaderIp(header)
    UdpHeaderPort(header)

PRI UpdHeaderIp(header)
{{
DESCRIPTION:

PARMS:
  
RETURNS:
  
}}
  RemoteIp(byte[header][UPD_HEADER_IP], byte[header][UPD_HEADER_IP+1], byte[header][UPD_HEADER_IP+2], byte[header][UPD_HEADER_IP+3])

PRI UdpHeaderPort(header)
{{
DESCRIPTION:

PARMS:
  
RETURNS:
  
}}
  RemotePort(DeserializeWord(header + UDP_HEADER_PORT))

PRI DeserializeWord(buffer) | value
{{
DESCRIPTION:

PARMS:
  
RETURNS:
  
}}
  value := byte[buffer++] << 8
  value += byte[buffer]
  return value

CON
{{
 ______________________________________________________________________________________________________________________________
|                                                   TERMS OF USE: MIT License                                                  |                                                            
|______________________________________________________________________________________________________________________________|
|Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    |     
|files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    |
|modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software|
|is furnished to do so, subject to the following conditions:                                                                   |
|                                                                                                                              |
|The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.|
|                                                                                                                              |
|THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          |
|WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         |
|COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   |
|ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         |
 ------------------------------------------------------------------------------------------------------------------------------ 
}}
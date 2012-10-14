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
  {{ W5200 Common register enumeration }}
  '      1              2              3              4              5              6
  '--------------------|--------------|--------------|--------------|--------------|-------------|    
  #0000,  MODE_REG,{
  01-04}  GATEWAY0,      GATEWAY1,      GATEWAY2,      GATEWAY3,{
  05-08}  SUBNET_MASK0,  SUBNET_MASK1,  SUBNET_MASK2,  SUBNET_MASK3,{
  09-0E}  MAC0,          MAC1,          MAC2,          MAC3,          MAC4,          MAC5,{
  0F-12}  SOURCE_IP0,    SOURCE_IP1,    SOURCE_IP2,    SOURCE_IP3,{
  13-14}  RES13,RES14,{
  15}     INTR,{
  16}     INTM2,{
  17-18}  RTIME0,        RTIME1,{
  19}     RETRY_COUNT,{
  1A-1B}  RES1A,         RES1B,{
  1C-1D}  P_AUTH_TYPE0,  P_AUTH_TYPE1,{
  1E}     PPPALGO,{
  1F}     VERSION,{
  20-27}  RES20,RES21,RES22,RES23,RES24,RES25,RES26,RES27,{
  28}     PTIMER,{
  29}     PMAGIC,{
  2A-2F}  RES2A,RES2B,RES2C,RES2D,RES2E,RES2F, {
  30-31}  INTLR0,        INTLR1,{
  32-33}  IR2,{
  34}     PSTATUS,{
  36}     IMR                                                                                               

  {{ W5200  Socket Register Base Addresses }}
  #0000,  S_MR,{
 01     } S_CR,{
 02     } S_IR,{
 03     } S_SR,{
 04-05  } S_PORT0,      S_PORT1,{
 06-0B  } S_DEST_MAC0,  S_DEST_MAC1,   S_DEST_MAC2,   S_DEST_MAC3,   S_DEST_MAC4,   S_DEST_MAC5,{
 0C-0F  } S_DEST_IP0,   S_DEST_IP1,    S_DEST_IP2,    S_DEST_IP3,{
 10-11  } S_DEST_PORT0, S_DEST_PORT1,{
 12-13  } S_MAX_SEGM0,  S_MAX_SEGM1,{
 14     } S_PROTOCOL,{
 15     } S_TOS,{
 16     } S_TTL,{
 17-1D  } S_RES17,S_RES18,S_RES19,S_RES1A,S_RES1B,S_RES1C,S_RES1D,{
 1E     } S_RX_MEM_SIZE, {
 1F     } S_TX_MEM_SIZE, {
 20-21  } S_TX_FREE0,   S_TX_FREE1,{
 22-23  } S_TX_R_PTR0,  S_TX_R_PTR1, {
 24-25  } S_TX_W_PTR0,  S_TX_W_PTR1, {
 26-27  } S_RX_RCV_SIZE0,S_RX_RCV_SIZE1,{
 28-29  } S_RX_R_PTR0,  S_RX_R_PTR1, {
 2A-2B  } S_RX_W_PTR0,  S_RX_W_PTR1, {
 2C     } S_INT_MASK, {
 2D-2E  } S_IP_HEADER_FRAG_OFFSET {
         Reservered $4n30 to $4nFF}
         
 {{Socket Register Offsets}}
  SOCKET_BASE_ADDRESS = $4000
  SOCKET_REG_SIZE     = $0100
  
  INTERNAL_RX_BUFFER_ADDRESS    = $C000
  INTERNAL_TX_BUFFER_ADDRESS    = $8000
  DEFAULT_RX_TX_BUFFER          = $800
  DEFAULT_RX_TX_BUFFER_MASK     = DEFAULT_RX_TX_BUFFER - 1

  {{ Socket Command Register}}
  OPEN              = $01
  LISTEN            = $02
  CONNECT           = $04
  DISCONNECT        = $08
  CLOSE             = $10
  SEND              = $20
  SEND_MAC          = $21
  SEND_KEEP         = $22
  RECV              = $40
  'ADSL 
  #$23, PCON, PDISCON, PCR, PCN, PCJ
  
  {{ Status Register }}
  SOCK_CLOSED       = $00
  SOCK_INIT         = $13
  SOCK_LISTEN       = $14
  SOCK_ESTABLISHED  = $17
  SOCK_CLOSE_WAIT   = $1C
  SOCK_UPD          = $22
  SOCK_IPRAW        = $32
  SOCK_MACRAW       = $42
  SOCK_PPPOE        = $5F
  {{ Status Change States }}
  SOCK_SYSENT       = $15
  SOCK_SYNRECV      = $16
  SOCK_FIN_WAIT     = $18
  SOCK_CLOSING      = $1A
  SOCK_TIME_WAIT    = $1B
  SOCK_LAST_ACK     = $1D
  SOCK_ARP          = $01

  'MACRAW and PPPOE can only be used with socket 0
  #0, CLOSED, TCP, UDP, IPRAW, MACRAW, PPPOE
  

  BUFFER_2K         = $800
  BUFFER_16         = $10
  SOCKETS           = 8

  #0, READ_OPCODE, WRITE_OPCODE

  ' SPI pins
  SPI_MOSI          = 1 ' SPI master out serial in to slave
  SPI_SCK           = 0 ' SPI clock from master to all slaves
  SPI_CS            = 3 ' SPI chip select (active low)
  SPI_MISO          = 2 ' SPI master in serial out from slave
   

  NULL              = 0
                                                            

DAT
  _mode           byte  %0000_0000                      'enable ping
  _gateway        byte  $00, $00, $00, $00              '192, 168, 1,   1  
  _subnetmask     byte  $00, $00, $00, $00              '255, 255, 255, 0 
  _mac            byte  $00, $00, $00, $00, $00, $00    '$00, $08, $DC, $16, $F8, $01
  _ip             byte  $00, $00, $00, $00              '192, 168,   1,   199
  _endcm          byte  $00

  _dns1           byte  $00, $00, $00, $00
  _dns2           byte  $00, $00, $00, $00
  _dns3           byte  $00, $00, $00, $00
  _dhcpServer     byte  $00, $00, $00, $00
  _router         byte  $00, $00, $00, $00

  workSpace       byte  $0[BUFFER_16]
  
  sockRxMem       byte  $02[SOCKETS]
  sockTxMem       byte  $02[SOCKETS]
  sockRxBase      word  INTERNAL_RX_BUFFER_ADDRESS[SOCKETS]
  sockRxMask      word  DEFAULT_RX_TX_BUFFER_MASK[SOCKETS]
  sockTxBase      word  INTERNAL_TX_BUFFER_ADDRESS[SOCKETS]
  sockTxMask      word  DEFAULT_RX_TX_BUFFER_MASK[SOCKETS]

{{
DESCRIPTION:

PARMS:
  
RETURNS:
  
}}

OBJ
  'spi           : "Spi.spin"
  spi           : "SpiPasm.spin" 


PUB Start(m_cs, c_clk, m_mosi, m_miso)
{{
DESCRIPTION:
  Initialize default values.  All 8 Rx/Tx bufffers are set to 2k.

PARMS:
  SPI_CS            = m_cs ' SPI chip select (active low)
  SPI_SCK           = c_clk ' SPI clock from master to all slaves
  SPI_MOSI          = m_mosi ' SPI master out serial in to slave
  SPI_MISO          = m_miso ' SPI master in serial out from slave 

RETURNS:
  Nothing
}}
  'Init the SPI bus
  spi.Init( m_cs, c_clk, m_mosi, m_miso )

  SetCommonDefaults

  ' Set Interrupt mask register
  SetIMR2($FF)

PUB Init
{{
DESCRIPTION:
  Initialize default values.  All 8 Rx/Tx bufffers are set to 2k.

  Hardcoded SPI IO
  SPI_MOSI          = 1 ' SPI master out serial in to slave
  SPI_SCK           = 0 ' SPI clock from master to all slaves
  SPI_CS            = 3 ' SPI chip select (active low)
  SPI_MISO          = 2 ' SPI master in serial out from slave 

PARMS:
  None

RETURNS:
  Nothing
}}
  'Init workspace buffer
  'bytefill(@workSpace, 0, BUFFER_16) 

  'Internal Rx and Tx Base buffer addresses
  'sockRxBase[0] := INTERNAL_RX_BUFFER_ADDRESS
  'sockTxBase[0] := INTERNAL_TX_BUFFER_ADDRESS

  'Init the SPI bus
  spi.Init( SPI_CS, SPI_SCK, SPI_MOSI, SPI_MISO )


  SetCommonDefaults

  ' Set Interrupt mask register
  SetIMR2($FF)

  
PUB InitSocket(socket, protocol, port)
{{
DESCRIPTION:
  Initialize a socket.
  W5100 has 4 sockets
  W5200 has 8 sockets

PARMS:
  socket    - Socket ID to initialize (0-n)
  protocol  - TCP/UPD
  port      - Listener port (0-65535)  

RETURNS:
  Nothing
}}
  SetSocketMode(socket, protocol)
  SetSocketPort(socket, port)

'----------------------------------------------------
' Receive data
'----------------------------------------------------  
PUB Rx(socket, buffer, length) | src_mask, src_ptr, upper_size, left_size
{{
DESCRIPTION:
  Read the Rx socket(n) buffer into HUB memory.  The W5200/W5100
  uses a circlar buffer. If the buffer is 100 bytes, we're
  currently at 91, and we receice 20 bytes the first 10 byte fill
  addresses 91-100. The remaining 10 bytes fill addresses 0-9.

  The Rx method figures ot if the buffer wraps an updates the
  buffer pointers for the next read.

PARMATERS:
  socket    - Socket ID
  buffer    - Pointer to HUB memory
  length    - Bytes to read into HUB memory

RETURNS:
  Nothing
}}
  'Rx memory buffer offset and Physical Rx buffer address
  src_mask := GetRxReadPointer(socket) & sockRxMask[socket]
  src_ptr :=  src_mask + sockRxBase[socket]

  'Check for Rx buffer wrap
  if((src_mask + length) > (sockRxMask[socket] + 1))
  
    'Data wraps, get the upper buffer, read into HUB memory
    'and update the buffer pointer
    upper_size := sockRxMask[socket] + 1 - src_mask
    Read(src_ptr, buffer, upper_size)
    buffer += upper_size
    
    'Calculate the remaining byte and read Rx into
    'HUB memory starting at the base buffer address
    left_size := length - upper_size
    Read(sockRxBase[socket] , buffer, left_size)
    
  else
    'The data did not wrap, just copy Rx to HUB memory
    Read(src_ptr, buffer, length)

  'Update the current Rx read buffer pointer
  length += GetRxReadPointer(socket)
  SetRxReadPointer(socket, length)

  'Set the command register to receive
  SetSocketCommandRegister(socket, RECV) 
  

'----------------------------------------------------
' Transmit data
'----------------------------------------------------
PUB Tx(socket, buffer, length) | dst_mask, dst_ptr, upper_size, left_size, ptr
{{
DESCRIPTION:
  Write HUB memory to the socket(n) Tx buffer.  If the Tx buffer is 100
  bytes, we're  currently pointing to 91, and we need to transmit 20 bytes
  the first 10 byte fill addresses 91-100. The remaining 10 bytes
  fill addresses 0-9.

PARMS:
  socket    - Socket ID
  buffer    - Pointer to HUB memory
  length    - Bytes to write to the socket(n) buffer
  
RETURNS:
  Nothing
}}
  'Exit if the the bytes to write are larger than the available Tx socket size
  'This should not happen as the socket object handles buffer overflow but the
  'implementer might decide to byapss the socket object
  if(GetFreeTxSize(socket) < length)
    return -2

  'Calculate the physical socket(n) Tx address
  ptr := GetTxWritePointer(socket)
  dst_mask := ptr & sockTxMask[socket]  
  dst_ptr :=  sockTxBase[socket] + dst_mask
  
  if((dst_mask + length) > (sockTxMask[socket] + 1))
    'Wrap and write the Tx data
    upper_size := (sockTxMask[socket] + 1) - dst_mask
    Write(dst_ptr, buffer, upper_size)
    buffer += upper_size
    left_size := length - upper_size
    Write(sockTxBase[socket], buffer, left_size)
  else
    Write(dst_ptr, buffer, length)

  'Set Tx pointers for the next Tx
  SetTxWritePointer(socket, length+ptr)



'----------------------------------------------------
' Socket Buffer Pointer Methods
'----------------------------------------------------
PUB GetRxBytesToRead(socket)
{{
DESCRIPTION:
  Read socket(n) receive size register
  
PARMS:
  socket    - Socket ID
    
RETURNS:
  2 bytes: Number of bytes received
}}
  return ReadSocketWord(socket, S_RX_RCV_SIZE0)

PUB GetFreeTxSize(socket)
{{
DESCRIPTION:
  Read 2 byte socket(n) Tx available size register
  
PARMS:
  socket    - Socket ID
   
RETURNS:
  2 bytes: Socket(n) available Tx size   
}}
  return ReadSocketWord(socket, S_TX_FREE0)

PUB GetRxReadPointer(socket)
{{
DESCRIPTION: Read socket(n) Rx read pointer

PARMS:
  socket    - Socket ID
  
RETURNS: 2 bytes: Socket(n) Rx read pointer   
}}
  return ReadSocketWord(socket, S_RX_R_PTR0)

PUB SetRxReadPointer(socket, value)
{{
DESCRIPTION: Write socket(n) Rx read pointer

PARMS:
  socket    - Socket ID
  
RETURNS: Nothing  
}}
  SocketWriteWord(socket, S_RX_R_PTR0, value) 

PUB GetTxWritePointer(socket)
{{
DESCRIPTION: Read socket(n) Tx write pointer

PARMS:
  socket    - Socket ID
  
RETURNS: 2 bytes: Socket(n) Tx write pointer   
}}
  return ReadSocketWord(socket, S_TX_W_PTR0)

PUB SetTxWritePointer(socket, value)
{{
DESCRIPTION: Write socket(n) Tx write pointer 

PARMS:
  socket    - Socket ID 
  
RETURNS: 2 bytes: Socket(n) Tx write pointer 
}}
  SocketWriteWord(socket, S_TX_W_PTR0, value)

PUB GetTxReadPointer(socket)
{{
DESCRIPTION: Read socket(n) Tx read pointer 

PARMS:
  socket    - Socket ID 
  
RETURNS: 2 bytes: Socket(n) Tx read pointer 
}}
  return ReadSocketWord(socket, S_TX_R_PTR0)

PUB SocketRxSize(socket)
{{
DESCRIPTION: Configuration: Rx socket(n) size in bytes 

PARMS:
  socket    - Socket ID 
  
RETURNS: Rx socket(n) size in bytes 
}}
  return sockRxMem[socket] * 1024

PUB SocketTxSize(socket)
{{
DESCRIPTION: Configuration: Tx socket(n) size in bytes 

PARMS:
  socket    - Socket ID 
  
RETURNS: Tx socket(n) size in bytes
}}
  return sockTxMem[socket] * 1024
  
'----------------------------------------------------
' Socket Commands
'----------------------------------------------------  
PUB OpenSocket(socket)
{{
DESCRIPTION: Open socket(n)

PARMS:
  socket    - Socket ID  
  
RETURNS: Nothing
}}
  SetSocketCommandRegister(socket, OPEN)

PUB StartListener(socket)
{{
DESCRIPTION: Listen on socket(n)

PARMS:
  socket    - Socket ID 
  
RETURNS: Nothing
}}
  SetSocketCommandRegister(socket, LISTEN)

PUB FlushSocket(socket)
{{
DESCRIPTION: Send data through socket(n)

PARMS:
  socket    - Socket ID 
  
RETURNS: Nothing
}}
  SetSocketCommandRegister(socket, SEND)

PUB OpenRemoteSocket(socket)
{{
DESCRIPTION: Connect remote socket(n)

PARMS:
  socket    - Socket ID  
  
RETURNS: Nothing
}}
  SetSocketCommandRegister(socket, CONNECT)  

PUB DisconnectSocket(socket)
{{
DESCRIPTION: Disconnect socket(n)

PARMS:
  socket    - Socket ID 
  
RETURNS: Nothing
}}
  SetSocketCommandRegister(socket, DISCONNECT)

PUB CloseSocket(socket)
{{
DESCRIPTION: Close socket(n)

PARMS:
  socket    - Socket ID 
  
RETURNS: Nothing
}}
  SetSocketCommandRegister(socket, CLOSE)
  
'----------------------------------------------------
' Socket Status
'----------------------------------------------------
PUB IsInit(socket)
{{
DESCRIPTION: Determine if the socket is initialized

PARMS:
  socket    - Socket ID 
  
RETURNS: True if the socket is initialized; otherwise returns false. 
}}
  return GetSocketStatus(socket) ==  SOCK_INIT

PUB IsEstablished(socket)
{{
DESCRIPTION: Determine if the socket is established

PARMS:
  socket    - Socket ID 
  
RETURNS: True if the socket is established; otherwise returns false. 
}}
  return GetSocketStatus(socket) ==  SOCK_ESTABLISHED

PUB IsCloseWait(socket)
{{
DESCRIPTION: Determine if the socket is close wait

PARMS:
  socket    - Socket ID 
  
RETURNS: True if the socket is close wait; otherwise returns false. 
}}
  return GetSocketStatus(socket) ==  SOCK_CLOSE_WAIT

PUB IsClosed(socket)
{{
DESCRIPTION: Determine if the socket is closed

PARMS:
  socket    - Socket ID 
  
RETURNS: True if the socket is closed; otherwise returns false. 
}}
  return GetSocketStatus(socket) ==  SOCK_CLOSED

PUB SocketStatus(socket)
{{
DESCRIPTION: Read the status of socket(n)

PARMS:
  socket    - Socket ID 
  
RETURNS: Byte: Socket(n) status register
}}
  return GetSocketStatus(socket)  

'----------------------------------------------------
' Common Register Initialize Methods
'----------------------------------------------------
PUB SetCommonDefaults
  Write(MODE_REG, @_mode, 19)
   'Use the default 8x2k Rx and Tx Buffers 
  SetDefault2kRxTxBuffers

PUB SetCommonnMode(value)
  _mode := value & $FF
  Write(MODE_REG, @_mode, 1)     
 
PUB SetGateway(octet3, octet2, octet1, octet0)
  _gateway[0] := octet3
  _gateway[1] := octet2
  _gateway[2] := octet1
  _gateway[3] := octet0 
  'long[@gateway] := octet3 << 8 + octet2 << 16 + octet1 << 24 + octet0
  Write(GATEWAY0, @_gateway, 4)

PUB SetSubnetMask(octet3, octet2, octet1, octet0)
  _subnetmask[0] := octet3 
  _subnetmask[1] := octet2
  _subnetmask[2] := octet1
  _subnetmask[3] := octet0
  Write(SUBNET_MASK0, @_subnetmask, 4) 

PUB SetMac(octet5, octet4, octet3, octet2, octet1, octet0)
  _mac[0] := octet5 
  _mac[1] := octet4
  _mac[2] := octet3
  _mac[3] := octet2
  _mac[4] := octet1
  _mac[5] := octet0
  Write(MAC0, @_mac, 6)

PUB SetIp(octet3, octet2, octet1, octet0)
  _ip[0] := octet3 
  _ip[1] := octet2
  _ip[2] := octet1
  _ip[3] := octet0
  Write(SOURCE_IP0, @_ip, 4 )

PUB RemoteIp(socket, octet3, octet2, octet1, octet0)
  workSpace[0] := octet3 
  workSpace[1] := octet2
  workSpace[2] := octet1
  workSpace[3] := octet0
  Write(GetSocketRegister(socket, S_DEST_IP0), @workspace, 4)


'----------------------------------------------------
' Common Register Properties
'----------------------------------------------------
PUB GetIp
{{
DESCRIPTION:

PARMS:
  
RETURNS:
  
}}
  return @_ip
  
PUB GetRemoteIp(socket)
  Read(GetSocketRegister(socket, S_DEST_IP0), @workspace, 4)
  return @workspace 

PUB SetRemotePort(socket, port)
  SocketWriteWord(socket, S_DEST_PORT0, port)
  
PUB GetGatewayIp
  Read( GATEWAY0, @workspace, 4)
  return @workspace 

PUB GetIR2
  return ReadByte(IR2)
  
PUB SetIR2(value)   
  WriteByte(IR2, value)

PUB GetIMR2
  return ReadByte(INTM2)

Pub SetIMR2(value)
  WriteByte(INTM2, value)



'----------------------------------------------------
' DHCP and DNS
' These methods are accessed by DHCP and DNS
' objects
'----------------------------------------------------
PUB CopyDns(source, len)
{{
DESCRIPTION:

PARMS:
  
RETURNS:
  
}}
  bytemove(@_dns1, source, len)

PUB CopyDhcpServer(source, len)
  bytemove(@_dhcpServer, source, len)

PUB CopyRouter(source, len)
  bytemove(@_router, source, len)

PUB CopyGateway(source, len)
  bytemove(@_gateway, source, len)

PUB CopySubnet(source, len)
  bytemove(@_subnetMask, source, len)
  Write(SUBNET_MASK0, @_subnetmask, 4)
    
PUB GetDns
  return GetDnsByIndex(0)

PUB GetDnsByIndex(idx)
  if(IsNullIp( @_dns1 + idx*4 ) )
    return NULL
  return @_dns1 + idx*4

PUB GetDhcpServerIp
  return @_dhcpServer

PUB GetRouter
  return @_router

PRI IsNullIp(ipaddr)
  return (byte[ipaddr][0] + byte[ipaddr][1] + byte[ipaddr][2] + byte[ipaddr][3]) == 0    


'----------------------------------------------------
' Set defaults
'----------------------------------------------------     
PUB SetDefault2kRxTxBuffers | i
{{
DESCRIPTION:

PARMS:
  
RETURNS:
  
}}
  repeat i from 0 to 7
    sockRxMem[i] := $02
    sockTxMem[i] := $02
    
  repeat i from 0 to 7
    sockRxMask[i] := DEFAULT_RX_TX_BUFFER_MASK
    sockTxMask[i] := DEFAULT_RX_TX_BUFFER_MASK

  repeat i from 1 to 7
    sockRxBase[i] := sockRxBase[i-1] + DEFAULT_RX_TX_BUFFER
    sockTxBase[i] := sockTxBase[i-1] + DEFAULT_RX_TX_BUFFER

  'repeat i from 0 to 7
    'WriteByte(GetSocketRegister(i, S_RX_MEM_SIZE) , sockRxMem[i])
    'WriteByte(GetSocketRegister(i, S_TX_MEM_SIZE) , sockTxMem[i])  


'----------------------------------------------------
' Wrapped Socket Register Methods
'----------------------------------------------------
PRI SetSocketMode(socket, value)
{{
DESCRIPTION:

PARMS:
  
RETURNS:
  
}}
  SocketWriteByte(socket, S_MR, value)

PRI SetSocketPort(socket, port)
  SocketWriteWord(socket, S_PORT0, port)

PRI SetSocketCommandRegister(socket, value)
  SocketWriteByte(socket, S_CR, value)

PRI GetSocketCommandRegister(socket)
  return SocketReadByte(socket, S_CR)

PUB GetSocketStatus(socket)
  return SocketReadByte(socket, S_SR)

PUB GetSocketIR(socket)
  return SocketReadByte(socket, S_IR)

PUB SetSocketIR(socket, value)
  SocketWriteByte(socket, S_IR, value)
  
'----------------------------------------------------
' Socket Helper Methods
'----------------------------------------------------
PRI ReadSocketWord(socket, register)
{{
DESCRIPTION:

PARMS:
  
RETURNS:
  
}}
  Read(GetSocketRegister(socket, register), @workSpace, 2)
  return DeserializeWord(@workSpace)
  
PRI SocketWriteWord(socket, register, value)
  SerializeWord(value, @workSpace)
  Write(GetSocketRegister(socket, register), @workSpace, 2)

PRI SocketReadByte(socket, register)
  return ReadByte(GetSocketRegister(socket, register))
  
PRI SocketWriteByte(socket, register, value)
  WriteByte(GetSocketRegister(socket, register), value)

'----------------------------------------------------
' Helper Methods
'---------------------------------------------------- 
PUB SerializeWord(value, buffer)
{{
DESCRIPTION:

PARMS:
  
RETURNS:
  
}}
  byte[buffer++] := (value & $FF00) >> 8
  byte[buffer] := value & $FF 

PUB DeserializeWord(buffer) | value
  value := byte[buffer++] << 8
  value += byte[buffer]
  return value

PUB GetSocketRegister(sock, register)
  return sock * SOCKET_REG_SIZE + SOCKET_BASE_ADDRESS + register


'----------------------------------------------------
' SPI Interface
'----------------------------------------------------  
PRI Read(register, buffer, length) | idx, data
{{
DESCRIPTION:

PARMS:
  
RETURNS:
  
}}
  spi.Read(register, length, buffer)

PRI Write(register, buffer, length) | idx, data
  spi.Write(register, length, buffer)

    
PRI ReadByte(register) | opcode, data
  spi.Read(register, 1, @workSpace)
  return workSpace[0] & $FF

PRI WriteByte(register, value) | idx, data
  workSpace[0] := value
  spi.Write(register, 1, @workSpace)

  
'----------------------------------------------------
' Debug methods
' Expose varaibles to higher level objects
'----------------------------------------------------


PUB GetCommonRegister(register)
  return @_mode + register
  
{ 
PUB GetWorkSpace
  return @workSpace
  
PUB DebugGet
  return _mode

PUB DebugWorkBuff
  return @workSpace
 
PUB DebugRead(register, buffer, length)
  Read(register, buffer, length)

PUB DebugReadWord(socket, register)
  Read(register, @workSpace, 2)
  return DeserializeWord(@workSpace)

PUB DebugReadByte(socket, register)
  return ReadByte(register)
   
 
PUB DebugSockRead(sock, register, buffer, length)
  Read(GetSocketRegister(sock, register), buffer, length)

PUB DebugSockReadWord(socket, register)
  Read(GetSocketRegister(socket, register), @workSpace, 2)
  return DeserializeWord(@workSpace)

PUB DebugSockReadByte(socket, register)
  return ReadByte(GetSocketRegister(socket, register))
}

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
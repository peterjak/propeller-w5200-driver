CON
  {{ Common register enumeration  }}
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
  17-19}  RTIME0,        RTIME1,{
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

  {{Socket Register Base Addresses}}
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
  SOCK_INT          = $13
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
  SPI_CS                 = 3 ' SPI chip select (active low)
  SPI_SCK                = 0 ' SPI clock from master to all slaves
  SPI_MOSI               = 1 ' SPI master out serial in to slave
  SPI_MISO               = 2 ' SPI master in serial out from slave
                                                            

DAT
  _mode           byte  %0001_0000                  'enable ping
  _gateway        byte  192, 168,   1,   1
  _subnetmask     byte  255, 255, 255,   0
  _mac            byte  $00, $08, $DC, $16, $F8, $01
  _ip             byte  192, 168,   1,   107
  endcm           byte  $00', $00

  workSpace       byte  $0[BUFFER_16]
  
  sockRxMem       byte  $02[SOCKETS]
  sockTxMem       byte  $02[SOCKETS]
  sockRxBase      word  $C000[SOCKETS]
  sockRxMask      word  $07FF[SOCKETS]
  sockTxBase      word  $8000[SOCKETS]
  sockTxMask      word  $07FF[SOCKETS]



OBJ
  spi           : "Spi.spin"

  
PUB Init

  'Init buffer
  bytefill(@workSpace, 0, BUFFER_16) 

  'Internal Rx and Tx Base buffer addresses
  sockRxBase[0] := INTERNAL_RX_BUFFER_ADDRESS
  sockTxBase[0] := INTERNAL_TX_BUFFER_ADDRESS

  'Init the SPI bus
  spi.Init( SPI_CS, SPI_SCK, SPI_MOSI, SPI_MISO )

  'This can/will be replaced with DHCP in higher level objects
  SetCommonDefaults


PUB GetWorkSpace
  return @workSpace



PUB InitSocket(socket, protocol, port)
  SetSocketMode(socket, protocol)
  SetSocketPort(socket, port)

'----------------------------------------------------
' Receive data
'----------------------------------------------------  
PUB Rx(socket, buffer, length) | src_mask, src_ptr, upper_size, left_size

  src_mask := GetRxReadPointer(socket) & sockRxMask[socket] 
  src_ptr :=  src_mask + sockRxBase[socket]

  'Check for overflow
  if((src_mask + length) > (sockRxMask[socket] + 1))
    upper_size := sockRxMask[socket] + 1 - src_mask
    Read(src_ptr, buffer, upper_size)
    buffer += upper_size
    left_size := length - upper_size
    Read(sockRxBase[socket] , buffer, left_size)
  else
    Read(src_ptr, buffer, length)

  'This might have to go elsewhere in the receive process
  'update the pointers
  length += GetRxReadPointer(socket)

  'Not sure about this
  SetRxReadPointer(socket, length)
  SetSocketCommandRegister(socket, RECV) 
  

'----------------------------------------------------
' Transmit data
'----------------------------------------------------
PUB Tx(socket, buffer, length) | dst_mask, dst_ptr, upper_size, left_size, ptr1
  if(GetFreeTxSize(socket) < length)
    return -2

  ptr1 := GetTxWritePointer(socket)
  dst_mask := ptr1 & sockTxMask[socket]  
  dst_ptr :=  sockTxBase[socket] + dst_mask

  if((dst_mask + length) > (sockTxMask[socket] + 1))
    upper_size := (sockTxMask[socket] + 1) - dst_mask
    Write(dst_ptr, buffer, upper_size)
    buffer += upper_size
    left_size := length - upper_size
    Write(buffer, sockTxBase[socket], left_size)
  else
    Write(dst_ptr, buffer, length)

  SetTxWritePointer(socket, length+ptr1) 


'----------------------------------------------------
' Buffer Pointer Methods
'----------------------------------------------------
PUB GetRxBytesToRead(socket)
  return ReadSocket16(socket, S_RX_RCV_SIZE0)

PUB GetFreeTxSize(socket)
  return ReadSocket16(socket, S_TX_FREE0)

PUB GetRxReadPointer(socket)
  return ReadSocket16(socket, S_RX_R_PTR0)

PUB SetRxReadPointer(socket, value)
  WriteSocket16(socket, S_RX_R_PTR0, value) 

PUB GetTxWritePointer(socket)
  return ReadSocket16(socket, S_TX_W_PTR0)

PUB SetTxWritePointer(socket, value)
  WriteSocket16(socket, S_TX_W_PTR0, value)

PUB GetTxReadPointer(socket)
  return ReadSocket16(socket, S_TX_R_PTR0)

  
  


'----------------------------------------------------
' Socket Commands
'----------------------------------------------------  
PUB OpenSocket(socket)
  SetSocketCommandRegister(socket, OPEN)

PUB StartListener(socket)
  SetSocketCommandRegister(socket, LISTEN)

PUB FlushSocket(socket)
  SetSocketCommandRegister(socket, SEND)

PUB OpenRemoteSocket(socket)
  SetSocketCommandRegister(socket, CONNECT)  

PUB DisconnectSocket(socket)
  SetSocketCommandRegister(socket, DISCONNECT)

PUB CloseSocket(socket)
  SetSocketCommandRegister(socket, CLOSE)
  
'----------------------------------------------------
' Socket Status
'---------------------------------------------------- 
PUB IsEstablished(socket)
  return GetSocketStatus(socket) ==  SOCK_ESTABLISHED

PUB IsCloseWait(socket)
  return GetSocketStatus(socket) ==  SOCK_CLOSE_WAIT

PUB IsClosed(socket)
  return GetSocketStatus(socket) ==  SOCK_CLOSED

PUB SocketStatus(socket)
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

PUB Mac(octet5, octet4, octet3, octet2, octet1, octet0)
  _mac[0] := octet5 
  _mac[1] := octet4
  _mac[2] := octet3
  _mac[3] := octet2
  _mac[4] := octet1
  _mac[5] := octet0
  Write(MAC0, @_mac, 6)

PUB Ip(octet3, octet2, octet1, octet0)
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

PUB GetRemoteIp(socket)
  Read(GetSocketRegister(socket, S_DEST_IP0), @workspace, 4) 

PUB RemotePort(socket, port)
  WriteSocket16(socket, S_DEST_PORT0, port)

   
PUB SetDefault2kRxTxBuffers | i

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
' Socket Register Methods
'----------------------------------------------------
PRI SetSocketMode(socket, value)
  WriteSocket8(socket, S_MR, value)

PRI SetSocketPort(socket, port)
  WriteSocket16(socket, S_PORT0, port)

PRI SetSocketCommandRegister(socket, value)
  WriteSocket8(socket, S_CR, value)

PRI GetSocketCommandRegister(socket)
  return ReadByte(GetSocketRegister(socket, S_CR))

PRI GetSocketStatus(socket)
  return ReadByte(GetSocketRegister(socket, S_SR))
  
'----------------------------------------------------
' Helper Methods
'----------------------------------------------------


PRI WriteSocket16(socket, register, value)
  SerializeWord(value, @workSpace)
  Write(GetSocketRegister(socket, register), @workSpace, 2)

PRI WriteSocket8(socket, register, value)
  WriteByte(GetSocketRegister(socket, register), value)

PRI ReadSocket16(socket, register)
  Read(GetSocketRegister(socket, register), @workSpace, 2)
  return DeserializeWord(@workSpace)

PRI ReadSocket8(socket, register)
  return ReadByte(GetSocketRegister(socket, register))
  
PRI SerializeWord(value, buffer)
  byte[buffer++] := (value & $FF00) >> 8
  byte[buffer] := value & $FF 

PRI DeserializeWord(buffer) | value
  value := byte[buffer++] << 8
  value += byte[buffer]
  return value

PUB GetSocketRegister(sock, register)
  return sock * SOCKET_REG_SIZE + SOCKET_BASE_ADDRESS + register

'----------------------------------------------------
' SPI Interface
'----------------------------------------------------  
PRI Read(register, buffer, length) | idx, data
  SendCommand(register, READ_OPCODE, length)
  repeat idx from 0 to length-1
    data := spi.WriteRead( 8, $00, $FF ) 
    byte[buffer][idx] := data & $FF

PRI Write(register, buffer, length) | idx, data
  SendCommand(register, WRITE_OPCODE, length)
  repeat idx from 0 to length-1
    data := byte[buffer][idx]
    spi.WriteRead( 8, data, $FF )
    
PRI ReadByte(register) | opcode, data
  SendCommand(register, READ_OPCODE, 1) 
  data := spi.WriteRead( 8, $00, $FF ) 
  return data & $FF

PRI WriteByte(register, value) | idx, data
  SendCommand(register, WRITE_OPCODE, 1)
  spi.WriteRead( 8, value, $FF )
  
PRI SendCommand(register, opcode, length) | cmd
  cmd := (register << 16) + (opcode << 15) + length
  spi.WriteRead( 32, cmd, $FF )


{  } 
 
PUB DebugGet
  return _mode

PUB DebugWorkBuff
  return @workSpace
{  
PUB DebugRead(register, buffer, length)
  Read(register, buffer, length)  
}
{  }   
PUB DebugRead(sock, register, buffer, length)
  Read(GetSocketRegister(sock, register), buffer, length)

PUB DebugReadWord(socket, register)
  Read(GetSocketRegister(socket, register), @workSpace, 2)
  return DeserializeWord(@workSpace)

PUB DebugReadByte(socket, register)
  return ReadByte(GetSocketRegister(socket, register))
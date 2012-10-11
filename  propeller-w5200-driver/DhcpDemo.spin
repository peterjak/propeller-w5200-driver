CON
  _clkmode = xtal1 + pll16x     
  _xinfreq = 5_000_000

  BUFFER_2K         = $800
  BUFFER_16         = $10
  
  CR                = $0D
  LF                = $0A
  DHCP_OPTIONS      = $F0
  DHCP_END          = $FF
  HARDWARE_ADDR_LEN = $06
  MAGIC_COOKIE_LEN  = $04
  UPD_HEADER_LEN    = $08
  MAX_DHCP_OPTIONS  = $10
  DHCP_PACKET_LEN        = $156 '342
  
  #0, CLOSED, TCP, UDP, IPRAW, MACRAW, PPPOE

  {{ DHCP Packet Pointers }}
  DHCP_OP            = $00
  DHCP_HTYPE         = $01
  DHCP_HLEN          = $02
  DHCP_HOPS          = $03
  DHCP_XID           = $04
  DHCP_SEC           = $08
  DHCP_FLAGS         = $0A
  DHCP_CIADDR        = $0C  
  DHCP_YIADDR        = $10
  DHCP_SIADDR        = $14
  DHCP_GIADDR        = $18
  DHCP_CHADDR        = $1C
  DHCP_BOOTP         = $2C
  DHCP_MAGIC_COOKIE  = $EC
  DHCP_DHCP_OPTIONS  = $F0

  {{ DHCP Options Enum}}
  SUBNET_MASK         = 01
  ROUTER              = 03
  DOMAIN_NAME_SERVER  = 06
  HOST_NAME           = 12
  REQUEST_IP          = 50
  MESSAGE_TYPE        = 53
  DHCP_SERVER_IP      = 54
  PARAM_REQUEST       = 55
  
  

  {{ DHCP Message Types}}
  DHCP_DISCOVER       = 1       
  DHCP_OFFER          = 2       
  DHCP_REQUEST        = 3       
  DHCP_DECLINE        = 4       
  DHCP_ACK            = 5       
  DHCP_NAK            = 6       
  DHCP_RELEASE        = 7      
                        
       
VAR
DAT
  magicCookie     byte  $63, $82, $53, $63
  paramReq        byte  $01, $03, $06, $2A ' Paramter Request; mask, router, domain name server, network time
  hostName        byte  "PropNet5200", $0 
  workspace       byte  $0[BUFFER_16]  
  buff            byte  $0[BUFFER_2K]

  optionPtr       long  $F0
  buffPtr         long  $00
  transId         long  $00
  null            long  $0

   
OBJ
  pst           : "Parallax Serial Terminal"
  sock          : "Socket"
  wiz           : "W5200"


 
PUB Init | ptr

  buffPtr := @buff

  pst.Start(115_200)
  pause(500)

  pst.str(string("Initialize", CR))
  CreateTransactionId

  'Wiz Mac and Ip
  wiz.Init
  'wiz.SetIp(192, 168, 1, 107)
  wiz.SetIp(0, 0, 0, 0) 
  wiz.SetMac($00, $08, $DC, $16, $F8, $01)
  
  'DHCP Port, Mac and Ip 
  sock.Init(0, UDP, 68)

  'Broadcast to port 67
  sock.RemoteIp(255, 255, 255, 255)
  'sock.RemoteIp(0,0,0,0)
  'sock.RemoteIp(192, 168, 1, 1)
  sock.RemotePort(67)

  pst.str(string("Remote IP: "))
  PrintIp(wiz.GetRemoteIP(0))
  pst.char(CR)

  'DHCP Process

  pst.str(string(CR, "Send Discover", CR))
  ptr := Discover
  if(ptr == @null)
    pst.str(string(CR, "Error: Discover", CR))
      return

  pst.str(string(CR, "Receive Offer", CR))       
  Offer

  pst.str(string(CR, "Send Request", CR))  
  ptr := Request
  if(ptr == @null)
    pst.str(string(CR, "Error: Request", CR))
      return

  pst.str(string(CR, "Receive Ack", CR))
  if(Ack)
    pst.str(string("IP Assigned......."))
  else
    pst.str(string("DHCP Failed", CR))

  PrintIp(wiz.GetIp)

  pst.str(string(CR, "DNS..............."))
  PrintIp(wiz.GetDns)

  pst.str(string(CR, "DHCP Server......."))
  printIp(wiz.GetDhcpServerIp)

  pst.str(string(CR, "Router IP........."))
  printIp(wiz.GetRouter)
  pst.char(CR)

  sock.Close


PUB Discover | len
  'optionPtr is a global pointer used in the
  'WriteDhcpOption and ReadDhcpOption methods
  optionPtr := DHCP_OPTIONS + buffPtr
  
  FillOpHtypeHlenHops($01, $01, $06, $00)
  
  FillTransactionID
  FillMac
  FillMagicCookie
  WriteDhcpOption(MESSAGE_TYPE, 1, DHCP_DISCOVER)
  WriteDhcpOption(REQUEST_IP, 4, wiz.GetCommonRegister(wiz#SOURCE_IP0))
  WriteDhcpOption(PARAM_REQUEST, 4, @paramReq)
  WriteDhcpOption(HOST_NAME, strsize(@hostName), @hostName)
  len := EndDhcpOptions
  DisplayMemory(buffPtr, len, true)
  return SendReceive(buffPtr, len)

  
PUB Offer | len
  optionPtr := DHCP_OPTIONS + buffPtr
  
  buffPtr += UPD_HEADER_LEN
  
  GetIp
  len := ReadDhcpOption(DOMAIN_NAME_SERVER)
  
  Wiz.copyDns(optionPtr, len)
  
  GetGateway

  len := ReadDhcpOption(SUBNET_MASK)
  wiz.CopySubnet(optionPtr, len)

  len := ReadDhcpOption(ROUTER)
  wiz.CopyRouter(optionPtr, len)

  len := ReadDhcpOption(DHCP_SERVER_IP)
  wiz.CopyDhcpServer(optionPtr, len) 
  
  buffPtr -= UPD_HEADER_LEN

PUB Request | len
  optionPtr := DHCP_OPTIONS + buffPtr
  
  'Broadcast - There must be a bug if I have to decalre the RemoteIP again?
  'Or maybe it is because the internal register updated - bet that's it!
  'sock.RemoteIp(255, 255, 255, 255)
  'sock.RemoteIp(0,0,0,0)
  'sock.RemotePort(67)

  'pst.str(string("Remote IP: "))
  'PrintIp(wiz.GetRemoteIP(0))
  'pst.char(CR)
  
  bytefill(@buff, 0, BUFFER_2K)
  FillOpHtypeHlenHops($01, $01, $06, $00)
  FillTransactionID
  FillMac
  FillServerIp
  FillMagicCookie
  WriteDhcpOption(MESSAGE_TYPE, 1, DHCP_REQUEST)
  WriteDhcpOption(REQUEST_IP, 4, wiz.GetCommonRegister(wiz#SOURCE_IP0))
  WriteDhcpOption(DHCP_SERVER_IP, 4, wiz.GetDhcpServerIp)
  WriteDhcpOption(HOST_NAME, strsize(@hostName), @hostName)
  len := EndDhcpOptions
  DisplayMemory(buffPtr, len, true)
  return SendReceive(buffPtr, len)

PUB Ack | len
  optionPtr := DHCP_OPTIONS + buffPtr
  
  buffPtr += UPD_HEADER_LEN
  len := ReadDhcpOption(MESSAGE_TYPE)
  buffPtr -= UPD_HEADER_LEN
  return byte[optionPtr] == DHCP_ACK   

PUB GetIp | ptr
  ptr := @byte[buffPtr][DHCP_YIADDR]
  pst.str(string("Assigned IP: "))
  PrintIP(ptr)
  pst.char(CR)
  Wiz.SetIp(byte[ptr][0], byte[ptr][1], byte[ptr][2], byte[ptr][3])
  

PUB GetGateway | ptr
  ptr := @byte[buffPtr][DHCP_SIADDR]
  pst.str(string("Gateway IP: "))
  PrintIP(ptr)
  pst.char(CR) 
  Wiz.SetGateway(byte[ptr][0], byte[ptr][1], byte[ptr][2], byte[ptr][3])


PUB FillOpHTypeHlenHops(op, htype, hlen, hops)
  byte[buffPtr][DHCP_OP] := op
  byte[buffPtr][DHCP_HTYPE] := htype
  byte[buffPtr][DHCP_HLEN] := hlen
  byte[buffPtr][DHCP_HOPS] := hops  


PUB CreateTransactionId
  transId := CNT
  ?transId
  
PUB FillTransactionID
  long[buffPtr+DHCP_XID] := transId

PUB FillMac
  bytemove(buffPtr+DHCP_CHADDR, wiz.GetCommonRegister(wiz#MAC0), HARDWARE_ADDR_LEN)    

PUB FillServerIp
  bytemove(buffPtr+DHCP_SIADDR, wiz.GetDhcpServerIp, 4)

  
PUB FillMagicCookie
  bytemove(buffPtr+DHCP_MAGIC_COOKIE, @magicCookie, MAGIC_COOKIE_LEN)


PUB WriteDhcpOption(option, len, data)
  byte[optionPtr++] := option
  byte[optionPtr++] := len
  
  if(len == 1)
    byte[optionPtr] := data
  else
    bytemove(optionPtr, data, len)
    
  optionPtr += len

PUB ReadDhcpOption(option) | len
  'Init pointer to options
  optionPtr := DHCP_OPTIONS + buffPtr

  'Repeat until we reach the end of the UPD packet
  repeat MAX_DHCP_OPTIONS

    if(byte[optionPtr] == DHCP_END)
      return -2
  
    if(byte[optionPtr++] == option)
      'return len and set the pointer to the data (hub) address
      return byte[optionPtr++]

    'point to the next option code 
    optionPtr += byte[optionPtr] + 1

  return -1 
      
  
PUB EndDhcpOptions | len
  byte[optionPtr] := DHCP_END
  return DHCP_PACKET_LEN
  
PUB SendReceive(buffer, len) | bytesToRead, ptr 
  
  bytesToRead := 0

  pst.str(string("Send Bytes......."))
  pst.dec(len)             
  pst.char(CR)

  sock.Open
  sock.Send(buffer, len)
  
  pause(500)

  bytesToRead := sock.Available
  pst.str(string("Bytes to Read...."))
  pst.dec(bytesToRead)
  pst.char(13)
  pst.char(13)
   
  'Check for a timeout
  if(bytesToRead =< 0 )
    bytesToRead~
    return @null

  if(bytesToRead > 0) 
    'Get the Rx buffer  
    ptr := sock.Receive(buffer, bytesToRead)
    PrintDebug(buffer,bytesToRead)

  sock.Disconnect
  return ptr

PUB PrintDebug(buffer,bytesToRead)
  pst.char(CR)
  pst.str(string(CR, "Message from: "))
  PrintIp(buffer)
  pst.char(":")
  pst.dec(DeserializeWord(buffer + 4))
  pst.str(string(" ("))
  pst.dec(DeserializeWord(buffer + 6))
  pst.str(string(")", CR))
   
  DisplayMemory(buffer+8, bytesToRead-8, true)
  
PUB DisplayMemory(addr, len, isHex) | j
  pst.str(string(13,"-----------------------------------------------------",13))
  pst.str(string(13, "      "))
  repeat j from 0 to $F
    pst.hex(j, 2)
    pst.char($20)
  pst.str(string(13, "      ")) 
  repeat j from 0 to $F
    pst.str(string("-- "))

  pst.char(13) 
  repeat j from 0 to len
    if(j == 0)
      pst.hex(0, 4)
      pst.char($20)
      pst.char($20)
      
    if(isHex)
      pst.hex(byte[addr + j], 2)
    else
      pst.char($20)
      if(byte[addr+j] == 0)
        pst.char($20)
      pst.char(byte[addr+j])

    pst.char($20) 
    if((j+1) // $10 == 0) 
      pst.char($0D)
      pst.hex(j+1, 4)
      pst.char($20)
      pst.char($20)  
  pst.char(13)
  
  pst.char(13)
  pst.str(string("Start: "))
  pst.dec(addr)
  pst.str(string(" Len: "))
  pst.dec(len)
  pst.str(string(13,"-----------------------------------------------------",13,13))
      
PUB PrintIp(addr) | i
  repeat i from 0 to 3
    pst.dec(byte[addr][i])
    if(i < 3)
      pst.char($2E)
    'else
      'pst.char($0D)
      
PRI SerializeWord(value, buffer)
  byte[buffer++] := (value & $FF00) >> 8
  byte[buffer] := value & $FF

PRI DeserializeWord(buffer) | value
  value := byte[buffer++] << 8
  value += byte[buffer]
  return value
        
PRI pause(Duration)  
  waitcnt(((clkfreq / 1_000 * Duration - 3932) #> 381) + cnt)
  return
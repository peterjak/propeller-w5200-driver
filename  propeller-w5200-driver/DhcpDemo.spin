CON
  _clkmode = xtal1 + pll16x     
  _xinfreq = 5_000_000

  BUFFER_2K         = $800
  BUFFER_16         = $10
  
  CR                = $0D
  LF                = $0A
  NULL              = $00
  DHCP_OPTIONS      = $F0
  DHCP_END          = $FF
  HARDWARE_ADDR_LEN = $06
  MAGIC_COOKIE_LEN  = $04
  UPD_HEADER_LEN    = $08
  
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
  DOMAIN_NAME_SERVER  = 06
  REQUEST_IP          = 50
  MESSAGE_TYPE        = 53
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
  workspace       byte  $0[BUFFER_16]  
  buff            byte  $0[BUFFER_2K]

  optionPtr       long  $F0
  buffPtr         long  $00

   
OBJ
  pst           : "Parallax Serial Terminal"
  sock          : "Socket"
  wiz           : "W5200"


 
PUB Init

  buffPtr := @buff '+ UPD_HEADER_LEN
  
  
  pst.Start(115_200)
  pause(500)

  pst.str(string("Initialize", CR))

  'DHCP Port
  sock.Init(0, UDP, 68)

  'Wiz Mac and Ip
  sock.Mac($00, $08, $DC, $16, $F8, $01)
  sock.Ip(192, 168, 1, 107)

  'Broadcast
  sock.RemoteIp(255, 255, 255, 255)
  sock.RemotePort(67)

  optionPtr := DHCP_OPTIONS + buffPtr
  Discover

  optionPtr := DHCP_OPTIONS + buffPtr 
  Offer

PUB Discover | len
  FillOpHtypeHlenHops($01, $01, $06, $00)
  FillTransactionID
  FillMac
  FillMagicCookie
  WriteDhcpOption(MESSAGE_TYPE, 1, DHCP_DISCOVER)
  WriteDhcpOption(REQUEST_IP, 4, wiz.GetCommonRegister(wiz#SOURCE_IP0))
  WriteDhcpOption(PARAM_REQUEST, 4, @paramReq) 
  len := EndDhcpOptions
  DisplayMemory(buffPtr, len, true)
  SendReceive(buffPtr, len)

  
PUB Offer | len
  buffPtr += UPD_HEADER_LEN
  
  GetIp
   'DeserializeWord(@buff + 6)
  'len := ReadDhcpOption(MESSAGE_TYPE, DeserializeWord(@buff + 6))
  len := ReadDhcpOption(DOMAIN_NAME_SERVER)
  'len := ReadDhcpOption($36)
  pst.dec(len)
  pst.char(13)
  PrintIP(optionPtr)
  
  buffPtr -= UPD_HEADER_LEN   

PUB GetIp
  'pst.dec(buffPtr)
  'DisplayMemory(@byte[buffPtr][DHCP_YIADDR], 10, true)
  PrintIP(@byte[buffPtr][DHCP_YIADDR])



PUB FillOpHTypeHlenHops(op, htype, hlen, hops)
  byte[buffPtr][DHCP_OP] := op
  byte[buffPtr][DHCP_HTYPE] := htype
  byte[buffPtr][DHCP_HLEN] := hlen
  byte[buffPtr][DHCP_HOPS] := hops  
  
PUB FillTransactionID | transId
  transId := CNT
  long[buffPtr+DHCP_XID] := ?transId

PUB FillMac
  bytemove(buffPtr+DHCP_CHADDR, wiz.GetCommonRegister(wiz#MAC0), HARDWARE_ADDR_LEN)    

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
  repeat 20 '(optionPtr - buffPtr) > len

    if(byte[optionPtr] == $FF)
      return -2
  
    if(byte[optionPtr++] == option)
      'return len and set the pointer to the data (hub) address
      return byte[optionPtr++]

    'point to the next option code 
    optionPtr += byte[optionPtr] + 1

  return -1 
      
  
PUB EndDhcpOptions | len
  byte[optionPtr] := DHCP_END
  return ((optionPtr-buffPtr) // 16) + (optionPtr-buffPtr) + 1
 

PUB SendReceive(buffer, len) | receiving, bytesToRead, ptr 
  
  bytesToRead := 0

  pst.str(string("Send Bytes: "))
  pst.dec(len)             
  pst.char(CR)
  
  pst.str(string("Open",CR))
  sock.Open
  
  pst.str(string("Send Message",CR))
  
  sock.Send(buffer, len)

  receiving := true
  repeat while receiving 
    'Data in the buffer?
    bytesToRead := sock.Available
    pst.str(string("Bytes to Read: "))
    pst.dec(bytesToRead)
    pst.char(13)
    pst.char(13)
     
    'Check for a timeout
    if(bytesToRead < 0)
      receiving := false
      pst.str(string("Done Receiving Data", CR))
      next

    if(bytesToRead > 0) 
      'Get the Rx buffer  
      ptr := sock.Receive(buffer)
      pst.char(CR)
      pst.str(string("UPD Header:",CR))
      PrintIp(buffer)
      pst.dec(DeserializeWord(buffer + 4))
      pst.char(CR)
      pst.dec(DeserializeWord(buffer + 6))
      pst.char(CR)
       
      pst.char(CR) 
      DisplayMemory(ptr, DeserializeWord(@buff + 6), true) 
      pst.char(CR)
      
    bytesToRead~

  pst.str(string(CR, "Disconnect", CR)) 
  sock.Disconnect


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
    else
      pst.char($0D)
      
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

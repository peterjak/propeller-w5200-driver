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
  DHCPDISCOVER   byte $01, $01, $06, $00, { Options: OP, HTYPE, HLEN, HOPS
}                     $39, $03, $F3, $26, { Trqansaction ID
}                     $00, $00, $00, $00, { SECS, FLAGS
}                     $00, $00, $00, $00, { Client IP
}                     $00, $00, $00, $00, { Your IP
}                     $00, $00, $00, $00, { Server IP
}                     $00, $00, $00, $00, { Gateway IP
}                     $00, $08, $DC, $16, { Mac (client hardware address)
}                     $F8, $01, $00, $00, { Padding
}                     $00, $00, $00, $00, { Padding 
}                     $00, $00, $00, $00, { Padding
}                     $0[64], $0[128],    { 0x44 Host name |  Boot file name
}                     $63, $82, $53, $63, { Magic cookie
}                     $35, $01, $01,      { DHCP Message = Discover
}                     $32, $04, $C0, $A8, $01, $6B, { IP Request
}                     $37, $04, $01, $03, $06, $2A, { Paramter Request; mask, router, domain name server, network time 
}                     $FF 
  padDiscover    byte $0[$200]
                                            
  DHCPREQUEST    byte $01, $01, $06, $00, { Options: OP, HTYPE, HLEN, HOPS
}                     $39, $03, $F3, $26, { Trqansaction ID
}                     $00, $00, $00, $00, { SECS, FLAGS
}                     $00, $00, $00, $00, { Client IP
}                     $00, $00, $00, $00, { Your IP
}                     $C0, $A8, $01, $01, { Server IP
}                     $00, $00, $00, $00, { Gateway IP switched by relay
}                     $00, $08, $DC, $16, { Mac (client hardware address)
}                     $F8, $01, $00, $00, { Padding
}                     $00, $00, $00, $00, { Padding 
}                     $00, $00, $00, $00, { Padding
}                     $0[192],            { overflow space for additional options 
}                     $63, $82, $53, $63, { Magic cookie
}                     $35, $01, $03,                    { DHCP Message  = Request
}                     $32, $04, $C0, $A8, $01, $82,     { Requested IP
}                     $36, $04, $C0, $A8, $01, $01,     { DHCP Server
}                     $FF
  padRequest       byte $0[$200]
  padOffer         byte $02, $01, $06, $00, $60, $A3, $21, $31, $00, $00, $00, $00, $00, $00, $00, $00, {
}                       $C0, $A8, $02, $02, $C0, $A8, $02, $10, $00, $00, $00, $00, $00, $08, $DC, $16, {
}                       $F8, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, {
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, {
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, {
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, {
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, {
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, {
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, {
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, {
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, {
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, {
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, {
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, {
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $63, $82, $53, $63, {
}                       $35, $01, $02, $01, $04, $FF, $FF, $FF, $00, $03, $04, $C0, $A8, $02, $FE, $06, {
}                       $04, $C0, $A8, $02, $FE, $0F, $03, $6C, $61, $6E, $36, $04, $C0, $A8, $02, $FE, {
}                       $33, $04, $00, $01, $51, $80, $FF, $00, $00, $00, $00, $00, $00, $00, $00, $00, {
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, {
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, {
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, {
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, {
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, {
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, {
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, {
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, {
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, {
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, {
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, {
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, {
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, {
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, {
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, {
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, {
}                       $00, $00, $00, $00, $00

  padAck        byte    $02, $01, $06, $00, $60, $A3, $21, $31, $00, $00, $00, $00, $00, $00, $00, $00,{
}                       $C0, $A8, $02, $02, $00, $00, $00, $00, $00, $00, $00, $00, $00, $08, $DC, $16,{
}                       $F8, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,{
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,{
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,{
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,{
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,{
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,{
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,{
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,{
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,{
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,{
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,{
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,{
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $63, $82, $53, $63,{
}                       $35, $01, $05, $01, $04, $FF, $FF, $FF, $00, $03, $04, $C0, $A8, $02, $FE, $06,{
}                       $04, $C0, $A8, $02, $FE, $0F, $03, $6C, $61, $6E, $36, $04, $C0, $A8, $02, $FE,{
}                       $33, $04, $00, $01, $51, $80, $FF, $00, $00, $00, $00, $00, $00, $00, $00, $00,{
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,{
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,{
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,{
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,{
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,{
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,{
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,{
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,{
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,{
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,{
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,{
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,{
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,{
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,{
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,{
}                       $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00,{
}                       $00, $00, $00, $00, $00

  buff            byte  $0[BUFFER_2K]
  optionPtr       long  $F0
  buffPtr         long  $00
  transId         long  $00
  null            long  $00

OBJ
  pst           : "Parallax Serial Terminal"
  sock          : "Socket"
  wiz           : "W5200"


PUB Offer | len, hasGateway
  buffPtr :=  @padOffer
  optionPtr := DHCP_OPTIONS + buffPtr
  
  'buffPtr += UPD_HEADER_LEN
  
  GetIp
  
  len := ReadDhcpOption(DOMAIN_NAME_SERVER)
  Wiz.copyDns(optionPtr, len)
  pst.str(string("DNS_SERVER........"))
  PrintIP(optionPtr)
  
  hasGateway := GetGateway

  len := ReadDhcpOption(SUBNET_MASK)
  wiz.CopySubnet(optionPtr, len)
  pst.str(string("SUBNET_MASK......."))
  PrintIP(optionPtr)

  len := ReadDhcpOption(ROUTER)
  wiz.CopyRouter(optionPtr, len)
  pst.str(string("ROUTER............"))
  PrintIP(optionPtr)

  ifnot(hasGateway)
    Wiz.SetGateway(byte[optionPtr][0], byte[optionPtr][1], byte[optionPtr][2], byte[optionPtr][3])
    pst.str(string("GATEWAY..........."))
    PrintIP(optionPtr)   

  len := ReadDhcpOption(DHCP_SERVER_IP)
  wiz.CopyDhcpServer(optionPtr, len)
  pst.str(string("DHCP_SERVER_IP...."))
  PrintIP(optionPtr) 
  
  'buffPtr -= UPD_HEADER_LEN

PUB TestPacket
  pst.Start(115_200)
  pause(500)

  wiz.Init
  wiz.SetIp(0, 0, 0, 0) 
  wiz.SetMac($00, $08, $DC, $16, $F8, $01)
  
  Offer

  pst.str(string(CR, "DNS..............."))
  PrintIp(wiz.GetDns)

  pst.str(string(CR, "DHCP Server......."))
  printIp(wiz.GetDhcpServerIp)

  pst.str(string(CR, "Router IP........."))
  printIp(wiz.GetRouter)
  pst.char(CR)
  
PUB Ack | len
  'buffPtr += UPD_HEADER_LEN
  len := ReadDhcpOption(MESSAGE_TYPE)
  'buffPtr -= UPD_HEADER_LEN
  
  return byte[optionPtr] == DHCP_ACK
  
PUB GetIp | ptr
  ptr := buffPtr + DHCP_YIADDR
  pst.str(string("Assigned IP:......"))
  PrintIP(ptr)
  pst.char(CR)
  Wiz.SetIp(byte[ptr][0], byte[ptr][1], byte[ptr][2], byte[ptr][3])

  

PUB GetGateway | ptr
  ptr := buffPtr + DHCP_SIADDR
  if( byte[ptr][0] == null AND byte[ptr][1] == null AND  byte[ptr][2] == null AND byte[ptr][3] == null)
    return false
  else
    pst.str(string("Gateway IP:......."))
    PrintIP(ptr)
    pst.char(CR) 
    Wiz.SetGateway(byte[ptr][0], byte[ptr][1], byte[ptr][2], byte[ptr][3])
    return true  


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
   
PUB Main | bytesToRead, buffer, bytesSent, receiving, ptr, len
  {{
    TODO: Make the Demo
  }}
  bytesToRead := 0
  pst.Start(115_200)
  pause(500)

  'bytemove(@DHCPDISCOVER + (4*11), string("PropNet"), strsize(string("PropNet")))
  'bytemove(@DHCPREQUEST + (4*11), string("PropNet"), strsize(string("PropNet"))) 

  len := @padDiscover - @DHCPDISCOVER
  'len := @padRequest - @DHCPREQUEST
  
  len += len // 16 + 16
  pst.str(string("DHCP Options Len: "))
  pst.dec(len)
  pst.char(CR)


  pst.str(string("Initialize", CR))

  'Set network parameters
  wiz.Init
  wiz.SetCommonnMode(0)
  wiz.SetGateway(192, 168, 1, 1)
  wiz.SetSubnetMask(255, 255, 255, 0)
  wiz.SetIp(192, 168, 1, 107)
  wiz.SetMac($00, $08, $DC, $16, $F8, $01)
  
  'DHCP Port
  buffer := sock.Init(0, UDP, 68)

  'Broadcast
  sock.RemoteIp(255, 255, 255, 255)
  sock.RemotePort(67)
  
  pst.str(string("Start UPD Client",CR))
  pst.str(string("Open",CR))
  sock.Open
  
  pst.str(string("Send Message",CR))
  
  sock.Send(@DHCPDISCOVER, len)
  'sock.Send(@DHCPREQUEST, len)

  receiving := true
  repeat while receiving 
    'Data in the buffer?
    bytesToRead := sock.Available
    pst.str(string("Bytes to Read: "))
    pst.dec(bytesToRead)
    pst.char(13)
    pst.char(13)
     
    'Check for a timeout
    if(bytesToRead == -1)
      receiving := false
      pst.str(string("Fail safe", CR))
      next

    if(bytesToRead == 0)
      receiving := false
      pst.str(string("Done", CR))
      next 

    if(bytesToRead > 0) 
      'Get the Rx buffer  
      ptr := sock.Receive(@buff, bytesToRead)
      pst.char(CR)
      pst.str(string("UPD Header:",CR))
      PrintIp(@buff)
      pst.dec(DeserializeWord(@buff + 4))
      pst.char(CR)
      pst.dec(DeserializeWord(@buff + 6))
      pst.char(CR)
       
      pst.char(CR) 
      DisplayMemory(ptr, DeserializeWord(@buff + 6), true) 
      pst.char(CR)
      
    bytesToRead~

  pst.str(string(CR, "Disconnect", CR)) 
  sock.Disconnect

  
   
  DisplayMemory(ptr, 36, true)



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
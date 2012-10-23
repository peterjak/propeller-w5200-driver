CON
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

  DELAY               = 0

  #0, SUCCESS, DISCOVER_ERROR, OFFER_ERROR, REQUEST_ERROR, ACK_ERROR      
                        
       
VAR

DAT
  noErr           byte  "Success", 0
  errDis          byte  "Discover Error", 0
  errOff          byte  "Offer Error", 0
  errReq          byte  "Request Error", 0
  errAck          byte  "Ack Error", 0
  errorCode       byte  $00
  magicCookie     byte  $63, $82, $53, $63
  paramReq        byte  $01, $03, $06, $2A ' Paramter Request; mask, router, domain name server, network time
  hostName        byte  "PropNet_5200", $0 
  optionPtr       long  $F0
  buffPtr         long  $00
  transId         long  $00
  null            long  $00
  errors          long  @noErr, @errDis, @erroff, @errReq, @errAck
  

   
OBJ
  sock          : "Socket"
  wiz           : "W5200" 
 
PUB Init(buffer, socket)

  buffPtr := buffer

  'Set up the socket 
  sock.Init(socket, UDP, 68)

  'Broadcast on port 67
  sock.RemoteIp(255, 255, 255, 255)   
  sock.RemotePort(67)

PUB GetErrorCode
  return errorCode

PUB GetErrorMessage
  return @@errors[errorCode]

PUB GetIp
  return wiz.GetCommonRegister(Wiz#SOURCE_IP0)  
  
PUB DoDhcp | ptr

  CreateTransactionId
  errorCode := 0
  
  ptr := Discover
  if(ptr == @null)
    errorCode := DISCOVER_ERROR
    sock.Close 
    return false   
      
  Offer
  
  ptr := Request
  if(ptr == @null)
    errorCode := REQUEST_ERROR
    sock.Close 
    return false
    
  ifnot(Ack)
    sock.Close
    return false 

  sock.Close 
  return true

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
  return SendReceive(buffPtr, len)

  
PUB Offer | len
  optionPtr := DHCP_OPTIONS + buffPtr

  'Move the pointer 8 bytes to the right
  'On receive the first 8 bytes in the UDP packet are IP:Port and len
  buffPtr += UPD_HEADER_LEN

  'Set the IP
  GetSetIp

  ' Set DNS server IP
  len := ReadDhcpOption(DOMAIN_NAME_SERVER)
  Wiz.copyDns(optionPtr, len)

  'Set the Gateway IP
  'GetSetGateway

  'Set the ubnet mask
  len := ReadDhcpOption(SUBNET_MASK)
  wiz.CopySubnet(optionPtr, len)

  'Set the router IP to the Gateway
  'Mike G 10/16/2012
  'From research and asking network guys the router IP (option 3)
  'should also be the gateway.
  len := ReadDhcpOption(ROUTER)
  wiz.CopyRouter(optionPtr, len)
  Wiz.CopyGateway(optionPtr, len)

  'Set the DHCP server IP
  len := ReadDhcpOption(DHCP_SERVER_IP)
  wiz.CopyDhcpServer(optionPtr, len) 

  'Reset the pointer
  buffPtr -= UPD_HEADER_LEN

PUB Request | len
  optionPtr := DHCP_OPTIONS + buffPtr
  
  bytefill(buffPtr, 0, BUFFER_2K)
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
  return SendReceive(buffPtr, len)

PUB Ack | len
  buffPtr += UPD_HEADER_LEN
  
  optionPtr := DHCP_OPTIONS + buffPtr
  len := ReadDhcpOption(MESSAGE_TYPE)
  
  buffPtr -= UPD_HEADER_LEN
  
  return byte[optionPtr] == DHCP_ACK   

PUB GetSetIp | ptr
  'ptr := @byte[buffPtr][DHCP_YIADDR]
  ptr := buffPtr + DHCP_YIADDR
  Wiz.SetIp(byte[ptr][0], byte[ptr][1], byte[ptr][2], byte[ptr][3])
  
{  Deprecated
PUB GetSetGateway | ptr
  ptr := buffPtr + DHCP_SIADDR
  if( byte[ptr][0] == null AND byte[ptr][1] == null AND  byte[ptr][2] == null AND byte[ptr][3] == null)
    return false
  else
    Wiz.SetGateway(byte[ptr][0], byte[ptr][1], byte[ptr][2], byte[ptr][3])
    return true 
}

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
  'return ((optionPtr-buffPtr) // 16) + (optionPtr-buffPtr) + 1
 
PUB SendReceive(buffer, len) | bytesToRead, ptr 
  
  bytesToRead := 0

  'Open socket and Send Message 
  sock.Open
  sock.Send(buffer, len)

  bytesToRead := sock.Available
   
  'Check for a timeout
  if(bytesToRead == -1 )
    bytesToRead~
    return @null

  'Check for a timeout
  if(bytesToRead == 0 )
    bytesToRead~
    return 0

  if(bytesToRead > 0) 
    'Get the Rx buffer  
    ptr := sock.Receive(buffer, bytesToRead)

  sock.Disconnect
  return ptr
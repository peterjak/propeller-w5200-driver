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

  {{ Packet Types }}
  #0, SUCCESS, DISCOVER_ERROR, OFFER_ERROR, REQUEST_ERROR, ACK_ERROR

  HOST_PORT           = 68
  REMOTE_PORT         = 67
      
                        
       
VAR

DAT
  noErr           byte  "Success", 0
  errDis          byte  "Discover Error", 0
  errOff          byte  "Offer Error", 0
  errReq          byte  "Request Error", 0
  errAck          byte  "Ack Error", 0
  requestIp       byte  00, 00, 00, 00
  'requestIp       byte  192, 168, 1, 110
  errorCode       byte  $00
  magicCookie     byte  $63, $82, $53, $63
  paramReq        byte  $01, $03, $06, $2A ' Paramter Request; mask, router, domain name server, network time
  hostName        byte  "propnet", $0 
  optionPtr       long  $F0
  buffPtr         long  $00_00_00_00
  transId         long  $00_00_00_00
  null            long  $00_00_00_00
  errors          long  @noErr, @errDis, @erroff, @errReq, @errAck
  

   
OBJ
  sock          : "Socket"
  wiz           : "W5200" 
 
PUB Init(buffer, socket)

  buffPtr := buffer

  'Set up the host socket 
  sock.Init(socket, UDP, HOST_PORT)


PUB GetErrorCode
  return errorCode

PUB GetErrorMessage
  return @@errors[errorCode]

PUB GetIp
  return wiz.GetCommonRegister(Wiz#SOURCE_IP0)  

PUB SetRequestIp(octet3, octet2, octet1, octet0)
  requestIp[0] := octet3 
  requestIp[1] := octet2
  requestIp[2] := octet1
  requestIp[3] := octet0

PRI IsRequestIp
   return requestIp[0] | requestIp[1] | requestIp[2] | requestIp[3]

PUB GetRequestIP
  return @requestIp
 
PUB DoDhcp 
  errorCode := 0
  CreateTransactionId

  ifnot(DiscoverOffer)
    sock.Close
    return false

  ifnot(RequestAck) 
    sock.Close
    return false
 
  sock.Close 
  return true

PRI DiscoverOffer | ptr

  InitRequest
  
  ptr := Discover
  if(ptr == @null)
    errorCode := DISCOVER_ERROR
    return false
        
  Offer

  return true

  
PRI RequestAck  | ptr

  InitRequest
  
  ptr := Request
  if(ptr == @null)
    errorCode := REQUEST_ERROR
    return false
    
  ifnot(Ack)
    errorCode := ACK_ERROR
    return false

  return true 

 
PRI InitRequest
  bytefill(buffPtr, 0, DHCP_MAGIC_COOKIE)
  sock.RemoteIp(255, 255, 255, 255)   
  sock.RemotePort(REMOTE_PORT)

  
PRI Discover | len
  'optionPtr is a global pointer used in the
  'WriteDhcpOption and ReadDhcpOption methods
  optionPtr := DHCP_OPTIONS + buffPtr
  
  FillOpHtypeHlenHops($01, $01, $06, $00)
  
  FillTransactionID
  FillMac
  FillMagicCookie
  WriteDhcpOption(MESSAGE_TYPE, 1, DHCP_DISCOVER)
  if(IsRequestIp)
    WriteDhcpOption(REQUEST_IP, 4, @requestIp)
  WriteDhcpOption(PARAM_REQUEST, 4, @paramReq)
  WriteDhcpOption(HOST_NAME, strsize(@hostName), @hostName)
  len := EndDhcpOptions
  return SendReceive(buffPtr, len)

  
PRI Offer | len
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

PRI Request | len
  optionPtr := DHCP_OPTIONS + buffPtr
  
  bytefill(buffPtr, 0, BUFFER_2K)
  FillOpHtypeHlenHops($01, $01, $06, $00)
  FillTransactionID
  FillMac
  FillServerIp
  FillMagicCookie
  WriteDhcpOption(MESSAGE_TYPE, 1, DHCP_REQUEST)
  IsRequestIp
    WriteDhcpOption(REQUEST_IP, 4, @requestIp)
  WriteDhcpOption(DHCP_SERVER_IP, 4, wiz.GetDhcpServerIp)
  WriteDhcpOption(HOST_NAME, strsize(@hostName), @hostName)
  len := EndDhcpOptions
  return SendReceive(buffPtr, len)

PRI Ack | len
  buffPtr += UPD_HEADER_LEN

  optionPtr := DHCP_OPTIONS + buffPtr
  len := ReadDhcpOption(MESSAGE_TYPE)
  
  buffPtr -= UPD_HEADER_LEN
  
  return byte[optionPtr] == DHCP_ACK   

PRI GetSetIp | ptr
  ptr := buffPtr + DHCP_YIADDR
  Wiz.SetIp(byte[ptr][0], byte[ptr][1], byte[ptr][2], byte[ptr][3])
  requestIp[0] := byte[ptr][0]
  requestIp[1] := byte[ptr][1]
  requestIp[2] := byte[ptr][2]
  requestIp[3] := byte[ptr][3] 
  

PRI FillOpHTypeHlenHops(op, htype, hlen, hops)
  byte[buffPtr][DHCP_OP] := op
  byte[buffPtr][DHCP_HTYPE] := htype
  byte[buffPtr][DHCP_HLEN] := hlen
  byte[buffPtr][DHCP_HOPS] := hops  


PRI CreateTransactionId
  transId := CNT
  ?transId
  
PRI FillTransactionID
  bytemove(buffPtr+DHCP_XID, @transId, 4)

PRI FillMac
  bytemove(buffPtr+DHCP_CHADDR, wiz.GetCommonRegister(wiz#MAC0), HARDWARE_ADDR_LEN)    

PRI FillServerIp
  bytemove(buffPtr+DHCP_SIADDR, wiz.GetDhcpServerIp, 4)

  
PRI FillMagicCookie
  bytemove(buffPtr+DHCP_MAGIC_COOKIE, @magicCookie, MAGIC_COOKIE_LEN)


PRI WriteDhcpOption(option, len, data)
  byte[optionPtr++] := option
  byte[optionPtr++] := len
  
  if(len == 1)
    byte[optionPtr] := data
  else
    bytemove(optionPtr, data, len)
    
  optionPtr += len

  
PRI ReadDhcpOption(option) | len
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
      
  
PRI EndDhcpOptions | len
  byte[optionPtr] := DHCP_END
  return DHCP_PACKET_LEN

 
PRI SendReceive(buffer, len) | bytesToRead, ptr 
  
  bytesToRead := 0

  'Open socket and Send Message 
  sock.Open
  sock.Send(buffer, len)

  bytesToRead := sock.Available
   
  'Check for a timeout
  if(bytesToRead == -1 )
    return @null

  'Check for data received
  if(bytesToRead == 0 )
    return 0
    
   'Get the Rx buffer 
  if(bytesToRead > 0) 
    ptr := sock.Receive(buffer, bytesToRead)

  sock.Disconnect
  
  return ptr
CON
  _clkmode = xtal1 + pll16x     
  _xinfreq = 5_000_000

  BUFFER_2K         = $800
  BUFFER_16         = $10
  
  CR                = $0D
  LF                = $0A
  NULL              = $00
  DOT               = $2E 

  
  #0, CLOSED, TCP, UDP, IPRAW, MACRAW, PPPOE

  {{ DNS Packet Enum}}
  TRANSACTION       = $00
  FLAGS             = $02
  QUESTIONS         = $04
  ANSWERS           = $06
  AUTHORITY         = $08
  ADDITIONAL        = $0A
  QUERY             = $0C
  DNS_HEADER_LEN    = QUERY               
       
VAR

DAT
  msgId           word  $0
  dnsHeader       byte  $01, $00,               { Flags
}                       $00, $01,               { Questions
}                       $00, $00,               { Answer RRS
}                       $00, $00,               { Authority RRS
}                       $00, $00                { Additional RRS }

  qtype           byte  $00, $01                { Host address: Type A }
  qclass          byte  $00, $01                { Class: 01 }
               
  rc0             byte  "No error condition." ,$0
  rc1             byte  "Format error", $0
  rc2             byte  "Server failure", $0
  rc3             byte  "Name Error", $0
  rc4             byte  "Not Implemented", $0
  rc5             byte  "Refused", $0
  rc6             byte  "Unknow error", $0
  rcPtr           long  @rc0, @rc1, @rc2, @rc3, @rc4, @rc5, @rc6
  rcode           byte  $0

  dnsServerIp     byte  $00, $00, $00, $00      '68, 105, 28, 12

  ip1             byte  $00, $00, $00, $00
  ip2             byte  $00, $00, $00, $00
  ip3             byte  $00, $00, $00, $00
  ip4             byte  $00, $00, $00, $00
  ip5             byte  $00, $00, $00, $00
  ip6             byte  $00, $00, $00, $00
  ip7             byte  $00, $00, $00, $00
  ip8             byte  $00, $00, $00, $00
  ip9             byte  $00, $00, $00, $00
  ip10            byte  $00, $00, $00, $00
  ip11            byte  $00, $00, $00, $00
  ip12            byte  $00, $00, $00, $00
  dnsIps          long  @ip1, @ip2, @ip3, @ip4, @ip5, @ip6, @ip7, @ip8, @ip9, @ip10, @ip11, @ip12

  
  buffPtr         long  $00
  transId         long  $00

OBJ
  sock          : "Socket"
  wiz           : "W5200"
 
PUB Init(buffer, socket) | dnsPtr

  buffPtr := buffer

  'DHCP Port, Mac and Ip 
  sock.Init(socket, UDP, 8080)

  'Get the default DNS from DHCP
  dnsPtr := wiz.GetDns

  'The DNS IP could be null if DHCP is not used 
  if(dnsPtr > NULL) 
    sock.RemoteIp(byte[dnsPtr][0], byte[dnsPtr][1], byte[dnsPtr][2], byte[dnsPtr][3])
    sock.RemotePort(53)
    
'Use this if you need to manually set DNS
PUB SetDnsServerIp(octet3, octet2, octet1, octet0)
  dnsServerIp[0] := octet3
  dnsServerIp[1] := octet2
  dnsServerIp[2] := octet1
  dnsServerIp[3] := octet0
  wiz.CopyDns(@dnsServerIp, 4)
  sock.RemoteIp(octet3 , octet2, octet1, octet0)
  sock.RemotePort(53)

 
PUB GetResolvedIp(idx)
  if(IsNullIp( @dnsIps[idx] ) )
    return NULL
  return @@dnsIps[idx]

PRI IsNullIp(ipaddr)
  return (byte[ipaddr][0] + byte[ipaddr][1] + byte[ipaddr][2] + byte[ipaddr][3]) == 0 
    
PUB ResolveDomain(url) | ptr
  CreateTransactionId($FFFF)
  FillTransactionID

  'Copy header to the buffer
  bytemove(buffPtr, @msgId, DNS_HEADER_LEN)
  'Format and copy the url
  ptr := ParseUrl(url, buffPtr+DNS_HEADER_LEN)
  'Add the QTYPE and QCLASS
  bytemove(ptr, @QTYPE, 4)
  ptr += 4


  ptr := SendReceive(buffPtr, ptr - buffPtr)
  ParseDnsResponse(ptr)
  return  GetResolvedIp(0)
  
  return  ptr


PRI ParseUrl(src, dest) | ptr
  ptr := src

  repeat strsize(src)
    if ( byte[ptr++] == DOT )
      byte[ptr-1] := NULL                                'Replace dot with a zero
      byte[dest++] := strsize(src)                       'Insert url segment len
      bytemove(dest, src, strsize(src))                  'Insert url segment
      dest += strsize(src)                               'set pointers
      src := ptr

  byte[dest++] := strsize(src)                           'Insert last url segment
  bytemove(dest, src, strsize(src))
  dest += strsize(src)
  byte[dest++] := NULL
  
  return dest


PUB GetRcode(src)

  CreateTransactionId($FFFF)
  FillTransactionID
  
  rcode := byte[src+FLAGS+1] & $000F
  return rcode


PUB RCodeError
  case rcode
    0..5  : return @@rcPtr[rcode]
    other : return @rc6

PUB ParseDnsResponse(buffer) | ptr, i, len, ansRRS

  ansRRS := DeserializeWord(buffer+6)

  'Query
  buffer += $0C
  repeat until byte[buffer++] == $00
  buffer += 4

  'Answer
  if(byte[buffer] & $C0 == $C0)
    buffer +=10
  else
    repeat until byte[buffer++] == $00

  len := DeserializeWord(buffer)

  if(len > 4)
    ansRRS--
    buffer += (2 + len)

      'Answer
    if(byte[buffer] & $C0 == $C0)
      buffer +=10
    else
      repeat until byte[buffer++] == $00

    i := 0
    len := DeserializeWord(buffer)

  buffer += 2

  bytemove(@@dnsIps[i++], buffer, len)


  if(ansRRS-1 < 0)
    return
  
  repeat ansRRS-1
    buffer += 4
    if(byte[buffer] & $C0 == $C0)
      buffer +=10
    else
      repeat until byte[buffer++] == $00
     
    len := DeserializeWord(buffer)
    buffer += 2
    bytemove(@@dnsIps[i++], buffer, len)


PUB CreateTransactionId(mask) 
  transId := CNT
  ?transId
  transId &= mask

PUB FillTransactionID
  word[@msgId] := transId


PRI DeserializeWord(buffer) | value
  value := byte[buffer++] << 8
  value += byte[buffer]
  return value

PUB SendReceive(buffer, len) | receiving, bytesToRead, ptr 
  
  bytesToRead := 0

  'Open and Send Message
  sock.Open 
  sock.Send(buffer, len)

  receiving := true
  repeat while receiving 
    'Data in the buffer?
    bytesToRead := sock.Available
 
    'Check for a timeout
    if(bytesToRead == -1)
      receiving := false
      next

    if(bytesToRead == 0)
      receiving := false
      next 

    if(bytesToRead > 0) 
      'Get the Rx buffer  
      ptr := sock.Receive(buffer, bytesToRead)
      
    bytesToRead~

  'Disconnect
  sock.Disconnect
  return ptr
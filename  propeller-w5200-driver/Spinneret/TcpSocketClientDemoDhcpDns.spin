CON
  _clkmode = xtal1 + pll16x     
  _xinfreq = 5_000_000

  BUFFER_2K     = $800
  
  CR            = $0D
  LF            = $0A
  
  #0, CLOSED, TCP, UDP, IPRAW, MACRAW, PPPOE

  ATTEMPTS      = 5 
  
  USB_Rx        = 31
  USB_Tx        = 30

  { Spinneret PIN IO  }  
  SPI_MISO          = 0 ' SPI master in serial out from slave 
  SPI_MOSI          = 1 ' SPI master out serial in to slave
  SPI_CS            = 2 ' SPI chip select (active low)
  SPI_SCK           = 3  ' SPI clock from master to all slaves
  WIZ_INT           = 13
  WIZ_RESET         = 14
  WIZ_SPI_MODE      = 15

  DHCP_SOCKET       = 3
  DNS_SOCKET        = 2

 
  
       
VAR

DAT
  request       byte  "GET /index.htm HTTP/1.1", CR, LF, {
}               byte  "User-Agent: Wiz5200", CR, LF, CR, LF, $0

  request2      byte  "GET /default.aspx HTTP/1.1", CR, LF, {
}               byte  "Host: agaverobotics.com", CR, LF, {
}               byte  "User-Agent: Wiz5200", CR, LF, CR, LF, $0


  google        byte  "GET /finance/historical?q=FB&output=csv HTTP/1.1", CR, LF, {
}               byte  "Host: finance.google.com", CR, LF, {
}               byte  "User-Agent: Wiz5200", CR, LF, CR, LF, $0

  weather       byte  "GET / HTTP/1.1", CR, LF, {
}               byte  "Host: www.weather.gov", CR, LF, {
}               byte  "User-Agent: Wiz5200", CR, LF, CR, LF, $0

  basicAuthReq  byte  "GET /spinneret/formtest.php HTTP/1.1", CR, LF, {
}               byte  "Host: rcc.cfbtechnologies.com", CR, LF, {
}               byte  "User-Agent: Wiz5200", CR, LF, {
}               byte  "Authorization: Basic dGVzdDojYnhGeFgheWxTR3A=", CR, LF, CR, LF, $0

  buff          byte  $0[BUFFER_2K]

  t1            long  $0
  null          long  $00
  site          byte  "finance.google.com", $0

OBJ
  pst           : "Parallax Serial Terminal"
  wiz           : "W5100"                                                                       
  sock          : "Socket"
  dhcp          : "Dhcp"
  dns           : "Dns"
   

PUB Main | bytesToRead, buffer, bytesSent, receiving, remoteIP, dnsServer, totalBytes, i, dnsInit

  wiz.HardReset(WIZ_RESET)

  receiving := true
  bytesToRead := 0

  dnsInit := 0
                                               
  pst.Start(115_200)      
  pause(500)
  
  pst.str(string("Initialize W5100", CR))
  wiz.Start(SPI_CS, SPI_SCK, SPI_MOSI, SPI_MISO)  
  wiz.SetMac($00, $08, $DC, $16, $F1, $32)
  pause(500)

  pst.str(string("Getting network paramters", CR))
  dhcp.Init(@buff, DHCP_SOCKET)

  pst.str(string("--------------------------------------------------", CR))
 
  pst.str(string("Requesting IP....."))      
  repeat until dhcp.DoDhcp(true)
    if(++t1 > ATTEMPTS)
      quit
   
  if(t1 > ATTEMPTS)
    pst.char(CR) 
    pst.str(string(CR, "DHCP Attempts: "))
    pst.dec(t1)
    pst.str(string(CR, "Error Code: "))
    pst.dec(dhcp.GetErrorCode)
    pst.char(CR)
    pst.str(dhcp.GetErrorMessage)
    pst.char(CR)
    return
  else
    PrintIp(dhcp.GetIp)

  { Stress test   
  repeat
    pst.str(string("Requesting IP....."))
    t1 := 0
    'wiz.SetIp(0,0,0,0)
    repeat until dhcp.RenewDhcp
      if(++t1 > ATTEMPTS)
        quit
    if(t1 > ATTEMPTS)
      pst.char(CR) 
      pst.str(string(CR, "DHCP Attempts: "))
      pst.dec(t1)
      pst.str(string(CR, "Error Code: "))
      pst.dec(dhcp.GetErrorCode)
      pst.char(CR)
      pst.str(dhcp.GetErrorMessage)
      pst.char(CR)
      return
    else
      PrintIp(dhcp.GetIp)
    'pause(2000)
   } 

  pst.str(string("Lease Time........"))
  pst.dec(dhcp.GetLeaseTime)
  pst.char(CR)
 
  pst.str(string("DNS..............."))
  dnsServer := wiz.GetDns
  PrintIp(wiz.GetDns)

  pst.str(string("DHCP Server......."))
  printIp(dhcp.GetDhcpServer)

  pst.str(string("Router............"))
  printIp(dhcp.GetRouter)

  pst.str(string("Gateway..........."))                                        
  printIp(wiz.GetGatewayIp)
  
  pst.char(CR) 

  pst.str(string("DNS Init (bool)..."))
  if(dns.Init(@buff, DNS_SOCKET))
    pst.str(string("True"))
  else
    pst.str(string("False"))
  pst.char(CR)

  pst.str(string("Resolved IP(0)....")) 
  'remoteIP := dns.ResolveDomain(string("www.agaverobotics.com"))
  remoteIP := dns.ResolveDomain(string("finance.google.com"))
  'remoteIP := dns.ResolveDomain(string("google.com"))
  'remoteIP := dns.ResolveDomain(string("www.weather.gov"))
  'remoteIP := dns.ResolveDomain(string("rcc.cfbtechnologies.com"))
   
  PrintIp(remoteIP)
   
  pst.str(string("Resolved IPs......"))
  pst.dec(dns.GetIpCount)
  pst.char(13)
  pst.char(13)
 
   'remoteIP := dns.GetResolvedIp(1) 

  pst.str(string("Initialize Socket"))
  buffer := sock.Init(0, TCP, 8080)
  sock.RemoteIp(byte[remoteIP][0], byte[remoteIP][1], byte[remoteIP][2], byte[remoteIP][3])  
  sock.RemotePort(80) 

  pst.str(string(CR, "Begin Client Web Request", CR))

  'Client
  'pst.str(string("Open Socket", CR))
  sock.Open
  pst.str(string("Status(open)......"))
  pst.hex(sock.GetStatus, 2)
  pst.char(CR)

  sock.Connect

  'repeat until sock.Connect > 1
    'pause(500)  
    'sock.Open
    'pst.str(string("Status(open)......"))
    'pst.hex(sock.GetStatus, 2)
    'pst.char(CR)
    'pause(500)
    
  pst.str(string("Status(conn)......"))
  pst.hex(sock.GetStatus, 2)
  pst.char(CR)
    
  pst.str(string("Connecting to.....")) 
  PrintIp(wiz.GetRemoteIP(0))
  pst.char(CR) 
   
  'Connection?
  repeat until sock.Connected

    pause(100)

  pst.str(string("Sending HTTP Request", CR))
  'bytesSent := sock.Send(@request2, strsize(@request2))
  bytesSent := sock.Send(@google, strsize(@google))
  'bytesSent := sock.Send(@s_google, strsize(@s_google))
  'bytesSent := sock.Send(@weather, strsize(@weather))
  'bytesSent := sock.Send(@basicAuthReq, strsize(@basicAuthReq))
  
  pst.str(string("Bytes Sent........"))
  pst.dec(bytesSent)
  pst.char(13)

  totalBytes := 0
  repeat while receiving 
    'Data in the buffer?
    bytesToRead := sock.Available
    totalBytes += bytesToRead
     
    'Check for a timeout
    if(bytesToRead < 0)
      receiving := false
      pst.str(string("Timeout", CR))
      return

    if(bytesToRead == 0)
      receiving := false
      'pst.str(string(CR, "Done Receiving Response", CR))
      next 

    if(bytesToRead > 0) 
      'Get the Rx buffer  
      buffer := sock.Receive(@buff, bytesToRead)
      'pst.str(buffer)
      
    bytesToRead~

  pst.str(string("Bytes received...."))
  pst.dec(totalBytes)
  pst.char(13)
  
  pst.str(string(CR, "Disconnect", CR, CR)) 
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
      if(byte[addr+j] < $20 OR byte[addr+j] > $7E)
        if(byte[addr+j] == 0)
          pst.char($20)
        else
          pst.hex(byte[addr+j], 2)
      else
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
  i := 0
  repeat i from 0 to 3
    pst.dec(byte[addr][i] & $FF)
    if(i < 3)
      pst.char($2E)
    else
      pst.char($0D)


PRI pause(Duration)  
  waitcnt(((clkfreq / 1_000 * Duration - 3932) #> 381) + cnt)
  return
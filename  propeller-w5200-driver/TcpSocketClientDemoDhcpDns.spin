CON
  _clkmode = xtal1 + pll16x     
  _xinfreq = 5_000_000

  BUFFER_2K     = $800
  
  CR            = $0D
  LF            = $0A
  NULL          = $00
  
  #0, CLOSED, TCP, UDP, IPRAW, MACRAW, PPPOE

  DHCP_ATTEMPTS = 5
  
       
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

  buff          byte  $0[BUFFER_2K]

  t1            long  $0

OBJ
  pst           : "Parallax Serial Terminal"
  wiz           : "W5200"
  sock          : "Socket"
  dhcp          : "Dhcp"
  dns           : "Dns"
   

PUB Main | bytesToRead, buffer, bytesSent, receiving, remoteIP, dnsServer, totalBytes

  receiving := true
  bytesToRead := 0
  pst.Start(115_200)
  pause(500)

  pst.str(string("Initialize W5200", CR))
  wiz.Start(3, 0, 1, 2)
  wiz.SetMac($00, $08, $DC, $16, $F8, $01)

  pst.str(string("Getting network paramters", CR))
  dhcp.Init(@buff, 7)
  pst.str(string("Requesting IP....."))

  repeat until dhcp.DoDhcp
    if(++t1 > DHCP_ATTEMPTS)
      quit

  if(t1 > DHCP_ATTEMPTS)
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

  pst.str(string("DNS..............."))
  dnsServer := wiz.GetDns
  PrintIp(wiz.GetDns)

  pst.str(string("DHCP Server......."))
  printIp(wiz.GetDhcpServerIp)

  pst.str(string("Router IP........."))
  printIp(wiz.GetRouter)

  pst.str(string("Gateway IP........"))                                        
  printIp(wiz.GetGatewayIp)
  
  pst.char(CR) 

  pst.str(string("Resolve domain IP.")) 
  dns.Init(@buff, 6)
  'remoteIP := dns.ResolveDomain(string("www.agaverobotics.com"))
  'remoteIP := dns.ResolveDomain(string("finance.google.com"))
  remoteIP := dns.ResolveDomain(string("www.weather.gov"))

  'pst.str(string(cr, "Remote IP addr: "))
  'pst.dec(remoteIp)
  'pst.char(13)

  'DisplayMemory(remoteIp, 512, true)
  'return  
  'remoteIP := dns.GetResolvedIp(1)
  PrintIp(remoteIP)
  pst.char(CR)

  pst.str(string("Initialize Socket"))
  buffer := sock.Init(0, TCP, 8080)
  sock.RemoteIp(byte[remoteIP][0], byte[remoteIP][1], byte[remoteIP][2], byte[remoteIP][3])  
  sock.RemotePort(80) 

  'PrintIp(wiz.GetRemoteIP(0))
  
  pst.str(string(CR, "Begin Client Web request", CR))
  'wiz.setGateway(0,0,0,0)
  'Client
  pst.str(string("Open", CR))
  sock.Open
  pst.str(string("Connecting to....."))
  sock.Connect

  PrintIp(wiz.GetRemoteIP(0))
  pst.char(CR) 
   
  'Connection?
  repeat until sock.Connected
    pause(100)

  pst.str(string("Send HTTP Header", CR)) 
  'bytesSent := sock.Send(@request2, strsize(@request2))
  'bytesSent := sock.Send(@google, strsize(@google))
  bytesSent := sock.Send(@weather, strsize(@weather))
  pst.str(string("Bytes Sent: "))
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
      pst.str(string("Done", CR))
      next 

    if(bytesToRead > 0) 
      'Get the Rx buffer  
      buffer := sock.Receive(@buff, bytesToRead)
      pst.str(buffer)
      
    bytesToRead~

  pst.str(string("Total Bytes: "))
  pst.dec(totalBytes)
  pst.char(13)
  
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
  repeat i from 0 to 3
    pst.dec(byte[addr][i])
    if(i < 3)
      pst.char($2E)
    else
      pst.char($0D)

PRI pause(Duration)  
  waitcnt(((clkfreq / 1_000 * Duration - 3932) #> 381) + cnt)
  return
CON
  _clkmode = xtal1 + pll16x     
  _xinfreq = 5_000_000

  BUFFER_2K     = $800
  
  CR            = $0D
  LF            = $0A
  NULL          = $00
  
  #0, CLOSED, TCP, UDP, IPRAW, MACRAW, PPPOE
  
       
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

  buff          byte  $0[BUFFER_2K]

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
  ifnot(dhcp.DoDhcp)
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
  remoteIP := dns.ResolveDomain(string("finance.google.com"))
  'remoteIP := dns.GetResolvedIp(1)
  PrintIp(remoteIP)
  pst.char(CR)

  pst.str(string("Initialize Socket"))
  buffer := sock.Init(0, TCP, 8080)
  sock.RemoteIp(byte[remoteIP][0], byte[remoteIP][1], byte[remoteIP][2], byte[remoteIP][3])  
  sock.RemotePort(80) 

  'PrintIp(wiz.GetRemoteIP(0))
  
  pst.str(string(CR, "Begin Client Web request", CR))

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
  bytesSent := sock.Send(@google, strsize(@google))
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
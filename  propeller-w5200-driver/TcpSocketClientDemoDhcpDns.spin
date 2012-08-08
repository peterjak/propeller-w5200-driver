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
   

PUB Main | bytesToRead, buffer, bytesSent, receiving, remoteIP, dnsServer

  receiving := true
  bytesToRead := 0
  pst.Start(115_200)
  pause(500)


  pst.str(string("Initialize W5200", CR))
  wiz.Init
  wiz.SetIp(192, 168, 1, 107)
  wiz.SetMac($00, $08, $DC, $16, $F8, $01)

  pst.str(string("Getting network paramters", CR))
  dhcp.Init(@buff, 7)
  pst.str(string("Requesting IP....."))
  PrintIp(dhcp.DoDhcp)

  pst.str(string("DNS..............."))
  dnsServer := wiz.GetDns
  PrintIp(wiz.GetDns)

  pst.str(string("DHCP Server......."))
  printIp(wiz.GetDhcpServerIp)

  pst.str(string("Router IP........."))
  printIp(wiz.GetRouter)
  pst.char(CR)

  pst.str(string("Resolve domain IP", CR)) 
  dns.Init(@buff, 6)
  'remoteIP := dns.ResolveDomain(string("www.agaverobotics.com"))
  remoteIP := dns.ResolveDomain(string("finance.google.com"))
  
   
  pst.str(string("Initialize", CR))
  buffer := sock.Init(0, TCP, 8080)
  sock.RemoteIp(byte[remoteIP][0], byte[remoteIP][1], byte[remoteIP][2], byte[remoteIP][3])  
  sock.RemotePort(80) 


  pst.str(string(CR, "Begin Client Web request", CR))

  'Client
  pst.str(string("Open", CR))
  sock.Open
  pst.str(string("Connect", CR))
  sock.Connect
   
  'Connection?
  repeat until sock.Connected
    pause(100)

  pst.str(string("Send HTTP Header", CR)) 
  'bytesSent := sock.Send(@request2, strsize(@request2))
  bytesSent := sock.Send(@google, strsize(@google))
  pst.str(string("Bytes Sent: "))
  pst.dec(bytesSent)
  pst.char(13)


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
      pst.str(string("Timeout", CR))
      return

    if(bytesToRead == 0)
      receiving := false
      pst.str(string("Done", CR))
      next 

    if(bytesToRead > 0) 
      'Get the Rx buffer  
      buffer := sock.Receive(@buff)
      pst.str(buffer)
      
    bytesToRead~

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

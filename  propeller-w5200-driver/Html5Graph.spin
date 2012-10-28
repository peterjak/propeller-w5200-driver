CON
  _clkmode = xtal1 + pll16x     
  _xinfreq = 5_000_000

  BUFFER_2K     = $800
  
  CR            = $0D
  LF            = $0A
  NULL          = $00

  SOCKETS       = 7
  
  #0, CLOSED, TCP, UDP, IPRAW, MACRAW, PPPOE

  DHCP_ATTEMPTS = 10  
    
VAR
  long  seed

DAT
  index byte  "HTTP/1.1 200 OK", CR, LF, {
}             "Content-Type: text/html", CR, LF, CR, LF, {
}             "<!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Transitional//EN' 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd'>", CR, LF, {
}             "<html  xmlns='http://www.w3.org/1999/xhtml'>" , CR, LF, {
}             "<head><meta http-equiv='Content-Type' content='text/html; charset=utf-8' />", CR, LF, {
}             "<title>Graph Example</title>", CR, LF, {
}             "<script type='text/javascript' src='http://www.mikegebhard.com/graph.js'></script>", CR, LF, {
}             "<script type='text/javascript'>" , CR, LF, {
}             "window.onload = function() {", CR, LF, {
}             "g_graph = new Graph({", CR, LF, {
}             "'id': 'firstgraph',", CR, LF, {
}             "'strokeStyle': '#819C58',", CR, LF, {
}             "'fillStyle': 'rgba(64,128,0,0.25)',", CR, LF, {
}             "'call': function(){ return ( Math.floor(latestTemp())); }", CR, LF, {
}             "});", CR, LF, {
}             "g_graph2 = new Graph({", CR, LF, {
}             "'id': 'secondgraph',", CR, LF, {
}             "'strokeStyle': '#819C58',", CR, LF, {
}             "'fillStyle': 'rgba(64,128,0,0.25)',", CR, LF, {
}             "'call': function(){ return ( Math.floor(latestHumidity())); }", CR, LF, {
}             "});}", CR, LF, {
}             "</script>", CR, LF, {
}             "<script type='text/javascript'>", CR, LF, {
}             "setInterval(", $22, "getRequest('xmltemp', 'placeholder')", $22, ", 1);", CR, LF, {
}             "</script>", CR, LF, {
}             "</head>", CR, LF, {
}             "<body>", CR, LF, {
}             "<div><span id='placeholder'>10.0</span></div>", CR, LF, {
}             "<div><canvas id='firstgraph' width='600' height='200'></canvas></div>", CR, LF, {
}             "<div><span id='placeholder2'>5.0</span></div>", CR, LF, { 
}             "<div><canvas id='secondgraph' width='600' height='200'></canvas></div>", CR, LF, {
}             "</body>", CR, LF, {
}             "</html>", 0

  xml   byte  "HTTP/1.1 200 OK", CR, LF, {
  }           "Content-Type: text/xml", CR, LF, CR, LF, {
  }           "<?xml version='1.0' encoding='utf-8'?><root><temp>"
  temperature  byte  $30, $30, $2E, $30, "</temp><humidity>"
  humidity     byte  $30, $30, $2E, $30, "</humidity></root>", 0
  
  buff  byte  $0[BUFFER_2K] 

  resPtr long $0[25] 
  
OBJ
  pst             : "Parallax Serial Terminal"
  wiz             : "W5200.spin" 
  sock[SOCKETS]   : "Socket.spin"
  dhcp            : "Dhcp" 
 
PUB Main | i, page, dnsServer

  i := 0
  
  pst.Start(115_200)
  pause(500)
  
  pst.str(string("Initialize W5200", CR))
  wiz.Start(3, 0, 1, 2) 
  wiz.SetMac($00, $08, $DC, $16, $F8, $01)

  pst.str(string("Getting network paramters", CR))
  dhcp.Init(@buff, 7)
  pst.str(string("Requesting IP....."))

  repeat until dhcp.DoDhcp
    if(++i > DHCP_ATTEMPTS)
      quit

  if(dhcp.GetErrorCode > 0 OR i > DHCP_ATTEMPTS)
    pst.char(CR) 
    pst.str(string(CR, "DHCP Attempts: "))
    pst.dec(i)
    pst.str(string(CR, "Error Code: "))
    pst.dec(dhcp.GetErrorCode)
    pst.char(CR)
    pst.str(dhcp.GetErrorMessage)
    pst.char(CR)
    Toggle(19, 1)
    Toggle(20, 1)
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
  pst.char(CR)

  repeat
    pst.str(string("Initialize Sockets",CR))
    repeat i from 0 to SOCKETS-1
      sock[i].Init(i, TCP, 8080)
           
    OpenListeners
    StartListners
    
    pst.str(string("Start Socket server",CR))
    \MultiSocketServer
    pst.str(string("I blew up!"))
    pause(5000)


  
PUB OpenListeners | i
  pst.str(string("Open",CR))
  repeat i from 0 to SOCKETS-1  
    sock[i].Open
      
PUB StartListners | i
  repeat i from 0 to SOCKETS-1
    if(sock[i].Listen)
      pst.str(string("Listen "))
    else
      pst.str(string("Listener failed ",CR))
    pst.dec(i)
    pst.char(CR)

PUB CloseWait | i
  repeat i from 0 to SOCKETS-1
    if(sock[i].IsCloseWait) 
      sock[i].Disconnect
      sock[i].Close
      
    if(sock[i].IsClosed)  
      sock[i].Open
      sock[i].Listen

PUB MultiSocketServer | bytesToRead, i, page, j, x , bytesSent, ptr
  bytesToRead := bytesSent := i := j := x := 0
  repeat
    pst.str(string("TCP Service", CR))
    CloseWait

    {
    repeat j from 0 to SOCKETS-1
      pst.str(string("Socket "))
      pst.dec(j)
      pst.str(string(" = "))
      pst.hex(wiz.GetSocketStatus(j), 2)
      pst.char(13)
    } 
    repeat until sock[i].Connected
      i := ++i // SOCKETS
    {
    pst.str(string("Connected Socket "))
    pst.dec(i)
    pst.char(CR)
    }
    'Data in the buffer?
    repeat until bytesToRead := sock[i].Available
    
    'Check for a timeout
    if(bytesToRead < 0)
      pst.str(string("Timeout",CR))
      sock[i].Disconnect
      sock[i].Open
      sock[i].Listen
      bytesToRead~
      next

    'pst.str(string("Copy Rx Data",CR))
  
    'Get the Rx buffer  
    sock[i].Receive(@buff, bytesToRead)

    {{ Process the Rx data}}
    {
    pst.char(CR)
    pst.str(string("Request:",CR))
    pst.str(@buff)
    }
    pst.str(string("Send Response",CR))
    page :=  ParseResource(@buff)
    
    pst.str(page)
    pst.char(CR)
    pst.str(string("Byte to send "))
    pst.dec(strsize(page))
    pst.char(CR)

    bytesSent := 0
    ptr := page
    repeat until bytesSent == strsize(page)
      bytesSent += sock[i].Send(ptr, strsize(ptr))
      ptr := page + bytesSent

    pst.str(string("Bytes Sent "))
    pst.dec(bytesSent)
    pst.char(CR)
    {
    pst.str(string("Disconnect socket "))
    pst.dec(i)
    pst.char(CR)
    }
    if(sock[i].Disconnect)
      pst.str(string("Disconnected", CR))
    else
      pst.str(string("Force Close", CR))
    sock[i].Open
    sock[i].Listen
    sock[i].SetSocketIR($FF)
    
    i := ++i // SOCKETS
    bytesToRead~

PUB ParseResource(header) | ptr, value, i, done, j
  ptr := header
  i := 0
  done := false

  repeat until IsEndOfLine(byte[ptr])
    if(IsToken(byte[ptr]))
      byte[ptr] := 0
      resPtr[i++] := ++ptr
    else
      ++ptr

    if(ptr - header > 500)
      pst.str(string(CR, "+++++++++++++++[ERROR]++++++++++++++",CR))
      return @index

  resPtr[0] := header
  repeat j from 0 to i-1
    pst.str(string("ID"))
    pst.dec(j)
    pst.char($20)
    pst.str(resPtr[j])
    pst.char(CR)

  repeat j from 0 to i-1
    if(strcomp(resPtr[j], string("HTTP")))
      return @index
      
    if(strcomp(resPtr[j], string("xmltemp")))
      value := GetTemp
      WriteNode(@temperature, value)
      value := GetHumidity
      WriteNode(@humidity, value) 
      return @xml

  if(strcomp(resPtr[j], string("halo")))
    'do something

PUB IsToken(value)
  return lookdown(value: "/", "?", "=", " ")

PUB IsEndOfLine(value)
  return lookdown(value: CR, LF)    

      
{    
PUB ParseResource(header) | ptr, value
  ptr := header
  repeat until byte[ptr++] == $2F '/ forward slash
  if(byte[ptr] == $20) ' space
    return @index
  else
    value := GetTemp
    WriteNode(@temperature, value)
    value := GetHumidity
    WriteNode(@humidity, value) 
    return @xml
 }



PUB GetTemp
  seed := CNT 
  ?seed
  return seed & $8F + 5

PUB GetHumidity
  seed := CNT 
  ?seed
  return !seed & $7F + 1
    
PUB WriteNode(buffer, value) | t1
  t1 := value
  t1 := t1/100
  value -= t1 * 100
  byte[buffer][0] := t1 + $30

  t1 := value
  t1 := t1/10
  value -= t1 * 10
  byte[buffer][1] := t1 + $30
  
  t1 := value
  byte[buffer][3] := t1 + $30


PUB Toggle(pin, count)
  repeat count
    dira[pin]~~
      !outa[pin]
      waitcnt(80_000_000/8 + cnt)


     
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
CON
  _clkmode = xtal1 + pll16x     
  _xinfreq = 5_000_000

  #0, CLOSED, TCP, UDP, IPRAW, MACRAW, PPPOE

  CR    = $0D
  LF    = $0A

       
VAR

DAT
  request       byte  "GET /index.htm HTTP/1.1", CR, LF, {
}               byte  "User-Agent: Wiz5200", CR, LF, CR, LF, $0

  request2      byte  "GET /default.aspx HTTP/1.1", CR, LF, {
}               byte  "Host: agaverobotics.com", CR, LF, {
}               byte  "User-Agent: Wiz5200", CR, LF, CR, LF, $0
  buff          byte  $0[$200]






OBJ
  pst           : "Parallax Serial Terminal"
  sock          : "Socket"
  wiz           : "W5200"


 
PUB Main | bytesToRead, buffer, bytesSent, receiving

  receiving := true
  bytesToRead := 0
  pst.Start(115_200)
  pause(500)


  pst.str(string("Initialize", CR))
  'Initialize Socket 0 port 8080
  buffer := sock.Init(0, TCP, 8080)

  'Wiz Mac and Ip
  sock.Mac($00, $08, $DC, $16, $F8, $01)
  sock.Ip(192, 168, 1, 107)

  'Remote Ip 1 and port
  'sock.RemoteIp(192, 168, 1, 120)
  'sock.RemotePort(5000)

  'www.agaverobotics.com
  sock.RemoteIp(65, 98, 8, 151)
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
  bytesSent := sock.Send(@request2, strsize(@request2))
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
      pst.str(string("Done Receiving Data", CR))
      return

    if(bytesToRead > 0) 
      'Get the Rx buffer  
      buffer := sock.Receive
      pst.str(buffer)
      
    bytesToRead~

  pst.str(string(CR, "Disconnect", CR)) 
  sock.Disconnect
   
  
  

PUB PrintNameValue(name, value, digits) | len
  len := strsize(name)
  
  pst.str(name)
  repeat 30 - len
    pst.char($2E)
  if(digits > 0)
    pst.hex(value, digits)
  else
    pst.dec(value)
  pst.char(CR)


        
PUB DisplayMemory(addr, len, isHex) | j
  pst.char(13)
  pst.str(string("Start: "))
  pst.dec(addr)
  pst.str(string(" Len: "))
  pst.dec(len)
  pst.char($0D)
  
  pst.str(string("-------- Buffer Dump -----------",13, "    "))
  repeat j from 0 to 9
    pst.dec(j)
    pst.char($20)
    pst.char($20)
  pst.char(13)
  repeat j from 0 to len
    if(j == 0)
      pst.dec(0)
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
    if((j+1) // 10 == 0) 
      pst.char($0D)
      pst.dec((j+10)/10)
      pst.char($20)
      if((j+10)/10 < 10)
        pst.char($20)  
  pst.char(13)
  
PRI pause(Duration)  
  waitcnt(((clkfreq / 1_000 * Duration - 3932) #> 381) + cnt)
  return
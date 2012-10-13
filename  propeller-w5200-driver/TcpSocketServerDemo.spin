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
  index         byte  "HTTP/1.1 200 OK", CR, LF, {
}                     "Content-Type: text/html", CR, LF, CR, LF, {
}                     "Hello World!", CR, LF, $0

  buff            byte  $0[BUFFER_2K] 

OBJ
  pst           : "Parallax Serial Terminal"
  wiz           : "W5200" 
  sock          : "Socket"
 
PUB Main | bytesToRead

  bytesToRead := 0
  pst.Start(115_200)
  pause(500)

  'Set network parameters
  wiz.Init
  wiz.SetCommonnMode(0)
  wiz.SetGateway(192, 168, 1, 1)
  wiz.SetSubnetMask(255, 255, 255, 0)
  wiz.SetIp(192, 168, 1, 107)
  wiz.SetMac($00, $08, $DC, $16, $F8, $01)
  
  pst.str(string("Initialize Socket",CR))
  sock.Init(0, TCP, 8080)

  pst.str(string("Start Socket server",CR))
  repeat
  
    pst.str(string("Status "))  
    pst.dec(wiz.SocketStatus(0))
    pst.char(CR)
    
    pst.str(string(CR, "---------------------------",CR))
    pst.str(string("Open",CR))
    sock.Open

    pst.str(string("Status "))  
    pst.hex(wiz.SocketStatus(0), 2)
    pst.char(CR)

    
    if(sock.Listen)
      pst.str(string("Listen",CR))
    else
      pst.str(string("Listener failed!",CR))  

    'Connection?
    repeat until sock.Connected
      pause(100)

    pst.str(string("Connected",CR))
    
    'Data in the buufer?
    repeat until bytesToRead := sock.Available

    'Check for a timeout
    if(bytesToRead < 0)
      bytesToRead~
      next

    pst.str(string("Copy Rx Data",CR))
  
    'Get the Rx buffer  
    sock.Receive(@buff, bytesToRead)

    {{ Process the Rx data}}
    pst.char(CR)
    pst.str(string("Request:",CR))
    pst.str(@buff)

    pst.str(string("Send Response",CR))
    sock.Send(@index, strsize(@index))

    pst.str(string("Disconnect",CR))
    sock.Disconnect
    
    bytesToRead~
     
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
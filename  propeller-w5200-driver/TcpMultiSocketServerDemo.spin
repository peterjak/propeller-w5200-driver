CON
  _clkmode = xtal1 + pll16x     
  _xinfreq = 5_000_000

  BUFFER_2K     = $800
  
  CR            = $0D
  LF            = $0A
  NULL          = $00

  LISTENERS     = 4
  
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
  sock[4]          : "Socket"
 
PUB Main | i

  pst.Start(115_200)
  pause(500)

  wiz.Init 
  wiz.SetIp(192, 168, 1, 107)
  wiz.SetMac($00, $08, $DC, $16, $F8, $01)
  
  pst.str(string("Initialize Sockets",CR))
  repeat i from 0 to LISTENERS-1
    sock[i].Init(i, TCP, 8080)

  OpenListeners
  StartListners
      
  pst.str(string("Start Socket server",CR))
  MultiSocketServer
  pause(5000)

  
PUB OpenListeners | i
  pst.str(string("Open",CR))
  repeat i from 0 to LISTENERS-1  
    sock[i].Open
      
PUB StartListners | i
  repeat i from 0 to LISTENERS-1
    if(sock[i].Listen)
      pst.str(string("Listen "))
    else
      pst.str(string("Listener failed ",CR))
    pst.dec(i)
    pst.char(CR)



PUB MultiSocketServer | bytesToRead, i
  bytesToRead := i := 0
  repeat
    pst.str(string("TCP Service", CR))
    repeat until sock[i].Connected
      i := ++i // LISTENERS
      pause(100)    

    pst.str(string("Connected "))
    pst.dec(i)
    pst.char(CR)
    
    'Data in the buufer?
    repeat until bytesToRead := sock[i].Available

    'Check for a timeout
    if(bytesToRead < 0)
      bytesToRead~
      next

    pst.str(string("Copy Rx Data",CR))
  
    'Get the Rx buffer  
    sock[i].Receive(@buff, bytesToRead)

    {{ Process the Rx data}}
    pst.char(CR)
    pst.str(string("Request:",CR))
    pst.str(@buff)

    pst.str(string("Send Response",CR))
    sock[i].Send(@index, strsize(@index))

    pst.str(string("Disconnect",CR))
    sock[i].Disconnect
    sock[i].Open
    sock[i].Listen
    i := ++i // LISTENERS
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
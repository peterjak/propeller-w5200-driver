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
  sock          : "Socket"
  wiz           : "W5200"


 
PUB Main | bytesToRead

  bytesToRead := 0
  pst.Start(115_200)
  pause(500)

  pst.str(string("Initialize Socket",CR))

  'Initialize Socket 0 port 8080
  sock.Init(0, TCP, 8080)

  pst.str(string("Set Mac and IP",CR))
  sock.Mac($00, $08, $DC, $16, $F8, $01)
  sock.Ip(192, 168, 1, 107)


  pst.str(string("Start Socket server",CR))
  repeat
    pst.str(string(CR, "---------------------------",CR))
    pst.str(string("Open",CR))
    sock.Open

    pst.str(string("Listen",CR))
    sock.Listen

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
    sock.Receive(@buff)

    {{ Process the Rx data}}
    pst.char(CR)
    pst.str(string("Request:",CR))
    pst.str(@buff)

    pst.str(string("Send Response",CR))
    sock.Send(@index, strsize(@index))

    pst.str(string("Disconnect",CR))
    sock.Disconnect
    
    bytesToRead~


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
      pst.char($20)
      if(byte[addr+j] == 0)
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
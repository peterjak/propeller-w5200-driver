CON
  _clkmode = xtal1 + pll16x     
  _xinfreq = 5_000_000

  #0, CLOSED, TCP, UDP, IPRAW, MACRAW, PPPOE

  CR    = $0D
  LF    = $0A

       
VAR

DAT
  udpHead       byte  192, 168, 1, 104, $1F, $90, $00, $0C
  udpMsg        byte  "Hello World!", $0 
OBJ
  pst           : "Parallax Serial Terminal"
  sock          : "Socket"
  'wiz           : "W5200"


 
PUB Main | bytesToRead, buffer, bytesSent, receiving

  receiving := true
  bytesToRead := 0
  pst.Start(115_200)
  pause(500)


  pst.str(string("Initialize", CR))
  'Initialize Socket 0 port 8080
  buffer := sock.Init(0, UDP, 8080)

  'Wiz Mac and Ip
  sock.Mac($00, $08, $DC, $16, $F8, $01)
  sock.Ip(192, 168, 1, 107)

  
  pst.str(string("Start UPD Socket Server",CR))
  pst.str(string("Open",CR))
  pst.str(string(CR, "---------------------------",CR))
  repeat
    sock.Open
    
    'Data in the buufer?
    repeat until bytesToRead := sock.Available

    'Check for a timeout
    if(bytesToRead < 0)
      bytesToRead~
      next

    pst.str(string("Copy Rx Data",CR))
  
    'Get the Rx buffer  
    sock.Receive

    {{ Process the Rx data}}
    pst.char(CR)
    pst.str(string("Request:",CR))
    PrintIp(buffer)
    pst.dec(DeserializeWord(buffer + 4))
    pst.char(CR)
    
    pst.dec(DeserializeWord(buffer + 6))
    pst.char(CR)
    
    pst.str(buffer + 8)
    pst.char(CR)

    DisplayMemory(buffer, 36, true)
    
    pst.str(string("Send Response",CR))

    
    'sock.RemoteIp(192, 168, 1, 104)
    'sock.RemotePort(8080)
    'PrintIp(sock.GetIp)
    'pst.dec(sock.GetPort)
    
    sock.Send(@udpMsg, strsize(@udpMsg))

    pst.str(string("Disconnect",CR))
    sock.Disconnect
    
    bytesToRead~

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
      
PUB PrintIp(addr) | i
  repeat i from 0 to 3
    pst.dec(byte[addr][i])
    if(i < 3)
      pst.char($2E)
    else
      pst.char($0D)
      
PRI SerializeWord(value, buffer)
  byte[buffer++] := (value & $FF00) >> 8
  byte[buffer] := value & $FF

PRI DeserializeWord(buffer) | value
  value := byte[buffer++] << 8
  value += byte[buffer]
  return value
        
PRI pause(Duration)  
  waitcnt(((clkfreq / 1_000 * Duration - 3932) #> 381) + cnt)
  return